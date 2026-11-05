extends SceneTree
func _initialize() -> void: call_deferred("run")
func close_dialog(g: Node) -> void:
	while g.dialogue_panel.visible: g.next_dialog()
func grid(g: Node) -> Node:
	return g.modal.find_child("BagGrid",true,false)
func run() -> void:
	var g=load("res://main.tscn").instantiate(); root.add_child(g)
	await process_frame; g.set_process(false); close_dialog(g)
	g.flags={"quickbar_initialized":true,"quickbar":["回血药水","军用旧铁剑","","","",""]}; g.quickbar=g.flags.quickbar.duplicate()
	g.inventory={"回血药水":10,"军用旧铁剑":1,"甲壳":20,"铁锭":4,"破旧铁甲":1}; g.equipment.worn.clear()
	g.show_inventory(); await process_frame; await process_frame; await process_frame
	assert(g.modal.size.x<=1280 and g.modal.size.y<=736,"bag fits viewport")
	g.attack_time=0; g.start_attack(); assert(g.attack_time==0,"modal blocks attack")
	g.attack_time=0.25; g.potion_cooldown=12; g._process(0.5); assert(g.attack_time==0.25 and g.potion_cooldown==12,"combat timers pause in UI")
	g.attack_time=0
	g.attack_buffer=0.2; g._process(0); assert(g.attack_buffer==0,"menu clears buffered attacks")
	var cells: Array=g.bag_stacks.sync(g)
	assert(cells[0].key=="甲壳")
	assert(g.bag_stacks.split(g,0,-1,7)); assert(g.inventory["甲壳"]==20)
	cells=g.bag_stacks.sync(g)
	assert(cells[0].count==13 and cells[3].key=="甲壳" and cells[3].count==7)
	g.bag_stacks.move(g,3,10); cells=g.bag_stacks.sync(g); assert(cells[10].count==7 and cells[3].is_empty())
	assert(g.bag_stacks.split(g,-1,0,3)); assert(g.bag_stacks.hot_count("回血药水",g)==7)
	var total:=0
	for c in g.bag_stacks.sync(g):
		if c.get("key","")=="回血药水": total+=int(c.count)
	assert(total==3 and g.inventory["回血药水"]==10)
	g.inventory["回血药水"]=2
	assert(g.bag_stacks.hot_count("回血药水",g)==1,"consumption reconciles split views")
	var fixed: Array=g.quickbar.duplicate(); g.bag_stacks.sort_bag(g); assert(g.quickbar==fixed and g.bag_stacks.hot_count("回血药水",g)==2)
	g.bag_stacks.sync(g); g.show_inventory()
	for s in grid(g).get_children():
		if s.item_name=="破旧铁甲": s.context_requested.emit(); break
	assert(g.equipment.worn.get("护甲","")=="破旧铁甲","right-click wears armor")
	g.hp=10; g.potion_cooldown=0; g.inventory_ui.quick_use("回血药水"); assert(g.hp>10 and g.potion_cooldown==30)
	assert(g.inventory_ui.tooltip("军用旧铁剑",1,g).contains("暴击"))
	assert(g.inventory_ui.tooltip("甲壳盔",1,g).contains("[color=#"))
	assert(g.inventory_ui.tooltip("制作书·甲壳盔",1,g).contains("一次性"))
	assert(g.inventory_ui.category("制作书·甲锋剑")=="材料")
	g.flags.storage={"甲壳":10}; g.flags.chest_initialized=true; g.flags.starter_equipment_granted=true
	g.transfer_item("甲壳","chest",4); assert(g.inventory["甲壳"]==24 and g.flags.storage["甲壳"]==6)
	await process_frame; await process_frame; assert(g.modal.size.y<=736,"chest fits viewport")
	g.modal.hide(); g.scene_id="home"; g.setup_scene(); g.actors=[{"id":"smith","name":"郭成","pos":Vector2(650,500)},{"id":"chest","name":"箱子","pos":Vector2(665,500)}]; g.player=Vector2(650,500); g.interaction_target=""
	assert(g.nearest().id=="smith"); g.cycle_target(); assert(g.nearest().id=="chest")
	assert(g.interaction_prompt(g.nearest()).contains("打开")); g.player=Vector2(900,500); assert(g.nearest().is_empty())
	g.step=8; g.flags.held_weapon="军用旧铁剑"; g.flags.training_active=true; g.flags.training_kills=2; assert(g.task_tracker.main_text(g).contains("2 / 3"))
	g.step=11; g.flags.search_stage=1; g.flags.search_flask=true; assert(g.task_tracker.main_text(g).contains("1/2"))
	g.flags.active_side="scout"; g.flags.side_stage=1; assert(g.task_tracker.side_text(g).contains("孙怀济"))
	g.flags.active_side=""; g.flags.training_active=false; g.inventory={"甲壳":12}; g.flags.quickbar=["","","","","",""]; g.quickbar=g.flags.quickbar.duplicate(); g.flags.bag_stacks=[]
	g.bag_stacks.sync(g); assert(g.bag_stacks.split(g,0,-1,5)); g.bag_stacks.move(g,1,15)
	g.save_game(); g.flags.bag_stacks=[]; g.load_game(); close_dialog(g)
	assert(g.flags.bag_stacks[15].key=="甲壳" and g.flags.bag_stacks[15].count==5 and g.inventory["甲壳"]==12)
	g.modal.hide(); close_dialog(g); g.attack_time=0; g.attack_recovery=0; g.attack_release_required=true
	var press:=InputEventMouseButton.new(); press.button_index=MOUSE_BUTTON_LEFT; press.pressed=true; press.button_mask=MOUSE_BUTTON_MASK_LEFT; press.position=Vector2(800,650); press.global_position=press.position
	Input.parse_input_event(press); Input.flush_buffered_events()
	assert(Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT))
	g.start_attack(); assert(g.attack_time==0,"held click after closing UI cannot attack")
	press.pressed=false; press.button_mask=0; Input.parse_input_event(press); Input.flush_buffered_events(); g.start_attack(); assert(g.attack_time>0,"release permits a fresh attack")
	g.inventory={}; g.flags.bag_stacks=[]
	for i in range(40): g.inventory["守恒材料%d" % i]=20
	g.quickbar=["守恒材料0","守恒材料1","守恒材料2","守恒材料3","守恒材料4","守恒材料5"]; g.flags.quickbar=g.quickbar.duplicate()
	seed(719)
	for n in range(200):
		var before: Dictionary=g.inventory.duplicate()
		var slots: Array=g.bag_stacks.sync(g)
		match n%4:
			0:
				var at: int=randi_range(0,35)
				if not slots[at].is_empty(): g.bag_stacks.split(g,at,-1,1)
			1: g.bag_stacks.move(g,randi_range(0,35),randi_range(0,35))
			2: g.bag_stacks.sort_bag(g)
			3: g.assign_quickbar(randi_range(0,5),"守恒材料%d" % randi_range(0,39))
		assert(g.inventory==before,"layout operations conserve every inventory total")
		var sums: Dictionary={}
		for c in g.bag_stacks.sync(g):
			if not c.is_empty(): sums[c.key]=int(sums.get(c.key,0))+int(c.count)
		for key in g.quickbar:
			if key!="": sums[key]=int(sums.get(key,0))+g.bag_stacks.hot_count(key,g,false)
		assert(sums==g.inventory,"all units remain represented in visible stacks")
	print("PASS v19: menu attack blocking, buffered-input clearing, bag/chest layout, split/move/consume/sort conservation, fixed bar, right-click armor/potion, rich tooltips, partial transfer, target cycling, main/side tracker and stack-layout saves")
	g.queue_free(); await process_frame; quit()
