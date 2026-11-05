extends Node
var game: Node
var commands: Array=[]
var transform: Array=[0,0,0,1,1]
func _get(key: StringName) -> Variant: return game.get(key)
func vec(p: Vector2) -> Array: return [p.x,p.y]
func rect(r: Rect2) -> Array: return [r.position.x,r.position.y,r.size.x,r.size.y]
func push(kind: String,content: Dictionary) -> void:
	content.kind=kind; content.transform=transform.duplicate(); commands.append(content)
func draw_rect(r: Rect2,c: Color,filled: bool=true,width: float=-1,_aa: bool=false) -> void: push("rect",{"rect":rect(r),"color":c.to_html(),"filled":filled,"width":width})
func draw_line(a: Vector2,b: Vector2,c: Color,width: float=-1,_aa: bool=false) -> void: push("line",{"a":vec(a),"b":vec(b),"color":c.to_html(),"width":width})
func draw_style_box(style: StyleBox,r: Rect2) -> void:
	push("card",{"rect":rect(r),"color":style.bg_color.to_html(),"border":style.border_color.to_html(),"radius":style.corner_radius_top_left})
func draw_string(_font: Font,p: Vector2,text: String,_align: int=0,_width: float=-1,size_: int=16,c: Color=Color.WHITE,_flags: int=3,_dir: int=0,_orientation: int=0) -> void: push("text",{"at":vec(p),"text":text,"size":size_,"color":c.to_html()})
func draw_texture_rect_region(texture: Texture2D,to: Rect2,region: Rect2,modulate: Color=Color.WHITE,_transpose: bool=false,_clip: bool=true) -> void:
	var name_ := "items_v26.png"
	for kind in game.actor_visual.sheets:
		if texture==game.actor_visual.sheets[kind]: name_=game.actor_visual.sheet_name(kind)
	push("texture",{"rect":rect(to),"region":rect(region),"color":modulate.to_html(),"file":name_})
func draw_set_transform(p: Vector2,angle: float=0,scale_: Vector2=Vector2.ONE) -> void: transform=[p.x,p.y,angle,scale_.x,scale_.y]
func draw_circle(p: Vector2,r: float,c: Color,_filled: bool=true,_width: float=-1,_aa: bool=false) -> void: push("circle",{"at":vec(p),"r":r,"color":c.to_html()})
func draw_arc(p: Vector2,r: float,a: float,b: float,count: int,c: Color,width: float=1,_aa: bool=false) -> void:
	for i in range(count): draw_line(p+Vector2.from_angle(lerpf(a,b,i/float(count)))*r,p+Vector2.from_angle(lerpf(a,b,(i+1)/float(count)))*r,c,width)
func draw_ellipse_shadow(p: Vector2) -> void: push("ellipse",{"rect":[p.x-19,p.y-5,38,11],"color":"26392f66"})
func text_at(p: Vector2,text: String,size_: int=16,c: Color=Color("efc888")) -> void: draw_string(game.font,p,text,0,-1,size_,c)
func draw_sword(p: Vector2,progress: float) -> void: pass
func draw_sword_at(hand: Vector2,angle: float,progress: float,trail: PackedVector2Array=PackedVector2Array()) -> void:
	push("sword",{"at":vec(hand),"angle":angle,"progress":progress,"trail":trail.size()})
func draw_polyline(points: PackedVector2Array,color: Color,width: float=-1,antialiased: bool=false) -> void:
	push("polyline",{"points":points.size(),"color":color.to_html(),"width":width})
func draw_colored_polygon(points: PackedVector2Array,color: Color) -> void:
	push("polygon",{"points":points.size(),"color":color.to_html()})

func movement_bounds() -> Rect2: return game.movement_bounds()
