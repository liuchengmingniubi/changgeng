extends RefCounted
const TILE=48
const SCALE=1.5
const BASE_SIZE=Vector2(2896,2172)
const MILL_RECT=Rect2(40,1340,220,135)
var props: Array=[]
var trees: Array=[]
var fences: Array=[]
var pond:=Rect2(1355,1000,220,110)
static func door(index: int) -> Vector2:
	return base_door(index)*SCALE
static func base_door(index: int) -> Vector2:
	var houses: Array=load("res://main.gd").HOUSE_DATA
	var r: Rect2=Rect2(houses[index][1].position*2,houses[index][1].size*2)
	if index==0: return Vector2(356,352)
	if index==4: return Vector2(2160,230)
	return Vector2(r.end.x-36 if index in [6,8,9,10,11,14] else r.get_center().x,r.end.y+30)
func setup(g: Node) -> void:
	trees=[]; fences=[]; props=[]
	if g.scene_id=="village":
		g.obstacles.clear()
		for i in range(g.HOUSE_DATA.size()):
			var r: Rect2=g.HOUSE_DATA[i][1]; g.obstacles.append(Rect2(r.position*2,r.size*2))
		g.obstacles.append_array([Rect2(1180,1070,40,25),Rect2(2860,0,36,2172),Rect2(2540,0,260,800),Rect2(2640,1000,160,1172),pond,Rect2(0,0,2896,36),Rect2(0,0,36,2172),Rect2(0,2020,1320,152),Rect2(1560,2020,1336,152)])
		# Farm perimeter is a real fence with a 96-pixel opening at its south gate.
		fences=[Rect2(150,380,135,8),Rect2(381,380,119,8),Rect2(150,380,8,280),Rect2(492,380,8,280),Rect2(150,650,135,8),Rect2(381,650,119,8),Rect2(64,814,222,8),Rect2(64,814,8,480),Rect2(64,1294,222,8),Rect2(278,814,8,240),Rect2(278,1200,8,102)]
		for f in fences: g.obstacles.append(f)
		for i in [0,6,8,9,10,11,14]:
			var h: Rect2=g.HOUSE_DATA[i][1]; g.obstacles.append(Rect2(h.position.x*2+24,h.end.y*2+8,32,29))
		for y in range(180,1920,190):
			for x in [80,2490]:
				var at:=Vector2(x,y)
				if safe_tree(g,at): trees.append(at); g.obstacles.append(Rect2(at-Vector2(12,16),Vector2(24,26)))
		for at in [Vector2(1170,340),Vector2(1200,640),Vector2(1810,1040),Vector2(1800,1460),Vector2(700,1550),Vector2(1520,1830)]:
			if safe_tree(g,at): trees.append(at); g.obstacles.append(Rect2(at-Vector2(12,16),Vector2(24,26)))
		for a in g.actors:
			if str(a.id).begins_with("house_"): a.pos=base_door(int(str(a.id).trim_prefix("house_")))
		props=[
			{"kind":"mill","rect":MILL_RECT},
			{"kind":"storage","rect":Rect2(530,470,60,40)},
			{"kind":"barrel","rect":Rect2(530,575,38,38)},
			{"kind":"stall","rect":Rect2(950,1030,84,38)},
			{"kind":"anvil","rect":Rect2(2280,1025,60,45)},
			{"kind":"rack","rect":Rect2(380,1385,120,24)},
			{"kind":"cart","rect":Rect2(75,1485,62,35)},
			{"kind":"bench","rect":Rect2(1580,1780,110,35)}]
		for prop in props: g.obstacles.append(prop.rect)
		g.actors.append({"id":"garden_storage","name":"农具储物箱","pos":Vector2(560,540)})
		for i in range(g.obstacles.size()): g.obstacles[i]=Rect2(g.obstacles[i].position*SCALE,g.obstacles[i].size*SCALE)
		for a in g.actors: a.pos*=SCALE
	elif g.scene_id=="field":
		# Rocks are actual obstacles, kept clear of spawns and essential search positions.
		for at in [Vector2(850,420),Vector2(1190,990),Vector2(1820,1280),Vector2(2250,850)]:
			var r:=Rect2(at-Vector2(24,18),Vector2(48,36))
			if g.actors.all(func(a): return a.pos.distance_to(at)>110): g.obstacles.append(r)
