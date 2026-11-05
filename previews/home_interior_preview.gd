extends Node2D
# 「主角家室内」独立预览场景：只用 assets/art/home_interior/ 里的素材与 layout.json。
# 素材是用户提供的 PNG 拼的（外壳 / 地面 / 床 / 桌 / 椅 / 箱 / 灶台 / 圆桌 / 遗书 / 油灯），没有重画。
# 不改正式地图、不改 main.gd。
#
# 画面分层：地面 → 外壳上半（后墙 + 立柱）→ 物件（按脚底 y 与人物混排）→ 人物 → 外壳下半（前矮墙 + 台阶）
# 玩法：WASD / 方向键走动，空格挥剑；走到书桌前按空格读旧家书。
# 截图：-- --shot=res://previews/home_interior/preview.png
# 行走录像：-- --demo=<绝对目录> --frames=300

const ART := "res://assets/art/home_interior/"
const LAYOUT := ART + "layout.json"
const SPEED := 150.0
const FRAME_DT := 1.0 / 30.0
const FOOT_RADIUS := 9.0

const LETTER_TITLE := "父母的遗书 · 剧情草稿"
const LETTER_LINES := [
	"承安：",
	"家中的东西都收在旧箱里。往后无论走多远，记得好好吃饭，照顾自己。",
	"我们盼你平安，也盼你能做自己认定的事。",
	"",
	"——父亲陆怀朴，母亲沈宜宁",
	"信纸已经泛黄，折痕处被仔细补过。里面的话，我早已记得。",
]

# 演示路点：进门 → 顶到书桌前（碰撞）→ 读遗书 → 绕过箱子 → 走到床后（遮挡）→ 横穿 → 顶到圆桌 → 灶台
const DEMO_PAUSE := {3: 50, 5: 26}
const DEMO_PATH := [
	Vector2(665, 640),
	Vector2(430, 600),
	Vector2(430, 486),
	Vector2(284, 428),
	Vector2(430, 422),
	Vector2(760, 560),
	Vector2(862, 600),
	Vector2(1058, 560),
]

# actor_visual.hero() 需要的宿主状态
var facing := Vector2(0, -1)
var attack_time := 0.0
var attack_duration := 0.30
var movement_time := 0.0
var elapsed := 0.0
var actual_walk := false
var walk_blend := 0.0
var hurt_flash := 0.0
var eating_time := 0.0
var quickbar: Array = [&""]
var quickbar_index := 0
var inventory := {}
var life := {"waking": false}

var pos := Vector2(665, 668)
var moving := false
var reading := false
var prompt := ""

var visual := preload("res://actor_visual.gd").new()
var ui_font: Font = preload("res://assets/font.otf")
var ground: Texture2D
var frame_back: Texture2D
var frame_front: Texture2D
var frame_back_pos := Vector2.ZERO
var frame_front_pos := Vector2.ZERO
var objects: Array = []
var colliders: Array = []
var interact: Array = []
var tex_cache := {}

var shot_path := ""
var shot_frames := 0
var demo_dir := ""
var demo_len := 300
var demo_index := -1
var demo_goal := 0
var demo_goal_frames := 0
var demo_wait := 0
var draw_hero := true


func _ready() -> void:
	visual.setup()
	ground = load(ART + "ground.png")
	var layout: Dictionary = _read_json(LAYOUT)
	objects = layout.get("objects", [])
	objects.sort_custom(func(a, b): return float(a["sort"]) < float(b["sort"]))
	colliders = layout.get("colliders", [])
	interact = layout.get("interact", [])
	var frame: Dictionary = layout.get("frame", {})
	if frame.has("back"):
		frame_back = load(ART + str(frame["back"]["tex"]) + ".png")
		frame_back_pos = Vector2(float(frame["back"]["x"]), float(frame["back"]["y"]))
	if frame.has("front"):
		frame_front = load(ART + str(frame["front"]["tex"]) + ".png")
		frame_front_pos = Vector2(float(frame["front"]["x"]), float(frame["front"]["y"]))
	var st: Array = layout.get("start", [665, 668])
	pos = Vector2(float(st[0]), float(st[1]))
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--shot="):
			shot_path = a.substr(7)
		elif a.begins_with("--demo="):
			demo_dir = a.substr(7)
		elif a.begins_with("--frames="):
			demo_len = int(a.substr(9))
		elif a == "--nohero":
			draw_hero = false
	if demo_dir != "":
		demo_index = 0
	queue_redraw()


