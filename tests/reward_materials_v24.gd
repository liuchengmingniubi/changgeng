extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var g=load("res://main.tscn").instantiate(); root.add_child(g)
	await process_frame; g.set_process(false)
	while g.dialogue_panel.visible: g.next_dialog()
	g.flags={}; g.scene_id="village"; g.time_minutes=600; g.farming.day=1; g.coins=10000
	g.npc_life.live.merchant={"scene":"village","pos":Vector2(1100,1020),"status":"工作"}; g.player=Vector2(1100,1020)
	assert(g.commerce.transact(g,"merchant","兽皮",16))
	assert(not g.commerce.transact(g,"merchant","兽皮",1))
	assert(g.commerce.transact(g,"merchant","铁锭",5) and not g.commerce.transact(g,"merchant","铁锭",1))
	assert(g.commerce.transact(g,"merchant","铜锭",5) and not g.commerce.transact(g,"merchant","铜锭",1))
	assert(not g.commerce.stock(g,"leather").has("皮革") and not g.commerce.stock(g,"smith").has("铁锭"))
	g.save_game(); g.load_game()
	while g.dialogue_panel.visible: g.next_dialog()
	assert(g.commerce.remaining(g,"兽皮",16)==0)
	g.farming.day=7; assert(g.commerce.remaining(g,"兽皮",16)==0)
	g.farming.day=8; assert(g.commerce.remaining(g,"兽皮",16)==16 and g.commerce.remaining(g,"铁锭",5)==5 and g.commerce.remaining(g,"铜锭",5)==5)
	g.npc_life.live.leather={"scene":"village","pos":Vector2(550,1320),"status":"工作"}; g.player=Vector2(550,1320)
	g.inventory={"兽皮":4}; g.craft_ui.show_menu(g,"leather"); g.craft_ui.prefill("皮革")
	assert(g.craft_ui.craft("皮革") and g.inventory["兽皮"]==2 and g.inventory["皮革"]==1)
	assert(not g.CraftCatalog.RECIPES.has("皮绳"))
	# Reward accessories use real slots and effects, and persist as worn gear.
	g.inventory={"普通皮革手套":1,"普通皮革腰带":1,"普通皮革鞋靴":1}; g.equipment.worn.clear(); g.recalculate_stats()
	var damage: int=g.attack_power; var defense: int=g.defense; var hp: int=g.max_hp
	for item in g.inventory.keys(): assert(g.equipment.wear(item,g))
	assert(g.attack_power==damage+2 and g.defense==defense+2 and g.max_hp==hp+10)
	g.save_game(); g.equipment.worn={}; g.load_game()
	while g.dialogue_panel.visible: g.next_dialog()
	assert(g.equipment.worn["手套"]=="普通皮革手套" and g.equipment.worn["鞋靴"]=="普通皮革鞋靴")
	# Fertilizer and rare seeds have usable, saved farming behavior.
	g.scene_id="village"; g.setup_scene(); g.player=g.farming.plots[0].pos; g.inventory={"锄头":1,"稀有种子":1,"肥料":2}
	g.farming.plots[0].tilled=true
	assert(g.farming.plant(0,"稀有种子",g))
	assert(g.farming.fertilize(g) and not g.farming.fertilize(g) and g.inventory["肥料"]==1)
	var saved: Dictionary=g.farming.snapshot(); g.farming.restore(saved); g.farming.plots[0].watered=true; g.farming.next_day()
	assert(g.farming.plots[0].growth==4 and not g.farming.plots[0].fertilizer_pending)
	g.farming.plots[0].watered=true; g.farming.next_day(); assert(g.farming.plots[0].growth==5)
	print("PASS v24 reward support: weekly 16 hides/5 iron/5 copper, independent saved quotas, hide processing, no cord recipe, actual leather accessory equipment stats/save, rare seed planting and once-per-crop fertilizer")
	g.queue_free(); await process_frame; quit()
