extends SceneTree
func _initialize() -> void: call_deferred("run")
func close_dialog(g: Node) -> void:
	while g.dialogue_panel.visible: g.next_dialog()
func run() -> void:
	var g=load("res://main.tscn").instantiate(); root.add_child(g)
	await process_frame; g.set_process(false); close_dialog(g)
	g.flags={}; g.inventory={}; g.equipment.worn.clear(); g.hearts={}; g.step=7
	g.scene_id="wall"; g.setup_scene(); g.interact("captain"); close_dialog(g)
	assert(g.step==8 and g.flags.recruit_flow==1 and g.modal.visible)
	await process_frame; await process_frame
	assert(g.modal.size.y<=700,"gear guide fits viewport")
	assert(g.inventory["破旧铁甲"]==1 and g.inventory["军用旧铁剑"]==1)
	g.frontier.begin_training(g)
	assert(not g.flags.get("training_active",false),"armor must be worn before supervised training")
	g.modal.hide(); assert(g.equipment.wear("破旧铁甲",g)); g.wield("军用旧铁剑")
	assert(g.recruitment.ready(g))
	g.interact("scout"); close_dialog(g); await create_timer(.65).timeout; close_dialog(g)
	assert(g.scene_id=="field" and g.combat.enemies.size()==3)
	for e in g.combat.enemies: assert(e.kind=="甲壳虫" and e.hp==55 and e.max_hp==55)
	var positions: Array=[]
	for e in g.combat.enemies: positions.append(e.home)
	g.frontier.begin_training(g)
	assert(g.combat.enemies[0].home==positions[0],"repeat conversation cannot reset training")
	g.swing_power=999
	g.combat.hit_enemy(g.combat.enemies[0],g)
	assert(g.flags.training_kills==1 and g.dialogue_panel.visible)
	close_dialog(g)
	assert(g.recruitment.objective(g).contains("侧面"))
	g.save_game(); g.load_game(); close_dialog(g)
	assert(g.flags.training_kills==1 and g.combat.enemies[0].hp==0)
	assert(g.combat.enemies[2].max_hp==55 and g.combat.enemies[2].home==positions[2])
	g.swing_power=999; g.combat.hit_enemy(g.combat.enemies[1],g); close_dialog(g)
	assert(g.recruitment.objective(g).contains("反击"))
	g.combat.hit_enemy(g.combat.enemies[2],g)
	assert(g.flags.training_done and g.flags.training_kills==3)
	g.save_game(); g.load_game(); close_dialog(g)
	assert(g.step==9 and g.flags.escort_return,"saving during final dialogue cannot strand the quest")
	g.interact("return_gate"); await create_timer(.65).timeout; close_dialog(g)
	assert(g.flags.training_returned and g.scene_id=="wall")
	g.scene_id="barracks"; g.setup_scene()
	g.interact("soldier"); close_dialog(g)
	g.interact("medic"); close_dialog(g)
	assert(g.step==9,"new flow includes physical roster interaction")
	g.scene_id="wall"; g.setup_scene(); g.interact("roster"); close_dialog(g)
	assert(g.flags.roster_intro_seen and g.modal.visible and g.npc_life.LOST.size()==14)
	assert(not g.flags.has("roster_秦二郎"),"introduction must not reveal future fates")
	await process_frame; await process_frame
	assert(g.modal.size.y<=736 and g.modal.size.x<=1280)
	var closed:=false
	for b in g.modal_body.find_children("*","Button",true,false):
		if b.text=="记下名字，收起名单": b.pressed.emit(); closed=true; break
	assert(closed); close_dialog(g); assert(g.step==10)
	g.interact("captain"); close_dialog(g)
	assert(g.step==11 and g.inventory["军籍腰牌"]==1)
	g.save_game(); g.load_game(); close_dialog(g)
	assert(g.step==11 and g.flags.roster_intro_seen)
	g.craft_ui.show_menu(g,"smith")
	var locked:=false
	for b in g.modal_body.find_children("*","Button",true,false):
		if b.text=="强化 · 暂未开放": locked=b.disabled
	assert(locked,"enhancement remains unavailable")
	# Existing saved journeys keep the previous recruitment completion rules.
	g.step=9; g.flags={"soldier_talk":true,"medic_talk":true}; g.reconcile(); assert(g.step==10)
	g.step=11; g.reconcile(); assert(g.step==11)
	print("PASS v18: gear guidance and gate, three equal normal beetles, three lesson dialogues, no training reset, mid-training/final-dialogue saves, return route, companions, roster/future-fate safety, roster layout, 1.2 handoff and legacy saves")
	g.queue_free(); await process_frame; quit()
