extends RefCounted
# 主角渲染：三张 48x88 图集（行走 / 挥剑 / 待机），全部由 tools/build_hero.py 生成。
# 手部锚点与刀身角度来自 hero_anim_data.gd，保证武器永远握在手里。
const Hero = preload("res://hero_anim_data.gd")

var walk: Texture2D          # 待机图集；背包头像与预览记录仍沿用这个字段
var flash: Texture2D         # 受击白闪
var frames: Array = []       # [朝向][帧] 待机帧区域，保持旧接口
var scale_factor := 1.0
const MAP_SHEET := "res://assets/art/hero_home_v4.png"
const MAP_HEIGHT := 87.0
var map_texture: Texture2D
var map_flash: Texture2D
var map_regions: Array = []
var sheets := {}
var flashes := {}


func setup() -> void:
	# 新版二头身图集独立于旧攻击锚点；各帧以透明边界和脚底对齐。
	var atlas := Image.new()
	if atlas.load(MAP_SHEET) == OK:
		map_texture = ImageTexture.create_from_image(atlas)
		var white: Image = atlas.duplicate()
		white.adjust_bcs(1.0, 0.0, 0.0)
		white.adjust_bcs(2.0, 1.0, 1.0)
		map_flash = ImageTexture.create_from_image(white)
		var cell := Vector2i(atlas.get_width() / 4, atlas.get_height() / 4)
		for row in range(4):
			for col in range(4):
				var offset := Vector2i(col, row) * cell
				var used := atlas.get_region(Rect2i(offset, cell)).get_used_rect()
				map_regions.append(Rect2(Vector2(offset + used.position), Vector2(used.size)))
	var ok := true
	for kind in ["walk", "attack", "idle"]:
		var path: String = {
			"walk": Hero.WALK_SHEET,
			"attack": Hero.ATTACK_SHEET,
			"idle": Hero.IDLE_SHEET,
		}[kind]
		var source := Image.new()
		if source.load(path) != OK:
			ok = false
			continue
		sheets[kind] = ImageTexture.create_from_image(source)
		var white: Image = source.duplicate()
		white.adjust_bcs(1.0, 0.0, 0.0)
		white.adjust_bcs(2.0, 1.0, 1.0)
		flashes[kind] = ImageTexture.create_from_image(white)
	if not ok:
		return
	walk = sheets["idle"]
	flash = flashes["idle"]
	for row in range(4):
		var list: Array = []
		for col in range(Hero.IDLE_FRAMES):
			list.append(Rect2(col * Hero.CELL.x, row * Hero.CELL.y, Hero.CELL.x, Hero.CELL.y))
		frames.append(list)


func direction(v: Vector2) -> int:
	if absf(v.x) > absf(v.y):
		return 2 if v.x > 0 else 1
	return 3 if v.y < 0 else 0


func sheet_name(kind: String) -> String:
	return {
		"walk": "hero_walk_v28.png",
		"attack": "hero_attack_v28.png",
		"idle": "hero_idle_v28.png",
	}.get(kind, "")


func hero(g: Node, p: Vector2) -> void:
	if not sheets.has("idle"):
		return
	var dir := direction(g.facing)
	var attacking: bool = g.attack_time > 0.0
	var moving: bool = g.actual_walk
	var kind := "attack" if attacking else ("walk" if moving else "idle")
	var frame := 0
	var progress := 0.0
	if attacking:
		progress = clampf(1.0 - g.attack_time / maxf(0.001, g.attack_duration), 0.0, 0.999)
		frame = clampi(int(progress * Hero.ATTACK_FRAMES), 0, Hero.ATTACK_FRAMES - 1)
	elif kind == "walk":
		frame = int(g.movement_time * 9.0) % Hero.WALK_FRAMES
	else:
		frame = int(g.elapsed * 2.0) % Hero.IDLE_FRAMES

	if map_texture != null:
		draw_map_hero(g, p, dir, moving, attacking, frame, progress)
		return
	var origin := (p - Vector2(Hero.CELL.x * 0.5, Hero.FOOT_LIFT)).round()
	var region := Rect2(frame * Hero.CELL.x, dir * Hero.CELL.y, Hero.CELL.x, Hero.CELL.y)
	var texture: Texture2D = flashes[kind] if g.hurt_flash > 0 else sheets[kind]
	var tint := Color("ffffff") if g.hurt_flash > 0 else Color("fff7e7")
	var hand: Vector2 = origin + Hero.hand(kind, dir, frame)

	g.draw_ellipse_shadow(p)
	# 背对镜头时剑在身后，先画剑再画人
	if attacking and dir == 3:
		strike(g, origin, dir, frame, progress, hand)
	g.draw_texture_rect_region(texture, Rect2(origin, Hero.CELL), region, tint)
	if attacking:
		if dir != 3:
			strike(g, origin, dir, frame, progress, hand)
	else:
		held(g, p, hand)


func draw_map_hero(g: Node, p: Vector2, dir: int, moving: bool, attacking: bool, attack_frame: int, progress: float) -> void:
	# 未提供新版挥剑图集：保持新版身体，以现有六阶段剑轨表现攻击。
	var pose := int(g.movement_time * 9.0) % 4 if moving and not attacking else 1
	var region: Rect2 = map_regions[dir * 4 + pose]
	if region.size.y <= 0:
		return
	var size := region.size * (MAP_HEIGHT / region.size.y)
	var destination := Rect2((p - Vector2(size.x * 0.5, size.y)).round(), size)
	var side := -1.0 if dir == 1 else 1.0
	var hand := p + Vector2(side * size.x * 0.32, -MAP_HEIGHT * 0.30)
	var old_origin := hand - Hero.hand("attack", dir, attack_frame)
	g.draw_ellipse_shadow(p)
	if attacking and dir == 3:
		strike(g, old_origin, dir, attack_frame, progress, hand)
	g.draw_texture_rect_region(map_flash if g.hurt_flash > 0 else map_texture, destination, region)
	if attacking and dir != 3:
		strike(g, old_origin, dir, attack_frame, progress, hand)
	elif not attacking:
		held(g, p, hand)


