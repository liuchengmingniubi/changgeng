extends RefCounted
const Data=preload("res://commission_data.gd")
const Catalog=preload("res://craft_catalog.gd")
const BOARD_POS=Vector2(1890,1785)
const DAY=1440.0
const LIVE_ENEMIES=["甲壳虫","厚甲甲壳虫"]
const AVAILABLE=["馒头","面条","草药饼","沙麦","面粉","初始种子","基础草药","回血药水","皮革","粗布","甲壳","厚甲片","铁锭","铜锭"]
var rng=RandomNumberGenerator.new()
var last_minute: int=-1
func now(g: Node) -> float: return (g.farming.day-1)*DAY+g.time_minutes
func chapter12(g: Node) -> bool: return bool(g.flags.get("chapter12_complete",false)) or bool(g.flags.get("wolf_defeated",false))
func data(g: Node) -> Dictionary:
	if not g.flags.has("commissions"):
		rng.randomize()
		g.flags.commissions={"slots":[{},{}],"warrant":{},"next":[now(g),now(g)],"warrant_next":now(g)+DAY,"serial":0,"history":[],"pending":[],"seed":str(rng.state)}
	if not g.flags.commissions.has("pending"): g.flags.commissions.pending=[]
	return g.flags.commissions
func restore_rng(s: Dictionary) -> void: rng.state=int(s.seed)
func store_rng(s: Dictionary) -> void: s.seed=str(rng.state)
func templates(warrant: bool) -> Array: return Data.WARRANTS if warrant else Data.TASKS
func definition(id: String) -> Dictionary:
	for t in Data.TASKS+Data.WARRANTS:
		if str(t.id)==id: return t
	return {}
func eligible(t: Dictionary,g: Node) -> bool:
	if g.step<8: return false
	if int(t.tier)>=2 and g.step<11: return false
	if int(t.tier)==3 and g.level<6: return false
	if int(t.tier)==4 and (g.level<3 or not g.flags.get("training_done",false)): return false
	for key in t.needs:
		if t.kind in ["kill","elite"]:
			if (str(t.base) if t.kind=="elite" else str(key)) not in LIVE_ENEMIES: return false
		elif str(key) not in AVAILABLE: return false
	return true
func slot(g: Node,index: int) -> Dictionary:
	var s:=data(g)
	return s.warrant if index==2 else s.slots[index]
func set_slot(s: Dictionary,index: int,value: Dictionary) -> void:
	if index==2: s.warrant=value
	else: s.slots[index]=value
func update(g: Node,force: bool=false) -> void:
	var minute: int=int(now(g))
	if not force and minute==last_minute: return
	last_minute=minute
	var s:=data(g); restore_rng(s)
	var changed:=false
	for i in range(3):
		var q: Dictionary=slot(g,i)
		if not q.is_empty() and q.status!="ready" and now(g)>=float(q.deadline):
			retire(g,i,float(q.deadline),"到期"); changed=true
		q=slot(g,i)
		if not q.is_empty() and q.status=="active":
			var reminders: Dictionary=q.get("reminders",{})
			for hours in [6,1]:
				if float(q.deadline)-now(g)<=hours*60 and not reminders.has(str(hours)):
					g.toast("%s剩余不足%d小时" % [definition(q.id).title,hours]); reminders[str(hours)]=true
			q.reminders=reminders
		var due: float=float(s.warrant_next if i==2 else s.next[i])
		if not q.is_empty() or now(g)<due: continue
		var pool: Array=[]
		for t in templates(i==2):
			if not eligible(t,g): continue
			var duplicate:=false
			for other in [s.slots[0],s.slots[1],s.warrant]:
				if other.get("id","")==t.id: duplicate=true
			if not duplicate: pool.append(t)
		if pool.is_empty(): continue
		# Only one persisted chance per due date. No reopening reroll.
		if i==2 and rng.randf()>=0.20:
			s.warrant_next=now(g)+DAY; changed=true; continue
		var recent: Array=s.history.slice(maxi(0,s.history.size()-4))
		var fresh: Array=pool.filter(func(t): return t.id not in recent)
		if not fresh.is_empty(): pool=fresh
		var t: Dictionary=pool[rng.randi_range(0,pool.size()-1)]
		s.serial=int(s.serial)+1
		var fresh_q: Dictionary={"id":t.id,"uid":s.serial,"status":"posted","deadline":now(g)+(3 if i==2 else int(t.tier))*DAY,"progress":{},"rewards":{}}
		set_slot(s,i,fresh_q); changed=true
	store_rng(s)
	if changed: g.mark_dirty()
