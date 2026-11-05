extends RefCounted
var walk: Texture2D
var flash: Texture2D
var frames: Array=[]
var scale_factor:=0.3
func setup() -> void:
	var source:=Image.new()
	if source.load("res://assets/art/hero_walk_v26.png")!=OK: return
	walk=ImageTexture.create_from_image(source)
	var white: Image=source.duplicate(); white.adjust_bcs(1.0,0.0,0.0); white.adjust_bcs(2.0,1.0,1.0); flash=ImageTexture.create_from_image(white)
	var tallest:=1
	for row in range(4):
		var list: Array=[]
		for col in range(4):
			var x:=int(round(col*source.get_width()/4.0)); var y:=int(round(row*source.get_height()/4.0))
			var cell:=Rect2i(x,y,int(round((col+1)*source.get_width()/4.0))-x,int(round((row+1)*source.get_height()/4.0))-y)
			var used:=source.get_region(cell).get_used_rect()
			list.append(Rect2(Vector2(cell.position+used.position),Vector2(used.size))); tallest=maxi(tallest,used.size.y)
		frames.append(list)
	scale_factor=88.0/tallest
func direction(v: Vector2) -> int:
	if absf(v.x)>absf(v.y): return 2 if v.x>0 else 1
	return 3 if v.y<0 else 0
func hero(g: Node,p: Vector2) -> void:
	if walk==null: return
	var moving: bool=g.actual_walk or g.walk_blend>0.2
	var frame: int=int(g.movement_time*9)%4 if moving else 1
	var region: Rect2=frames[direction(g.facing)][frame]
	var visible_texture: Texture2D=flash if g.hurt_flash>0 else walk
	var dims:=region.size*scale_factor; var origin: Vector2=(p-Vector2(dims.x/2,dims.y)).round()
	g.draw_ellipse_shadow(p)
	# The complete frame is translated, never split or stretched.
	if g.attack_time<=0:
		for shift in [Vector2(-1,0),Vector2(1,0),Vector2(0,-1)]: g.draw_texture_rect_region(walk,Rect2(origin+shift,dims),region,Color("273a2c"))
		g.draw_texture_rect_region(visible_texture,Rect2(origin,dims),region,Color("fff7e7") if g.hurt_flash<=0 else Color("ffffff"))
		held(g,p)
	else:
		# During the strike, use the center body section and replace the resting arms with jointed arms.
		var inset:=region.size.x*0.14
		g.draw_texture_rect_region(visible_texture,Rect2(origin+Vector2(inset*scale_factor,0),Vector2(dims.x-inset*scale_factor*2,dims.y)),Rect2(region.position+Vector2(inset,0),Vector2(region.size.x-inset*2,region.size.y)))
		arms(g,p,1.0-g.attack_time/g.attack_duration)
func arms(g: Node,p: Vector2,progress: float) -> void:
	var angle: float=g.swing_angle(progress)
	var shoulder: Vector2=p+Vector2(8,-54)
	var target: Vector2=p+Vector2(0,-40)+Vector2.from_angle(angle)*22
	var delta: Vector2=target-shoulder; var distance:=clampf(delta.length(),2,39.9)
	var middle:=shoulder+delta.normalized()*distance*0.5+delta.normalized().orthogonal()*sqrt(maxf(0,20*20-distance*distance/4))
	var other_shoulder:=p+Vector2(-9,-54)
	var other_hand:=p+Vector2(-14,-28)
	if str(g.swing_weapon.get("kind","")) in ["战锤","镰刀"]: other_hand=target-Vector2.from_angle(angle)*8
	var other_delta: Vector2=other_hand-other_shoulder
	var other_middle: Vector2=(other_hand+other_shoulder)/2-other_delta.normalized().orthogonal()*sqrt(maxf(0,400-other_delta.length_squared()/4))
	for pair in [[other_shoulder,other_middle],[other_middle,other_hand],[shoulder,middle],[middle,target]]:
		g.draw_line(pair[0].round(),pair[1].round(),Color("293d36"),11,false)
		g.draw_line(pair[0].round(),pair[1].round(),Color("457b79"),7,false)
	g.draw_rect(Rect2(target.round()-Vector2(3,3),Vector2(7,7)),Color("e5ba88"))
	g.draw_sword(p,progress)