func safe_tree(g: Node,p: Vector2) -> bool:
	for r in g.obstacles:
		if r.grow(70).has_point(p): return false
	for a in g.actors:
		if p.distance_to(a.pos)<120: return false
	return true
func rect(g: Node,r: Rect2,c: String) -> void: g.draw_rect(r,Color(c))
func tag(g: Node,p: Vector2,text: String,small: bool=false) -> void:
	var size_: int=13 if small else 16
	var w: float=text.length()*size_+18
	g.draw_style_box(load("res://jade_theme.gd").card("203e38","ad8b4e",6),Rect2(p-Vector2(w/2,21),Vector2(w,29)))
	g.draw_string(g.font,p+Vector2(-w/2+9,0),text,HORIZONTAL_ALIGNMENT_LEFT,-1,size_,Color("f0dfb7"))
func ground(g: Node) -> void:
	var bounds: Rect2=g.movement_bounds(); var total:=Vector2(1280,800)
	if g.scene_id=="village": total=BASE_SIZE
	elif g.frontier.SIZES.has(g.scene_id): total=g.frontier.SIZES[g.scene_id]
	rect(g,Rect2(Vector2.ZERO,total),"c9ac73")
	# Discrete square terrain tiles; no stretched background images.
	var view:=Rect2((g.camera_offset/SCALE if g.scene_id=="village" else g.camera_offset)-Vector2(48,48),Vector2(1376,896))
	for y in range(maxi(0,int(view.position.y/TILE)),mini(int(total.y/TILE)+1,int(view.end.y/TILE)+1)):
		for x in range(maxi(0,int(view.position.x/TILE)),mini(int(total.x/TILE)+1,int(view.end.x/TILE)+1)):
			var at:=Vector2(x*TILE,y*TILE); var n:=posmod(x*17+y*31,7)
			rect(g,Rect2(at,Vector2(TILE,TILE)),["d5bc83","d0b57e","ceb17a","d1b57f","d7bf88","cdb07a","d3b780"][n])
			for k in range(4): rect(g,Rect2(at+Vector2(4+posmod(x*7+k*13,39),4+posmod(y*9+k*11,39)),Vector2(3,2)),"bea16e")
	if g.scene_id=="village":
		road(g,Rect2(1310,560,160,1460)); road(g,Rect2(1450,620,1030,70)); road(g,Rect2(400,1110,2110,120)); road(g,Rect2(2390,860,380,140)); road(g,Rect2(2390,880,120,350))
		for i in range(g.HOUSE_DATA.size()):
			var d:=base_door(i); road(g,Rect2(d-Vector2(35,0),Vector2(70,92)))
		road(g,Rect2(260,1408,1100,60))
		pond_draw(g)
		# A stone well is its own object, with the same 40x25 solid base used above.
		rect(g,Rect2(1174,1065,52,35),"675c43"); rect(g,Rect2(1181,1071,38,22),"a6a18a"); rect(g,Rect2(1187,1075,26,12),"355e5b")
		for x in [1177,1220]: rect(g,Rect2(x,1012,6,70),"735438")
		rect(g,Rect2(1168,1006,65,12),"47665b"); rect(g,Rect2(1173,1002,55,5),"a58e59")
		for fence in fences: fence_draw(g,fence)
		rect(g,Rect2(70,820,210,470),"7b5c3c")
		for y in range(850,1270,58):
			for x in range(95,260,33):
				g.draw_line(Vector2(x,y+14),Vector2(x,y-14),Color("748549"),3)
				for k in [-1,1]: rect(g,Rect2(x+k*3-2,y-9,5,9),"e2c578")
		for r in [Rect2(0,0,2896,36),Rect2(0,0,36,2172),Rect2(2860,0,36,2172),Rect2(2540,0,260,800),Rect2(2640,1000,160,1172),Rect2(0,2020,1320,90),Rect2(1560,2020,1336,90)]: masonry(g,r)
		g.commissions.draw(g)
	elif g.frontier.SIZES.has(g.scene_id):
		for r in g.obstacles:
			if g.scene_id=="field": rock(g,r)
			else:
				if g.scene_id=="barracks" and r.size.x<450 and r.size.y<250: furniture(g,r)
				else: masonry(g,r)
		for rim in [Rect2(0,0,total.x,35),Rect2(0,total.y-35,total.x,35),Rect2(0,0,35,total.y),Rect2(total.x-35,0,35,total.y)]: rock(g,rim)
		if g.scene_id=="field": g.frontier.draw_herbs(g)
	else:
		rect(g,Rect2(260,170,760,480),"283e38")
		rect(g,Rect2(275,200,725,430),"9b7850")
		for y in range(200,630,28):
			for x in range(275,1000,56):
				rect(g,Rect2(x,y,54,26),"b99664" if (x+y)%3==0 else "ac865a")
				g.draw_line(Vector2(x+6,y+6),Vector2(x+42,y+6),Color("c4a777"),2)
		for r in g.obstacles: furniture(g,r)
		if g.scene_id=="mill": tag(g,Vector2(640,178),"周家磨坊")
		elif g.scene_id=="clinic": tag(g,Vector2(640,178),"许氏医馆 · 留观室")
		else: tag(g,Vector2(640,178),"陆家旧宅" if g.scene_id=="home" else "东沙村民居")
