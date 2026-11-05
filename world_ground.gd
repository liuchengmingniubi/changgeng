extends Node2D
var game: Node
var last_scene: String=""
var last_cell:=Vector2i(-999,-999)
var refresh:=0.0
func _get(key: StringName) -> Variant: return game.get(key)
func movement_bounds() -> Rect2: return game.movement_bounds()
func text_at(p: Vector2,value: String,size_: int=16,color: Color=Color("efc888")) -> void:
	draw_string(game.font,p,value,HORIZONTAL_ALIGNMENT_LEFT,-1,size_,color)
func _process(delta: float) -> void:
	if game==null: return
	var cell:=Vector2i(game.camera_offset/24)
	refresh+=delta
	if last_scene!=game.scene_id or cell!=last_cell or (refresh>=0.25 and not game.modal.visible):
		last_scene=game.scene_id; last_cell=cell; refresh=0; queue_redraw()
func _draw() -> void:
	if game!=null:
		draw_set_transform(Vector2.ZERO,0,Vector2.ONE*(game.world_layout.SCALE if game.scene_id=="village" else 1.0))
		game.world_layout.ground(self)
