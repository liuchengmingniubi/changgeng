extends Control
var hero: Texture2D
var region:=Rect2()
var font: Font
var owner_game: Node
var accessories_open:=false
signal slot_clicked(slot: String)
const SLOT_NAMES := ["头盔","护甲","护腿","时装","手套","腰带","鞋靴","项链","戒指","手环"]
func _ready() -> void:
	custom_minimum_size=Vector2(420,310)
	mouse_filter=Control.MOUSE_FILTER_STOP
func slot_rect(i: int) -> Rect2:
	if i<4: return Rect2(Vector2(4,8+i*74),Vector2(78,66))
	return Rect2(Vector2(244+(1 if i>=7 else 0)*85,63+((i-4)%3)*74),Vector2(78,66))
func visible_slot(i: int) -> bool: return i<4 or accessories_open
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index in [MOUSE_BUTTON_LEFT,MOUSE_BUTTON_RIGHT]:
		if Rect2(370,8,40,40).has_point(event.position): accessories_open=not accessories_open; queue_redraw(); accept_event(); return
		for i in range(SLOT_NAMES.size()):
			if visible_slot(i) and slot_rect(i).has_point(event.position): slot_clicked.emit(SLOT_NAMES[i]); accept_event()
func _get_tooltip(at: Vector2) -> String:
	if Rect2(370,8,40,40).has_point(at): return "显示／收起饰品栏"
	for i in range(SLOT_NAMES.size()):
		if visible_slot(i) and slot_rect(i).has_point(at):
			var item: String=str(owner_game.equipment.worn.get(SLOT_NAMES[i],"")) if owner_game else ""
			return SLOT_NAMES[i]+("（空）" if item=="" else "："+item+"\n"+owner_game.equipment.description(item)+"\n点击卸下")
	return ""
func _make_custom_tooltip(text: String) -> Object:
	var helper=load("res://item_slot.gd").new()
	helper.icon_font=font; helper.tooltip_text=text
	var panel: Object=helper._make_custom_tooltip(text)
	helper.free()
	return panel
func _draw() -> void:
	draw_rect(Rect2(0,0,420,310),Color("d3ddbf"))
	if hero:
		var h:=235.0
		var w:=region.size.x/region.size.y*h
		draw_texture_rect_region(hero,Rect2(210-w/2,38,w,h),region)
	draw_arc(Vector2(390,27),11,0,TAU,24,Color.WHITE,2)
	draw_circle(Vector2(390,14),3,Color.WHITE)
	for i in range(SLOT_NAMES.size()):
		if not visible_slot(i): continue
		var rect:=slot_rect(i)
		var occupied: bool=owner_game!=null and str(owner_game.equipment.worn.get(SLOT_NAMES[i],""))!=""
		draw_rect(rect,Color("c7d6af") if occupied else Color("b9caa6"))
		draw_rect(rect,Color("c4a55e") if occupied else Color("87976f"),false,2)
		if font:
			draw_string(font,rect.position+Vector2(12,25),SLOT_NAMES[i],HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("45634d"))
			if occupied: draw_string(font,rect.position+Vector2(9,51),"已穿戴",HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("304e3b"))
