extends RefCounted
# The three maps share east/right = outside, west/left = village.
const SIZES := {"wall":Vector2(2172,1629),"barracks":Vector2(2172,1629),"field":Vector2(2560,1600)}
const SPAWNS := [Vector2(1100,650),Vector2(1630,470),Vector2(1900,1050),Vector2(1450,1230)]
func setup(g: Node) -> void:
	match g.scene_id:
		"wall":
			g.obstacles.assign([Rect2(1545,0,215,760),Rect2(1545,890,215,739),Rect2(0,0,1510,720),Rect2(0,910,745,719),Rect2(1010,910,530,719)])
			g.actors=[{"id":"village","name":"返回东沙村","pos":Vector2(90,825)}, {"id":"captain","name":"裴肃 · 队正","pos":Vector2(650,825)}, {"id":"scout","name":"韩守义 · 老斥候","pos":Vector2(1330,830)}, {"id":"roster","name":"失踪村民名单","pos":Vector2(1035,735)}, {"id":"gate","name":"出关 · 关外沙地","pos":Vector2(1830,825)}, {"id":"barracks_entry","name":"前往食宿院","pos":Vector2(870,1510)}]
		"barracks":
			# Roofless rooms: all doors connect to courtyard; wall segments leave door gaps.
			g.obstacles.assign([Rect2(0,0,870,250),Rect2(1100,0,1072,250),Rect2(0,250,240,1379),Rect2(1805,250,367,1379),Rect2(240,1375,1565,254),Rect2(240,280,610,35),Rect2(240,315,30,500),Rect2(820,315,30,425),Rect2(240,780,475,35),Rect2(300,625,425,65),Rect2(300,350,430,140),Rect2(240,945,600,30),Rect2(240,975,30,380),Rect2(805,975,35,120),Rect2(805,1230,35,125),Rect2(300,1090,135,200),Rect2(465,1090,135,200),Rect2(625,1090,135,200),Rect2(1095,950,625,30),Rect2(1095,980,35,115),Rect2(1095,1230,35,145),Rect2(1665,980,55,395),Rect2(1320,1120,150,160)])
			g.actors=[{"id":"barracks_exit","name":"返回关门营地","pos":Vector2(990,140)}, {"id":"soldier","name":"石大川","pos":Vector2(730,730)}, {"id":"medic","name":"孙怀济 · 军医","pos":Vector2(1500,1170)}, {"id":"army_bed","name":"营房床铺 · 休息","pos":Vector2(470,1040)}, {"id":"army_meal","name":"公用饭桌","pos":Vector2(540,730)}]
		"field":
			g.obstacles.assign([Rect2(0,0,290,690),Rect2(0,915,310,685),Rect2(310,20,320,440),Rect2(840,0,990,205),Rect2(2100,0,460,210),Rect2(300,1330,690,270),Rect2(1500,1410,1060,190)])
			g.actors=[{"id":"return_gate","name":"返回长城关门","pos":Vector2(330,805)}]
			if g.flags.get("training_active",false): g.actors.append({"id":"scout","name":"韩守义 · 实战指导","pos":Vector2(540,840)})
			if not g.flags.has("field_plants"):
				g.flags["field_plants"]=[{"pos":[2120,1250],"taken":false}]
			for i in range(g.flags.field_plants.size()):
				var herb: Dictionary=g.flags.field_plants[i]
				if not herb.taken: g.actors.append({"id":"field_herb_"+str(i),"name":"少量野生草药","pos":Vector2(herb.pos[0],herb.pos[1])})
func camera_target(g: Node) -> Vector2:
	var size: Vector2=SIZES[g.scene_id]
	var focus: Vector2=g.player
	if g.scene_id=="barracks":
		# Fixed camera once indoors; courtyard continues to follow the player.
		for room in [Rect2(240,280,610,535),Rect2(240,945,600,430),Rect2(1095,950,625,425)]:
			if room.has_point(g.player): focus=room.get_center()
	return Vector2(clampf(focus.x-640,0,size.x-1280),clampf(focus.y-400,0,size.y-800))
func begin_training(g: Node) -> void:
	if not g.recruitment.ready(g): g.recruitment.show_gear_guide(g); return
	if g.flags.get("training_active",false) or g.flags.get("training_done",false): return
	g.flags["training_active"]=true
	g.flags["training_kills"]=0
	g.recruitment.configure_training(g,true)
	g.story_events.record(g,"跟随韩守义出关：先练攻击，再练避让与反击")
	g.change_scene("field",Vector2(550,805))
	g.update_hud(); g.mark_dirty()
func on_kill(g: Node) -> void:
	if not g.flags.get("training_active",false) or g.step!=8: return
	var count: int=mini(3,int(g.flags.get("training_kills",0))+1)
	g.flags["training_kills"]=count
	var lines: Array=[
		[["韩守义","第一只倒了。把气喘匀，再捡材料。不是每只都有材料，没掉也不用停在原地找。"],["韩守义","下一只看它的动作：压低身子、地面亮起橙色，就向侧面走。先躲过冲撞，才有空回手。"]],
		[["韩守义","两只。第三只自己把握：等它冲过去、停下来，再上前反击，别在它蓄势时贪刀。"],["陆承安","记住了。打完，先看回关的路。"],["韩守义","这句倒听进去了。"]],
		[["韩守义","三只清了。我在，你也在。东西拾好，沿西边回关。"],["陆承安","才三只，你也要清点？"],["韩守义","清点不是等出了事才做。回去认认同袍，再看名单。那上面的名字，家里都还有人等。"]]]
	if count==3:
		g.flags["training_active"]=false
		g.flags["training_done"]=true
		g.relationships.reward_once("main_training",{"scout":3.0},g)
		g.flags["escort_return"]=true
		g.show_dialog(lines[2],func(): g.advance(8))
	else: g.show_dialog(lines[count-1])
	g.update_hud(); g.mark_dirty()
func draw_herbs(g: Node) -> void:
	for a in g.actors:
		if str(a.id).begins_with("field_herb_"):
			g.draw_line(a.pos,a.pos+Vector2(0,-30),Color("42774d"),4)
			for side in [-1,1]: g.draw_circle(a.pos+Vector2(side*8,-17),7,Color("739657"))
