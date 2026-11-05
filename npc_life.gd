extends RefCounted
const PEOPLE := {
 "elder":{"name":"田敬修","job":"村长","hours":"06:30—17:00","start":390,"end":1020,"scene":"village","work":Vector2(1580,610),"door":Vector2(1590,574),"house":6,"color":"788675","nature":"牵挂晚辈，习惯把担忧藏进家常话"},
 "smith":{"name":"郭成","job":"铁匠","hours":"07:00—18:30","start":420,"end":1110,"scene":"village","work":Vector2(2140,1040),"door":Vector2(2160,1024),"house":10,"color":"8a6650","nature":"嘴硬，宁肯少收钱也不肯交出坏甲"},
 "doctor":{"name":"许素问","job":"医生","hours":"06:00—18:00","start":360,"end":1080,"scene":"village","work":Vector2(2130,1410),"door":Vector2(2170,1394),"house":14,"color":"b4b999","nature":"温和有主见，不纵容病人逞强"},
 "merchant":{"name":"康裕","job":"商人","hours":"09:00—19:00","start":540,"end":1140,"scene":"village","work":Vector2(1100,1020),"door":Vector2(1110,988),"house":9,"color":"8a7356","nature":"贪小利、爱面子，也记得别人给过的饭"},
 "farmer":{"name":"周满仓","job":"种田与磨面","hours":"05:30—16:30（10点起磨面）","start":330,"end":990,"scene":"mill","work":Vector2(700,410),"door":Vector2(780,278),"house":1,"color":"8b7a50","nature":"朴实惜粮，收的是工钱而不是人情"},
 "innkeeper":{"name":"杜芸娘","job":"客栈掌柜","hours":"06:00—23:00","start":360,"end":1380,"scene":"village","work":Vector2(550,1000),"door":Vector2(550,1000),"house":8,"color":"a66e62","nature":"爽快善良，留着弟弟杜仲平的位置"},
 "leather":{"name":"冯厚","job":"制革匠","hours":"07:30—17:30","start":450,"end":1050,"scene":"village","work":Vector2(550,1364),"door":Vector2(550,1364),"house":11,"color":"907453","nature":"沉默固执，不愿草率认定儿子冯小川遇难"},
 "captain":{"name":"裴肃","job":"队正","hours":"06:00—18:00","start":360,"end":1080,"scene":"wall","work":Vector2(650,825),"color":"637d7b","nature":"克制负责，记录必须经得起核实"},
 "scout":{"name":"韩守义","job":"斥候","hours":"04:30—12:30；14:00—16:00","start":270,"end":960,"scene":"wall","work":Vector2(1330,740),"color":"8a8063","nature":"嘴硬心细，看重认路和清点人数"},
 "soldier":{"name":"石大川","job":"值守士卒","hours":"10:00—22:00","start":600,"end":1320,"scene":"wall","work":Vector2(1180,820),"color":"87917a","nature":"胆小却重情，惦记姐姐石阿菱"},
 "medic":{"name":"孙怀济","job":"军医兼军需","hours":"12:00—24:00","start":720,"end":1440,"scene":"barracks","work":Vector2(1500,1170),"color":"a3ada1","nature":"谨慎操劳，常把自己的饭放凉"},
 "guard_day":{"name":"卫迟","job":"日间巡守","hours":"05:45—17:45","start":345,"end":1065,"scene":"wall","work":Vector2(1490,825),"color":"637d7b","nature":"守规矩，巡防时总先看路口"},
 "guard_night":{"name":"段宁","job":"夜间巡守","hours":"17:45—05:45","start":1065,"end":345,"scene":"wall","work":Vector2(1440,850),"color":"6e7989","nature":"寡言警觉，夜里仍会给晚归者留灯"}}
const LOST := ["柳知微","石阿菱","赵成器","曹顺","周禾","冯小川","杜仲平","何春娘","孟有田","陶冬生","秦二郎","郑绣娘","罗长生","白景和"]
const PORTALS := {
 "village":{"wall":[Vector2(4080,1410),Vector2(200,825)],"mill":[Vector2(435,2130),Vector2(640,580)]},
 "wall":{"village":[Vector2(90,825),Vector2(4020,1410)],"barracks":[Vector2(870,1510),Vector2(990,350)],"field":[Vector2(1830,825),Vector2(550,805)]},
 "barracks":{"wall":[Vector2(990,140),Vector2(870,1380)]},
 "mill":{"village":[Vector2(640,615),Vector2(480,2175)]},
 "field":{"wall":[Vector2(330,805),Vector2(1830,825)]}}