func road(g: Node,r: Rect2) -> void:
	rect(g,r.grow(5),"9f986d"); rect(g,r,"d9c79c")
	for y in range(int(r.position.y),int(r.end.y),24):
		for x in range(int(r.position.x),int(r.end.x),32):
			var tile:=Rect2(x+2+(12 if int(y/24)%2==0 else 0),y+2,27,18).intersection(r)
			if tile.size.x>0 and tile.size.y>0: rect(g,tile,"e5d3a9")
func masonry(g: Node,r: Rect2) -> void:
	if not r.intersects(Rect2((g.camera_offset/SCALE if g.scene_id=="village" else g.camera_offset)-Vector2(60,60),Vector2(1400,920))): return
	rect(g,r.grow(3),"574b38"); rect(g,r,"95866a")
	var visible:=r.intersection(Rect2((g.camera_offset/SCALE if g.scene_id=="village" else g.camera_offset)-Vector2(48,48),Vector2(1376,896)))
	for y in range(int(visible.position.y/24)*24,int(visible.end.y),24):
		for x in range(int(visible.position.x/48)*48,int(visible.end.x),48):
			var b:=Rect2(x+(12 if int(y/24)%2==1 else 0),y,43,20).intersection(r)
			if b.size.x>0 and b.size.y>0: rect(g,b,"b5a381"); rect(g,Rect2(b.position,Vector2(b.size.x,minf(3,b.size.y))),"cbb995")
func rock(g: Node,r: Rect2) -> void:
	rect(g,r,"74695b"); rect(g,Rect2(r.position,Vector2(r.size.x,minf(r.size.y,12))),"b4a58b")
	for y in range(int(r.position.y)+18,int(r.end.y),36):
		for x in range(int(r.position.x)+10,int(r.end.x),48): rect(g,Rect2(x,y,minf(26,r.end.x-x),4),"8f826c")
func fence_draw(g: Node,r: Rect2) -> void:
	rect(g,r.grow(2),"463d2e"); rect(g,r,"bd9456")
	for t in range(0,int(maxf(r.size.x,r.size.y)),24):
		var p: Vector2=r.position+(Vector2(t,0) if r.size.x>r.size.y else Vector2(0,t))
		rect(g,Rect2(p-Vector2(2,12),Vector2(8,24)),"6c5136"); rect(g,Rect2(p-Vector2(0,10),Vector2(3,16)),"d0af70")