func retire(g: Node,index: int,at: float,why: String) -> void:
	var s:=data(g); var q:=slot(g,index)
	if q.is_empty(): return
	if why in ["到期","撤回"] and q.status=="active":
		var penalty: int=[0,10,20,28,0][int(definition(str(q.id)).tier)]
		g.change_coins(-mini(g.coins,penalty),"委托失败罚款")
	s.history.append(q.id)
	if s.history.size()>80: s.history.pop_front()
	set_slot(s,index,{})
	if index==2: s.warrant_next=at+DAY
	else: s.next[index]=at+rng.randi_range(0,2)*DAY
	if index==2:
		g.combat.enemies=g.combat.enemies.filter(func(e): return int(e.get("warrant_uid",-1))!=int(q.uid))
	g.toast(("悬赏令" if index==2 else "委托")+"已"+why)
func near_board(g: Node) -> bool: return g.scene_id=="village" and g.player.distance_to(BOARD_POS)<=100
func accept(g: Node,index: int,uid: int) -> bool:
	update(g,true)
	if index<0 or index>2 or not near_board(g): return false
	var q:=slot(g,index)
	if q.is_empty() or int(q.uid)!=uid or q.status!="posted": return false
	var t:=definition(str(q.id))
	if not eligible(t,g): return false
	q.status="active"; q.progress={}; q.contributed={}
	if index!=2: q.deadline=now(g)+int(t.tier)*DAY
	var s:=data(g); restore_rng(s)
	q.rewards=roll_rewards(int(t.tier),g,t)
	store_rng(s)
	g.mark_dirty(); g.update_hud()
	g.toast("已接取："+str(t.title))
	return true
func books(g: Node) -> Array:
	var result: Array=[]
	for item in Catalog.RECIPES:
		var r: Dictionary=Catalog.RECIPES[item]
		if r.book=="" or int(r.level)>g.level: continue
		var available:=true
		for material in r.materials:
			if str(material) not in AVAILABLE and not str(material).begins_with("甲壳"): available=false
		if available: result.append(str(r.book))
	
	return result
func choose_book(g: Node) -> String:
	if chapter12(g) and rng.randf()<0.05: return ["通用手套制作书","通用腰带制作书","通用鞋靴制作书"][rng.randi_range(0,2)]
	var pool:=books(g)
	return str(pool[rng.randi_range(0,pool.size()-1)]) if not pool.is_empty() else "制作书·甲壳盔"
func roll_rewards(tier: int,g: Node,t: Dictionary={}) -> Dictionary:
	var result: Dictionary={"铜钱":[0,28,65,130,200][tier]}
	# Delivery payment covers reference material value plus the base labor payment.
	const VALUES={"铁锭":50,"铜锭":45,"皮革":50,"粗布":3,"回血药水":35,"面粉":7,"沙麦":6,"初始种子":8,"馒头":10,"面条":18,"草药饼":20,"甲壳":5,"厚甲片":15,"基础草药":10}
	if t.get("kind","")=="deliver":
		for key in t.needs: result["铜钱"]+=int(VALUES.get(key,10))*int(t.needs[key])
	var pool: Array=[]
	if tier==1:
		result["皮革"]=1; pool=[["铁锭",35,1],["铜锭",40,1],["回血药水",25,1]]
	elif tier==2:
		result["铜锭"]=1; pool=[["铁锭",45,1],["肥料",50,2]]
		if chapter12(g): pool.append(["破旧皮革饰品",5,1])
	elif tier==3:
		result["铁锭"]=1; result["铜锭"]=1
		pool=[["制作书",25,1],["白银",25,1],["稀有种子",22,1],["铜锭",30,1]]
		if chapter12(g): pool.append_array([["模具",25,1],["普通皮革饰品",3,1]])
	else:
		result["铁锭"]=2; result["肥料"]=2; result[choose_book(g)]=1
		pool=[["白银",25,1],["黄金",10,1],["铜锭",40,1]]
		if chapter12(g): pool.append_array([["模具",22,1],["普通皮革饰品",3,1]])
	var count: int=(2 if tier>=3 else 1)+(1 if rng.randf()<0.20 else 0)
	for n in range(mini(count,pool.size())):
		var weight:=0
		for entry in pool: weight+=int(entry[1])
		var pick: int=rng.randi_range(1,weight); var at:=0
		for j in range(pool.size()):
			pick-=int(pool[j][1])
			if pick<=0: at=j; break
		var entry: Array=pool.pop_at(at); var item: String=entry[0]
		if item=="制作书": item=choose_book(g)
		elif item=="模具": item=["项链模具","戒指模具","手环模具"][rng.randi_range(0,2)]
		elif item in ["破旧皮革饰品","普通皮革饰品"]: item=("破旧皮革" if item=="破旧皮革饰品" else "普通皮革")+["手套","腰带","鞋靴"][rng.randi_range(0,2)]
		result[item]=int(result.get(item,0))+int(entry[2])
	return result
