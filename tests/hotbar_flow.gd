extends SceneTree
func _initialize() -> void: call_deferred("run")
func find_grid(node: Node) -> Node:
	if str(node.name)=="BagGrid": return node
	for child in node.get_children():
		var found=find_grid(child)
		if found: return found
	return null
func run() -> void:
	var g=load("res://main.tscn").instantiate()
	root.add_child(g)
	await process_frame
	while g.dialogue_panel.visible: g.next_dialog()
	g.flags={}
	g.inventory={}
	for i in range(42): g.inventory["物品"+str(i)]=i+1
	g.ensure_quickbar()
	var fixed: Array=g.quickbar.duplicate()
	for page in range(3):
		g.inventory_ui.bag_page=page
		g.inventory_ui.show_bag(g)
		var grid=find_grid(g.modal)
		assert(grid.get_child_count()==18)
		for i in range(6): assert(grid.get_child(i).item_name==fixed[i] and grid.get_child(i).golden)
		assert(grid.get_child(6).item_name=="物品"+str(6+page*12))
	g.inventory_ui.bag_filter="药剂"
	g.inventory_ui.show_bag(g)
	assert(find_grid(g.modal).get_child(0).item_name==fixed[0],"filter must not hide fixed bar")
	assert(find_grid(g.modal).get_child(6).item_name=="")
	g.assign_quickbar(0,"物品9")
	assert(g.quickbar[0]=="物品9")
	g.assign_quickbar(1,"物品9")
	assert(g.quickbar[1]=="物品9" and g.quickbar[0]=="物品1")
	g.modal.hide()
	g.quickbar_index=0
	var event:=InputEventMouseButton.new()
	event.pressed=true
	event.button_index=MOUSE_BUTTON_WHEEL_UP
	g._input(event)
	assert(g.quickbar_index==5,"wheel wraps backwards")
	event.button_index=MOUSE_BUTTON_WHEEL_DOWN
	g._input(event)
	assert(g.quickbar_index==0)
	g.inventory_ui.show_bag(g)
	g._input(event)
	assert(g.quickbar_index==0,"wheel locked while modal open")
	g.modal.hide()
	g.save_game()
	g.quickbar=["","","","","",""]
	g.quickbar_index=4
	g.load_game()
	assert(g.quickbar_index==0 and g.quickbar[1]=="物品9")
	g.inventory["多出物品"]=8
	g.migrate_bag_capacity()
	assert(g.inventory.size()==42 and g.flags.storage["多出物品"]==8)
	g.refresh_quickbar()
	assert(g.quickbar_slots.size()==6)
	assert(g.quickbar_slots[1].item_name=="物品9")
	print("PASS: fixed gold row, lower 12 paging, category persistence, assignment swap, vertical sync, wheel wrap/modal lock, save and capacity migration")
	for child in root.get_children(): child.queue_free()
	await process_frame
	quit()
