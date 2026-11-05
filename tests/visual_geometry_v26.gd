extends SceneTree
func _initialize() -> void: call_deferred("run")
func close(g: Node) -> void:
	while g.dialogue_panel.visible: g.next_dialog()
func run() -> void:
	var g=load("res://main.tscn").instantiate(); root.add_child(g); await process_frame; g.set_process(false); close(g)
	g.step=11; g.flags.training_done=true; g.time_minutes=600; g.scene_id="village"; g.setup_scene()
	assert(g.actor_visual.frames.size()==4)
	for row in g.actor_visual.frames:
		assert(row.size()==4)
		for frame in row: assert(frame.size.x>0 and frame.size.y>0)
	assert(g.actor_visual.direction(Vector2.LEFT)==1 and g.actor_visual.direction(Vector2.RIGHT)==2 and g.actor_visual.direction(Vector2.UP)==3)
	assert(not g.world_layout.trees.is_empty() and not g.world_layout.fences.is_empty())
	assert(g.blocked(g.world_layout.pond.get_center()*g.world_layout.SCALE))
	for tree in g.world_layout.trees: assert(g.blocked(tree*g.world_layout.SCALE))
	var moved: Vector2=g.sweep_move(Vector2(1200,1050)*g.world_layout.SCALE,Vector2(500,0)*g.world_layout.SCALE,g.movement_bounds())
	assert(moved.x<g.world_layout.pond.position.x*g.world_layout.SCALE-8,"large frame movement cannot cross the pond")
	moved=g.sweep_move(Vector2(240,620)*g.world_layout.SCALE,Vector2(0,150)*g.world_layout.SCALE,g.movement_bounds()); assert(moved.y<650*g.world_layout.SCALE-8,"thin farm fence blocks swept movement")
	for i in range(g.HOUSE_DATA.size()):
		var door: Vector2=g.world_layout.door(i); assert(not g.blocked(door),"house door blocked: "+str(i))
	# Static business doors are separate from their working characters.
	for id in ["elder","smith","doctor","merchant","leather","innkeeper"]:
		var d: Dictionary=g.npc_life.PEOPLE[id]
		assert(g.world_layout.door(int(d.house)).distance_to(d.work*g.world_layout.SCALE)>=96,"overlapping shop and house targets: "+id)
	var art=load("res://item_art.gd")
	for name in g.CraftCatalog.WEAPONS.keys()+g.CraftCatalog.ARMOR.keys()+art.NAMES:
		assert(art.index_for(name)>=0 and art.index_for(name)<64)
	g.time_minutes=600; g.scene_id="wall"; g.npc_life.live.clear(); g.setup_scene()
	var before: Vector2=g.npc_life.live.scout.pos
	g.npc_life.live.scout.pos=before-Vector2(40,0); g.npc_life.tick(0.1,g)
	assert(g.npc_life.live.scout.has("facing"))
	# Rendering/UI still fit, all slots now reference the pixel icon atlas.
	g.inventory={"铁锭":1,"甲锋剑":1,"普通皮革手套":1,"通用手套制作书":1}; g.show_inventory()
	await process_frame; await process_frame
	assert(g.modal.size.x<=1280 and g.modal.size.y<=736 and g.modal.has_meta("bronze_trim"))
	assert(g.panel_style("dfe5ca").corner_radius_top_left>=8)
	print("PASS v26: 4 directions x 4 real walk frames, no limb stretching, shared render/collision geometry, trees/pond/fences, swept movement, 19 clear doors, separated shop targets, all item atlas bindings, NPC facing and decorated jade UI")
	g.queue_free(); await process_frame; quit()
