extends SceneTree
func _initialize() -> void: call_deferred("run")
func close_dialog(g) -> void:
	while g.dialogue_panel.visible: g.next_dialog()
func run() -> void:
	var g=load("res://main.tscn").instantiate()
	root.add_child(g)
	await process_frame
	close_dialog(g)
	g.step=11
	g.scene_id="field"
	g.setup_scene()
	close_dialog(g)
	g.combat.reset_enemies()
	g.combat.loot.clear()
	g.player=Vector2(600,400)
	g.obstacles.clear()
	var e: Dictionary=g.combat.enemies[0]
	e.pos=Vector2(655,400)
	e.home=e.pos
	e.state="recover"
	e.timer=100
	g.facing=Vector2.RIGHT
	g.combo=1
	g.attack_duration=0.5
	g.swing_weapon=g.CraftCatalog.WEAPONS["军用旧铁剑"].duplicate()
	g.swing_weapon.crit=0
	g.swing_power=18
	g.attack_time=0.25
	g.combat.begin_swing()
	g.combat.tick(.01,g)
	assert(e.hp==37,"single correct damage")
	g.combat.tick(.01,g)
	assert(e.hp==37,"one hit per swing")
	g.combat.begin_swing()
	g.facing=Vector2.LEFT
	g.combat.tick(.01,g)
	assert(e.hp==37,"backwards swing must miss")
	g.facing=Vector2.RIGHT
	g.obstacles.append(Rect2(620,380,15,40))
	g.combat.tick(.01,g)
	assert(e.hp==37,"obstacles must block sword")
	g.obstacles.clear()
	g.combat.begin_swing()
	g.combat.tick(.01,g)
	assert(e.hp==19)
	g.combat.begin_swing()
	g.combo=3
	g.combat.tick(.01,g)
	assert(e.hp<=0)
	assert(g.xp==25)
	assert(g.combat.loot.size()==1)
	g.player=e.pos
	g.combat.tick(.01,g)
	assert(g.inventory.get("甲壳",0) in [0,1] and g.coins>=3 and g.coins<=5)
	var coin_total: int=g.coins
	var shell_total: int=int(g.inventory.get("甲壳",0))
	g.combat.tick(.01,g)
	assert(int(g.inventory.get("甲壳",0))==shell_total and g.coins==coin_total,"no duplicate loot")
	g.hp=100
	g.invulnerability=0
	g.take_damage(12,g.player+Vector2(20,0))
	g.take_damage(12,g.player+Vector2(20,0))
	assert(g.hp==88,"damage protection")
	g.inventory["回血药水"]=2
	g.potion_cooldown=0
	assert(g.use_potion())
	assert(g.hp==100 and g.inventory["回血药水"]==1)
	g.hp=50
	assert(not g.use_potion(),"cooldown enforced")
	g.potion_cooldown=0
	g.hp=100
	assert(not g.use_potion(),"full hp must not consume")
	g.gain_experience(55)
	assert(g.level==2 and g.max_hp==110)
	g.coins=100
	g.hp=1
	g.invulnerability=0
	g.take_damage(12,g.player+Vector2(20,0))
	assert(g.scene_id=="clinic" and g.hp==55 and g.coins==80)
	close_dialog(g)
	g.save_game()
	g.level=1
	g.load_game()
	assert(g.level==2 and g.coins==80)
	assert(g.combat.enemies[0].hp<=0,"dead enemies persist")
	g.level=19
	g.gain_experience(10000)
	assert(g.level==20 and g.xp==0,"first chapter level cap")
	print("PASS: directional hits, once per swing, wall blocking, kill XP, loot once, invulnerability, potion rules, level-up, death, saved enemies, level cap")
	for child in root.get_children(): child.queue_free()
	await process_frame
	quit()
