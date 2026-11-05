extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var args:=OS.get_cmdline_user_args(); var spot: String=args[0] if args.size()>0 else "center"
	var g=load("res://main.tscn").instantiate(); root.add_child(g); await process_frame; g.set_process(false)
	while g.dialogue_panel.visible: g.next_dialog()
	g.flags={"training_done":true}; g.step=11; g.scene_id="village"; g.time_minutes=600; g.player={"center":Vector2(1300,1210),"garden":Vector2(333,600),"mill":Vector2(330,1430)}.get(spot,Vector2(1300,1210))*g.world_layout.SCALE; g.npc_life.live.clear(); g.inventory={"军用旧铁剑":1,"回血药水":3,"初始种子":6,"基础草药":4,"锄头":1,"镐子":1}; g.setup_scene(); g.quickbar=["锄头","肥料","军用旧铁剑","","",""]; g.quickbar_index=0; g.update_camera(true)
	if spot=="garden":
		for i in range(12):
			var crop: Dictionary=g.farming.plots[i]; crop.tilled=true
			if i%3!=0: crop.seed="初始种子"; crop.growth=i%4; crop.watered=i%2==0; crop.fertilized=i in [2,5]
	g.update_hud()
	await process_frame; await process_frame
	var recorder=load("res://tests/previews/canvas_recorder.gd").new(); recorder.game=g; root.add_child(recorder)
	recorder.draw_set_transform(Vector2.ZERO,0,Vector2.ONE*g.world_layout.SCALE); g.world_layout.ground(recorder); recorder.draw_set_transform(Vector2.ZERO); g.farming.draw_world(recorder,g)
	var entries: Array=[{"kind":"hero","y":g.player.y}]
	for a in g.actors:
		if g.npc_life.PEOPLE.has(a.id): entries.append({"kind":"npc","y":a.pos.y,"actor":a})
	for i in range(g.HOUSE_DATA.size()): entries.append({"kind":"house","y":g.HOUSE_DATA[i][1].end.y*2*g.world_layout.SCALE,"index":i})
	for prop in g.world_layout.props: entries.append({"kind":"prop","y":prop.rect.end.y*g.world_layout.SCALE,"data":prop})
	for tree in g.world_layout.trees: entries.append({"kind":"tree","y":tree.y*g.world_layout.SCALE,"pos":tree})
	entries.sort_custom(func(a,b): return a.y<b.y)
	for entry in entries:
		match entry.kind:
			"hero": g.actor_visual.hero(recorder,g.player)
			"npc": g.actor_visual.npc(recorder,entry.actor.pos,entry.actor.id)
			"house":
				recorder.draw_set_transform(Vector2.ZERO,0,Vector2.ONE*g.world_layout.SCALE); g.world_layout.house(recorder,entry.index); recorder.draw_set_transform(Vector2.ZERO)
			"tree":
				recorder.draw_set_transform(Vector2.ZERO,0,Vector2.ONE*g.world_layout.SCALE); g.world_layout.tree(recorder,entry.pos); recorder.draw_set_transform(Vector2.ZERO)
			"prop":
				recorder.draw_set_transform(Vector2.ZERO,0,Vector2.ONE*g.world_layout.SCALE); g.world_layout.prop(recorder,entry.data); recorder.draw_set_transform(Vector2.ZERO)
	var output: Dictionary={"camera":[g.camera_offset.x,g.camera_offset.y],"commands":recorder.commands,"ui":[]}
	capture_ui(g.ui,output.ui)
	var f:=FileAccess.open("/tmp/v27-"+spot+"-commands.json",FileAccess.WRITE); f.store_string(JSON.stringify(output)); f.close()
	print("RENDER COMMANDS ",recorder.commands.size())
	g.queue_free(); recorder.queue_free(); await process_frame; quit()
func capture_ui(node: Node,list: Array) -> void:
	if node is CanvasItem and not node.is_visible_in_tree(): return
	if node is Control:
		var r: Rect2=node.get_global_rect(); var box: Array=[r.position.x,r.position.y,r.size.x,r.size.y]
		if node is PanelContainer:
			var style: StyleBox=node.get_theme_stylebox("panel")
			if style is StyleBoxFlat: list.append({"kind":"card","rect":box,"color":style.bg_color.to_html(),"border":style.border_color.to_html(),"radius":style.corner_radius_top_left})
		elif node is Label: list.append({"kind":"label","rect":box,"text":node.text,"size":node.get_theme_font_size("font_size"),"color":node.get_theme_color("font_color").to_html()})
		elif node is Button:
			list.append({"kind":"card","rect":box,"color":"d2ddc0ff","border":"b29a61ff","radius":8})
			if node.get_script()==load("res://item_slot.gd") and node.item_name!="": list.append({"kind":"icon","rect":[r.position.x+(r.size.x-54)/2,r.position.y+3,54,54],"index":load("res://item_art.gd").index_for(node.item_name),"quantity":node.quantity})
			elif node.text!="": list.append({"kind":"label","rect":box,"text":node.text,"size":14,"color":"365440ff"})
	for child in node.get_children(): capture_ui(child,list)