func pond_draw(g: Node) -> void:
	rect(g,pond.grow(6),"6e7756"); rect(g,pond,"517d7c")
	for y in range(int(pond.position.y)+12,int(pond.end.y),18):
		for x in range(int(pond.position.x)+12,int(pond.end.x)-25,38): rect(g,Rect2(x+int(sin(g.elapsed+x)*2),y,20,3),"8cb5a2")
func house(g: Node,index: int) -> void:
	var source: Rect2=g.HOUSE_DATA[index][1]; var r:=Rect2(source.position*2,source.size*2)
	if not r.grow(120).intersects(Rect2(g.camera_offset/SCALE,Vector2(1280,800)/SCALE)): return
	rect(g,Rect2(r.position+Vector2(8,12),r.size),"77684d")
	rect(g,r,"685139"); rect(g,r.grow(-5),"bc9560"); rect(g,Rect2(r.position+Vector2(8,8),Vector2(r.size.x-16,22)),"dec08a")
	# Stucco wear, brick sill and a raised foundation are visible at the exact solid footprint.
	for y in range(int(r.position.y+r.size.y*.5),int(r.end.y)-12,19):
		for x in range(int(r.position.x)+12,int(r.end.x)-12,29):
			if posmod(x*3+y,7)<2: rect(g,Rect2(x,y,12,3),"9e774b")
	rect(g,Rect2(r.position.x,r.end.y-10,r.size.x,10),"8e7956")
	var roof:=Rect2(r.position+Vector2(-10,-17),Vector2(r.size.x+20,r.size.y*0.48))
	rect(g,roof.grow(3),"403f35"); rect(g,roof,"465e52")
	for y in range(int(roof.position.y)+4,int(roof.end.y),14):
		for x in range(int(roof.position.x)+4,int(roof.end.x)-10,20):
			rect(g,Rect2(x,y,16,5),"789077"); rect(g,Rect2(x,y+5,16,3),"314a43")
	rect(g,Rect2(roof.position+Vector2(0,-6),Vector2(roof.size.x,9)),"ac8550")
	var d:=base_door(index); var door_r:=Rect2(d.x-23,r.end.y-66,46,66)
	if index==4: door_r=Rect2(r.position.x-4,d.y-58,12,56)
	rect(g,door_r.grow(4),"765337"); rect(g,door_r,"46392b")
	for x in range(int(door_r.position.x)+4,int(door_r.end.x),8): rect(g,Rect2(x,door_r.position.y+4,3,58),"84613b")
	rect(g,Rect2(d.x+12,r.end.y-35,5,5),"d4b66a")
	for side in [-1,1]:
		var at:=Vector2(r.get_center().x+side*r.size.x*.30,r.end.y-61)
		if absf(at.x-d.x)<48: continue
		rect(g,Rect2(at-Vector2(23,20),Vector2(46,38)),"64513b"); rect(g,Rect2(at-Vector2(19,16),Vector2(38,30)),"dcb477")
		for j in range(3): rect(g,Rect2(at.x-15+j*12,at.y-16,3,30),"7e6645")
	# Door lamps, stone steps and timber braces give each house a readable entrance.
	if index!=4:
		rect(g,Rect2(d.x-29,r.end.y,58,9),"ad9b75"); rect(g,Rect2(d.x-34,r.end.y+9,68,7),"c6b690")
		for sign_ in [-1,1]:
			var lamp:=Vector2(d.x+sign_*34,r.end.y-55)
			rect(g,Rect2(lamp+Vector2(-5,-10),Vector2(10,20)),"8e4935"); rect(g,Rect2(lamp+Vector2(-3,-7),Vector2(6,13)),"e3bb6c")
			rect(g,Rect2(lamp+Vector2(-6,-12),Vector2(12,3)),"5c4930")
	if index in [0,6,8,9,10,11,14]:
		var pot:=Vector2(r.position.x+40,r.end.y+25)
		rect(g,Rect2(pot-Vector2(16,17),Vector2(32,28)),"694b32"); rect(g,Rect2(pot-Vector2(13,14),Vector2(26,23)),"b97d4e")
		for k in range(3): rect(g,Rect2(pot+Vector2(-18+k*12,-34-abs(k-1)*7),Vector2(13,22)),"778d4c")
	if index in [8,9,10,11,14]:
		var emblem: String={8:"面条",9:"铜锭",10:"军用铁锤",11:"皮革",14:"基础草药"}[index]
		preload("res://item_art.gd").draw(g,emblem,Rect2(r.position.x+25,r.end.y-93,40,40))
	tag(g,Vector2(r.get_center().x,r.end.y-90),str(g.HOUSE_DATA[index][0]),true)
	if index==10:
		rect(g,Rect2(r.position.x+30,r.end.y-60,42,50),"443b30"); rect(g,Rect2(r.position.x+39,r.end.y-45,24,20),"ed9d43")
