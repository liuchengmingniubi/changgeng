extends SceneTree
func _initialize() -> void: call_deferred("run")
func clear_dialog(g: Node) -> void:
	while g.dialogue_panel.visible: g.next_dialog()
func put(g: Node,index: int,id: String,uid: int) -> Dictionary:
	var q: Dictionary={"id":id,"uid":uid,"status":"posted","deadline":g.commissions.now(g)+4320,"progress":{},"rewards":{}}
	g.commissions.set_slot(g.commissions.data(g),index,q); return q
func run() -> void:
	var g=load("res://main.tscn").instantiate(); root.add_child(g); await process_frame; g.set_process(false); clear_dialog(g)
	g.flags={"training_done":true}; g.step=11; g.level=6; g.scene_id="village"; g.player=g.commissions.BOARD_POS; g.farming.day=2; g.time_minutes=600
	var c=g.commissions; var s: Dictionary=c.data(g)
	g.ledger_muted=true; g.coins=100; g.ledger_muted=false
	var q:=put(g,0,"c02",100); assert(c.accept(g,0,100)); g.inventory={"馒头":1}
	assert(c.invest(g,0,100) and g.inventory["馒头"]==0 and q.contributed["馒头"]==1 and not c.complete(g,q))
	assert(c.abandon(g,0,100) and g.coins==90 and g.inventory["馒头"]==0)
	assert(not c.abandon(g,0,100) and g.coins==90)
	q=put(g,0,"c11",101); assert(c.accept(g,0,101)); q.deadline=c.now(g)
	c.update(g,true); assert(g.coins==70,"middle expiry deducts 20")
	q=put(g,0,"c21",102); assert(c.accept(g,0,102)); assert(c.abandon(g,0,102) and g.coins==42)
	q=put(g,2,"w1",103); assert(c.accept(g,2,103)); assert(c.abandon(g,2,103) and g.coins==42)
	# Posted-but-unaccepted jobs never charge a failure penalty.
	q=put(g,0,"c21",104); q.deadline=c.now(g); c.update(g,true); assert(g.coins==42)
	# Partial stock can be invested, full investment freezes the deadline until claim.
	q=put(g,0,"c02",105); assert(c.accept(g,0,105)); g.inventory={"馒头":2}; assert(c.invest(g,0,105) and q.status=="ready")
	q.deadline=c.now(g)-100; c.update(g,true); assert(c.slot(g,0).uid==105 and c.complete(g,q))
	var old: int=g.coins; assert(c.claim(g,0,105) and g.coins>old); clear_dialog(g)
	# Kills freeze completed ordinary tasks even without a return trip before deadline.
	q=put(g,0,"c01",106); assert(c.accept(g,0,106)); c.event(g,"kill","甲壳虫",3)
	assert(q.status=="ready"); q.deadline=c.now(g)-1; c.update(g,true); assert(c.slot(g,0).uid==106)
	# Elite completion immediately frees its own slot, keeps pending loot and starts cooldown.
	q=put(g,2,"w1",107); assert(c.accept(g,2,107)); c.event(g,"elite","铁背甲壳虫",1,107)
	assert(s.warrant.is_empty() and s.pending.size()==1 and s.warrant_next==c.now(g)+1440)
	var pending: Dictionary=s.pending[0]; pending.deadline=c.now(g)-1
	assert(c.claim(g,2,107) and s.pending.is_empty()); clear_dialog(g); assert(not c.claim(g,2,107))
	assert(g.commerce.stock(g,"merchant")["铁锭"].price==50 and g.commerce.stock(g,"merchant")["铜锭"].price==45 and g.CraftCatalog.RECIPES["皮革"].fee==10)
	var entries: Array=g.flags.weekly_finance.weeks["1"].entries
	var penalties:=0
	for entry in entries:
		if entry.reason=="委托失败罚款": penalties-=int(entry.amount)
	assert(penalties==58)
	print("PASS v25 commissions: failure 10/20/28/0, no penalty for posted jobs, partial materials forfeited, completed tasks freeze, elite clears slot and preserves pending rewards, exact prices and categorized penalties")
	g.queue_free(); await process_frame; quit()
