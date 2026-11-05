extends SceneTree
func _initialize() -> void: call_deferred("run")
func close_dialog(g: Node) -> void:
	while g.dialogue_panel.visible: g.next_dialog()
func fit(g: Node) -> void:
	assert(g.modal.size.x<=1280 and g.modal.size.y<=736,"panel fits viewport")
func run() -> void:
	var g=load("res://main.tscn").instantiate(); root.add_child(g)
	await process_frame; g.set_process(false); close_dialog(g)
	g.flags={}; g.inventory={"制作书·甲壳盔":3,"甲壳":5,"铁锭":5}; g.coins=100; g.time_minutes=600; g.scene_id="village"
	g.npc_life.live.smith={"scene":"village","pos":Vector2(2100,1050),"status":"工作"}; g.player=Vector2(2100,1050)
	var c=g.craft_ui; c.show_menu(g,"smith")
	assert(c.put("制作书·甲壳盔",-1,true,3) and c.put("甲壳",0,false,5) and c.put("铁锭",1,false,5))
	assert(c.craft("甲壳盔",2))
	assert(g.inventory["制作书·甲壳盔"]==1 and g.inventory["甲壳盔"]==2 and g.inventory["甲壳"]==3)
	assert(c.book_count==1 and c.amounts[0]==3 and c.amounts[1]==3,"remaining staged materials retained")
	assert(c.craft("甲壳盔") and g.inventory["甲壳盔"]==3 and g.inventory["制作书·甲壳盔"]==0)
	var before: Dictionary=g.inventory.duplicate(); var coins: int=g.coins
	assert(not c.craft("甲壳盔",2) and g.inventory==before and g.coins==coins)
	c.show_crafting(); await process_frame; await process_frame; fit(g)
	g.inventory={"制作书·甲壳盔":1,"甲壳":1}; c.prefill("甲壳盔"); c.show_crafting()
	assert(c.result_label.text.contains("[color=#a34535]") and c.make_button.disabled)
	await process_frame; await process_frame; fit(g)
	g.inventory_ui.show_crafting(g); await process_frame; await process_frame; fit(g)
	g.inventory={"制作书·甲壳盔":3,"甲壳":6,"铁锭":6}; g.coins=100
	c.show_menu(g,"smith"); c.show_crafting()
	g.modal.find_child("PlaceQuantity",true,false).value=3
	for key in ["制作书·甲壳盔","甲壳","铁锭"]:
		var clicked:=false
		for button in g.modal.find_children("*","Button",true,false):
			if button.get_script()==load("res://item_slot.gd") and button.item_name==key and button.drag_payload.get("source","")=="bag": button.pressed.emit(); clicked=true; break
		assert(clicked)
	g.modal.find_child("CraftQuantity",true,false).value=2
	assert(not c.make_button.disabled); c.make_button.pressed.emit()
	assert(g.inventory["甲壳盔"]==2 and c.book_count==1 and c.amounts[0]==1 and g.toast_panel.visible)
	# Trade checks are authoritative, independent of the open quantity dialog.
	g.npc_life.live.merchant={"scene":"village","pos":Vector2(1100,1020),"status":"工作"}; g.player=Vector2(1100,1020); g.coins=200; g.level=1; g.inventory={"沙麦":4}
	assert(g.commerce.transact(g,"merchant","初始种子",3) and g.coins==176 and g.inventory["初始种子"]==3)
	assert(not g.commerce.transact(g,"merchant","制作书·甲壳盔",1))
	g.level=3; assert(g.commerce.transact(g,"merchant","制作书·甲壳盔",2) and g.inventory["制作书·甲壳盔"]==2 and g.coins==148)
	assert(g.commerce.transact(g,"merchant","沙麦",2,true) and g.inventory["沙麦"]==2 and g.coins==160)
	before=g.inventory.duplicate(); coins=g.coins
	assert(not g.commerce.transact(g,"merchant","初始种子",0))
	assert(not g.commerce.transact(g,"merchant","初始种子",999))
	assert(not g.commerce.transact(g,"merchant","甘草",1))
	g.npc_life.live.merchant.status="休息"; assert(not g.commerce.transact(g,"merchant","初始种子",1)); g.npc_life.live.merchant.status="工作"
	assert(g.inventory==before and g.coins==coins)
	g.level=1; g.commerce.show_quantity(g,"merchant","制作书·甲壳盔",false,true)
	g.modal.find_child("TradeQuantity",true,false).value=2
	var found:=false
	for l in g.modal.find_children("*","Label",true,false):
		if l.text=="总价 28文": found=true
	assert(found)
	await process_frame; await process_frame; fit(g)
	g.commerce.show(g,"merchant",true); await process_frame; await process_frame; fit(g)
	g.inventory={}; g.coins=100
	for i in range(42): g.inventory["占格%d" % i]=1
	assert(not g.commerce.transact(g,"merchant","初始种子",1) and g.coins==100)
	# Audio and video preferences survive gameplay loading independently.
	var options=g.game_options
	assert(options.music.stream!=null and options.music.stream.get_length()>20)
	options.set_volume(g,"music",0); assert(options.music.stream_paused and g.sound_enabled)
	options.set_volume(g,"music",70); options.set_volume(g,"sfx",0); assert(not g.sound_enabled and not options.music.stream_paused)
	options.set_volume(g,"sfx",30); assert(g.sound_enabled and is_equal_approx(g.sound_player.volume_db,-9+linear_to_db(0.3)))
	options.fullscreen=true; options.window_size=Vector2i(1600,1000); assert(options.save()); options.fullscreen=false; options.restore(g)
	assert(options.fullscreen and options.window_size==Vector2i(1600,1000) and options.sfx_volume==30)
	options.show(g); await process_frame; await process_frame; fit(g)
	options.show_controls(g); await process_frame; await process_frame; fit(g)
	assert(g.save_game()); g.flags.sound_enabled=false; g.save_game(); g.load_game(); close_dialog(g); assert(g.sound_enabled and options.music_volume==70)
	# White atlas preserves silhouette alpha, cooldown and short sparks stay separate.
	var normal: Image=g.hero_texture.get_image(); var white: Image=g.hero_flash_texture.get_image(); var sampled:=false
	for y in range(100,800,31):
		for x in range(80,390,19):
			var pixel: Color=normal.get_pixel(x,y)
			if pixel.a>0.9:
				var flash: Color=white.get_pixel(x,y)
				assert(flash.r>0.99 and flash.g>0.99 and flash.b>0.99 and is_equal_approx(pixel.a,flash.a),"white hit silhouette")
				sampled=true; break
		if sampled: break
	assert(sampled)
	g.modal.hide(); g.scene_id="field"; g.flags.field_tutorial=true; g.obstacles.clear(); g.hp=100; g.max_hp=100; g.defense=0; g.invulnerability=0; g.player=Vector2(1000,800)
	g.take_damage(10,Vector2(900,800)); assert(g.hp==90 and g.hurt_flash>0)
	g.combat.reset_enemies(); var e: Dictionary=g.combat.enemies[0]; e.pos=g.player+Vector2(60,0); e.hp=100; e.state="recover"; e.timer=10
	g.swing_weapon=g.CraftCatalog.WEAPONS["军用旧铁剑"].duplicate(); g.swing_weapon.crit=1; g.swing_power=18; g.combo=1
	g.combat.hit_enemy(e,g); assert(g.combat.effects.size()==1 and g.combat.numbers[-1].critical and g.combat.numbers[-1].text.contains("暴击"))
	g.combat.tick(0.2,g); assert(g.combat.effects.is_empty())
	g.inventory={"回血药水":2}; g.flags.quickbar=["回血药水","","","","",""]; g.flags.quickbar_initialized=true; g.potion_cooldown=29.2; g.refresh_quickbar(); assert(g.quickbar_slots[0].cooldown_seconds==29.2)
	print("PASS v20: batch one-use books, retained staging, failure atomicity, red shortages, quantities and totals, locks/full bag/off-duty trades, independent audio/settings persistence, menu layout, saved game result, white silhouette, critical sparks and potion countdown")
	g.queue_free(); await process_frame; quit()
