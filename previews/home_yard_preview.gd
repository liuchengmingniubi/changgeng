extends Node2D
# 「主角家门口一屏」独立预览场景：只读 assets/art/home_yard/ 的素材与 layout.json。
# 不参与正式地图，不改动 main.gd / world_*.gd 的任何逻辑。

const ART := "res://assets/art/home_yard/"
const LAYOUT := ART + "layout.json"
const HERO_POS := Vector2(520.0, 620.0)

# actor_visual.hero() 需要的宿主状态，这里给一组静止的默认值
var facing := Vector2(0, 1)
var attack_time := 0.0
var attack_duration := 0.3
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

func draw_ellipse_shadow(p: Vector2) -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.42))
	draw_circle(p + Vector2(0, 8), 13.0, Color(0.06, 0.09, 0.08, 0.30))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

var textures := {}
var props_atlas: Texture2D
var props_index := {}
var objects: Array = []
var ground: Texture2D
var visual := preload("res://actor_visual.gd").new()

var shot_path := ""
var shot_frames := 0


func _ready() -> void:
	visual.setup()
	ground = load(ART + "ground.png")
	props_atlas = load(ART + "props.png")
	props_index = _read_json(ART + "props.json")
	var layout: Dictionary = _read_json(LAYOUT)
	for o in layout.get("objects", []):
		objects.append(o)
	objects.sort_custom(func(a, b): return float(a["sort"]) < float(b["sort"]))
	for name in ["house", "tree_big", "tree_small", "fence", "gate",
			"crops_0", "crops_1", "crops_2"]:
		textures[name] = load(ART + name + ".png")
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--shot="):
			shot_path = a.substr(7)
	queue_redraw()


func _read_json(path: String) -> Dictionary:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("读不到 " + path)
		return {}
	var data = JSON.parse_string(f.get_as_text())
	return data if data is Dictionary else {}


func _tex_for(o: Dictionary) -> Texture2D:
	var name: String = str(o["tex"])
	if name.begins_with("prop:"):
		return props_atlas
	return textures.get(name)


func _region_for(o: Dictionary) -> Rect2:
	var name: String = str(o["tex"])
	if name.begins_with("prop:"):
		var idx: int = int(props_index.get(name.substr(5), 0))
		return Rect2((idx % 4) * 32, (idx / 4) * 32, 32, 32)
	var tex: Texture2D = textures.get(name)
	return Rect2(Vector2.ZERO, tex.get_size()) if tex != null else Rect2()


func _draw() -> void:
	if ground != null:
		draw_texture(ground, Vector2.ZERO)
	for o in objects:
		var tex := _tex_for(o)
		if tex == null:
			continue
		var region := _region_for(o)
		var pos := Vector2(float(o["x"]) - region.size.x * 0.5, float(o["y"]) - region.size.y)
		draw_texture_rect_region(tex, Rect2(pos.round(), region.size), region)
	visual.hero(self, HERO_POS)


func _process(delta: float) -> void:
	elapsed += delta
	if shot_path != "":
		shot_frames += 1
		if shot_frames == 3:
			await RenderingServer.frame_post_draw
			var img := get_viewport().get_texture().get_image()
			var err := img.save_png(ProjectSettings.globalize_path(shot_path))
			print("SHOT %s err=%d size=%s" % [shot_path, err, img.get_size()])
			get_tree().quit()
	queue_redraw()
