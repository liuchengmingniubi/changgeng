extends SceneTree
func _initialize() -> void: call_deferred("run")
func close_dialog(g: Node) -> void:
	while g.dialogue_panel.visible: g.next_dialog()
func hold(g: Node,item: String) -> void:
	g.inventory={item:6}; g.quickbar=[item,"","","","",""]; g.quickbar_index=0
	g.flags.quickbar=g.quickbar.duplicate(); g.flags.quickbar_initialized=true; g.flags.bag_stacks=[]
func run() -> void:
	var g=load("res://main.tscn").instantiate(); root.add_child(g)
	await process_frame; g.set_process(false); close_dialog(g)
	g.flags={"social_revision":1}; g.hearts={}; g.step=0; g.scene_id="village"; g.player=Vector2(1000,800)
	var r=g.relationships
	assert(r.DATA.size()==13)
	for id in g.npc_life.PEOPLE:
		var p: Dictionary=r.DATA[id]
		assert(p.daily.size()==15 and p.topics.size()==5 and p.quiz.size()==3 and p.likes.size()>0)
		var unique: Dictionary={}
		g.npc_life.live[id]={"scene":"village","pos":g.player+Vector2(20,0),"status":"休息"}
		g.hearts[id]=0.0
		for day in range(1,16):
			g.farming.day=day; r.daily(id,g)
			assert(g.dialog_lines[-1][1]==p.daily[day-1]); unique[g.dialog_lines[-1][1]]=true
			close_dialog(g)
			var affinity: float=g.hearts[id]; var seq: int=g.flags["daily_sequence_"+id]
			r.daily(id,g); close_dialog(g)
			assert(g.hearts[id]==affinity and g.flags["daily_sequence_"+id]==seq)
		assert(unique.size()==15 and g.hearts[id]==22.5)
		r.show_topics(id,g); await process_frame; await process_frame
		assert(g.modal.size.x<=1280 and g.modal.size.y<=736)
	# Ordinary and preferred gifts, single item and day+3 eligibility per person.
	g.modal.hide(); close_dialog(g); g.farming.day=20; g.hearts.elder=0
	hold(g,"甲壳"); g.gifting.show_confirm("elder","甲壳",g); var token: int=g.gifting.pending.token
	assert(not g.gifting.accept(g,token,2) and g.inventory["甲壳"]==6)
	assert(g.gifting.accept(g,token,1)); close_dialog(g); assert(g.hearts.elder==1.5)
	var before: Dictionary=g.inventory.duplicate(); g.gifting.show_confirm("elder","甲壳",g)
	assert(g.gifting.pending.is_empty() and g.inventory==before)
	g.farming.day=22; assert(r.gift_wait("elder",g)==1)
	g.farming.day=23; assert(r.gift_wait("elder",g)==0)
	hold(g,"馒头"); g.gifting.show_confirm("elder","馒头",g); token=int(g.gifting.pending.token)
	assert(g.gifting.accept(g,token,1)); close_dialog(g); assert(g.hearts.elder==4.5)
	assert(r.gift_wait("smith",g)==0)
	# A correct response rewards once, a wrong response still consumes the interval.
	g.flags.chat_days_elder=2; g.flags.quiz_day_elder=-999; g.farming.day=24
	assert(r.quiz_due("elder",g)); r.show_quiz("elder",g); token=int(r.pending.token)
	var prior: float=g.hearts.elder
	assert(r.answer_quiz(g,token,0)); close_dialog(g); assert(g.hearts.elder==prior+1.5)
	assert(not r.answer_quiz(g,token,0) and not r.quiz_due("elder",g))
	g.farming.day=27; r.show_quiz("elder",g); token=int(r.pending.token); prior=float(g.hearts.elder)
	assert(r.answer_quiz(g,token,1)); close_dialog(g); assert(g.hearts.elder==prior and not r.quiz_due("elder",g))
	# New story events produce new contextual questions without consuming daily reward.
	g.step=11; g.flags.search_stage=1; g.flags.search_flask=false
	var first: String=r.context_key(g); r.discuss("elder",g); close_dialog(g); assert(g.flags.context_seen_elder==first)
	g.flags.search_flask=true; assert(r.context_key(g)!=first and r.context_label(g).contains("水壶"))
	r.daily("elder",g); assert(g.dialog_lines[0][1].contains("水壶")); close_dialog(g)
	g.modal.hide(); g.flags.search_stage=2; r.show_menu("elder",g)
	assert(g.dialogue_panel.visible and g.dialog_lines[0][1].contains("两处线索"))
	close_dialog(g); assert(g.modal.visible and g.flags.context_seen_elder==r.context_key(g))
	g.farming.day=30; r.show_quiz("elder",g); token=int(r.pending.token); prior=float(g.hearts.elder)
	g.modal.hide(); assert(not r.answer_quiz(g,token,0) and g.hearts.elder==prior)
	r.show_quiz("elder",g); token=int(r.pending.token); g.save_game(); g.load_game(); close_dialog(g)
	assert(not r.answer_quiz(g,token,0))
	g.modal.hide(); g.step=0; g.hearts={"elder":69.5,"scout":49.5,"merchant":54.5}
	assert(not r.hidden_ready("roof",g) and not r.hidden_ready("scout",g) and not r.hidden_ready("ledger",g))
	r.change("elder",0.5,g); r.change("scout",0.5,g); r.change("merchant",0.5,g)
	assert(r.hidden_ready("roof",g) and r.hidden_ready("scout",g) and r.hidden_ready("ledger",g),"no main-story gating")
	g.story_events.activate(g,"roof"); g.story_events.activate(g,"scout"); assert(g.flags.active_side=="roof")
	g.story_events.finish(g,"roof","elder"); var done: float=g.hearts.elder
	g.story_events.finish(g,"roof","elder"); assert(g.hearts.elder==done)
	g.hearts.elder=99.75; assert(r.change("elder",5,g)==0.25 and g.hearts.elder==100)
	r.change("elder",1,g); assert(g.hearts.elder==100)
	g.hearts.merchant=150; g.flags.social_revision=0; g.flags.gifts_merchant=1; g.flags.last_gift_days={}; r.normalize(g)
	assert(g.hearts.merchant==100 and r.gift_wait("merchant",g)==3)
	g.hearts.scout=3.5; assert(g.save_game()); g.hearts.scout=0; g.load_game(); close_dialog(g)
	assert(g.hearts.scout==3.5 and g.flags.last_gift_days.has("merchant"))
	print("PASS v22: 195 distinct daily lines/65 topics/39 quizzes, all 13 NPCs, daily gain/once-per-day, preferred gifts, strict one-item three-day rule, quiz rewards/retries, plot context, no-main-gate thresholds, one-side limit, 100 cap and legacy/decimal save migration")
	g.queue_free(); await process_frame; quit()
