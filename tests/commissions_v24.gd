extends SceneTree
func _initialize() -> void: call_deferred("run")
func close_dialog(g: Node) -> void:
	while g.dialogue_panel.visible: g.next_dialog()
func put(g: Node,index: int,id: String,uid: int=123) -> Dictionary:
	var q: Dictionary={"id":id,"uid":uid,"status":"posted","deadline":g.commissions.now(g)+4320,"progress":{},"rewards":{}}
	g.commissions.set_slot(g.commissions.data(g),index,q); return q
func run() -> void:
	var g=load("res://main.tscn").instantiate(); root.add_child(g)
	await process_frame; g.set_process(false); close_dialog(g)
	g.flags={"training_done":true}; g.step=11; g.level=6; g.scene_id="village"; g.player=g.commissions.BOARD_POS; g.farming.day=5; g.time_minutes=360
	var c=g.commissions; c.update(g,true); var s: Dictionary=c.data(g)
	assert(s.slots.size()==2 and c.Data.TASKS.size()==40 and c.Data.WARRANTS.size()==6)
	for t in c.Data.TASKS:
		if c.eligible(t,g):
			for item in t.needs: assert(item in c.AVAILABLE or item in c.LIVE_ENEMIES)
	# Posting and acceptance use different clocks; warrants retain the posting deadline.
	var q:=put(g,0,"c02"); g.time_minutes+=60
	assert(c.accept(g,0,123) and q.deadline==c.now(g)+1440)
	assert(not c.accept(g,0,123))
	q=put(g,2,"w1",124); var original_deadline: float=q.deadline; g.time_minutes+=60
	assert(c.accept(g,2,124) and q.deadline==original_deadline)
	assert(q.rewards["铁锭"]==2 and q.rewards.has("肥料"))
	var books:=0
	for key in q.rewards:
		if str(key).begins_with("制作书·"): books+=int(q.rewards[key])
	assert(books==1 and q.rewards.size()>=6,"warrant guarantees one book plus 2-3 different bonus types")
	# Only the specifically accepted elite counts; normal beetles cannot satisfy it.
	c.ensure_elite(g); var elite: Dictionary=g.combat.enemies.back()
	assert(elite.warrant_uid==124 and elite.max_hp==280)
	c.event(g,"kill","厚甲甲壳虫"); assert(not c.complete(g,q))
	c.event(g,"elite","铁背甲壳虫",1,999); assert(not c.complete(g,q))
	var combat_save: Dictionary=g.combat.snapshot(); g.combat.restore(combat_save)
	assert(g.combat.enemies.back().warrant_uid==124)
	c.event(g,"elite","铁背甲壳虫",1,124); assert(c.complete(g,q))
	var before_coins: int=g.coins
	assert(c.claim(g,2,124) and g.coins>before_coins and s.warrant.is_empty())
	assert(s.warrant_next==c.now(g)+1440)
	assert(not c.claim(g,2,124),"same stale callback cannot pay twice")
	close_dialog(g)
	# Reopening during the cool-down cannot reroll, nor can reopening after a failed check.
	g.time_minutes+=30; var state_before: String=s.seed
	for i in range(10): c.update(g,true)
	assert(s.warrant.is_empty() and state_before==s.seed)
	# Mandatory delivery checks, inventory consumption and full-bag storage fallback.
	q=put(g,0,"c02",200); assert(c.accept(g,0,200)); assert(not c.claim(g,0,200))
	g.inventory={"馒头":3}
	for i in range(41): g.inventory["占格%d" % i]=1
	var affinity: float=g.hearts.innkeeper
	assert(c.invest(g,0,200)); assert(c.claim(g,0,200) and g.inventory["馒头"]==1 and not g.flags.storage.is_empty())
	assert(g.hearts.innkeeper==affinity+1.5); close_dialog(g)
	var serialized: String=JSON.stringify(g.flags.commissions)
	g.save_game(); g.load_game(); close_dialog(g)
	assert(g.flags.commissions.history==JSON.parse_string(serialized).history and not c.claim(g,0,200))
	# Expiry removes its elite and starts exactly one-day cool-down at the deadline.
	q=put(g,2,"w1",300); assert(c.accept(g,2,300)); c.ensure_elite(g)
	q.deadline=c.now(g); var expired_at: float=q.deadline
	c.update(g,true); s=c.data(g)
	assert(s.warrant.is_empty() and s.warrant_next==expired_at+1440)
	for e in g.combat.enemies: assert(int(e.get("warrant_uid",-1))!=300)
	# Reward pools are stage gated; gold/silver are real persistent material stacks.
	c.rng.seed=12345; var silver:=false; var gold:=false; var accessory:=false; var mold:=false
	for i in range(1000):
		var r: Dictionary=c.roll_rewards(4,g)
		assert(not r.has("普通皮革手套") and not r.has("项链模具"))
		if r.has("白银"): silver=true
		if r.has("黄金"): gold=true
	assert(silver and gold)
	g.flags.wolf_defeated=true
	for i in range(5000):
		var r: Dictionary=c.roll_rewards(3,g)
		assert(r["铁锭"]==1 and int(r["铜锭"])>=1)
		for key in r:
			if str(key).begins_with("普通皮革"): accessory=true
			if str(key).ends_with("模具"): mold=true
	assert(accessory and mold)
	# 20% is checked once per day, separate from both commission slots.
	var spawned:=0
	g.flags={"training_done":true}; s=c.data(g); s.seed="12345678"
	for i in range(1000):
		s.warrant={}; s.warrant_next=c.now(g); c.update(g,true)
		if not s.warrant.is_empty(): spawned+=1
		else:
			var saved_seed: String=s.seed; c.update(g,true); assert(s.seed==saved_seed and s.warrant_next==c.now(g)+1440)
	assert(spawned>150 and spawned<250)
	# Board/UI stays usable and new material names survive old-save migration.
	g.scene_id="village"; g.player=c.BOARD_POS; g.setup_scene(); c.show(g)
	await process_frame; await process_frame
	assert(g.modal.visible and g.modal.size.x<=1280 and g.modal.size.y<=736)
	g.inventory={"铜料":3,"铜锭":2,"白银":2,"黄金":1}; g.migrate_craft_save()
	assert(g.inventory["铜锭"]==5 and not g.inventory.has("铜料"))
	g.save_game(); g.inventory={}; g.load_game(); close_dialog(g)
	assert(g.inventory["白银"]==2 and g.inventory["黄金"]==1)
	print("PASS v24 commissions: 40 templates, 6 gated warrants, 2+1 slots, clocks, cooldown, 20% persisted checks, reward pools, elite identity/save, delivery, storage overflow, no duplicate claim, affinity, jade UI, currency migration")
	g.queue_free(); await process_frame; quit()
