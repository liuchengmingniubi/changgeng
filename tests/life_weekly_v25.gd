extends SceneTree
func _initialize() -> void: call_deferred("run")
func dialog(g: Node) -> void:
	while g.dialogue_panel.visible: g.next_dialog()
func run() -> void:
	var g=load("res://main.tscn").instantiate(); root.add_child(g); await process_frame; g.set_process(false); dialog(g)
	g.flags={}; g.farming.day=1; g.time_minutes=600; g.life.initialize(g); g.weekly.data(g)
	g.ledger_muted=true; g.coins=200; g.ledger_muted=false; g.hp=40; g.energy=12
	# Manual saving is the only non-wake write; internal operations never replace it.
	assert(g.save_game()); var original:=FileAccess.get_file_as_string(g.SAVE)
	g.change_coins(30,"出售物品·沙麦"); g.mark_dirty(); assert(FileAccess.get_file_as_string(g.SAVE)==original)
	g.show_menu(); var buttons:=[]
	for b in g.modal.find_children("*","Button",true,false): buttons.append(b.text)
	assert(buttons==["设置","手动存档"]); g.modal.hide()
	# 17:00 +3h reaches 20:00: wake at next morning in clinic and overwrite same save.
	g.time_minutes=1020; g.scene_id="field"; g.hp=0; g.life.wake(g,"death")
	assert(g.scene_id=="clinic" and g.farming.day==2 and g.time_minutes==360 and g.hp==50 and g.energy==100 and g.coins==184)
	dialog(g); g.npc_life.tick(0.01,g); assert(not g.life.waking and FileAccess.get_file_as_string(g.SAVE)!=original)
	var save: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(g.SAVE)); assert(save.scene=="clinic" and save.coins==184)
	# Daytime death still advances exactly three hours.
	g.time_minutes=600; g.life.wake(g,"death"); assert(g.time_minutes==780 and g.farming.day==2); dialog(g)
	# Living enemies reset; dead ones wait for the next 06:00 refresh.
	g.combat.enemies[0].hp=0; g.combat.enemies[1].hp=4; g.life.reset_survivors(g)
	assert(g.combat.enemies[0].hp==0 and g.combat.enemies[1].hp==g.combat.enemies[1].max_hp)
	g.life.advance_to(g,(g.farming.day-1)*1440+1439); assert(g.combat.enemies[0].hp==0)
	g.life.advance_to(g,g.farming.day*1440+359); assert(g.combat.enemies[0].hp==0)
	g.life.advance_to(g,(g.farming.day-1)*1440+360); assert(g.combat.enemies[0].hp==55)
	g.combat.enemies[0].hp=0; g.life.refresh_morning(g); assert(g.combat.enemies[0].hp==0)
	# 02:00 forced collapse: 5% healing, energy exactly 50, 10% loss, no extra calendar day.
	g.time_minutes=119; g.hp=20; g.energy=3; g.ledger_muted=true; g.coins=100; g.ledger_muted=false
	var day: int=g.farming.day; g.tick_clock(1)
	assert(g.farming.day==day and g.time_minutes==360 and g.scene_id=="home" and g.hp==25 and g.energy==50 and g.coins==90)
	dialog(g); assert(not g.life.waking)
	# Paid treatment, hours, and state validation at the actual clinician.
	g.scene_id="clinic"; g.time_minutes=600; g.hp=79; g.energy=40; g.ledger_muted=true; g.coins=100; g.ledger_muted=false
	assert(g.life.treatment(g,"doctor",true) and g.hp==100 and g.coins==85 and g.energy==40)
	g.time_minutes=1080; g.hp=79; assert(not g.life.treatment(g,"doctor",true))
	assert(g.npc_life.working("doctor",360) and not g.npc_life.working("doctor",1080))
	assert(g.npc_life.working("medic",720) and not g.npc_life.working("medic",0))
	# Delayed food consumption and cancellation on hurt do not lose food.
	g.inventory={"馒头":2}; g.energy=0; g.scene_id="field"; g.hp=100; g.invulnerability=0
	assert(g.cooking.eat("馒头",g) and g.inventory["馒头"]==2); g.tick_eating(0.4); assert(g.energy==0)
	g.take_damage(1,Vector2.ZERO); assert(g.eating_time==0 and g.inventory["馒头"]==2)
	assert(g.cooking.eat("馒头",g)); g.tick_eating(0.8); assert(g.energy==20 and g.inventory["馒头"]==1)
	g.energy=0; g.attack_time=0; g.start_attack(); assert(g.attack_time==0)
	# Sunday night includes after-midnight amounts; all losses enter the closed week.
	g.flags={}; g.farming.day=7; g.time_minutes=1200; g.weekly.data(g); g.life.initialize(g)
	g.ledger_muted=true; g.coins=0; g.ledger_muted=false
	g.change_coins(500,"委托奖励"); g.change_coins(-100,"购买物品·兽皮")
	g.life.advance_to(g,7*1440+119); g.change_coins(30,"打怪拾取")
	g.tick_clock(1); assert(g.coins==387 and g.farming.day==8 and g.time_minutes==360)
	dialog(g); assert(g.weekly.active and g.weekly.current.income==530 and g.weekly.current.expense==143 and g.weekly.current.net==387)
	assert(g.weekly.COMMENTS.size()==4)
	for tier in g.weekly.COMMENTS: assert(tier.size()==10)
	assert(g.weekly.tier_for(199)==0 and g.weekly.tier_for(200)==1 and g.weekly.tier_for(400)==2 and g.weekly.tier_for(700)==3)
	g.weekly.advance(g); assert(g.weekly.phase==0 and g.weekly.settled); g.weekly.advance(g); assert(g.weekly.phase==1)
	g.weekly.advance(g); g.weekly.advance(g); assert(g.weekly.phase==2)
	await process_frame; await process_frame
	var chart=g.modal.find_children("*","Control",true,false).filter(func(c): return c.get_script()==load("res://weekly_chart.gd"))[0]
	chart.set_metric("net"); assert(chart.metric=="net" and chart.values==[387.0])
	assert(g.modal.size.x<=1280 and g.modal.size.y<=736)
	# A second week can lose money; the graph must interpolate below the zero line.
	chart.history.append({"week":2,"income":40,"expense":90,"net":-50}); chart.set_metric("net",true)
	assert(chart.values==[387.0,-50.0]); chart.set_metric("income"); assert(chart.progress==0)
	chart._process(0.3); assert(chart.progress>0 and chart.progress<1)
	chart._process(0.3); assert(chart.progress==1 and chart.display_values()==[530.0,40.0])
	g.weekly.finish(g); assert(not g.weekly.active and not g.life.waking and g.flags.weekly_finance.history.size()==1)
	var bank: Dictionary=g.flags.weekly_finance.duplicate(true)
	g.load_game(); dialog(g); assert(g.flags.weekly_finance==JSON.parse_string(JSON.stringify(bank)) and g.coins==387)
	g.weekly.close_due(g); assert(not g.weekly.active,"weekly report cannot replay")
	# An expiry skipped during Sunday medical recovery is booked before the Monday boundary.
	g.flags={}; g.farming.day=7; g.time_minutes=1380; g.weekly.data(g); g.life.initialize(g)
	g.ledger_muted=true; g.coins=100; g.ledger_muted=false
	var board: Dictionary=g.commissions.data(g)
	board.slots[0]={"id":"c02","uid":900,"status":"active","deadline":7*1440+120,"progress":{},"contributed":{},"rewards":{}}
	g.life.wake(g,"death"); dialog(g)
	assert(g.weekly.active and g.weekly.current.expense==30 and g.coins==70)
	g.weekly.advance(g); g.weekly.advance(g); g.weekly.advance(g); g.weekly.advance(g); g.weekly.finish(g)
	print("PASS v25 life/weekly: single overwrite save, manual-only changes, death times/clinic/50%, 02:00 collapse/5%/50 energy/10%, daily 06 reset, treatment costs/hours, food animation interruption, all money ledger, Sunday midnight attribution, 4x10 comments, rolling pages, week-axis graph and once-only report save")
	g.queue_free(); await process_frame; quit()
