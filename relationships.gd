extends RefCounted
const DATA=preload("res://social_data.gd").PROFILES
const IMPORTANT=["elder","smith","doctor","merchant","captain","scout","soldier","medic","innkeeper","leather"]
const INITIAL={"elder":40.0,"smith":10.0,"doctor":12.0,"merchant":6.0,"farmer":9.0,"innkeeper":11.0,"leather":7.0,"captain":3.0,"scout":5.0,"soldier":2.0,"medic":4.0,"guard_day":1.0,"guard_night":0.0}
const DAILY_GAIN:=1.5
const FIRST_GAIN:=0.0
const QUIZ_GAIN:=1.5
const SIDE_GAIN:=4.0
const HIDDEN={"roof":{"npc":"elder","threshold":70.0},"scout":{"npc":"scout","threshold":50.0},"ledger":{"npc":"merchant","threshold":55.0},"letter":{"npc":"soldier","threshold":65.0}}
var pending: Dictionary={}
var serial:=0
func cancel_question() -> void:
	pending.clear(); serial+=1
func change(id: String,amount: float,g: Node) -> float:
	var before: float=clampf(float(g.hearts.get(id,0)),0,100)
	g.hearts[id]=clampf(before+amount,0,100)
	return float(g.hearts[id])-before
func initialize_new(g: Node) -> void:
	g.hearts=INITIAL.duplicate()
func normalize(g: Node) -> void:
	for id in INITIAL:
		if not g.hearts.has(id): g.hearts[id]=INITIAL[id]
	for id in g.hearts: g.hearts[id]=clampf(float(g.hearts[id]),0,100)
	if int(g.flags.get("social_revision",0))<1:
		var days: Dictionary=g.flags.get("last_gift_days",{})
		for id in DATA:
			if int(g.flags.get("gifts_"+id,0))>0 and not days.has(id): days[id]=g.farming.day
		g.flags["last_gift_days"]=days; g.flags["social_revision"]=1
	if int(g.flags.get("affinity_reward_revision",0))<1:
		var claimed: Dictionary=g.flags.get("affinity_rewards",{})
		if g.step>=9 or g.flags.get("training_done",false): claimed["main_training"]=true
		if int(g.flags.get("search_stage",0))>=3: claimed["patrol_report"]=true
		if int(g.flags.get("search_stage",0))>=7: claimed["cave_report"]=true
		g.flags["affinity_rewards"]=claimed; g.flags["affinity_reward_revision"]=1
func liked(id: String,item: String) -> bool:
	return DATA.has(id) and item in DATA[id].likes
func gift_gain(id: String,item: String) -> float: return 3.0 if liked(id,item) else 1.5
func gift_wait(id: String,g: Node) -> int:
	var days: Dictionary=g.flags.get("last_gift_days",{})
	return maxi(0,3-(g.farming.day-int(days[id]))) if days.has(id) else 0
func mark_gift(id: String,g: Node) -> void:
	var days: Dictionary=g.flags.get("last_gift_days",{}); days[id]=g.farming.day; g.flags["last_gift_days"]=days
func hidden_ready(key: String,g: Node) -> bool:
	return HIDDEN.has(key) and not g.flags.get("side_done_"+key,false) and float(g.hearts.get(HIDDEN[key].npc,0))>=float(HIDDEN[key].threshold)
func context_key(g: Node) -> String:
	return "%d/%d/%d/%s/%d/%s/%s/%s/%s/%s/%s/%s" % [g.step,int(g.flags.get("training_kills",0)),int(g.flags.get("search_stage",0)),str(g.flags.get("active_side","")),int(g.flags.get("side_stage",0)),str(g.flags.get("training_returned",false)),str(g.flags.get("side_done_roof",false)),str(g.flags.get("side_done_scout",false)),str(g.flags.get("side_done_ledger",false)),str(g.flags.get("search_flask",false)),str(g.flags.get("search_remains",false)),str(g.flags.get("roster_intro_seen",false))]
func context_label(g: Node) -> String:
	var side: String=str(g.flags.get("active_side",""))
	if g.story_events.SIDE_NAMES.has(side): return "你最近在忙“"+str(g.story_events.SIDE_NAMES[side])+"”的事"
	if g.step==8 and int(g.flags.get("training_kills",0))>0: return "关外训练已经清理了%d只甲壳虫" % int(g.flags.training_kills)
	if g.step==9 and g.flags.get("roster_intro_seen",false): return "你查看过了失踪名单"
	var journal: Array=g.flags.get("journal",[])
	if not journal.is_empty() and str(journal[-1]).contains("完成隐藏剧情："):
		return "你刚办完“"+str(journal[-1]).get_slice("完成隐藏剧情：",1)+"”的事"
	if g.step==9: return "你已回到关内" if g.flags.get("training_returned",false) else "你完成了关外训练"
	if g.step>=11:
		if int(g.flags.get("search_stage",0))==1 and g.flags.get("search_flask",false): return "你在旧巡逻线找到了刻名水壶"
		if int(g.flags.get("search_stage",0))==1 and g.flags.get("search_remains",false): return "你在旧巡逻线找到了身份遗物"
		return ["你正式入伍了","你接下了第一次巡防","搜寻找到了两处线索","你汇报了搜寻发现","巡防记录有了新的进展","你准备探查洞口","你在洞口发现了新的痕迹","你已完成洞口探查并归营"][mini(7,int(g.flags.get("search_stage",0)))]
	return "你刚完成了“"+str(g.OBJECTIVES[g.step-1])+"”" if g.step>0 else "你准备走出家门了"