func _read_json(path: String) -> Dictionary:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("读不到 " + path)
		return {}
	var data = JSON.parse_string(f.get_as_text())
	return data if data is Dictionary else {}


func _tex(name: String) -> Texture2D:
	if not tex_cache.has(name):
		tex_cache[name] = load(ART + name + ".png")
	return tex_cache[name]


func _draw_object(o: Dictionary) -> void:
	var tex := _tex(str(o["tex"]))
	if tex == null:
		return
	var size := tex.get_size()
	draw_texture(tex, Vector2(float(o["x"]) - size.x * 0.5, float(o["y"]) - size.y).round())


func _blocked(p: Vector2) -> bool:
	for c in colliders:
		var r := Rect2(float(c[0]), float(c[1]), float(c[2]), float(c[3]))
		if r.grow(FOOT_RADIUS).has_point(p):
			return true
	return false


func _near_interact() -> Dictionary:
	for it in interact:
		var r: Array = it["rect"]
		if Rect2(float(r[0]), float(r[1]), float(r[2]), float(r[3])).has_point(pos):
			return it
	return {}


func _step(dt: float, dir: Vector2) -> void:
	var moved := false
	if dir.length() > 0.01:
		facing = dir
		var d := dir.normalized() * SPEED * dt
		var before := pos
		pos.x += d.x
		if _blocked(pos):
			pos.x -= d.x
		pos.y += d.y
		if _blocked(pos):
			pos.y -= d.y
		moved = pos.distance_squared_to(before) > 0.0001
	# 撞墙/撞家具时停在原地：位移与走路动画一起停，不再原地踏步
	moving = moved
	if moved:
		movement_time += dt
	if moved:
		walk_blend = minf(1.0, walk_blend + dt * 8.0)
	else:
		walk_blend = maxf(0.0, walk_blend - dt * 10.0)
	actual_walk = moved
	elapsed += dt
	if attack_time > 0.0:
		attack_time = maxf(0.0, attack_time - dt)


func _demo_dir() -> Vector2:
	if demo_index < 6:
		return Vector2.ZERO
	if demo_wait > 0:
		demo_wait -= 1
		return Vector2.ZERO
	while demo_goal < DEMO_PATH.size():
		var goal: Vector2 = DEMO_PATH[demo_goal]
		var to := goal - pos
		demo_goal_frames += 1
		# 走不到（被家具挡住）就按帧数放行，别让录像卡在一个点上
		if to.length() <= 5.0 or demo_goal_frames > 66:
			demo_goal += 1
			demo_goal_frames = 0
			var pause: int = int(DEMO_PAUSE.get(demo_goal, 0))
			if pause > 0:
				demo_wait = pause
			continue
		if absf(to.x) > 3.0:
			return Vector2(signf(to.x), 0)
		return Vector2(0, signf(to.y))
	return Vector2.ZERO


func _process(delta: float) -> void:
	if demo_dir != "":
		if demo_index >= demo_len:
			get_tree().quit()
			return
		var d := _demo_dir()
		var it := _near_interact()
		prompt = str(it.get("prompt", ""))
		reading = demo_wait > 0
		_step(FRAME_DT, d)
		queue_redraw()
		# 用 process_frame 等一帧，避免窗口失焦时 frame_post_draw 不再触发导致录像卡死
		await get_tree().process_frame
		await get_tree().process_frame
		var img := get_viewport().get_texture().get_image()
		if demo_index % 15 == 0:
			print("DEMO %d pos=%s goal=%d" % [demo_index, pos, demo_goal])
		var err := img.save_png(demo_dir.path_join("f_%03d.png" % demo_index))
		if err != OK:
			print("DEMO frame %d err=%d" % [demo_index, err])
		demo_index += 1
		return

	if shot_path != "":
		shot_frames += 1
		if shot_frames == 3:
			await RenderingServer.frame_post_draw
			var img := get_viewport().get_texture().get_image()
			var err := img.save_png(ProjectSettings.globalize_path(shot_path))
			print("SHOT %s err=%d size=%s" % [shot_path, err, img.get_size()])
			get_tree().quit()
			return

	if reading:
		if Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("ui_cancel"):
			reading = false
		queue_redraw()
		return

	var dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if dir.length() > 0.01:
		if absf(dir.x) > absf(dir.y):
			dir = Vector2(signf(dir.x), 0)
		else:
			dir = Vector2(0, signf(dir.y))
	var it := _near_interact()
	prompt = str(it.get("prompt", ""))
	if not prompt.is_empty() and Input.is_action_just_pressed("ui_accept"):
		reading = true
		queue_redraw()
		return
	if Input.is_action_just_pressed("ui_accept") and attack_time <= 0.0:
		attack_time = attack_duration
	_step(delta, dir)
	queue_redraw()


