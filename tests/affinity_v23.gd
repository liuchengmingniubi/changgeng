extends SceneTree
func _initialize() -> void: call_deferred("run")
func close_dialog(g: Node) -> void:
	while g.dialogue_panel.visible: g.next_dialog()
func run() -> void:
	var g=load("res://main.tscn").instantiate(); root.add_child(g)
	await process_frame; g.set_process(false); close_dialog(g)
	var r=g.relationships
	assert(g.hearts==r.INITIAL and g.hearts.elder==40 and g.hearts.size()==13)
	var used: Dictionary={}
	for id in r.INITIAL: assert(not used.has(g.hearts[id])); used[g.hearts[id]]=true
	var original: Dictionary=g.hearts.duplicate(); g.bond("elder"); g.bond("elder"); g.bond("scout"); assert(g.hearts==original,"first meeting does not add to configured starting values")
	assert(r.DAILY_GAIN==1.5 and r.QUIZ_GAIN==1.5 and r.SIDE_GAIN==4)
	assert(r.gift_gain("elder","甲壳")==1.5 and r.gift_gain("elder","馒头")==3)
	assert(r.HIDDEN.roof.threshold==70 and r.HIDDEN.scout.threshold==50 and r.HIDDEN.ledger.threshold==55 and r.HIDDEN.letter.threshold==65)
	g.step=0
	for key in r.HIDDEN:
		var rule: Dictionary=r.HIDDEN[key]; g.hearts[rule.npc]=float(rule.threshold)-0.5
		assert(not r.hidden_ready(key,g)); r.change(rule.npc,0.5,g); assert(r.hidden_ready(key,g))
	g.story_events.activate(g,"letter"); assert(g.flags.get("active_side","")=="","threshold data does not falsely enable unfinished side quest")
	g.flags={}; g.hearts={"elder":13.5}; g.step=11; g.flags.search_stage=7; r.normalize(g)
	assert(g.hearts.elder==13.5 and g.hearts.doctor==12 and g.hearts.scout==5,"existing values stay; only missing NPCs receive defaults")
	var previous: float=g.hearts.scout
	assert(r.reward_once("main_training",{"scout":3.0},g).is_empty() and g.hearts.scout==previous,"old completed tasks do not grant again")
	assert(r.reward_once("cave_report",{"scout":4.0},g).is_empty())
	# Completing the three-monster tutorial commits the reward before the final dialogue.
	g.flags={}; g.step=8; g.hearts={"scout":5.0}; g.frontier.begin_training(g) # Unprepared: does not grant anything.
	assert(g.hearts.scout==5)
	g.modal.hide(); g.flags.training_active=true; g.flags.training_kills=2
	g.frontier.on_kill(g); assert(g.flags.training_done and g.hearts.scout==8 and g.flags.affinity_rewards.main_training)
	g.save_game(); g.load_game(); close_dialog(g); assert(g.hearts.scout==8)
	assert(r.reward_once("main_training",{"scout":3.0},g).is_empty())
	g.step=11; g.flags.search_stage=2; g.hearts.captain=3
	g.story_events.interact("captain",g); close_dialog(g)
	assert(g.flags.search_stage==3 and g.hearts.scout==11 and g.hearts.captain==6)
	g.flags.search_stage=6; g.story_events.interact("captain",g); close_dialog(g)
	assert(g.flags.search_stage==7 and g.hearts.scout==15 and g.hearts.captain==10)
	g.hearts.scout=99; var gains: Dictionary=r.reward_once("test_cap",{"scout":4.0},g)
	assert(g.hearts.scout==100 and gains.scout==1)
	g.save_game(); g.hearts.scout=0; g.load_game(); close_dialog(g)
	assert(g.hearts.scout==100 and r.reward_once("test_cap",{"scout":4.0},g).is_empty())
	print("PASS v23: 13 distinct initial affinities, elder 40, no first-meet bonus, moderate-minus gains, 50/70/55/65 gates, old-value preservation, missing-NPC defaults, task hand-in rewards, mid-dialogue save safety, no duplicate payouts and cap")
	g.queue_free(); await process_frame; quit()
