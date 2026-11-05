extends SceneTree
func _initialize() -> void: call_deferred("run")
func close_dialog(g: Node) -> void:
	while g.dialogue_panel.visible: g.next_dialog()
func run() -> void:
	var g=load("res://main.tscn").instantiate()
	root.add_child(g)
	await process_frame
	close_dialog(g)
	g.flags={"field_tutorial":true}
	g.step=11
	g.time_minutes=600
	g.scene_id="village"
	g.npc_life.live.clear()
	g.setup_scene()
	assert(g.npc_life.PEOPLE.size()==13)
	assert(g.actors.any(func(a): return a.id=="innkeeper"))
	assert(g.actors.any(func(a): return a.id=="leather"))
	assert(g.npc_life.working("smith",500))
	assert(not g.npc_life.working("smith",1200))
	assert(not g.npc_life.working("doctor",1200))
	assert(not g.npc_life.working("merchant",1200))
	assert(g.npc_life.working("guard_night",60))
	assert(not g.npc_life.working("guard_night",600))
	# A real route is computed around building footprints, not through them.
	var route: Array=g.npc_life.path(g,Vector2(1100,1020),Vector2(650,1030))
	assert(not route.is_empty())
	for p in route: assert(not g.blocked(p))
	var merchant: Dictionary=g.npc_life.live.merchant
	merchant.pos=Vector2(1100,1020)
	merchant.goal=Vector2(-999,-999)
	g.time_minutes=841
	var original: Vector2=merchant.pos
	g.npc_life.tick(.5,g)
	assert(merchant.pos.distance_to(original)>0 and merchant.pos.distance_to(original)<=41)
	# Daily affinity cannot be farmed by repeating a button.
	g.hearts={"elder":70,"scout":50,"merchant":55}
	var schedules: Dictionary={}
	for id in g.npc_life.PEOPLE:
		var d: Dictionary=g.npc_life.PEOPLE[id]
		var key: String=str(d.start)+":"+str(d.end)
		assert(not schedules.has(key) or id=="captain","doctor and captain may share the confirmed 06—18 shift")
		schedules[key]=true
	for repeat in range(2):
		g.story_events.routine_menu("elder",g)
		close_dialog(g)
		for child in g.modal_body.find_children("*","Button",true,false):
			if child is Button and child.text=="聊聊近况": child.pressed.emit(); break
		close_dialog(g)
	assert(g.hearts.elder==71.5,"only one daily affinity reward")
	g.story_events.activate(g,"roof")
	g.story_events.activate(g,"ledger")
	assert(g.flags.active_side=="roof")
	assert(g.story_events.side_talk("smith",g))
	close_dialog(g)
	assert(g.flags.side_stage==1)
	assert(g.story_events.side_talk("elder",g))
	close_dialog(g)
	assert(g.flags.side_done_roof and g.flags.active_side=="")
	g.story_events.activate(g,"scout")
	g.story_events.interact("route_mark",g)
	close_dialog(g)
	g.story_events.side_talk("medic",g)
	close_dialog(g)
	g.story_events.side_talk("scout",g)
	close_dialog(g)
	assert(g.flags.han_sword_confession)
	g.story_events.activate(g,"ledger")
	g.story_events.side_talk("innkeeper",g)
	close_dialog(g)
	g.story_events.side_talk("merchant",g)
	close_dialog(g)
	assert(g.flags.side_done_ledger)
	# Search, evidence, report, family verification, supplies, cave mouth, report.
	g.story_events.interact("captain",g)
	close_dialog(g)
	assert(g.flags.search_stage==1)
	g.story_events.interact("search_flask",g)
	close_dialog(g)
	g.story_events.interact("search_remains",g)
	close_dialog(g)
	assert(g.flags.search_stage==2)
	assert(g.flags.get("roster_冯小川","")!="确认遇难")
	assert(g.flags["roster_秦二郎"]=="确认遇难")
	g.story_events.interact("captain",g)
	close_dialog(g)
	g.story_events.interact("leather",g)
	close_dialog(g)
	assert(g.flags.search_stage==4)
	g.inventory={}
	g.story_events.interact("captain",g)
	close_dialog(g)
	assert(g.flags.search_stage==4)
	g.inventory={"馒头":1,"回血药水":1}
	g.story_events.interact("captain",g)
	close_dialog(g)
	assert(g.flags.search_stage==5)
	g.scene_id="field"
	g.player=Vector2(750,805)
	g.npc_life.live.scout.scene="field"
	g.npc_life.live.scout.pos=Vector2(650,805)
	g.setup_scene()
	var before: Vector2=g.npc_life.live.scout.pos
	g.npc_life.tick(.2,g)
	assert(g.npc_life.live.scout.pos.distance_to(before)>0,"scout actually walks")
	g.story_events.interact("cave_entry",g)
	close_dialog(g)
	g.story_events.interact("captain",g)
	close_dialog(g)
	assert(g.flags.search_stage==7)
	g.story_events.show_journal(g)
	assert(g.flags.journal.size()>8)
	g.modal.hide()
	g.save_game()
	g.flags={}
	g.load_game()
	assert(g.flags.side_done_roof and g.flags.search_stage==7)
	g.scene_id="home_elder"
	g.setup_scene()
	g.npc_life.show_people(g)
	await process_frame
	print("PASS: 13 schedules, day/night shifts, collision-aware walking, three hidden stories, one-side limit, scout movement, search evidence, family report, cave-mouth reconnaissance, journal/save")
	quit()
