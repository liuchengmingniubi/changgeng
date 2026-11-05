extends Button
var item_name := ""
var quantity := 0
var cooldown_seconds:=0.0
var icon_font: Font
var selected := false
var jade := false
var golden := false
var slot_minimum := Vector2(92,68)
var drag_payload := {}
signal dropped(payload: Dictionary)
signal context_requested
signal quantity_requested
static var atlas: Texture2D
const ICONS := {"镐子":Rect2(56,167,351,375),"斧子":Rect2(467,171,371,371),"父母遗书":Rect2(897,213,363,293),"初始种子":Rect2(1330,203,364,312),"锄头":Rect2(1769,166,353,376)}
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index==MOUSE_BUTTON_RIGHT:
			context_requested.emit(); accept_event()
		elif event.button_index==MOUSE_BUTTON_LEFT and event.shift_pressed:
			quantity_requested.emit(); accept_event()

func _make_custom_tooltip(_for_text: String) -> Object:
	var panel:=PanelContainer.new()
	var style:=StyleBoxFlat.new(); style.bg_color=Color("e0e5cdfc"); style.border_color=Color("b79555"); style.set_border_width_all(2); style.set_content_margin_all(12)
	panel.add_theme_stylebox_override("panel",style)
	var text:=RichTextLabel.new(); text.bbcode_enabled=true; text.fit_content=true; text.custom_minimum_size.x=360
	text.add_theme_color_override("default_color",Color("244b3d")); text.add_theme_font_size_override("normal_font_size",14)
	if icon_font: text.add_theme_font_override("normal_font",icon_font)
	text.text=tooltip_text; panel.add_child(text); return panel

func _get_drag_data(_position: Vector2) -> Variant:
	if item_name=="" or drag_payload.is_empty(): return null
	var preview:=Label.new()
	preview.text=item_name+" ×"+str(quantity)
	if icon_font: preview.add_theme_font_override("font",icon_font)
	set_drag_preview(preview)
	return drag_payload
func _can_drop_data(_position: Vector2,data: Variant) -> bool:
	return data is Dictionary and data.has("key") and not drag_payload.get("locked",false)
func _drop_data(_position: Vector2,data: Variant) -> void:
	dropped.emit(data)

func _ready() -> void:
	preload("res://item_art.gd").setup()
	custom_minimum_size = slot_minimum
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if item_name!="" else Control.CURSOR_ARROW
	if tooltip_text.is_empty(): tooltip_text = item_name+" ×"+str(quantity) if item_name!="" else "空格"
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)
func _draw() -> void:
	var border := Color("dbb95e") if is_hovered() or selected or has_focus() else (Color("84956e") if jade else Color("85694b"))
	draw_style_box(make_style(Color("ced9b8") if jade else Color("293b39"),border),Rect2(Vector2.ZERO,size))
	draw_rect(Rect2(5,5,size.x-10,size.y-10),Color("b5c59f") if jade else Color("35443c"),false,1)
	if golden:
		draw_rect(Rect2(1,1,size.x-2,size.y-2),Color("ddb850"),false,3)
		if selected: draw_rect(Rect2(5,5,size.x-10,size.y-10),Color("fff0a4"),false,2)
	if item_name=="":
		draw_circle(size/2,2,Color("576154"))
		return
	var target:=Rect2(Vector2(size.x/2-27,3),Vector2(54,54))
	preload("res://item_art.gd").draw(self,item_name,target)
	if icon_font: draw_string(icon_font,Vector2(size.x-28,size.y-7),str(quantity),HORIZONTAL_ALIGNMENT_RIGHT,25,13,Color("294b39") if jade else Color("ffe9bc"))
	if cooldown_seconds>0:
		draw_arc(Vector2(size.x/2,28),24,-PI/2,-PI/2+TAU*clampf(cooldown_seconds/30,0,1),32,Color("f1d69a"),3)

func make_style(bg: Color,border: Color) -> StyleBoxFlat:
	var style:=StyleBoxFlat.new()
	style.bg_color=bg
	style.border_color=border
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	return style