func tree(g: Node,p: Vector2) -> void:
	rect(g,Rect2(p-Vector2(27,2),Vector2(54,12)),"a28c5c")
	rect(g,Rect2(p-Vector2(10,62),Vector2(20,66)),"654b32"); rect(g,Rect2(p-Vector2(4,58),Vector2(7,57)),"aa7947")
	for i in range(4):
		var r:=Rect2(p+Vector2(-43+i%2*8,-132+i*20),Vector2(84-i*9,39))
		rect(g,r.grow(3),"3e5137"); rect(g,r,"6c8243"); rect(g,Rect2(r.position+Vector2(6,3),Vector2(r.size.x-16,10)),"a1ac59")
		for j in range(5):
			rect(g,Rect2(r.position+Vector2(6+j*11,15+posmod(j*7+i,13)),Vector2(7,4)),"889e4c")
			rect(g,Rect2(r.position+Vector2(4+j*11,24),Vector2(6,3)),"516c39")
func furniture(g: Node,r: Rect2) -> void:
	rect(g,r.grow(2),"493a2c"); rect(g,r,"876640"); rect(g,Rect2(r.position+Vector2(4,4),Vector2(maxf(0,r.size.x-8),minf(16,r.size.y-8))),"c19c67")
	if r.size.y>100:
		rect(g,Rect2(r.position+Vector2(12,28),Vector2(maxf(12,r.size.x-24),r.size.y-42)),"6b9080")
		rect(g,Rect2(r.position+Vector2(16,12),Vector2(maxf(12,r.size.x-32),24)),"e3d9b2")
		for x in range(int(r.position.x)+16,int(r.end.x)-12,12): rect(g,Rect2(x,r.end.y-28,4,12),"9db399")
	if g.scene_id=="home" and r.position==Vector2(870,250):
		rect(g,Rect2(r.position+Vector2(3,16),Vector2(r.size.x-6,8)),"5d573b"); rect(g,Rect2(r.get_center()-Vector2(7,0),Vector2(14,17)),"d2ae5f")
	if g.scene_id=="home" and r.position==Vector2(810,465):
		rect(g,r,"6c6856"); rect(g,Rect2(r.position+Vector2(20,10),Vector2(40,12)),"252e29"); rect(g,Rect2(r.position+Vector2(24,39),Vector2(24,19)),"e9a44a")
func markers(g: Node) -> void:
	for a in g.actors:
		if g.npc_life.PEOPLE.has(a.id) or str(a.id).begins_with("farm_") or str(a.id).begins_with("house_"): continue
		var d: float=g.player.distance_to(a.pos)
		if d>170: continue
		g.draw_rect(Rect2(a.pos-Vector2(8,5),Vector2(16,10)),Color("ad8d52"),false,2)
		if d<90: tag(g,a.pos+Vector2(0,34),str(a.name),true)