func event(g: Node,kind: String,item: String,amount: int=1,uid: int=-1) -> void:
	update(g)
	for i in range(3):
		var q:=slot(g,i)
		if q.is_empty() or q.status!="active" or now(g)>=float(q.deadline): continue
		var t:=definition(str(q.id))
		if t.kind!=kind or not t.needs.has(item): continue
		if kind=="elite" and uid!=int(q.uid): continue
		q.progress[item]=mini(int(t.needs[item]),int(q.progress.get(item,0))+amount)
		mark_ready(g,i,q)
func material_needs(t: Dictionary) -> Dictionary:
	var needs: Dictionary=t.needs.duplicate() if t.kind=="deliver" else {}
	for item in t.get("hand_in",{}): needs[item]=int(needs.get(item,0))+int(t.hand_in[item])
	return needs
func invest(g: Node,index: int,uid: int) -> bool:
	update(g,true)
	if index<0 or index>2 or not near_board(g): return false
	var q:=slot(g,index)
	if q.is_empty() or int(q.uid)!=uid or q.status!="active": return false
	var paid: Dictionary=q.get("contributed",{}); var changed:=false
	for item in material_needs(definition(str(q.id))):
		var missing: int=int(material_needs(definition(str(q.id)))[item])-int(paid.get(item,0))
		var count:=mini(maxi(0,missing),int(g.inventory.get(item,0)))
		if count>0: g.inventory[item]=int(g.inventory[item])-count; paid[item]=int(paid.get(item,0))+count; changed=true
	q.contributed=paid; mark_ready(g,index,q); g.update_hud(); return changed
func complete(g: Node,q: Dictionary) -> bool:
	if q.is_empty() or q.status not in ["active","ready"]: return false
	if q.status=="ready": return true
	if now(g)>=float(q.deadline): return false
	var t:=definition(str(q.id))
	if t.kind!="deliver":
		for item in t.needs:
			if int(q.progress.get(item,0))<int(t.needs[item]): return false
	for item in material_needs(t):
		if int(q.get("contributed",{}).get(item,0))<int(material_needs(t)[item]): return false
	return true
func mark_ready(g: Node,index: int,q: Dictionary) -> void:
	if not complete(g,q): return
	q.status="ready"; q.completed_at=now(g)
	if index==2:
		var s:=data(g); s.pending.append(q.duplicate(true)); restore_rng(s); retire(g,2,now(g),"完成"); store_rng(s)
	g.toast("任务已达成，奖励等待领取："+str(definition(q.id).title))
