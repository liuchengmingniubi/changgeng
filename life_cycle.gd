extends RefCounted
var waking:=false
var wake_kind: String=""
func service_day(g: Node) -> int: return maxi(1,g.farming.day-(1 if g.time_minutes<360 else 0))
func stamp(g: Node) -> float: return (g.farming.day-1)*1440.0+g.time_minutes
func initialize(g: Node) -> void:
	if not g.flags.has("monster_refresh_day"): g.flags.monster_refresh_day=service_day(g)
func advance_to(g: Node,target: float) -> void:
	while stamp(g)<target:
		var current:=stamp(g)
		var next_midnight: float=g.farming.day*1440.0
		var six: float=(g.farming.day-1)*1440.0+360.0
		if six<=current: six+=1440.0
		var stop:=minf(target,minf(next_midnight,six))
		# Settle task expiries at their real timestamp, even while medical recovery skips hours.
		if g.flags.has("commissions"):
			var board: Dictionary=g.commissions.data(g)
			if board.warrant.is_empty() and float(board.warrant_next)>current: stop=minf(stop,float(board.warrant_next))
			for i in range(2):
				if board.slots[i].is_empty() and float(board.next[i])>current: stop=minf(stop,float(board.next[i]))
			for q in [board.slots[0],board.slots[1],board.warrant]:
				if not q.is_empty() and q.get("status","")!="ready" and float(q.deadline)>current: stop=minf(stop,float(q.deadline))
		g.time_minutes+=stop-current
		if g.time_minutes>=1440:
			g.time_minutes=0
			g.farming.next_day()
		if is_equal_approx(g.time_minutes,360.0): refresh_morning(g)
		g.commissions.update(g,true)
func refresh_morning(g: Node) -> void:
	var day:=service_day(g)
	if int(g.flags.get("monster_refresh_day",0))>=day: return
	g.flags.monster_refresh_day=day
	g.combat.reset_enemies()
	if g.flags.get("training_active",false):
		g.recruitment.configure_training(g,true)
		for i in range(mini(3,int(g.flags.get("training_kills",0)))): g.combat.enemies[i].hp=0; g.combat.enemies[i].state="dead"
	if day%3==0:
		for herb in g.flags.get("field_plants",[]): herb.taken=false
func reset_survivors(g: Node) -> void:
	for e in g.combat.enemies:
		if int(e.hp)>0: e.hp=e.max_hp; e.pos=e.home; e.state="idle"; e.timer=1.0; e.velocity=Vector2.ZERO
func tick(g: Node,delta: float) -> void:
	if waking: return
	initialize(g)
	var current:=stamp(g); var threshold: float=(g.farming.day-1)*1440.0+120.0
	if g.time_minutes>=360: threshold+=1440.0
	if current+delta>=threshold:
		advance_to(g,threshold); wake(g,"collapse"); return
	advance_to(g,current+delta)
	g.update_hud()
func sleep(g: Node) -> bool:
	if waking: return false
	if g.scene_id not in ["home","barracks","clinic"]: g.toast("请到家中、营房或医馆床铺休息"); return false
	if g.time_minutes>=360 and g.time_minutes<960: g.toast("下午16:00起可以睡到清晨"); return false
	wake(g,"sleep"); return true
