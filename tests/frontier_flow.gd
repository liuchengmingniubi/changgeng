extends SceneTree
func _initialize() -> void: call_deferred("run")
func reachable(g: Node,start: Vector2,goal: Vector2) -> bool:
	var queue: Array=[Vector2i(roundi(start.x/20),roundi(start.y/20))]
	var seen: Dictionary={queue[0]:true}
	var index:=0
	while index<queue.size():
		var cell: Vector2i=queue[index]
		index+=1
		var p:=Vector2(cell)*20
		if p.distance_to(goal)<60: return true
		for offset in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
			var next: Vector2i=cell+offset
			var point:=Vector2(next)*20
			if not seen.has(next) and g.movement_bounds().has_point(point) and not g.blocked(point):
				seen[next]=true
				queue.append(next)
	return false
func close_dialog(g: Node) -> void:
	while g.dialogue_panel.visible: g.next_dialog()
func run() -> void:
	var g=load("res://main.tscn").instantiate()
	root.add_child(g)
	await process_frame
	close_dialog(g)
	g.flags={"field_tutorial":true}
	g.step=11
	for id in ["wall","barracks","field"]:
		g.scene_id=id
		g.player={"wall":Vector2(200,825),"barracks":Vector2(990,350),"field":Vector2(550,805)}[id]
		g.setup_scene()
		assert(g.world_layout!=null,"native layered scene renderer exists")
		for actor in g.actors:
			assert(reachable(g,g.player,actor.pos),"unreachable "+id+"/"+actor.id)
		g.player=Vector2(1200,850)
		g.update_camera(true)
		assert(g.camera_offset.x>0 and g.camera_offset.y>0,"outdoor tracking")
	g.scene_id="barracks"
	g.player=Vector2(500,1000)
	g.setup_scene()
	var fixed: Vector2=g.camera_offset
	g.player=Vector2(700,1020)
	g.update_camera(true)
	assert(g.camera_offset==fixed,"bedroom camera fixed")
	g.scene_id="home"
	g.update_camera(true)
	assert(g.camera_offset==Vector2.ZERO)
	g.scene_id="wall"
	g.step=8
	g.grant_enlistment_gear()
	g.equipment.wear("破旧铁甲",g)
	g.frontier.begin_training(g)
	await create_timer(.65).timeout
	close_dialog(g)
	assert(g.scene_id=="field" and g.combat.enemies.size()==3)
	g.swing_power=999
	for enemy in g.combat.enemies:
		assert(enemy.kind=="甲壳虫")
		g.combat.hit_enemy(enemy,g)
		close_dialog(g)
	assert(g.step==9 and g.flags.training_kills==3)
	g.save_game()
	g.load_game()
	assert(g.flags.training_done and g.step==9)
	assert(g.camera_offset.x>=0)
	print("PASS: three maps, reachable NPC/doors/herbs, outdoor follow, fixed rooms, three-kill training and save")
	quit()
