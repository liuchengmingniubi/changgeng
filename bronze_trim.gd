extends Node2D
func _ready() -> void:
	z_index=5
	get_parent().resized.connect(queue_redraw)
func _draw() -> void:
	var area: Vector2=get_parent().size
	if area.x<50 or area.y<35: return
	var gold:=Color("bda36a"); var dark:=Color("567263")
	for x in [9,area.x-9]:
		for y in [9,area.y-9]:
			var sx:=1 if x<area.x/2 else -1; var sy:=1 if y<area.y/2 else -1
			draw_line(Vector2(x,y),Vector2(x+sx*19,y),gold,2,false)
			draw_line(Vector2(x,y),Vector2(x,y+sy*17),gold,2,false)
			draw_rect(Rect2(Vector2(x+sx*6-2,y+sy*6-2),Vector2(4,4)),gold)
			draw_line(Vector2(x+sx*12,y+sy*4),Vector2(x+sx*12,y+sy*12),dark,2,false)
	draw_line(Vector2(32,5),Vector2(area.x-32,5),Color("cdd4ad"),1,false)
