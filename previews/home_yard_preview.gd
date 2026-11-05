extends Node2D
# 「主角家门口一屏」独立预览场景：只读 assets/art/home_yard/ 的素材与 layout.json。
# 不参与正式地图，不改动 main.gd / world_*.gd 的任何逻辑。
#
# 玩法：WASD / 方向键走动，空格挥剑；人物按脚底 y 与场景物件一起排序，栅栏、菜畦、水井会挡在前面。
# 碰撞：layout.json 的 colliders 是一组轴对齐矩形，逐轴推开。
# 截图：-- --shot=res://previews/home_yard/preview.png
# 行走演示：-- --demo=<绝对目录> --frames=72  （每帧 1/30 秒固定步长，逐帧存 PNG）

const ART := "res://assets/art/home_yard/"
const LAYOUT := ART + "layout.json"
const SPEED := 150.0
const FRAME_DT := 1.0 / 30.0
const FOOT_RADIUS := 9.0

# actor_visual.hero() 需要的宿主状态
var facing := Vector2(0, 1)
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

var pos := Vector2(440.0, 566.0)
var moving := false

var visual := preload("res://actor_visual.gd").new()
var ground: Texture2D
var objects: Array = []
var colliders: Array = []
var tex_cache := {}

var shot_path := ""
var shot_frames := 0
var demo_dir := ""
var demo_len := 72
var demo_index := -1
var draw_hero := true


func _ready() -> void:
	visual.setup()
	ground = load(ART + "ground.png")
	var layout: Dictionary = _read_json(LAYOUT)
	objects = layout.get("objects", [])
	objects.sort_custom(func(a, b): return float(a["sort"]) < float(b["sort"]))
	colliders = layout.get("colliders", [])
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
	var at := Vector2(float(o["x"]) - size.x * 0.5, float(o["y"]) - size.y)
	draw_texture(tex, at.round())


func _blocked(p: Vector2) -> bool:
	for c in colliders:
		var r := Rect2(float(c[0]), float(c[1]), float(c[2]), float(c[3]))
		if r.grow(FOOT_RADIUS).has_point(p):
			return true
	return false


func _step(dt: float, dir: Vector2) -> void:
	if dir.length() > 0.01:
		moving = true
		facing = dir
		var d := dir.normalized() * SPEED * dt
		pos.x += d.x
		if _blocked(pos):
			pos.x -= d.x
		pos.y += d.y
		if _blocked(pos):
			pos.y -= d.y
		movement_time += dt
		walk_blend = minf(1.0, walk_blend + dt * 8.0)
	else:
		moving = false
		walk_blend = maxf(0.0, walk_blend - dt * 8.0)
	actual_walk = moving
	elapsed += dt
	if attack_time > 0.0:
		attack_time = maxf(0.0, attack_time - dt)


func _demo_dir() -> Vector2:
	var t := float(demo_index) * FRAME_DT
	if t < 0.9:
		return Vector2(1, 0)
	elif t < 1.5:
		return Vector2(1, -1)
	elif t < 2.1:
		return Vector2(0, -1)
	elif t < 2.9:
		return Vector2(-1, 0)
	elif t < 3.4:
		return Vector2(-1, 1)
	return Vector2.ZERO


func _process(delta: float) -> void:
	if demo_dir != "":
		if demo_index >= demo_len:
			get_tree().quit()
			return
		var dir := _demo_dir()
		if demo_index == 6:
			attack_time = attack_duration
		_step(FRAME_DT, dir)
		queue_redraw()
		await RenderingServer.frame_post_draw
		var img := get_viewport().get_texture().get_image()
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

	var dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if dir.length() > 0.01:
		# 八向输入收敛成四向，人物精灵只有四个朝向
		if absf(dir.x) > absf(dir.y):
			dir = Vector2(signf(dir.x), 0)
		else:
			dir = Vector2(0, signf(dir.y))
	if Input.is_action_just_pressed("ui_accept") and attack_time <= 0.0:
		attack_time = attack_duration
	_step(delta, dir)
	queue_redraw()


func _draw() -> void:
	if ground != null:
		draw_texture(ground, Vector2.ZERO)
	# 人物按脚底 y 插进排序表：站在栅栏北侧时，栅栏要压住他的小腿。
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


func draw_ellipse_shadow(p: Vector2) -> void:
	# p 是脚底点。阴影压在脚底、只往南偏 2 像素，两圈同心椭圆做软边。
	# 注意：不能用 draw_set_transform 缩放坐标系——那样会把圆心 p 也一起压扁到画面上方。
	_blob(p + Vector2(0, 2), 13.0, 5.2, Color(0.06, 0.09, 0.08, 0.16))
	_blob(p + Vector2(0, 2), 9.0, 3.6, Color(0.06, 0.09, 0.08, 0.26))


func _blob(center: Vector2, rx: float, ry: float, color: Color) -> void:
	var pts := PackedVector2Array()
	for i in range(20):
		var a := TAU * float(i) / 20.0
		pts.append(center + Vector2(cos(a) * rx, sin(a) * ry))
	draw_colored_polygon(pts, color)


func draw_sword_at(hand: Vector2, angle: float, progress: float,
		trail: PackedVector2Array = PackedVector2Array()) -> void:
	# 预览场景里把剑画成硬边像素长条，和 v28 人物图集的笔触一致；
	# 刀光只留一条半透明的弧，不再用 main.gd 的矢量武器造型。
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
