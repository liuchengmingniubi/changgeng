extends SceneTree
func _initialize() -> void: call_deferred("run")
func close_dialog(g: Node) -> void:
	while g.dialogue_panel.visible: g.next_dialog()
func press(g: Node,text: String) -> bool:
	for button in g.modal.find_children("*","Button",true,false):
		if button.text==text: button.pressed.emit(); return true
	return false
func hold(g: Node,item: String,count: int=5) -> void:
	g.inventory={item:count}; g.quickbar=[item,"","","","",""]; g.quickbar_index=0
	g.flags.quickbar=g.quickbar.duplicate(); g.flags.quickbar_initialized=true; g.flags.bag_stacks=[]
func run() -> void:
	var g=load("res://main.tscn").instantiate(); root.add_child(g)
	await process_frame; g.set_process(false); close_dialog(g)
	g.flags={}; g.hearts={}; g.step=11; g.scene_id="village"; g.player=Vector2(1000,800)
	g.npc_life.live.elder={"scene":"village","pos":g.player+Vector2(30,0),"status":"休息"}
	for item in ["军用旧铁剑","铁钩镰","军用铁锤","破旧铁甲","赤铜戒","旧布腰带","锄头","斧子","镐子","稿子","父母遗书","《草药大全》","军籍腰牌","秦二郎的遗物"]:
		hold(g,item); assert(not g.gifting.allowed(item,g)); assert(not g.gifting.offer("elder",g))
	for item in ["甲壳","皮革","馒头","回血药水","初始种子","药草种子","制作书·甲壳盔"]: assert(g.gifting.allowed(item,g))
	hold(g,"馒头"); var before: Dictionary=g.inventory.duplicate()
	g.interact("elder"); assert(g.modal.visible and not g.dialogue_panel.visible and g.hearts.get("elder",0)==0)
	assert(press(g,"赠送")); var token: int=g.gifting.pending.token
	await process_frame; await process_frame
	assert(g.modal.size.y<=700 and g.modal.size.x<=1280)
	g.modal.find_child("GiftQuantity",true,false).value=1
	assert(press(g,"取消") and g.inventory==before and g.gifting.pending.is_empty())
	assert(not g.gifting.accept(g,token,2))
	assert(press(g,"赠送")); token=int(g.gifting.pending.token)
	g.flags.active_side="roof"; g.flags.side_stage=0
	g.energy=40; var hp: int=g.hp
	g.modal.find_child("GiftQuantity",true,false).value=1
	assert(press(g,"确认赠送"))
	assert(g.inventory["馒头"]==4 and g.hearts.elder==3 and g.flags.gifts_elder==1 and g.energy==40 and g.hp==hp)
	assert(g.flags.active_side=="roof" and g.flags.side_stage==0)
	g.flags.active_side=""
	assert(not g.gifting.accept(g,token,2) and g.inventory["馒头"]==4 and g.hearts.elder==3,"double confirm cannot send twice")
	close_dialog(g); g.farming.day+=3; g.gifting.show_confirm("elder","馒头",g); token=int(g.gifting.pending.token)
	g.player+=Vector2(300,0); assert(not g.gifting.accept(g,token,1)); g.player-=Vector2(300,0)
	g.quickbar_index=1; assert(not g.gifting.accept(g,token,1)); g.quickbar_index=0
	assert(not g.gifting.accept(g,token,0) and not g.gifting.accept(g,token,9))
	g.modal.hide(); assert(not g.gifting.accept(g,token,1),"Escape/modal close invalidates confirmation")
	# All 13 people accept gifts in person; no shop-hours restriction.
	for id in g.npc_life.PEOPLE:
		close_dialog(g); hold(g,"甲壳",2)
		g.npc_life.live[id]={"scene":"village","pos":g.player+Vector2(30,0),"status":"休息"}
		g.gifting.show_confirm(id,"甲壳",g)
		var previous: float=float(g.hearts.get(id,0)); var serial: int=int(g.gifting.pending.token)
		assert(g.gifting.accept(g,serial,1) and is_equal_approx(float(g.hearts[id]),previous+g.relationships.gift_gain(id,"甲壳")))
	assert(g.flags.get("active_side","")=="","gifting does not occupy a side-quest slot")
	close_dialog(g); hold(g,"初始种子"); g.interact("elder"); assert(press(g,"正常交谈")); close_dialog(g)
	assert(g.gifting.bypass_npc=="" and g.modal.visible)
	# Actual recruitment dialogue remains reachable through the normal-talk option.
	g.step=7; g.scene_id="wall"; g.npc_life.live.captain={"scene":"wall","pos":g.player+Vector2(25,0),"status":"等候任务"}
	g.modal.hide(); hold(g,"药草种子"); g.interact("captain"); assert(press(g,"正常交谈")); assert(g.dialogue_panel.visible); close_dialog(g)
	assert(g.step==8 and g.flags.enlistment_gear)
	g.modal.hide(); g.farming.day+=3; g.scene_id="village"; hold(g,"回血药水"); g.potion_cooldown=20
	g.gifting.show_confirm("elder","回血药水",g); token=int(g.gifting.pending.token)
	g.save_game(); g.load_game(); close_dialog(g)
	assert(not g.gifting.accept(g,token,1) and g.potion_cooldown==20)
	assert(g.hearts.elder>=2 and g.flags.gifts_elder>=2)
	print("PASS v21: gift exclusions and quest protection, held-item menu, quantity/cancel, one-shot confirmation, range/held-state validation, 13 off-duty NPCs, affinity/consumption, ordinary recruitment dialogue, side-quest independence and save/load invalidation")
	g.queue_free(); await process_frame; quit()
