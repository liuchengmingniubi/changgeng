extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var g=load("res://main.tscn").instantiate(); root.add_child(g); await process_frame; g.set_process(false)
	while g.dialogue_panel.visible: g.next_dialog()
	g.flags={"training_done":true}; g.step=11; g.scene_id="village"; g.time_minutes=780; g.npc_life.live.clear(); g.setup_scene()
	assert(g.VILLAGE_SIZE==Vector2(4344,3258))
	for t in [690,735,780,810,840,900,1080,1110]:
		g.time_minutes=t
		for id in g.npc_life.PEOPLE: assert(g.npc_life.desired(id,g).status!="用饭")
	var mill: Dictionary=g.actors.filter(func(a): return a.id=="mill_entry")[0]
	assert(mill.pos==g.cooking.MILL_POS and not g.blocked(mill.pos))
	for i in range(12):
		var actor: Dictionary=g.actors.filter(func(a): return a.id=="farm_"+str(i))[0]
		assert(actor.pos==g.farming.plots[i].pos)
	for prop in g.world_layout.props: assert(g.blocked(prop.rect.get_center()*g.world_layout.SCALE))
	var rec=load("res://tests/previews/canvas_recorder.gd").new(); rec.game=g; root.add_child(rec)
	g.inventory={"镐子":1,"肥料":2}; g.quickbar=["镐子","肥料","","","",""]; g.quickbar_index=0
	g.actor_visual.held(rec,g.player); assert(rec.commands.any(func(c): return c.kind=="texture"))
	var first: Array=rec.commands.filter(func(c): return c.kind=="texture")[0].region
	rec.commands.clear(); g.quickbar_index=1; g.actor_visual.held(rec,g.player)
	assert(rec.commands.filter(func(c): return c.kind=="texture")[0].region!=first)
	rec.commands.clear(); g.quickbar_index=2; g.actor_visual.held(rec,g.player); assert(rec.commands.is_empty()); rec.queue_free()
	var board: Dictionary=g.actors.filter(func(a): return a.id=="commission_board")[0]; assert(board.pos==g.commissions.BOARD_POS)
	for i in range(g.HOUSE_DATA.size()): assert(not g.blocked(g.world_layout.door(i)),"blocked door "+str(i))
	g.player=g.farming.plots[0].pos; g.interaction_target=""; g.inventory={"药草种子":1,"肥料":3}; g.energy=100
	g.farming.plots[0].tilled=true; assert(g.farming.plant(0,"药草种子",g))
	assert(g.farming.fertilize(g) and g.farming.plots[0].growth==3 and g.inventory["肥料"]==2)
	assert(not g.farming.fertilize(g) and g.inventory["肥料"]==2)
	var save: Dictionary=g.farming.snapshot(); g.farming.restore(save); assert(g.farming.plots[0].growth==3 and g.farming.plots[0].fertilized)
	for i in range(3): g.farming.plots[0].watered=true; g.farming.next_day()
	assert(g.farming.plots[0].growth==6)
	g.farming.work(0,g); assert(g.farming.plots[0].seed=="" and not g.farming.plots[0].fertilized)
	g.inventory["初始种子"]=1; assert(g.farming.plant(0,"初始种子",g)); g.farming.plots[0].growth=2
	assert(not g.farming.fertilize(g) and g.inventory["肥料"]==2)
	# Odd remaining days round up; old pending fertilizer converts once on restore.
	g.farming.plots[0].seed="药草种子"; g.farming.plots[0].growth=1; g.farming.plots[0].fertilized=false
	assert(g.farming.fertilize(g) and g.farming.plots[0].growth==3 and g.inventory["肥料"]==1)
	var legacy: Dictionary=g.farming.snapshot(); legacy.plots[0].growth=0; legacy.plots[0].fertilizer_pending=true
	g.farming.restore(legacy); assert(g.farming.plots[0].growth==3 and not g.farming.plots[0].fertilizer_pending)
	g.farming.restore(g.farming.snapshot()); assert(g.farming.plots[0].growth==3)
	# Save migration scales an old village position once, not again on each load.
	g.player=Vector2(2160,2775); g.time_minutes=600; g.save_game()
	var saved: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(g.SAVE)); saved.map_revision=3; saved.player=[1440,1850]
	var f:=FileAccess.open(g.SAVE,FileAccess.WRITE); f.store_string(JSON.stringify(saved)); f.close()
	g.load_game(); assert(g.player==Vector2(2160,2775))
	g.save_game(); g.load_game(); assert(g.player==Vector2(2160,2775))
	print("PASS v27: 2.25x village area, no meal shifts, separate mill, aligned portals/doors, half-remaining fertilizer, feedback/save/reset, no wasted last-day fertilizer, once-only coordinate migration")
	g.queue_free(); await process_frame; quit()