func context_lines(id: String,g: Node) -> Array:
	var question: String=str(DATA[id].context)
	if g.step<8:
		question={"elder":"出门要办的事，补给和回来的安排，你想好了吗？","smith":"还没出关，先把材料和护具认清。手册里有哪样不明白？","doctor":"要出门，先认清药草。你知道拿不准的草该怎么处理了吗？","merchant":"要添补给？先把数量、总价和自己要留的口粮算清了么？","captain":"你想参军的缘由，我会听。听到的规矩也准备照做了吗？","scout":"还没走远，先看看回头的路。你认得哪几处路标？","soldier":"你也打算来参军？要是心里发慌，能说给我听。","medic":"出门的药先准备好。许先生教你的那些，你记牢了吗？"}.get(id,question)
	elif g.step>=11 and int(g.flags.get("search_stage",0))>=5:
		question={"elder":"说要去探洞，我还是担心。你和同袍约好怎样回来了吗？","captain":"洞口看见的痕迹、听见的动静和自己的推断，你能分别说清吗？","scout":"洞口狭窄，退出的路线记好了没有？","doctor":"要往洞口走，补给备够了吗？受伤回来别瞒着。","medic":"探洞回来，有没有谁还不肯把伤说出来？","soldier":"里面真有动静？你把亲眼见到的先讲给我听，别让我瞎猜。","leather":"有了新痕迹？你确实看见了什么，慢慢跟我说。"}.get(id,question)
	return [[g.npc_life.PEOPLE[id].name,context_label(g)+"。\n"+question]]
func discuss(id: String,g: Node) -> void:
	var key:=context_key(g); g.modal.hide()
	g.show_dialog(context_lines(id,g),func(): g.flags["context_seen_"+id]=key; g.mark_dirty())
func small(g: Node,text: String,callback: Callable) -> Button:
	var button: Button=g.button(text,callback); button.add_theme_font_size_override("font_size",14); return button
func show_menu(id: String,g: Node,after_context: bool=false) -> void:
	var context:=context_key(g)
	if not after_context and id in IMPORTANT and g.step>0 and str(g.flags.get("context_seen_"+id,""))!=context:
		g.modal.hide()
		g.show_dialog(context_lines(id,g),func():
			g.flags["context_seen_"+id]=context; g.mark_dirty(); show_menu(id,g,true))
		return
	cancel_question(); g.inventory_ui.prepare(g,g.npc_life.PEOPLE[id].name+" · 交谈")
	g.modal_body.add_child(g.label("亲密度 %.1f/100 · 每日聊天缓慢增长，重复交谈不重复奖励。" % float(g.hearts.get(id,0)),14))
	var pane:=ScrollContainer.new(); pane.custom_minimum_size=Vector2(1080,350)
	var body:=VBoxContainer.new(); pane.add_child(body); g.modal_body.add_child(pane)
	body.add_child(small(g,"聊聊近况",func(): daily(id,g)))
	body.add_child(small(g,"想问你几件事",func(): show_topics(id,g)))
	var fresh: bool=str(g.flags.get("context_seen_"+id,""))!=context_key(g)
	body.add_child(small(g,"聊聊刚才的事"+(" · 新" if fresh else ""),func(): discuss(id,g)))
	body.add_child(small(g,"问问藏在心里的事",func():
		g.modal.hide()
		if not g.story_events.offer(id,g): g.show_dialog([[g.npc_life.PEOPLE[id].name,"眼下还没有别的事要托付你。得空再来坐坐，有话慢慢说。"]])))
	if quiz_due(id,g): body.add_child(small(g,"你有什么想问我的？",func(): show_quiz(id,g)))
	if id in ["medic","doctor"]: body.add_child(small(g,"治疗 · 每10点生命5文",func(): g.life.treatment(g,id)))
	if id in ["merchant","smith","leather","farmer","doctor"]:
		body.add_child(small(g,"办正事",func(): g.modal.hide(); g.flags["skip_npc_menu"]=true; g.interact(id)))
	g.modal_body.add_child(small(g,"关闭",func(): g.modal.hide()))
