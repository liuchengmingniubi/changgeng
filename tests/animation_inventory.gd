extends SceneTree
func _initialize() -> void: call_deferred("run")
func find_grid(node: Node) -> GridContainer:
	if node is GridContainer: return node
	for child in node.get_children():
		var result=find_grid(child)
		if result: return result
	return null
func run() -> void:
	var game=load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	while game.dialogue_panel.visible: game.next_dialog()
	game.inventory={"锄头":1,"基础草药":99,"《草药大全》":1}
	for i in range(20): game.inventory["测试材料"+str(i)]=i+1
	game.show_inventory()
	var grid=find_grid(game.modal)
	assert(grid and grid.get_child_count()==18)
	grid.get_child(0).pressed.emit()
	assert(grid.get_child(0).selected)
	game.inventory_page=1
	game.show_inventory()
	grid=find_grid(game.modal)
	assert(grid.get_child_count()==18)
	assert(grid.get_child(9).item_name!="")
	assert(grid.get_child(10).item_name=="")
	game.modal.hide()
	game.attack_time=game.ATTACK_DURATION
	for i in range(60):
		game._process(0.0167)
	assert(game.attack_time==0.0)
	assert(game.walk_blend==0.0)
	game.actual_walk=true
	game._process(0.05)
	assert(game.walk_blend>0.0 and game.walk_blend<=1.0)
	game.actual_walk=false
	for i in range(15): game._process(0.02)
	assert(game.walk_blend==0.0)
	print("PASS: 18 slots, paging, stack count, selection, attack recovery, walk start/stop")
	for child in root.get_children(): child.queue_free()
	await process_frame
	quit()
