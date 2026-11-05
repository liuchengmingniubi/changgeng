extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var g=load("res://main.tscn").instantiate()
	root.add_child(g)
	await process_frame
	g.set_process(false)
	while g.dialogue_panel.visible: g.next_dialog()
	g.flags={}; g.inventory={}; g.equipment.worn.clear()
	g.grant_starter_equipment()
	assert(not g.flags.storage.has("粗布衣"))
	assert(not g.equipment.ITEMS.has("粗布衣"))
	g.grant_enlistment_gear(); g.grant_enlistment_gear()
	assert(g.inventory["破旧铁甲"]==1 and g.inventory["军用旧铁剑"]==1)
	assert(g.equipment.wear("破旧铁甲",g) and g.defense==5)
	g.scene_id="village"; g.time_minutes=600
	g.npc_life.live.smith={"scene":"village","pos":Vector2(2100,1050),"status":"工作"}
	g.player=Vector2(2100,1050); g.coins=100
	g.inventory={"制作书·甲壳盔":2,"甲壳":3,"铁锭":3}
	var c=g.craft_ui
	c.show_menu(g,"smith"); c.prefill("甲壳盔")
	assert(c.reason("甲壳盔")=="")
	var before: Dictionary=g.inventory.duplicate()
	c.show_crafting(); c.show_catalog(); c.show_menu(g,"smith")
	assert(g.inventory==before,"cancel and browsing must not consume anything")
	c.prefill("甲壳盔"); assert(c.craft("甲壳盔"))
	assert(g.inventory["制作书·甲壳盔"]==1 and g.inventory["甲壳盔"]==1 and g.inventory["甲壳"]==2)
	c.prefill("甲壳盔"); assert(c.craft("甲壳盔"))
	assert(g.inventory["制作书·甲壳盔"]==0 and g.inventory["甲壳盔"]==2)
	c.prefill("甲壳盔"); assert(not c.craft("甲壳盔"))
	g.inventory["厚甲片"]=1
	c.prefill("厚甲盔"); assert(c.book=="" and c.craft("厚甲盔"))
	assert(g.inventory["甲壳盔"]==1 and g.inventory["厚甲盔"]==1)
	c.owner_id="leather"; c.prefill("甲壳盔"); assert(not c.craft("甲壳盔"))
	c.owner_id="smith"; g.inventory={"制作书·甲壳盔":2,"甲壳":2,"铁锭":2}
	for i in range(39): g.inventory["满包材料%d" % i]=1
	c.prefill("甲壳盔"); before=g.inventory.duplicate(); var coins: int=g.coins
	assert(not c.craft("甲壳盔") and g.inventory==before and g.coins==coins)
	g.inventory={"制作书·甲壳盔":1,"甲壳":1,"铁锭":1}; c.prefill("甲壳盔")
	g.npc_life.live.smith.status="休息"
	assert(not c.craft("甲壳盔"))
	g.npc_life.live.smith.status="工作"
	g.level=1; c.show_bookshop(g)
	g.inventory={"军用旧铁剑":1,"铁钩镰":1,"军用铁锤":1}; g.quickbar.fill(""); g.flags={"held_weapon":"军用旧铁剑"}; g.modal.hide()
	g.scene_id="field"; g.flags.field_tutorial=true; g.obstacles.clear(); g.player=Vector2(1000,600)
	g.combat.reset_enemies(); g.combat.loot.clear()
	for weapon in ["军用旧铁剑","铁钩镰","军用铁锤"]:
		g.flags.held_weapon=weapon; g.attack_time=0; g.attack_recovery=0; g.start_attack()
		assert(g.attack_duration==float(g.CraftCatalog.WEAPONS[weapon].duration))
		g.attack_time=0.1; g.start_attack(); assert(g.attack_buffer>0,"late input buffered")
		var last: float=g.swing_angle(0)
		for i in range(1,241):
			var angle: float=g.swing_angle(float(i)/240)
			assert(absf(angle-last)<0.06,"continuous high rate interpolation")
			last=angle
	g.swing_weapon=g.CraftCatalog.WEAPONS["军用旧铁剑"].duplicate(); g.swing_weapon.crit=0
	g.swing_power=18; g.combo=1; g.attack_duration=0.5; g.attack_time=0.25; g.facing=Vector2.RIGHT
	var e: Dictionary=g.combat.enemies[0]; e.pos=g.player+Vector2(60,0); e.home=e.pos; e.hp=55; e.state="recover"; e.timer=100
	g.combat.begin_swing(); g.combat.tick(0,g); assert(e.hp==37)
	g.combat.tick(0,g); assert(e.hp==37,"one hit per swing")
	g.swing_weapon.crit=1; g.combat.begin_swing(); g.combat.tick(0,g); assert(e.hp==10,"150 percent crit")
	for weapon in ["铁钩镰","军用铁锤"]:
		g.swing_weapon=g.CraftCatalog.WEAPONS[weapon].duplicate(); g.swing_weapon.crit=0
		g.attack_duration=float(g.swing_weapon.duration); g.attack_time=g.attack_duration*0.5
		for j in range(2):
			g.combat.enemies[j].hp=100; g.combat.enemies[j].pos=g.player+Vector2(60,j*10); g.combat.enemies[j].state="recover"; g.combat.enemies[j].timer=100
		g.combat.begin_swing(); g.combat.tick(0,g)
		assert(g.combat.enemies[0].hp<100)
		assert((g.combat.enemies[1].hp<100)==(weapon=="铁钩镰"),"scythe multi-target and hammer single-target")
	var empty:=0; var shells:=0; var thick:=0
	seed(567)
	for i in range(10000):
		var drop: Dictionary=g.combat.roll_drop("厚甲甲壳虫")
		assert(drop.coins>=7 and drop.coins<=10)
		if drop.materials.is_empty(): empty+=1
		if drop.materials.has("甲壳"): shells+=1
		if drop.materials.has("厚甲片"): thick+=1
	assert(empty>0 and shells>8800 and shells<9200 and thick>3800 and thick<4200)
	g.combat.loot=[{"pos":g.player,"coins":5,"materials":{"甲壳":1}}]
	g.inventory={}; g.coins=0
	for i in range(42): g.inventory["满包%d" % i]=1
	g.attack_time=0; g.combat.tick(0,g)
	assert(g.coins==5 and g.combat.loot[0].materials.has("甲壳"),"full bag still picks up coins")
	var data: Dictionary=g.combat.snapshot(); g.combat.restore(data)
	assert(g.combat.loot[0].coins==0 and g.combat.loot[0].materials["甲壳"]==1)
	g.inventory={"馒头":2,"回血药水":2}; g.energy=20; g.hp=10; g.potion_cooldown=0
	assert(g.cooking.eat("馒头",g)); g.tick_eating(0.8)
	assert(g.cooking.eat("馒头",g)); g.tick_eating(0.8); assert(g.food_cooldown==0)
	assert(g.use_potion() and g.potion_cooldown==30)
	print("PASS v17: recipes, one-use books, cancel/full-bag atomicity, worker checks, upgrade, weapon timing, buffered input, continuous swing, crit, probabilistic drops, loot save, cooldowns")
	g.queue_free(); await process_frame; quit()
