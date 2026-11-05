extends SceneTree
func _initialize() -> void: call_deferred("run")
func finish(g) -> void:
	while g.dialogue_panel.visible: g.next_dialog()
func run() -> void:
	var g=load("res://main.tscn").instantiate()
	root.add_child(g)
	await process_frame
	finish(g)
	g.scene_id="village"
	g.player=Vector2(356,370)*g.world_layout.SCALE
	g.setup_scene()
	assert(g.HOUSE_DATA.size()==19)
	assert(g.farming.plots.size()==12)
	var start:=Vector2i(27,28)
	var todo=[start]
	var seen={start:true}
	var index:=0
	while index<todo.size():
		var p: Vector2i=todo[index]
		index+=1
		for offset in [Vector2i(1,0),Vector2i(-1,0),Vector2i(0,1),Vector2i(0,-1)]:
			var next: Vector2i=p+offset
			var world:=Vector2(next)*20
			if not seen.has(next) and g.movement_bounds().has_point(world) and not g.blocked(world):
				seen[next]=true
				todo.append(next)
	var failures:=[]
	for a in g.actors:
		var accessible:=false
		for tile in seen:
			if (Vector2(tile)*20).distance_to(a.pos)<70:
				accessible=true
				break
		if not accessible: failures.append(a.id)
	assert(failures.is_empty(),"Unreachable: "+str(failures))
	g.player=Vector2(2400,1700)
	g.update_camera(true)
	assert(g.camera_offset.x>0 and g.position==-g.camera_offset)
	g.farming.water=12
	g.inventory={"锄头":1,"初始种子":6,"药草种子":1}
	g.farming.work(0,g)
	assert(g.farming.plots[0].tilled)
	assert(g.farming.plant(0,"初始种子",g))
	assert(g.inventory["初始种子"]==5)
	assert(not g.farming.plant(0,"初始种子",g),"no duplicate plant")
	g.farming.next_day()
	assert(g.farming.plots[0].growth==0,"unwatered crop must not grow")
	for day in range(3):
		g.farming.work(0,g)
		assert(g.farming.plots[0].watered)
		g.farming.work(0,g)
		g.farming.next_day()
	assert(g.farming.plots[0].growth==3)
	g.farming.work(0,g)
	assert(g.inventory["沙麦"]==2)
	g.farming.work(0,g)
	assert(g.inventory["沙麦"]==2,"cannot harvest twice")
	g.modal.hide()
	assert(g.farming.plant(0,"药草种子",g))
	g.farming.work(0,g)
	g.save_game()
	var saved_day=g.farming.day
	g.farming.day=100
	g.load_game()
	assert(g.farming.day==saved_day)
	assert(g.farming.plots[0].seed=="药草种子" and g.farming.plots[0].watered)
	assert(g.inventory["沙麦"]==2)
	print("PASS: 19 houses and all NPC/door/field paths, camera, hoe, planting, watering, days, harvest once, farming save/load")
	for child in root.get_children(): child.queue_free()
	await process_frame
	quit()
