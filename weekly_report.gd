extends RefCounted
const COMMENTS=[
["忙了一周，成功让钱包保持了通风。","你不是没赚钱，你是在替铜钱保留自由。","甲壳虫看了你的账，都想给你掉两文低保。","钱包里没回声，可能是穷得太实心。","你与富贵之间，目前隔着整个东沙村。","铜钱没留下，风沙倒是包了周。","这周最大的积蓄，是下周再说的勇气。","账本翻得很响，内容安静得像没写。","财运路过你家，连门都没敲。","村口的风车都转了，你的资金还在原地。"],
["恭喜，已经从没钱，进化成了不太有钱。","这点家底，铁匠听完都得先把炉火调小。","钱是赚到了，就是每一文都像最后一文。","钱包终于鼓了，别急，可能是账单塞进去了。","铜钱肯来上班，就是还没答应加班。","比上不足，比昨天的空口袋强一点。","温饱在招手，富贵还装不认识你。","你这周的财力，主打一个能看见底。","买东西前的沉默，还是那么有分量。","财神留了脚印，没留住宿费。"],
["钱包终于有点分量，走路先别学康裕。","再努力一点，买铁锭就能少装一次路过。","你负责赚钱，商人负责研究你什么时候来。","铜钱开始排队，花钱的理由已经排到村口。","你离财大气粗，还差把问价的声音放大。","不错，穷日子已经开始跟你客气了。","钱袋有了重量，脑袋先别跟着膨胀。","这周不是风把钱吹来，是你把腿跑细了。","铁匠说欢迎常来，炉火笑得格外灿烂。","你刚摸到富贵的门槛，账单已经替你开门。"],
["你再这么赚，甲壳虫就要申请轮休了。","康裕看你的眼神，已经从乡亲变成了商机。","村长让你出人头地，没让你把公告栏盘包浆。","铜钱是不是长腿了，怎么全往你兜里跑。","这周的你不叫承安，叫商铺的流动粮仓。","甲壳虫负责刷新，你负责让它们没有明天。","财神来村里走访，先找你报了到。","别人接委托，你像在收购公告栏。","铁匠已经把你路过的脚步声当成开炉信号。","钱袋都快站起来了，你还说只做了点小任务。"]]
var active:=false
var phase:=0
var current: Dictionary={}
var rolling: Label
var elapsed:=0.0
var amount:=0
var settled:=false
var animation_button: Button
var g_ref: Node
func week(g: Node) -> int: return int((g.life.service_day(g)-1)/7)+1
func data(g: Node) -> Dictionary:
	if not g.flags.has("weekly_finance"):
		g.flags.weekly_finance={"closed":week(g)-1,"weeks":{},"history":[]}
	return g.flags.weekly_finance
func record(g: Node,delta: int,reason: String) -> void:
	if delta==0: return
	var s:=data(g); var key:=str(week(g))
	if not s.weeks.has(key): s.weeks[key]={"week":week(g),"income":0,"expense":0,"entries":[]}
	var row: Dictionary=s.weeks[key]
	if delta>0: row.income+=delta
	else: row.expense-=delta
	row.entries.append({"day":g.life.service_day(g),"time":g.time_minutes,"reason":reason,"amount":delta})
func close_due(g: Node) -> void:
	var s:=data(g); var last:=week(g)-1
	if int(s.closed)>=last: return
	var index:=int(s.closed)+1; var key:=str(index)
	current=s.weeks.get(key,{"week":index,"income":0,"expense":0,"entries":[]}).duplicate(true)
	current.net=int(current.income)-int(current.expense)
	var tier:=tier_for(int(current.income)); current.tier=tier
	current.comment=COMMENTS[tier][posmod(hash(str(current.week)+":"+str(current.income)),10)]
	active=true; g_ref=g; phase=0; show_page(g)