func strike(g: Node, origin: Vector2, dir: int, frame: int, progress: float, hand: Vector2) -> void:
	var trail := PackedVector2Array()
	for i in range(maxi(0, frame - 2), frame + 1):
		var at: Vector2 = origin + Hero.hand("attack", dir, i)
		trail.append(at + Vector2.from_angle(deg_to_rad(Hero.ATTACK_BLADE[dir][i])) * 50.0)
	g.draw_sword_at(hand, deg_to_rad(Hero.ATTACK_BLADE[dir][frame]), progress, trail)


func held(g: Node, p: Vector2, hand_at: Vector2 = Vector2.INF) -> void:
	if g.life.waking or g.eating_time > 0:
		return
	var item: String = str(g.quickbar[g.quickbar_index])
	if item == "" or int(g.inventory.get(item, 0)) <= 0:
		return
	var side: int = -1 if g.facing.x < 0 else 1
	var hand: Vector2 = hand_at
	if hand_at == Vector2.INF:
		hand = (p + Vector2(side * 17, -32 + sin(g.movement_time * 9))).round()
		g.draw_line(p + Vector2(side * 11, -48), hand, Color("3f6f6c"), 6, false)
	preload("res://item_art.gd").draw(g, item, Rect2(hand - Vector2(13, 19), Vector2(26, 26)))
	g.draw_rect(Rect2(hand - Vector2(3, 2), Vector2(6, 5)), Color("e3b78a"))


func npc(g: Node, p: Vector2, id: String) -> void:
	var state: Dictionary = g.npc_life.live[id]; var velocity: Vector2 = state.get("facing", Vector2.DOWN)
	var d := direction(velocity); var moving: bool = state.get("moving", false)
	var step_: int = [-3, 0, 3, 0][int(g.elapsed * 8) % 4] if moving else 0
	var coat := Color(g.npc_life.PEOPLE[id].color); var skin := Color("d8b18a"); var hair := Color("373833")
	if id in ["elder", "scout", "farmer"]: hair = Color("b4ae98")
	g.draw_ellipse_shadow(p)
	var q := p.round()
	# Fixed-size pixel clusters; changing poses only offsets limbs.
	for side in [-1, 1]:
		var at := q + Vector2(side * 7 - 5, -23 + step_ * side)
		g.draw_rect(Rect2(at - Vector2.ONE, Vector2(12, 24)), Color("2a3831")); g.draw_rect(Rect2(at, Vector2(10, 21)), Color("535249"))
		g.draw_rect(Rect2(at + Vector2(-2, 18), Vector2(14, 6)), Color("3c342b"))
	var width := 23 if d in [1, 2] else 34
	g.draw_rect(Rect2(q + Vector2(-width / 2.0 - 2, -59), Vector2(width + 4, 40)), Color("293e35"))
	g.draw_rect(Rect2(q + Vector2(-width / 2.0, -57), Vector2(width, 35)), coat)
	g.draw_rect(Rect2(q + Vector2(-width / 2.0 + 3, -55), Vector2(5, 29)), coat.lightened(0.2))
	g.draw_rect(Rect2(q + Vector2(-width / 2.0, -31), Vector2(width, 6)), Color("79573a")); g.draw_rect(Rect2(q + Vector2(-3, -31), Vector2(7, 5)), Color("d0b16a"))
	for side in [-1, 1]:
		var arm := q + Vector2(side * (width / 2.0 + 3) - 4, -55 - step_ * side)
		g.draw_rect(Rect2(arm - Vector2.ONE, Vector2(10, 29)), Color("2e4035")); g.draw_rect(Rect2(arm, Vector2(8, 22)), coat.darkened(0.1)); g.draw_rect(Rect2(arm + Vector2(1, 21), Vector2(6, 6)), skin)
	g.draw_rect(Rect2(q + Vector2(-15, -84), Vector2(30, 29)), Color("2a3930")); g.draw_rect(Rect2(q + Vector2(-13, -81), Vector2(26, 23)), skin)
	g.draw_rect(Rect2(q + Vector2(-15, -87), Vector2(30, 10)), hair); g.draw_rect(Rect2(q + Vector2(-7, -95), Vector2(14, 12)), hair)
	if d == 3: g.draw_rect(Rect2(q + Vector2(-13, -81), Vector2(26, 18)), hair)
	elif d in [1, 2]:
		var eye := q + Vector2(-10 if d == 1 else 8, -71); g.draw_rect(Rect2(eye, Vector2(3, 4)), Color("28382f"))
		g.draw_rect(Rect2(q + Vector2(8 if d == 1 else -13, -79), Vector2(5, 19)), hair)
	else:
		for side in [-1, 1]: g.draw_rect(Rect2(q + Vector2(side * 7 - 1, -71), Vector2(3, 4)), Color("273930"))
	if id in ["captain", "guard_day", "guard_night", "soldier"]:
		for x in [-10, 0, 10]: g.draw_rect(Rect2(q + Vector2(x - 3, -50), Vector2(6, 13)), Color("a8b49b"))
	if id in ["elder", "scout"] and d != 3: g.draw_rect(Rect2(q + Vector2(-5, -60), Vector2(10, 8)), hair)
	g.world_layout.tag(g, p + Vector2(0, -109), g.npc_life.PEOPLE[id].name, true)