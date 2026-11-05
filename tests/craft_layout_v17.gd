extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var g=load("res://main.tscn").instantiate(); root.add_child(g)
	await process_frame; g.set_process(false)
	while g.dialogue_panel.visible: g.next_dialog()
	g.inventory={"制作书·甲壳护甲":1,"甲壳":2,"铁锭":2,"皮革":2}; g.coins=100
	g.craft_ui.show_menu(g,"smith"); g.craft_ui.prefill("甲壳护甲"); g.craft_ui.show_crafting()
	await process_frame; await process_frame; await process_frame
	assert(g.modal.size.x<=1280 and g.modal.size.y<=736,"craft panel fits viewport")
	assert(g.craft_ui.make_button.get_global_rect().end.y<=800)
	assert(g.craft_ui.output_slot.get_global_rect().end.x<=1280)
	g.inventory={"兽皮":2}; g.craft_ui.owner_id="leather"; g.craft_ui.prefill("皮革")
	assert(g.craft_ui.candidates()==["皮革"],"complete recipe wins over partial recipe")
	g.craft_ui.show_crafting(); await process_frame; await process_frame
	assert(g.modal.size.y<=736)
	g.craft_ui.show_catalog(); await process_frame; await process_frame; assert(g.modal.size.y<=736)
	g.craft_ui.show_bookshop(g); await process_frame; await process_frame; assert(g.modal.size.y<=736)
	# A frame spanning the complete hit window must still land exactly once.
	g.modal.hide(); g.scene_id="field"; g.obstacles.clear(); g.player=Vector2(1000,650)
	g.swing_weapon=g.CraftCatalog.WEAPONS["军用旧铁剑"].duplicate(); g.swing_weapon.crit=0
	g.swing_power=18; g.combo=1; g.attack_time=0; g.attack_previous_progress=0.1
	g.facing=Vector2.RIGHT; g.combat.reset_enemies()
	var e: Dictionary=g.combat.enemies[0]; e.pos=g.player+Vector2(55,0); e.home=e.pos; e.state="recover"; e.timer=100
	g.combat.begin_swing(); g.combat.tick(0,g); assert(e.hp==37)
	g.combat.tick(0,g); assert(e.hp==37)
	print("PASS: craft control layout fits 1280x800, bookless recipe selection, frame-spanning hit window")
	g.queue_free(); await process_frame; quit()
