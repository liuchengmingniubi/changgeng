extends SceneTree
func _initialize() -> void: call_deferred("run")
func close_dialog(g: Node) -> void:
	while g.dialogue_panel.visible: g.next_dialog()
func run() -> void:
	var g=load("res://main.tscn").instantiate(); root.add_child(g); await process_frame; g.set_process(false); close_dialog(g)
	g.step=7; g.scene_id="village"; g.time_minutes=600; g.setup_scene()
	var gate: Dictionary=g.actors.filter(func(a): return a.id=="wall")[0]
	assert(gate.pos==g.VILLAGE_GATE)
	# Walk the visible east-gate approach and doorway, not just an arbitrary reachable trigger.
	for x in range(2480,2801,4): assert(not g.blocked(Vector2(x,940)*g.world_layout.SCALE))
	for y in range(840,981,4): assert(not g.blocked(Vector2(2720,y)*g.world_layout.SCALE))
	assert(g.blocked(Vector2(2720,750)*g.world_layout.SCALE) and g.blocked(Vector2(2720,1040)*g.world_layout.SCALE))
	g.player=Vector2(2750,960)*g.world_layout.SCALE; g.interaction_target=""
	assert(g.nearest().id=="wall" and g.interaction_prompt(g.nearest()).contains("前往"))
	g.interact("wall"); await create_timer(0.65).timeout
	assert(g.scene_id=="wall" and g.player.distance_to(Vector2(200,825))<1)
	g.interact("village"); await create_timer(0.65).timeout
	assert(g.scene_id=="village" and g.player==g.VILLAGE_GATE_RETURN and not g.blocked(g.player))
	assert(g.npc_life.PORTALS.village.wall[0]==g.VILLAGE_GATE and g.npc_life.PORTALS.wall.village[1]==g.VILLAGE_GATE_RETURN)
	# The original recruitment gate remains intact.
	g.step=0; g.player=g.VILLAGE_GATE; g.interact("wall"); assert(g.scene_id=="village" and g.dialogue_panel.visible)
	close_dialog(g)
	print("PASS v251: art-aligned gate, real approach corridor, wall collision, F prompt from screenshot position, both-way transitions, return spawn, NPC route alignment and recruitment gate")
	g.queue_free(); await process_frame; quit()
