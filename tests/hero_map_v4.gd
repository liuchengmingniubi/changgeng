extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var visual = load("res://actor_visual.gd").new()
	visual.setup()
	assert(visual.map_texture != null)
	assert(visual.map_regions.size() == 16)
	for region in visual.map_regions:
		assert(region.size.x > 0 and region.size.y > 0)
	assert(visual.direction(Vector2.DOWN) == 0)
	assert(visual.direction(Vector2.LEFT) == 1)
	assert(visual.direction(Vector2.RIGHT) == 2)
	assert(visual.direction(Vector2.UP) == 3)
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	assert(game.actor_visual.map_texture != null)
	for scene in ["home", "village", "field"]:
		game.scene_id = scene
		game.setup_scene()
		game.queue_redraw()
		await process_frame
	print("PASS: v4 atlas, sixteen frames, four directions and shared map renderer")
	game.queue_free()
	await process_frame
	quit()
