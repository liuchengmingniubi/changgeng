extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game=load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	while game.dialogue_panel.visible: game.next_dialog()
	assert(game.npc_texture!=null)
	assert(game.npc_regions.size()==8)
	assert(game.sound_bank.size()==7)
	game.flags={}
	game.inventory={}
	game.show_chest()
	assert(game.flags.storage["锄头"]==1)
	assert(game.flags.storage["父母遗书"]==1)
	game.transfer_item("锄头","chest")
	assert(game.inventory["锄头"]==1)
	assert(not game.flags.storage.has("锄头"))
	game.transfer_item("锄头","bag")
	assert(not game.inventory.has("锄头"))
	assert(game.flags.storage["锄头"]==1)
	game.show_chest()
	assert(game.flags.storage["锄头"]==1,"opening must not duplicate")
	game.inventory={"基础草药":8,"回血药水":2}
	game.transfer_item("基础草药","bag")
	assert(game.flags.storage["基础草药"]==8)
	game.transfer_item("基础草药","chest")
	assert(game.inventory["基础草药"]==8)
	game.swap_bag_order("基础草药","回血药水")
	assert(game.inventory.keys()[0]=="基础草药")
	assert(game.inventory["基础草药"]==8 and game.inventory["回血药水"]==2)
	game.save_game()
	game.inventory={}
	game.load_game()
	assert(game.inventory["基础草药"]==8)
	assert(game.flags.storage["父母遗书"]==1)
	print("PASS: NPC atlas, five audio samples, tool transfer, no duplicates, stack roundtrip, bag reorder, save/load")
	for child in root.get_children(): child.queue_free()
	await process_frame
	quit()