func wake(g: Node,kind: String) -> void:
	if waking: return
	waking=true; wake_kind=kind; g.cancel_eating(); g.attack_time=0; g.attack_buffer=0; g.modal.hide(); g.dialogue_panel.hide(); g.dialog_callback=Callable()
	var old_scene: String=g.scene_id; var day:=service_day(g); var target:=stamp(g)
	var loss:=0
	if kind=="death":
		loss=int(floor(g.coins*0.2)); g.change_coins(-loss,"死亡损失")
		target+=180
		var minute:=fposmod(target,1440.0)
		if minute>=1200 or minute<360: target=(floor(target/1440.0)+(1 if minute>=1200 else 0))*1440.0+360
		g.hp=maxi(1,int(ceil(g.max_hp*0.5))); g.energy=100; g.scene_id="clinic"; g.player=Vector2(550,420)
	else:
		target=(g.farming.day-1)*1440.0+360
		if g.time_minutes>=360: target+=1440
		if kind=="collapse":
			loss=int(floor(g.coins*0.1)); g.change_coins(-loss,"熬夜昏倒损失")
			g.hp=mini(g.max_hp,g.hp+maxi(1,int(ceil(g.max_hp*0.05)))); g.energy=50; g.scene_id="home"; g.player=Vector2(680,510)
		else:
			g.hp=mini(g.max_hp,g.hp+maxi(1,int(ceil(g.max_hp*0.1)))); g.energy=100
	# Sunday sleep/death ends the week and always leads to Monday morning.
	if day%7==0: target=maxf(target,day*1440.0+360)
	reset_survivors(g); advance_to(g,target)
	g.npc_life.live.clear(); g.setup_scene(); g.invulnerability=1.5; g.update_hud()
	var line: String="灯火渐暗，你躺下睡去。醒来时，窗外已有晨光。"
	if kind=="collapse":
		line=("你倒在关外的风沙中，被巡卒发现并送回了家。" if old_scene=="field" else ("你在屋内疲惫倒下，醒来时已躺在家中。" if old_scene in ["home","clinic","barracks"] else "你疲惫地倒在村道上，被人送回了家。"))+"\n损失%d文；恢复5%%生命，精力为50%%。" % loss
	elif kind=="death": line="巡卒将你送到了村医馆。醒来时伤口已经包扎。\n损失%d文；生命恢复至50%%，精力回满。" % loss
	var cover:=ColorRect.new(); cover.color=Color(0,0,0,0); cover.size=Vector2(1280,800); cover.mouse_filter=Control.MOUSE_FILTER_IGNORE; cover.z_index=90; g.ui.add_child(cover)
	var tween: Tween=g.create_tween(); tween.tween_property(cover,"color:a",1.0,0.2); tween.tween_interval(0.25); tween.tween_property(cover,"color:a",0.0,0.35); tween.tween_callback(cover.queue_free)
	g.show_dialog([["休息之后",line]],func():
		g.weekly.close_due(g)
		if not g.weekly.active: finish_wake(g))
func finish_wake(g: Node) -> void:
	waking=false; g.weekly.active=false; g.modal.hide(); g.update_hud()
	if g.save_game(): g.toast("醒来后的旅程已保存")
func treatment(g: Node,id: String,confirm: bool=false) -> bool:
	if id not in ["doctor","medic"]: return false
	var d: Dictionary=g.npc_life.PEOPLE[id]
	var present: Dictionary=g.npc_life.live.get(id,{})
	var clinic: bool=id=="doctor" and g.scene_id=="clinic"
	if not g.npc_life.working(id,g.time_minutes): g.toast("医者已经休息，请按值诊时间前来"); return false
	if not clinic and (present.get("scene","")!=g.scene_id or g.player.distance_to(present.get("pos",Vector2(-99999,-99999)))>110): g.toast("请到医者身边治疗"); return false
	var cost:=int(ceil(float(g.max_hp-g.hp)/10.0))*5
	if cost<=0: g.toast("生命已满，无需治疗"); return false
	if g.coins<cost: g.toast("治疗需要%d文，铜钱不足" % cost); return false
	if not confirm:
		g.inventory_ui.prepare(g,"%s · 治疗" % d.name)
		g.modal_body.add_child(g.inventory_ui.jl("缺失生命%d点，治疗费用%d文。每10点5文，不足10点按10点计算。" % [g.max_hp-g.hp,cost],16))
		g.modal_body.add_child(g.inventory_ui.jb("确认治疗",func(): treatment(g,id,true)))
		g.modal_body.add_child(g.inventory_ui.jb("取消",func(): g.modal.hide())); return true
	g.change_coins(-cost,"治疗费"); g.hp=g.max_hp; g.regen_timer=0; g.modal.hide(); g.update_hud(); g.toast("治疗完成，生命回满，精力不变"); return true