func claim(g: Node,index: int,uid: int) -> bool:
	update(g,true)
	if index<0 or index>2 or not near_board(g): return false
	var q:=slot(g,index)
	var pending_at: int=-1
	if index==2:
		for j in range(data(g).pending.size()):
			if int(data(g).pending[j].uid)==uid: pending_at=j; q=data(g).pending[j]; break
	if q.is_empty() or int(q.uid)!=uid or not complete(g,q): return false
	var t:=definition(str(q.id)); var reward: Dictionary=q.rewards.duplicate()
	if pending_at>=0: data(g).pending.remove_at(pending_at)
	var stored: Array=[]
	for item in reward:
		if item=="铜钱": g.change_coins(int(reward[item]),"悬赏奖励" if index==2 else "委托奖励"); continue
		if int(g.inventory.get(item,0))<=0 and g.equipment.count_items(g)>=42:
			var storage: Dictionary=g.flags.get("storage",{}); storage[item]=int(storage.get(item,0))+int(reward[item]); g.flags.storage=storage; stored.append(item)
		else: g.inventory[item]=int(g.inventory.get(item,0))+int(reward[item])
	g.relationships.change(str(t.owner),[0.0,1.5,2.0,3.0,3.0][int(t.tier)],g)
	var s:=data(g)
	if pending_at<0: restore_rng(s); retire(g,index,now(g),"完成"); store_rng(s)
	g.update_hud(); g.mark_dirty()
	var line: String="交付完成："+reward_text(reward)
	if not stored.is_empty(): line+="\n背包已满，以下奖励送至家中箱子："+"、".join(stored)
	g.modal.hide()
	g.show_dialog([[g.npc_life.PEOPLE[t.owner].name,str(t.get("ending","东西和工钱都点清了。这件事，多谢你。"))],["委托结算",line]])
	return true
func abandon(g: Node,index: int,uid: int) -> bool:
	if index<0 or index>2 or not near_board(g): return false
	var q:=slot(g,index)
	if q.is_empty() or int(q.uid)!=uid or q.status=="ready": return false
	var s:=data(g); restore_rng(s); retire(g,index,now(g),"撤回"); store_rng(s); g.update_hud(); g.mark_dirty(); return true
func reward_text(reward: Dictionary) -> String:
	var parts: Array=[]
	for item in reward: parts.append("%s ×%d" % [item,reward[item]])
	return "、".join(parts)
func progress_text(g: Node,q: Dictionary) -> String:
	var t:=definition(str(q.id)); var parts: Array=[]
	for item in t.needs: parts.append("%s %d/%d" % [item,int(q.get("contributed",{}).get(item,0) if t.kind=="deliver" else q.progress.get(item,0)),t.needs[item]])
	for item in t.get("hand_in",{}): parts.append("另交%s %d/%d" % [item,int(q.get("contributed",{}).get(item,0)),t.hand_in[item]])
	return "、".join(parts)
func summary(g: Node) -> String:
	if not g.flags.has("commissions"): return ""
	var lines: Array=[]
	for i in range(3):
		var q:=slot(g,i)
		if not q.is_empty() and q.status in ["active","ready"]: lines.append(str(definition(str(q.id)).title)+"\n"+progress_text(g,q)+(" · 待领取" if q.status=="ready" else " · 剩余%.1f天" % maxf(0,(float(q.deadline)-now(g))/DAY)))
	if not data(g).pending.is_empty(): lines.append("悬赏奖励待领取 ×%d" % data(g).pending.size())
	return "\n\n委托／悬赏\n"+"\n".join(lines) if not lines.is_empty() else ""
