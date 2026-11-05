extends SceneTree
var game
func finish_dialog() -> void:
	while game.dialogue_panel.visible:
		game.next_dialog()
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	finish_dialog()
	game.flags={}
	game.inventory={}
	game.hearts={}
	game.step=0
	game.flags["chest_taken"]=true
	for item in ["锄头","斧子","镐子"]: game.inventory[item]=1
	game.read_letter()
	finish_dialog()
	assert(game.step==1,"home progression")
	game.interact("smith")
	finish_dialog()
	game.interact("doctor")
	finish_dialog()
	game.interact("elder")
	finish_dialog()
	assert(game.step==5,"books and teaching herbs reconcile")
	game.scene_id="village"
	game.setup_scene()
	game.inventory_ui.show_crafting(game)
	for child in game.modal_body.find_children("*","Button",true,false):
		if child is Button and child.text=="合成一瓶回血药水":
			child.pressed.emit()
	assert(game.step==6,"craft progression")
	assert(game.inventory["基础草药"]==1,"craft cost")
	assert(game.inventory["回血药水"]==1,"craft reward")
	game.modal.hide()
	game.interact("elder")
	finish_dialog()
	assert(game.step==7)
	game.scene_id="wall"
	game.setup_scene()
	game.interact("captain")
	finish_dialog()
	assert(game.step==8)
	game.modal.hide()
	assert(game.equipment.wear("破旧铁甲",game))
	game.frontier.begin_training(game)
	await create_timer(.65).timeout
	finish_dialog()
	game.swing_power=999
	for enemy in game.combat.enemies:
		game.combat.hit_enemy(enemy,game)
		finish_dialog()
	assert(game.flags.get("training_done",false))
	game.scene_id="wall"
	game.recruitment.returned(game)
	game.scene_id="barracks"
	game.setup_scene()
	game.interact("soldier")
	finish_dialog()
	game.interact("medic")
	finish_dialog()
	game.scene_id="wall"
	game.setup_scene()
	game.interact("roster")
	finish_dialog()
	for b in game.modal_body.find_children("*","Button",true,false):
		if b.text=="记下名字，收起名单": b.pressed.emit(); break
	finish_dialog()
	assert(game.step==10)
	game.interact("captain")
	finish_dialog()
	assert(game.step==11)
	assert(game.inventory.has("军籍腰牌"))
	game.save_game()
	game.step=0
	game.load_game()
	assert(game.step==11,"save roundtrip")
	var before=game.hearts["soldier"]
	game.interact("soldier")
	finish_dialog()
	assert(game.hearts["soldier"]==before,"repeat talk must not farm relationship")
	print("PASS: complete opening, out-of-order exploration, crafting, relationships, save/load")
	for child in root.get_children(): child.queue_free()
	await process_frame
	quit()
