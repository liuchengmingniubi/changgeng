extends SceneTree
func _initialize() -> void: call_deferred("run")
func walk(node: Node,needle: String) -> Node:
	if str(node.name)==needle: return node
	for c in node.get_children():
		var found=walk(c,needle)
		if found: return found
	return null
func run() -> void:
	var g=load("res://main.tscn").instantiate()
	root.add_child(g)
	await process_frame
	while g.dialogue_panel.visible: g.next_dialog()
	g.inventory={"馒头":2,"回血药水":3,"甲壳":4,"斧子":1}
	g.show_inventory()
	assert(walk(g.modal,"BagGrid").get_child_count()==18)
	assert(g.inventory_ui.category("馒头")=="食物")
	assert(g.inventory_ui.category("回血药水")=="药剂")
	assert(g.inventory_ui.category("基础草药")=="材料")
	assert(g.inventory_ui.category("斧子")=="装备")
	assert(g.inventory_ui.CATEGORIES==["全部","装备","材料","食物","药剂"])
	g.inventory_ui.bag_page=2
	g.inventory_ui.show_bag(g)
	assert(walk(g.modal,"BagGrid").get_child_count()==18)
	assert(walk(g.modal,"BagGrid").get_child(6).item_name=="")
	g.inventory_ui.bag_filter="食物"
	g.inventory_ui.bag_page=0
	g.inventory_ui.show_bag(g)
	assert(walk(g.modal,"BagGrid").get_child(0).item_name=="馒头")
	assert(walk(g.modal,"BagGrid").get_child(6).item_name=="")
	g.inventory_ui.bag_filter="全部"
	g.flags["starter_equipment_granted"]=true
	g.flags["chest_initialized"]=true
	g.flags["chest_taken"]=true
	g.flags["storage"]={}
	for i in range(300): g.flags.storage["材料"+str(i)]=i+1
	g.show_chest()
	assert(walk(g.modal,"ChestGrid").get_child_count()==30)
	g.inventory_ui.chest_page=9
	g.inventory_ui.show_chest(g)
	assert(walk(g.modal,"ChestGrid").get_child(29).item_name=="材料299")
	g.transfer_item("甲壳","bag")
	assert(g.inventory["甲壳"]==4,"full chest must reject transfer without loss")
	g.transfer_item("材料299","chest")
	assert(g.inventory["材料299"]==300)
	assert(not g.flags.storage.has("材料299"))
	g.inventory={}
	for i in range(42): g.inventory["随身"+str(i)]=1
	g.transfer_item("材料0","chest")
	assert(g.flags.storage["材料0"]==1,"full bag must reject without loss")
	g.flags["enlistment_gear"]=true
	g.save_game()
	g.inventory.clear()
	g.load_game()
	assert(g.inventory.size()==42)
	assert(g.flags.storage.size()==299)
	print("PASS: jade bag 3x18, chest 10x30, five filters, last-page access, container limits, no lost stacks, save/load")
	for c in root.get_children(): c.queue_free()
	await process_frame
	quit()