func _draw() -> void:
	if ground != null:
		draw_texture(ground, Vector2.ZERO)
	if frame_back != null:
		draw_texture(frame_back, frame_back_pos)
	var hero_y := pos.y
	var split := objects.size()
	for i in range(objects.size()):
		if float(objects[i]["sort"]) > hero_y:
			split = i
			break
	for i in range(split):
		_draw_object(objects[i])
	if draw_hero:
		draw_ellipse_shadow(pos)
		visual.hero(self, pos)
	for i in range(split, objects.size()):
		_draw_object(objects[i])
	if frame_front != null:
		draw_texture(frame_front, frame_front_pos)
	if not prompt.is_empty() and not reading:
		_hint(prompt)
	if reading:
		_draw_letter()


func _hint(text: String) -> void:
	var w := ui_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x
	var at := Vector2(pos.x - w * 0.5, pos.y - 108.0)
	draw_rect(Rect2(at + Vector2(-10, -19), Vector2(w + 20, 28)), Color(0.08, 0.06, 0.04, 0.78))
	draw_rect(Rect2(at + Vector2(-10, -19), Vector2(w + 20, 28)), Color(0.72, 0.61, 0.36, 0.75), false, 1.0)
	draw_string(ui_font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("efe3c2"))


func _draw_letter() -> void:
	var box := Rect2(196, 150, 888, 452)
	draw_rect(box, Color(0.09, 0.06, 0.04, 0.95))
	draw_rect(box.grow(-4.0), Color(0.72, 0.61, 0.36, 0.55), false, 2.0)
	draw_string(ui_font, box.position + Vector2(40, 62), LETTER_TITLE, HORIZONTAL_ALIGNMENT_LEFT, -1, 27, Color("efe3c2"))
	draw_line(box.position + Vector2(40, 84), box.position + Vector2(box.size.x - 40, 84), Color(0.72, 0.61, 0.36, 0.45), 1.0)
	var y := box.position.y + 136.0
	for line in LETTER_LINES:
		draw_string(ui_font, Vector2(box.position.x + 40, y), line, HORIZONTAL_ALIGNMENT_LEFT,
				box.size.x - 80, 22, Color("e6dcc0"))
		y += 44.0
	draw_string(ui_font, Vector2(box.position.x + 40, box.end.y - 30), "空格：合上",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("b9a97e"))


func draw_ellipse_shadow(p: Vector2) -> void:
	_blob(p + Vector2(0, 2), 12.0, 4.8, Color(0.05, 0.06, 0.05, 0.18))
	_blob(p + Vector2(0, 2), 8.0, 3.2, Color(0.05, 0.06, 0.05, 0.28))


func _blob(center: Vector2, rx: float, ry: float, color: Color) -> void:
	var pts := PackedVector2Array()
	for i in range(20):
		var a := TAU * float(i) / 20.0
		pts.append(center + Vector2(cos(a) * rx, sin(a) * ry))
	draw_colored_polygon(pts, color)


func draw_sword_at(hand: Vector2, angle: float, progress: float,
		trail: PackedVector2Array = PackedVector2Array()) -> void:
	if trail.size() > 1:
		draw_polyline(trail, Color(0.96, 0.93, 0.72, sin(progress * PI) * 0.42), 6, true)
	var d := Vector2.from_angle(angle)
	var side := Vector2(-d.y, d.x)
	var guard := hand - d * 3.0
	var tip := hand + d * 34.0
	draw_line(guard, tip, Color("2b1d12"), 5, true)
	draw_line(guard - d * 2.0, tip - d * 3.0, Color("cbdcd4"), 3, true)
	draw_line(guard - d * 3.0, tip - d * 5.0, Color("f1f5d6"), 1, true)
	draw_line(guard - side * 5.0, guard + side * 5.0, Color("bda36a"), 3, true)
	draw_line(hand - d * 9.0, hand - d * 2.0, Color("6b4b32"), 4, true)
