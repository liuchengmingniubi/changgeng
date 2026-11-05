extends Control
var picture: Texture2D
var marker:=Vector2.ZERO
var text_font: Font
const SCALE=Vector2(620.0/2896,465.0/2172)
func _ready() -> void: custom_minimum_size=Vector2(620,465)
func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,Vector2(620,465)),Color("cdb782"))
	for r in [Rect2(1310,560,160,1460),Rect2(400,1110,2110,120),Rect2(2390,860,380,140),Rect2(2390,880,120,350),Rect2(260,1408,1100,60)]: draw_rect(Rect2(r.position*SCALE,r.size*SCALE),Color("eddbb0"))
	var houses: Array=load("res://main.gd").HOUSE_DATA
	for i in range(houses.size()):
		var r: Rect2=houses[i][1]; r=Rect2(r.position*2*SCALE,r.size*2*SCALE)
		draw_rect(r,Color("8b7753")); draw_rect(Rect2(r.position,r.size*Vector2(1,0.55)),Color("567663"))
		var d: Vector2=preload("res://world_layout.gd").door(i)/1.5*SCALE; draw_circle(d,3,Color("f6df9b"))
		if text_font: draw_string(text_font,r.position+Vector2(2,r.size.y-4),str(i+1),HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("f2e3b9"))
	for r in [Rect2(2540,0,260,800),Rect2(2640,1000,160,1172)]: draw_rect(Rect2(r.position*SCALE,r.size*SCALE),Color("8d8065"))
	draw_rect(Rect2(Vector2(1355,1000)*SCALE,Vector2(220,110)*SCALE),Color("598b83"))
	draw_rect(Rect2(Vector2(40,1340)*SCALE,Vector2(220,135)*SCALE),Color("6f8b68"))
	var here:=marker/1.5*SCALE; draw_circle(here,6,Color("283e36")); draw_circle(here,3,Color("f6dd8d"))
func _get_tooltip(at: Vector2) -> String:
	var houses: Array=load("res://main.gd").HOUSE_DATA
	for i in range(houses.size()):
		var r: Rect2=houses[i][1]
		if Rect2(r.position*2*SCALE,r.size*2*SCALE).has_point(at): return "%d · %s" % [i+1,houses[i][0]]
	if Rect2(Vector2(40,1340)*SCALE,Vector2(220,135)*SCALE).has_point(at): return "周家磨坊 · 公共农田南侧"
	return ""