func npc(g: Node,p: Vector2,id: String) -> void:
	var state: Dictionary=g.npc_life.live[id]; var velocity: Vector2=state.get("facing",Vector2.DOWN)
	var d:=direction(velocity); var moving: bool=state.get("moving",false)
	var step_: int=[-3,0,3,0][int(g.elapsed*8)%4] if moving else 0
	var coat:=Color(g.npc_life.PEOPLE[id].color); var skin:=Color("d8b18a"); var hair:=Color("373833")
	if id in ["elder","scout","farmer"]: hair=Color("b4ae98")
	g.draw_ellipse_shadow(p)
	var q:=p.round()
	# Fixed-size pixel clusters; changing poses only offsets limbs.
	for side in [-1,1]:
		var at:=q+Vector2(side*7-5,-23+step_*side)
		g.draw_rect(Rect2(at-Vector2.ONE,Vector2(12,24)),Color("2a3831")); g.draw_rect(Rect2(at,Vector2(10,21)),Color("535249"))
		g.draw_rect(Rect2(at+Vector2(-2,18),Vector2(14,6)),Color("3c342b"))
	var width:=23 if d in [1,2] else 34
	g.draw_rect(Rect2(q+Vector2(-width/2.0-2,-59),Vector2(width+4,40)),Color("293e35"))
	g.draw_rect(Rect2(q+Vector2(-width/2.0,-57),Vector2(width,35)),coat)
	g.draw_rect(Rect2(q+Vector2(-width/2.0+3,-55),Vector2(5,29)),coat.lightened(0.2))
	g.draw_rect(Rect2(q+Vector2(-width/2.0,-31),Vector2(width,6)),Color("79573a")); g.draw_rect(Rect2(q+Vector2(-3,-31),Vector2(7,5)),Color("d0b16a"))
	for side in [-1,1]:
		var arm:=q+Vector2(side*(width/2.0+3)-4,-55-step_*side)
		g.draw_rect(Rect2(arm-Vector2.ONE,Vector2(10,29)),Color("2e4035")); g.draw_rect(Rect2(arm,Vector2(8,22)),coat.darkened(0.1)); g.draw_rect(Rect2(arm+Vector2(1,21),Vector2(6,6)),skin)
	g.draw_rect(Rect2(q+Vector2(-15,-84),Vector2(30,29)),Color("2a3930")); g.draw_rect(Rect2(q+Vector2(-13,-81),Vector2(26,23)),skin)
	g.draw_rect(Rect2(q+Vector2(-15,-87),Vector2(30,10)),hair); g.draw_rect(Rect2(q+Vector2(-7,-95),Vector2(14,12)),hair)
	if d==3: g.draw_rect(Rect2(q+Vector2(-13,-81),Vector2(26,18)),hair)
	elif d in [1,2]:
		var eye:=q+Vector2(-10 if d==1 else 8,-71); g.draw_rect(Rect2(eye,Vector2(3,4)),Color("28382f"))
		g.draw_rect(Rect2(q+Vector2(8 if d==1 else -13,-79),Vector2(5,19)),hair)
	else:
		for side in [-1,1]: g.draw_rect(Rect2(q+Vector2(side*7-1,-71),Vector2(3,4)),Color("273930"))
	if id in ["captain","guard_day","guard_night","soldier"]:
		for x in [-10,0,10]: g.draw_rect(Rect2(q+Vector2(x-3,-50),Vector2(6,13)),Color("a8b49b"))
	if id in ["elder","scout"] and d!=3: g.draw_rect(Rect2(q+Vector2(-5,-60),Vector2(10,8)),hair)
	g.world_layout.tag(g,p+Vector2(0,-109),g.npc_life.PEOPLE[id].name,true)

func held(g: Node,p: Vector2) -> void:
	if g.life.waking or g.eating_time>0: return
	var item: String=str(g.quickbar[g.quickbar_index])
	if item=="" or int(g.inventory.get(item,0))<=0: return
	var side: int=-1 if g.facing.x<0 else 1
	var hand: Vector2=(p+Vector2(side*17,-32+sin(g.movement_time*9))).round()
	g.draw_line(p+Vector2(side*11,-48),hand,Color("3f6f6c"),6,false)
	preload("res://item_art.gd").draw(g,item,Rect2(hand-Vector2(13,19),Vector2(26,26)))
	g.draw_rect(Rect2(hand-Vector2(3,2),Vector2(6,5)),Color("e3b78a"))