var live: Dictionary={}
var grid: AStarGrid2D
var grid_scene: String=""
var sync_timer:=0.0
func working(id: String,t: float) -> bool:
	var d: Dictionary=PEOPLE[id]
	return (t>=d.start and t<d.end) if int(d.start)<int(d.end) else (t>=d.start or t<d.end)
func desired(id: String,g: Node) -> Dictionary:
	var result:=desired_base(id,g)
	if result.scene=="village": result.pos*=preload("res://world_layout.gd").SCALE
	return result
func desired_base(id: String,g: Node) -> Dictionary:
	var d: Dictionary=PEOPLE[id]
	var t: float=g.time_minutes
	if id=="scout" and (g.flags.get("training_active",false) or g.flags.get("escort_return",false) or g.flags.get("patrol_active",false)) and g.scene_id in ["wall","field","barracks"]:
		return {"scene":g.scene_id,"pos":g.player,"status":"随队行动"}
	# Essential recruitment actors report to their posts until the pending task is done.
	var pinned: bool=(id=="captain" and g.step in [7,10]) or (id=="scout" and g.step==8)
	if id in ["soldier","medic"] and g.step==9: return {"scene":"barracks","pos":Vector2(730,730) if id=="soldier" else Vector2(1500,1170),"status":"等候新兵"}
	if id in ["elder","smith","doctor"] and ((id=="elder" and g.step in [1,6]) or (id=="smith" and g.step==2) or (id=="doctor" and g.step in [3,4])): pinned=true
	if pinned: return {"scene":d.scene,"pos":d.work,"status":"等候任务"}
	if id in ["doctor","medic"] and working(id,t): return {"scene":d.scene,"pos":d.work,"status":"工作"}
	if working(id,t):
		if id=="farmer" and t<600: return {"scene":"village","pos":Vector2(230,1150),"status":"田间劳作"}
		if id=="elder" and t<540: return {"scene":"village","pos":Vector2(1120,1160),"status":"巡村"}
		var p: Vector2=d.work
		if id.begins_with("guard_"): p=Vector2(1470+int(t/12)%3*120,825)
		if id=="soldier": p=Vector2(980+int(t/18)%3*110,860)
		return {"scene":d.scene,"pos":p,"status":"值勤" if d.scene in ["wall","barracks"] else "工作"}
	if d.has("house"): return {"scene":"home_"+id,"pos":Vector2(700,410),"status":"休息"}
	return {"scene":"barracks","pos":Vector2([300,620,760][["captain","scout","soldier","medic","guard_day","guard_night"].find(id)%3],1010+int(["captain","scout","soldier","medic","guard_day","guard_night"].find(id)/3)*320),"status":"休息"}
func build_grid(g: Node) -> void:
	grid=AStarGrid2D.new()
	var bounds: Rect2=g.movement_bounds()
	grid.region=Rect2i(0,0,ceili(bounds.end.x/20)+1,ceili(bounds.end.y/20)+1)
	grid.cell_size=Vector2(20,20)
	grid.diagonal_mode=AStarGrid2D.DIAGONAL_MODE_NEVER
	grid.update()
	for y in range(grid.region.size.y):
		for x in range(grid.region.size.x):
			var p:=Vector2(x*20,y*20)
			if not bounds.has_point(p) or g.blocked(p): grid.set_point_solid(Vector2i(x,y))
	grid_scene=g.scene_id
func free_cell(p: Vector2) -> Vector2i:
	var center:=Vector2i(roundi(p.x/20),roundi(p.y/20))
	for radius in range(0,12):
		for y in range(-radius,radius+1):
			for x in range(-radius,radius+1):
				var c:=center+Vector2i(x,y)
				if grid.is_in_boundsv(c) and not grid.is_point_solid(c): return c
	return center
func path(g: Node,start: Vector2,end: Vector2) -> Array:
	if grid==null or grid_scene!=g.scene_id: build_grid(g)
	return Array(grid.get_point_path(free_cell(start),free_cell(end)))
func next_scene(from: String,to: String) -> String:
	if from.begins_with("home_"): return "village"
	if from=="village" and to.begins_with("home_"): return to
	if PORTALS.get(from,{}).has(to): return to
	if from in ["mill"]: return "village"
	if from in ["field","barracks"]: return "wall"
	return "wall" if from=="village" else "village"