func daily(id: String,g: Node) -> void:
	var day: int=g.farming.day; var first: bool=int(g.flags.get("daily_"+id,-1))!=day
	var index: int=int(g.flags.get("daily_sequence_"+id,0))%15 if first else int(g.flags.get("daily_line_"+id,0))%15
	var key:=context_key(g); var lines: Array=[]
	if str(g.flags.get("context_seen_"+id,""))!=key: lines.append_array(context_lines(id,g))
	lines.append([g.npc_life.PEOPLE[id].name,DATA[id].daily[index]])
	g.modal.hide()
	g.show_dialog(lines,func():
		g.flags["context_seen_"+id]=key
		if int(g.flags.get("daily_"+id,-1))!=day:
			g.flags["daily_"+id]=day; g.flags["daily_line_"+id]=index
			g.flags["daily_sequence_"+id]=int(g.flags.get("daily_sequence_"+id,0))+1
			g.flags["chat_days_"+id]=int(g.flags.get("chat_days_"+id,0))+1
			var gain:=change(id,DAILY_GAIN,g); g.toast("交谈 · 亲密度 +%.1f" % gain)
		g.mark_dirty(); g.update_hud()
		if quiz_due(id,g): show_quiz(id,g))
func show_topics(id: String,g: Node) -> void:
	g.inventory_ui.prepare(g,g.npc_life.PEOPLE[id].name+" · 想问的事")
	var pane:=ScrollContainer.new(); pane.custom_minimum_size=Vector2(1080,400)
	var body:=VBoxContainer.new(); pane.add_child(body); g.modal_body.add_child(pane)
	for i in range(DATA[id].topics.size()):
		var topic: Array=DATA[id].topics[i]
		body.add_child(small(g,str(topic[0]),func():
			g.modal.hide(); g.show_dialog([["陆承安",topic[0]],[g.npc_life.PEOPLE[id].name,topic[1]]])))
	g.modal_body.add_child(small(g,"返回",func(): show_menu(id,g)))
func quiz_due(id: String,g: Node) -> bool:
	var last: int=int(g.flags.get("quiz_day_"+id,-999))
	return int(g.flags.get("chat_days_"+id,0))>=2 and g.farming.day-last>=3 and (g.farming.day+DATA.keys().find(id))%3==0
func show_quiz(id: String,g: Node) -> void:
	if not quiz_due(id,g): g.toast("对方暂时没有新的问题"); return
	cancel_question(); var token: int=serial
	var index: int=int(g.flags.get("quiz_sequence_"+id,0))%DATA[id].quiz.size()
	var q: Dictionary=DATA[id].quiz[index]; var order: Array=[0,1,2]
	var shift: int=(absi(hash(id))+index+int(g.farming.day/3))%3
	for i in range(shift): order.append(order.pop_front())
	pending={"npc":id,"token":token,"question":index,"day":g.farming.day}
	g.inventory_ui.prepare(g,g.npc_life.PEOPLE[id].name+" · 问你一件事")
	g.modal_body.add_child(g.label(q.question,16))
	g.modal_body.add_child(g.label("答对亲密度 +%.1f；每人至少间隔三个游戏日再提问。答错不扣分。" % QUIZ_GAIN,14))
	for i in order:
		var answer: int=i
		g.modal_body.add_child(small(g,str(q.answers[answer]),func(): answer_quiz(g,token,answer)))
	g.modal_body.add_child(small(g,"以后再聊",func(): cancel_question(); g.modal.hide()))
func answer_quiz(g: Node,token: int,answer: int) -> bool:
	if pending.is_empty() or int(pending.get("token",-1))!=token: return false
	var id: String=str(pending.npc); var index: int=int(pending.question)
	if answer<0 or answer>=3 or int(pending.day)!=g.farming.day or not quiz_due(id,g) or not g.gifting.near_npc(id,g): return false
	var q: Dictionary=DATA[id].quiz[index]; var correct: bool=answer==int(q.correct)
	cancel_question(); g.flags["quiz_day_"+id]=g.farming.day; g.flags["quiz_sequence_"+id]=int(g.flags.get("quiz_sequence_"+id,0))+1
	var gain: float=change(id,QUIZ_GAIN,g) if correct else 0.0
	g.modal.hide(); g.mark_dirty(); g.update_hud()
	g.show_dialog([[g.npc_life.PEOPLE[id].name,("记住了就好。亲密度 +%.1f。" % gain) if correct else "不要紧。记住，是“"+str(q.answers[q.correct])+"”，下回用得上。"]])
	return true

func reward_once(key: String,rewards: Dictionary,g: Node) -> Dictionary:
	var claimed: Dictionary=g.flags.get("affinity_rewards",{})
	if claimed.get(key,false): return {}
	claimed[key]=true; g.flags["affinity_rewards"]=claimed
	var actual: Dictionary={}; var notices: Array=[]
	for id in rewards:
		if not DATA.has(id): continue
		actual[id]=change(id,float(rewards[id]),g)
		notices.append("%s +%.1f" % [g.npc_life.PEOPLE[id].name,actual[id]])
	if not notices.is_empty(): g.toast("亲密度："+"、".join(notices))
	g.update_hud()
	return actual
