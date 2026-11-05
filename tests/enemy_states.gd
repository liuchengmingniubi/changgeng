extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var g=load("res://main.tscn").instantiate()
	root.add_child(g)
	await process_frame
	while g.dialogue_panel.visible: g.next_dialog()
	g.scene_id="field"
	g.setup_scene()
	while g.dialogue_panel.visible: g.next_dialog()
	g.obstacles.clear()
	for other in g.combat.enemies: other.hp=0
	var e: Dictionary=g.combat.enemies[0]
	e.hp=55
	e.pos=Vector2(800,650)
	e.home=e.pos
	e.state="idle"
	g.player=Vector2(720,650)
	g.combat.tick(.01,g)
	assert(e.state=="chase")
	g.combat.tick(.01,g)
	assert(e.state=="windup")
	var locked: Vector2=e.facing
	g.player=Vector2(720,750)
	g.combat.tick(.86,g)
	assert(e.state=="lunge" and e.facing==locked)
	var hp=g.hp
	for i in range(31): g.combat.tick(.01,g)
	assert(g.hp==hp,"side-step avoids attack")
	assert(e.state=="recover")
	g.combat.tick(1.1,g)
	assert(e.state=="chase")
	g.player=Vector2(550,650)
	g.combat.tick(.01,g)
	assert(e.state=="return","entrance safety area")
	g.inventory["甲壳"]=3
	g.time_minutes=1300
	g.rest()
	assert(g.combat.enemies[0].hp==55)
	assert(g.inventory["甲壳"]==3)
	print("PASS: detect, chase, windup, locked attack, side-step, recovery, leash, rest respawn")
	g.queue_free()
	await process_frame
	quit()
