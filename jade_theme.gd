extends RefCounted
static func card(bg: String="dfe5ca",border: String="a8894e",radius: int=10) -> StyleBoxFlat:
	var s:=StyleBoxFlat.new(); s.bg_color=Color(bg); s.border_color=Color(border); s.set_border_width_all(3); s.set_corner_radius_all(radius); s.corner_detail=3
	s.shadow_color=Color("142d2860"); s.shadow_size=6; s.shadow_offset=Vector2(0,4); s.set_content_margin_all(10)
	return s
static func decorate(canvas: Control) -> void:
	canvas.queue_redraw()

static func install(panel: Control) -> void:
	if panel.has_meta("bronze_trim"): return
	panel.set_meta("bronze_trim",true)
	panel.add_child(load("res://bronze_trim.gd").new())
