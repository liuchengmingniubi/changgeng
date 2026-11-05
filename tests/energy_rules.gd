extends SceneTree
func _initialize() -> void: call_deferred("run")
func close_dialog(g: Node) -> void:
	while g.dialogue_panel.visible: g.next_dialog()
func run() -> void:
	var g=load("res://main.tscn").instantiate()
	root.add_child(g)
	await process_frame
	close_dialog(g)
	g.flags={"field_tutorial":true}
	g.inventory={"馒头":4,"面条":3,"回血药水":3}
	g.hp=20
	g.energy=50
	g.food_cooldown=0
	g.potion_cooldown=0
	assert(g.cooking.eat("馒头",g))
	g.tick_eating(0.8)
	assert(g.energy==70 and g.hp==20 and g.food_cooldown==0)
	assert(g.use_potion(),"food does not block medicine")
	assert(g.hp==55 and g.potion_cooldown==30)
	g.food_cooldown=0
	assert(g.cooking.eat("面条",g),"medicine does not block food")
	g.tick_eating(0.8)
	assert(g.energy==100 and g.hp==55)
	g.food_cooldown=0
	assert(not g.cooking.eat("馒头",g),"full energy must not consume")
	g.energy=69.9
	g.regen_timer=0
	g.tick_energy(20)
	assert(g.hp==55)
	g.energy=70
	g.tick_energy(9)
	assert(g.hp==55)
	g.tick_energy(1)
	assert(g.hp==56,"70 percent inclusive")
	g.time_minutes=600
	g.tick_clock(60)
	assert(g.time_minutes==660,"24 real minutes per complete game day")
	g.scene_id="barracks"
	g.hp=20
	g.time_minutes=1300
	var day: int=g.farming.day
	g.rest()
	assert(g.farming.day==day+1 and g.hp==30)
	close_dialog(g)
	g.scene_id="home"
	g.time_minutes=360
	g.rest()
	assert(g.hp==30,"cannot heal twice by switching beds in same dawn")
	g.scene_id="barracks"
	g.player=Vector2(1500,1170)
	g.npc_life.live.medic={"scene":"barracks","pos":Vector2(1500,1170),"status":"值勤","goal":Vector2(1500,1170),"path":[],"moving":false}
	g.time_minutes=800; g.coins=100
	var energy: float=g.energy
	assert(g.life.treatment(g,"medic",true) and g.hp==100 and g.energy==energy)
	g.hp=50
	g.npc_life.live.medic.status="休息"; g.time_minutes=360
	assert(not g.army_treatment() and g.hp==50)
	g.scene_id="field"
	g.coins=100
	g.hp=1
	g.invulnerability=0
	g.take_damage(50,Vector2.ZERO)
	assert(g.coins==80 and g.scene_id=="clinic")
	close_dialog(g)
	g.scene_id="village"
	g.time_minutes=1320
	g.interact("house_6")
	assert(g.scene_id=="village" and not g.transition)
	close_dialog(g)
	g.energy=42
	g.food_cooldown=21
	g.potion_cooldown=4
	g.save_game()
	g.energy=100
	g.food_cooldown=0
	g.load_game()
	assert(g.energy==42 and g.food_cooldown==0 and g.potion_cooldown==4)
	g.show_inventory()
	assert(g.item_description("馒头").contains("精力"))
	g.inventory_ui.show_crafting(g)
	await process_frame
	print("PASS: 24-minute day, food-energy only, independent cooldowns, inclusive 70 percent regen, 10 percent barracks sleep, doctor full heal, locked homes, 20 percent death loss, energy/cooldown save and UI")
	quit()