func portal(from: String,to: String) -> Array:
	if from.begins_with("home_"): return [Vector2(640,615),preload("res://world_layout.gd").door(int(PEOPLE[from.trim_prefix("home_")].house))+Vector2(30,30)]
	if to.begins_with("home_"): return [preload("res://world_layout.gd").door(int(PEOPLE[to.trim_prefix("home_")].house)),Vector2(640,580)]
	return PORTALS.get(from,{}).get(to,[Vector2(640,400),Vector2(640,400)])
func setup(g: Node) -> void:
	build_grid(g)
	for id in PEOPLE:
		if not live.has(id):
			var want:=desired(id,g)
			live[id]={"scene":want.scene,"pos":want.pos,"status":want.status,"goal":want.pos,"path":[],"moving":false}
	sync(g)
func sync(g: Node) -> void:
	g.actors=g.actors.filter(func(a): return not PEOPLE.has(a.id) and not str(a.id).begins_with("npc_home_"))
	for id in PEOPLE:
		var state: Dictionary=live[id]
		if state.scene==g.scene_id and g.blocked(state.pos):
			state.pos=Vector2(free_cell(state.pos))*20
			state.path=[]
		if state.scene==g.scene_id:
			g.actors.append({"id":id,"name":PEOPLE[id].name+" · "+str(state.status),"pos":state.pos})
func tick(delta: float,g: Node) -> void:
	for id in PEOPLE:
		var state: Dictionary=live[id]
		var before: Vector2=state.pos
		var want:=desired(id,g)
		var escort: bool=id=="scout" and want.status=="随队行动"
		if escort:
			if state.scene!=g.scene_id: state.scene=g.scene_id; state.pos=g.player+Vector2(-50,20); state.path=[]
			if g.scene_id=="field":
				if g.flags.get("escort_return",false): want.pos=Vector2(420,805)
				elif g.flags.get("patrol_active",false): want.pos=Vector2(1120,800) if int(g.flags.get("search_stage",0))<2 else Vector2(2130,840)
				else: want.pos=Vector2(900+int(g.flags.get("training_kills",0))*400,800)
			if state.pos.distance_to(g.player)>200: want.pos=state.pos
			if state.pos.distance_to(g.player)>340: want.pos=g.player
		state.status=want.status
		var dest: String=str(want.scene)
		var goal: Vector2=want.pos
		var route: Array=[]
		var next: String=""
		if state.scene!=dest:
			next=next_scene(state.scene,dest)
			route=portal(state.scene,next)
			goal=route[0]
		if state.scene==g.scene_id:
			if state.goal.distance_to(goal)>15 or (state.path.is_empty() and state.pos.distance_to(goal)>24):
				state.goal=goal
				state.path=path(g,state.pos,goal)
			if not state.path.is_empty() and state.pos.distance_to(state.path[0])<8: state.path.pop_front()
			state.moving=not state.path.is_empty()
			if state.moving: state.pos=state.pos.move_toward(state.path[0],delta*(105 if escort else 80))
		else:
			state.pos=state.pos.move_toward(goal,delta*100)
			state.moving=true
		if next!="" and state.pos.distance_to(goal)<28:
			state.scene=next
			state.pos=route[1]
			state.path=[]
			state.goal=Vector2(-999,-999)
		if state.pos.distance_to(before)>0.1: state["facing"]=(state.pos-before).normalized()
	sync(g)
func service_open(id: String,g: Node) -> bool:
	if not PEOPLE.has(id): return true
	if not working(id,g.time_minutes): return false
	return str(live.get(id,{}).get("status","")) in ["工作","等候任务","值勤"]
func talk(id: String,g: Node) -> bool:
	if id in ["innkeeper","leather","guard_day","guard_night"]:
		g.bond(id)
		var text: String={"innkeeper":"客人少，锅也得热着。仲平回来时，别让他以为这儿没人等他。","leather":"这线轴小川拿得顺手。旧的我没扔，谁说新的就一定比旧的好？","guard_day":"门内外的人都要记。少一个，不能拿一句大概回去了搪塞。","guard_night":"夜里看不远，灯得留着。有人回来，先让他进门，再问迟归的缘由。"}[id]
		g.show_dialog([[PEOPLE[id].name,text]])
		return true
	return false
