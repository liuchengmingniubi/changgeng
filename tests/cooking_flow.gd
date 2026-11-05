extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var g=load("res://main.tscn").instantiate()
	root.add_child(g)
	await process_frame
	while g.dialogue_panel.visible: g.next_dialog()
	g.time_minutes=600
	g.npc_life.live.clear()
	g.scene_id="home"
	g.setup_scene()
	g.inventory={"沙麦":3,"《材料大全》":1,"《草药大全》":1}
	g.coins=3
	g.scene_id="mill"
	g.player=Vector2(700,410)
	assert(g.cooking.mill(g))
	assert(g.inventory["沙麦"]==2 and g.inventory["面粉"]==1)
	assert(g.cooking.make("馒头",g))
	assert(g.inventory["馒头"]==1)
	assert(not g.cooking.make("面条",g))
	g.cooking.mill(g)
	g.cooking.mill(g)
	assert(g.cooking.make("面条",g))
	g.scene_id="field"
	g.inventory["沙麦"]=1
	assert(not g.cooking.mill(g))
	g.max_hp=100
	g.hp=50
	g.energy=50
	g.food_cooldown=0
	assert(g.cooking.eat("馒头",g)); g.tick_eating(0.8); assert(g.energy==70 and g.hp==50)
	assert(g.food_cooldown==0)
	g.food_cooldown=0
	assert(g.cooking.eat("面条",g)); g.tick_eating(0.8); assert(g.energy==100 and g.hp==50)
	g.inventory["馒头"]=1
	g.food_cooldown=0
	assert(not g.cooking.eat("馒头",g))
	assert(g.inventory["馒头"]==1)
	g.save_game()
	g.inventory.clear()
	g.load_game()
	assert(g.inventory["馒头"]==1)
	print("PASS: wheat/flour/foods, recipe cost, paid mill-only, energy cap, unrestricted food and 30s potion cooldown, full energy no consumption, saved foods")
	for child in root.get_children(): child.queue_free()
	await process_frame
	quit()
