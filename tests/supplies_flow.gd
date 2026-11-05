extends SceneTree
func _initialize() -> void: call_deferred("run")
func close_dialog(g: Node) -> void:
	while g.dialogue_panel.visible: g.next_dialog()
func run() -> void:
	var g=load("res://main.tscn").instantiate()
	root.add_child(g)
	await process_frame
	close_dialog(g)
	g.flags={}
	g.inventory={"沙麦":5,"《材料大全》":1,"《草药大全》":1,"基础草药":3}
	g.coins=5
	g.time_minutes=600
	g.npc_life.live.clear()
	g.scene_id="home"
	g.setup_scene()
	assert(not g.cooking.make("面粉",g))
	assert(not g.cooking.mill(g,1))
	g.scene_id="mill"
	g.player=Vector2(700,430)
	assert(g.cooking.mill(g,5))
	assert(g.coins==0 and g.inventory["沙麦"]==0 and g.inventory["面粉"]==5)
	assert(not g.cooking.mill(g,1))
	g.scene_id="field"
	assert(g.cooking.make("馒头",g,2))
	assert(g.cooking.make("草药饼",g,1))
	assert(g.cooking.make("面条",g,1))
	assert(g.cooking.make("回血药水",g,1))
	g.modal.hide()
	close_dialog(g)
	g.hp=40
	g.energy=20
	g.food_cooldown=0
	g.potion_cooldown=0
	assert(g.cooking.eat("馒头",g)); g.tick_eating(0.8)
	assert(g.hp==40 and g.energy==40 and g.food_cooldown==0)
	assert(g.cooking.eat("草药饼",g)); g.tick_eating(0.8)
	assert(g.use_potion())
	g.hp=40
	g.scene_id="home"
	g.time_minutes=900
	var day: int=g.farming.day
	g.rest()
	assert(g.farming.day==day and g.hp==40 and g.time_minutes==900)
	g.time_minutes=1250
	g.rest()
	assert(g.farming.day==day+1 and g.time_minutes==360 and g.hp==50)
	close_dialog(g)
	assert(g.food_cooldown==0,"rest cannot bypass cooldown")
	g.rest()
	assert(g.hp==50)
	g.time_minutes=90
	day=g.farming.day
	g.rest()
	assert(g.farming.day==day and g.time_minutes==360,"after midnight sleep must not skip another day")
	close_dialog(g)
	g.time_minutes=800
	g.save_game()
	g.time_minutes=0
	g.load_game()
	assert(g.time_minutes==800 and g.food_cooldown==0)
	g.inventory_ui.show_crafting(g)
	assert(g.modal.visible)
	g.flags["chapter1_complete"]=false
	g.show_market()
	g.flags["chapter1_complete"]=true
	g.show_market()
	var saved_inventory: Dictionary=g.inventory.duplicate(true)
	g.inventory={"《材料大全》":1,"面粉":5}
	for i in range(41): g.inventory["填充材料"+str(i)]=1
	assert(not g.cooking.make("馒头",g,1))
	assert(g.inventory["面粉"]==5 and not g.inventory.has("馒头"))
	assert(g.cooking.make("馒头",g,5),"consuming last ingredient frees slot")
	g.inventory=saved_inventory
	g.scene_id="mill"
	g.setup_scene()
	g.queue_redraw()
	await process_frame
	print("PASS: paid bulk milling, portable recipes, unrestricted food and 30s potion cooldown, night-only partial rest, midnight/day rules, saved clock and UI")
	quit()