func draw_person(g: Node2D,a: Dictionary) -> void:
	g.actor_visual.npc(g,a.pos,a.id)
func show_people(g: Node) -> void:
	g.clear_modal("人物 · 作息与关系")
	var scroll:=ScrollContainer.new()
	scroll.custom_minimum_size=Vector2(630,440)
	var list:=VBoxContainer.new()
	scroll.add_child(list)
	g.modal_body.add_child(scroll)
	for id in PEOPLE:
		var d: Dictionary=PEOPLE[id]
		var state: Dictionary=live[id]
		list.add_child(g.label("%s · %s · 亲密度%.1f/100" % [d.name,d.job,float(g.hearts.get(id,0))],19))
		var place: String={"village":"村中","wall":"关门营地","barracks":"食宿院","mill":"周家磨坊","field":"关外"}.get(str(state.scene),"家中")
		list.add_child(g.label(d.hours+"；当前："+str(state.status)+" / "+place,14))
		list.add_child(g.label(d.nature,14))
		list.add_child(g.label("喜欢："+"、".join(g.relationships.DATA[id].likes)+" · 送礼还需%d天" % g.relationships.gift_wait(id,g),14))
	g.modal_body.add_child(g.button("关闭",func(): g.modal.hide()))
func snapshot() -> Dictionary:
	var data: Dictionary={}
	for id in live: data[id]={"scene":live[id].scene,"pos":[live[id].pos.x,live[id].pos.y],"status":live[id].status}
	return data
func restore(data: Dictionary) -> void:
	live.clear()
	for id in PEOPLE:
		if not data.has(id): continue
		var saved: Dictionary=data[id]
		live[id]={"scene":str(saved.scene),"pos":Vector2(saved.pos[0],saved.pos[1]),"status":str(saved.status),"goal":Vector2(-999,-999),"path":[],"moving":false}

func draw_native(g: Node2D,p: Vector2,id: String) -> void:
	var coat:=Color(PEOPLE[id].color)
	var phase:=sin(g.elapsed*10)*4 if live[id].moving else 0.0
	g.draw_ellipse_shadow(p)
	for side in [-1,1]:
		g.box(Rect2(p+Vector2(side*7-4,-21+phase*side),Vector2(9,23)),Color("565345"))
		g.box(Rect2(p+Vector2(side*7-5,-3+phase*side),Vector2(12,7)),Color("343c36"))
	g.box(Rect2(p+Vector2(-14,-49),Vector2(28,33)),coat)
	g.draw_line(p+Vector2(-7,-46),p+Vector2(8,-26),coat.lightened(.35),3)
	for side in [-1,1]:
		g.box(Rect2(p+Vector2(side*17-4,-46-phase*side),Vector2(8,24)),coat)
		g.draw_rect(Rect2(p+Vector2(side*17-3,-25-phase*side),Vector2(6,7)),Color("c6a17b"))
	g.box(Rect2(p+Vector2(-12,-73),Vector2(24,25)),Color("d0ad86"))
	g.draw_rect(Rect2(p+Vector2(-12,-76),Vector2(24,10)),Color("4f4a40"))
	g.draw_rect(Rect2(p+Vector2(-5,-82),Vector2(10,7)),Color("4f4a40"))
	for side in [-1,1]: g.draw_rect(Rect2(p+Vector2(side*5-1,-61),Vector2(3,3)),Color("3f3b33"))
	if id=="innkeeper":
		g.draw_rect(Rect2(p+Vector2(-10,-39),Vector2(20,25)),Color("d1b48c"))
		g.draw_line(p+Vector2(-11,-73),p+Vector2(10,-78),Color("cbb27b"),3)
	elif id=="farmer":
		g.draw_rect(Rect2(p+Vector2(-18,-74),Vector2(36,5)),Color("b9a16c"))
		g.draw_rect(Rect2(p+Vector2(-13,-82),Vector2(26,10)),Color("a38a55"))
	elif id=="leather":
		g.draw_rect(Rect2(p+Vector2(-10,-42),Vector2(20,30)),Color("69533e"))
	else:
		g.box(Rect2(p+Vector2(-14,-78),Vector2(28,13)),Color("768b86"))
		g.draw_line(p+Vector2(24,3),p+Vector2(24,-92),Color("7a6447"),4)
		g.draw_line(p+Vector2(24,-92),p+Vector2(24,-103),Color("b4c0b0"),3)