func tier_for(value: int) -> int: return 0 if value<200 else (1 if value<400 else (2 if value<700 else 3))
func tick(delta: float) -> void:
	if not active or not is_instance_valid(rolling) or phase>1: return
	elapsed+=delta
	var digits:=str(amount); var result: String=""
	for i in range(digits.length()):
		var lock_at:=0.45+(i+1)*0.20
		result+=digits[i] if elapsed>=lock_at else str(posmod(int(elapsed*45)+i*7,10))
	rolling.text=result+" 文"
	if elapsed>=0.45+digits.length()*0.20:
		settled=true
		if is_instance_valid(animation_button): animation_button.text="查看支出" if phase==0 else "查看收入趋势"
func advance(g: Node) -> void:
	if not settled:
		elapsed=10; tick(0); return
	phase+=1; show_page(g)
func breakdown(income: bool) -> String:
	var sums: Dictionary={}
	for entry in current.entries:
		if (int(entry.amount)>0)!=income: continue
		var key: String=str(entry.reason); sums[key]=int(sums.get(key,0))+absi(int(entry.amount))
	var lines: Array=[]
	for key in sums: lines.append("%s　%d文" % [key,sums[key]])
	return "\n".join(lines) if not lines.is_empty() else "本周没有这类铜钱变动。"
func show_page(g: Node) -> void:
	g.inventory_ui.prepare(g,"第%d周 · %s" % [current.week,"赚入账页" if phase==0 else ("支出账页" if phase==1 else "收入趋势")])
	g.modal.z_index=80
	rolling=null; animation_button=null
	if phase<2:
		amount=int(current.income if phase==0 else current.expense); elapsed=0; settled=false
		rolling=g.inventory_ui.jl("0 文",42); rolling.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; g.modal_body.add_child(rolling)
		var scroll:=ScrollContainer.new(); scroll.custom_minimum_size=Vector2(1040,220); scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
		var box:=VBoxContainer.new(); box.custom_minimum_size.x=1010; scroll.add_child(box); g.modal_body.add_child(scroll)
		box.add_child(g.inventory_ui.jl(breakdown(phase==0),16))
		for entry in current.entries:
			if (int(entry.amount)>0)!=(phase==0): continue
			box.add_child(g.inventory_ui.jl("第%d天 %02d:%02d　%s　%+d文" % [entry.day,int(entry.time)/60,int(entry.time)%60,entry.reason,entry.amount],13))
		var comment: Label=g.inventory_ui.jl(str(current.comment),16); comment.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT; comment.vertical_alignment=VERTICAL_ALIGNMENT_BOTTOM; comment.size_flags_vertical=Control.SIZE_EXPAND_FILL; g.modal_body.add_child(comment)
		animation_button=g.inventory_ui.jb("加速数字跳动",func(): advance(g)); g.modal_body.add_child(animation_button)
	else:
		var history: Array=data(g).history.duplicate(true); history.append(current)
		var chart=load("res://weekly_chart.gd").new(); chart.font=g.font; chart.history=history
		var row:=HBoxContainer.new(); g.modal_body.add_child(row)
		row.add_child(g.inventory_ui.jb("周总收入",func(): chart.set_metric("income")))
		row.add_child(g.inventory_ui.jb("周净收入",func(): chart.set_metric("net")))
		row.add_child(g.inventory_ui.jl("本周净收益：%+d文　当前持有：%d文" % [current.net,g.coins],16))
		g.modal_body.add_child(chart)
		var spacer:=Control.new(); spacer.size_flags_vertical=Control.SIZE_EXPAND_FILL; g.modal_body.add_child(spacer)
		var b: Button=g.inventory_ui.jb("继续旅程",func(): finish(g)); b.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN; g.modal_body.add_child(b)
func finish(g: Node) -> void:
	if not active or phase<2: return
	var s:=data(g)
	if int(s.closed)<int(current.week): s.history.append(current.duplicate(true)); s.closed=int(current.week)
	active=false; g.modal.z_index=0; g.modal.hide()
	close_due(g)
	if not active: g.life.finish_wake(g)