func show(g: Node) -> void:
	update(g,true)
	if not near_board(g): g.toast("请到村中公告栏前查看"); return
	g.inventory_ui.prepare(g,"东沙村 · 委托与悬赏")
	g.modal_body.add_child(g.inventory_ui.jl("两个委托栏＋独立悬赏栏 · 奖励到公告栏交付领取；背包满则送入家中箱子。",14))
	var scroll:=ScrollContainer.new(); scroll.custom_minimum_size=Vector2(1080,355); scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	var body:=VBoxContainer.new(); body.custom_minimum_size.x=1040; scroll.add_child(body); g.modal_body.add_child(scroll)
	for i in range(3):
		var index: int=i; var q:=slot(g,i); var heading: String="委托栏 %d" % (i+1) if i<2 else "悬赏令 · 独立栏"
		body.add_child(g.inventory_ui.jl(heading,18))
		if q.is_empty():
			var s:=data(g); var due: float=s.warrant_next if i==2 else s.next[i]
			body.add_child(g.inventory_ui.jl("暂无告示 · "+("每日判定20%%，距离下次判定%.1f天" % maxf(0,(due-now(g))/DAY) if i==2 else "刷新等待%.1f天／尚无可完成任务" % maxf(0,(due-now(g))/DAY)),14)); continue
		var t:=definition(str(q.id)); var uid: int=int(q.uid)
		var text: Label=g.inventory_ui.jl("%s · %s · %s\n%s\n%s · 剩余%.1f天\n基础奖励＋随机奖励：%s" % [t.title,g.npc_life.PEOPLE[t.owner].name,["","普通","中等","困难","悬赏"][int(t.tier)],t.story,progress_text(g,q)+(" · 已完成，等待领奖" if q.status=="ready" else ""),maxf(0,(float(q.deadline)-now(g))/DAY),reward_text(q.rewards) if q.status in ["active","ready"] else "接取时确定；普通／中等1—2种，困难／悬赏2—3种"],14)
		text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; text.custom_minimum_size.x=1020; body.add_child(text)
		if q.status=="posted": body.add_child(g.inventory_ui.jb("接取"+(" · 张贴起三天内完成" if i==2 else " · 接取后限时%d天" % int(t.tier)),func(): accept(g,index,uid); show(g)))
		else:
			if q.status=="active" and not material_needs(t).is_empty(): body.add_child(g.inventory_ui.jb("投入持有材料（失败不退还）",func(): invest(g,index,uid); show(g)))
			var b: Button=g.inventory_ui.jb("上交／领取奖励" if complete(g,q) else "尚未完成",func():
				if not claim(g,index,uid): show(g))
			b.disabled=not complete(g,q); body.add_child(b)
			body.add_child(g.inventory_ui.jb("放弃任务",func():
				g.inventory_ui.prepare(g,"确认放弃")
				g.modal_body.add_child(g.inventory_ui.jl("放弃后已投入材料不退还，普通/中等/困难另扣10/20/28文；悬赏不扣款。确定撤下？",16))
				g.modal_body.add_child(g.inventory_ui.jb("确定放弃",func(): abandon(g,index,uid); show(g)))
				g.modal_body.add_child(g.inventory_ui.jb("返回",func(): show(g)))))
	for pending in data(g).pending:
		var uid: int=int(pending.uid)
		body.add_child(g.inventory_ui.jb("领取已完成悬赏："+str(definition(pending.id).title),func(): claim(g,2,uid)))
	g.modal_body.add_child(g.inventory_ui.jb("关闭",func(): g.modal.hide()))
func ensure_elite(g: Node) -> void:
	var q:=slot(g,2)
	if q.is_empty() or q.get("status","")!="active" or now(g)>=float(q.deadline) or complete(g,q) or int(q.get("spawn_day",g.life.service_day(g)))>g.life.service_day(g): return
	for e in g.combat.enemies:
		if int(e.get("warrant_uid",-1))==int(q.uid): return
	q.spawn_day=g.life.service_day(g)
	var t:=definition(str(q.id)); var at:=Vector2(2020,850)
	g.combat.enemies.append({"kind":str(t.needs.keys()[0]),"base_kind":t.base,"warrant_uid":q.uid,"id":100000+int(q.uid),"pos":at,"home":at,"hp":t.hp,"max_hp":t.hp,"state":"idle","timer":1.0,"facing":Vector2.LEFT,"hurt":0.0,"velocity":Vector2.ZERO})
func draw(g: Node) -> void:
	if g.scene_id!="village": return
	var p: Vector2=BOARD_POS/g.world_layout.SCALE
	g.draw_rect(Rect2(p+Vector2(-43,-78),Vector2(86,60)),Color("647c68"))
	g.draw_rect(Rect2(p+Vector2(-43,-78),Vector2(86,60)),Color("b99a60"),3)
	for x in [-29,25]: g.draw_rect(Rect2(p+Vector2(x,-18),Vector2(6,22)),Color("795d3f"))
	for x in [-27,-6,15]: g.draw_rect(Rect2(p+Vector2(x,-65),Vector2(16,33)),Color("eee4c5"))
	g.text_at(p+Vector2(-40,-89),"公告栏",17,Color("35503f"))