func mill(g: Node) -> void:
	rect(g,MILL_RECT,"b69765"); rect(g,Rect2(35,1325,230,45),"425d50")
	for x in range(45,260,22): rect(g,Rect2(x,1330,16,6),"829373")
	rect(g,Rect2(236,1380,24,65),"524232")
	g.draw_circle(Vector2(140,1418),36,Color("716c56")); g.draw_circle(Vector2(140,1418),29,Color("b6b198"))
	g.draw_line(Vector2(116,1401),Vector2(166,1433),Color("786e54"),4)
	for x in [64,195]: rect(g,Rect2(x,1440,25,29),"d5ba84")
	tag(g,Vector2(148,1307),"周家磨坊",true)

func prop(g: Node,item: Dictionary) -> void:
	var r: Rect2=item.rect
	if not r.grow(110).intersects(Rect2(g.camera_offset/SCALE,Vector2(1280,800)/SCALE)): return
	if item.kind=="mill": mill(g); return
	rect(g,Rect2(r.position+Vector2(5,5),r.size),"aa9163")
	match item.kind:
		"storage":
			rect(g,r,"674a30"); rect(g,r.grow(-3),"a47e48")
			for x in range(int(r.position.x)+7,int(r.end.x),12): rect(g,Rect2(x,r.position.y+3,3,r.size.y-6),"bf9c62")
			for y in [r.position.y+5,r.end.y-10]: rect(g,Rect2(r.position.x+2,y,r.size.x-4,5),"59634b")
			rect(g,Rect2(r.get_center()-Vector2(5,3),Vector2(10,12)),"dfbc68")
		"barrel":
			rect(g,r,"654c32"); rect(g,r.grow(-4),"b68a4f")
			for y in [r.position.y+7,r.end.y-11]: rect(g,Rect2(r.position.x,y,r.size.x,5),"5b6253")
			rect(g,Rect2(r.position+Vector2(5,0),Vector2(r.size.x-10,8)),"557e7c")
		"stall":
			rect(g,r,"765333"); rect(g,Rect2(r.position-Vector2(3,8),Vector2(r.size.x+6,19)),"ba975c")
			for i in range(3):
				var at:=r.position+Vector2(10+i*25,-15)
				rect(g,Rect2(at,Vector2(20,17)),"d8bc80"); rect(g,Rect2(at+Vector2(2,1),Vector2(16,5)),"8f8053")
		"anvil":
			rect(g,r,"6c5039"); rect(g,Rect2(r.position+Vector2(5,-12),Vector2(r.size.x-10,25)),"4b5a57")
			rect(g,Rect2(r.position+Vector2(-5,-12),Vector2(r.size.x+10,9)),"a5aaa0")
			g.draw_line(r.position+Vector2(17,-26),r.position+Vector2(37,-5),Color("ac804b"),5)
			rect(g,Rect2(r.position+Vector2(9,-28),Vector2(20,9)),"89978b")
		"rack":
			for x in [r.position.x,r.end.x-7]: rect(g,Rect2(x,r.position.y-55,7,78),"695138")
			rect(g,Rect2(r.position-Vector2(4,55),Vector2(r.size.x+8,7)),"aa8250")
			for x in range(int(r.position.x)+14,int(r.end.x)-17,30):
				rect(g,Rect2(x,r.position.y-44,24,46),"a4754c"); rect(g,Rect2(x+4,r.position.y-40,16,35),"c39865")
		"cart":
			rect(g,r,"6d4c32"); rect(g,Rect2(r.position-Vector2(0,12),Vector2(r.size.x,25)),"b79056")
			for x in [r.position.x-3,r.end.x-13]:
				g.draw_circle(Vector2(x+7,r.end.y-3),10,Color("493d30")); g.draw_circle(Vector2(x+7,r.end.y-3),4,Color("c7a76d"))
			for x in [r.position.x+6,r.position.x+33]: rect(g,Rect2(x,r.position.y-25,23,28),"d5ba84")
		"bench":
			rect(g,r,"6c4f32"); rect(g,Rect2(r.position-Vector2(3,8),Vector2(r.size.x+6,19)),"b18d55")
			for x in [r.position.x+5,r.end.x-12]: rect(g,Rect2(x,r.end.y-12,7,17),"554230")
