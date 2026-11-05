extends RefCounted
const SIDE_NAMES := {"roof":"屋檐之下","scout":"一条退路","ledger":"多出的一文"}
const SIDE_GOALS := {"roof":["向郭成询问田伯旧军扣的来历","回去与田敬修谈谈爷爷"],"scout":["到关外枯树处记下回程路标","向孙怀济问问老韩的备用药包","返回与韩守义交谈"],"ledger":["将多出的一文交给杜芸娘核对","返回康裕处说明账目"]}
const SEARCH_GOALS := ["找裴肃领取第一次正式搜寻任务","随韩守义出关，检查旧水壶与遗物","回营向裴肃汇报两处发现","将线轴交冯厚辨认，核实记录","准备一份食物与一瓶药水，再找裴肃","到关外东侧山洞入口探查","返回营地，向裴肃汇报洞口发现","搜寻前段完成；狼人战与深入山洞待后续章节"]
func record(g: Node,text: String) -> void:
	var journal: Array=g.flags.get("journal",[])
	journal.append("第%d天 %02d:%02d · %s" % [g.farming.day,int(g.time_minutes)/60,int(g.time_minutes)%60,text])
	g.flags["journal"]=journal
func goal(g: Node) -> String:
	var key: String=str(g.flags.get("active_side",""))
	return "隐藏剧情 · "+SIDE_NAMES[key]+"\n"+SIDE_GOALS[key][clampi(int(g.flags.get("side_stage",0)),0,SIDE_GOALS[key].size()-1)] if SIDE_NAMES.has(key) else "暂无支线 · 同时只能接取一条"
func activate(g: Node,key: String) -> void:
	if not SIDE_NAMES.has(key): g.toast("这段人物支线尚未开放"); return
	if str(g.flags.get("active_side",""))!="": g.toast("先完成当前支线，再接取新的支线"); return
	if not g.relationships.hidden_ready(key,g): g.toast("还需要多些了解，才能听到这段往事"); return
	g.flags["active_side"]=key
	g.flags["side_stage"]=0
	record(g,"发现隐藏剧情："+str(SIDE_NAMES[key]))
	g.update_hud()
	g.mark_dirty()
func finish(g: Node,key: String,id: String) -> void:
	if g.flags.get("side_done_"+key,false): return
	g.flags["side_done_"+key]=true
	g.flags["active_side"]=""
	g.flags["side_stage"]=0
	g.relationships.change(id,g.relationships.SIDE_GAIN,g)
	if key=="scout": g.flags["han_sword_confession"]=true
	record(g,"完成隐藏剧情："+str(SIDE_NAMES[key]))
	g.toast("支线完成 · "+str(SIDE_NAMES[key]))
	g.update_hud()
	g.mark_dirty()
func side_talk(id: String,g: Node) -> bool:
	var active: String=str(g.flags.get("active_side",""))
	var stage: int=int(g.flags.get("side_stage",0))
	if active=="roof" and id=="smith" and stage==0:
		g.show_dialog([["郭成","这旧军扣我修过。陆定山背着田伯撤下来时，扣子都被血浸住了。"],["陆承安","田伯从来没说。"],["郭成","他欠你爷爷一条命，不等于你欠他一条。去听他自己说。"]],func(): g.flags["side_stage"]=1; record(g,"郭成认出陆定山的旧军扣"); g.mark_dirty())
		return true
	if active=="roof" and id=="elder" and stage==1:
		g.show_dialog([["田敬修","我看着你长大，不只是因为欠你爷爷。你头回喊我田伯时，我就舍不得这屋里再少一个人。"],["陆承安","那我回来，还坐原来那把椅子。"],["田敬修","椅子一直给你留着。"]],func(): finish(g,"roof","elder"))
		return true
	if active=="scout" and id=="medic" and stage==1:
		g.show_dialog([["孙怀济","他那包药总备双份，一份给自己，一份说是怕新兵忘了带。"],["陆承安","他嘴上总嫌我们拖后腿。"],["孙怀济","真嫌你们，他就不肯带路了。回来时你也数一数人，别总让他一个人记着。"]],func(): g.flags["side_stage"]=2; g.mark_dirty())
		return true
	if active=="scout" and id=="scout" and stage==2:
		g.show_dialog([["韩守义","枯树往西是关门，背风处能藏人。记住了？"],["陆承安","记住了。我也会数清回来的人。"],["韩守义","别只会说。哪天我回不来……算了，先把这趟路走好。"]],func(): finish(g,"scout","scout"))
		return true
	if active=="ledger" and id=="innkeeper" and stage==0:
		g.show_dialog([["杜芸娘","他多收你一文？这回倒不是。他夹在账里的那一文，是替一个没回来的脚夫还的饭钱。"],["陆承安","他怎么不说？"],["杜芸娘","康老板只肯让人知道他会算账。善心被人看见，他觉得往后不好还价。"]],func(): g.flags["side_stage"]=1; g.mark_dirty())
		return true
	if active=="ledger" and id=="merchant" and stage==1:
		g.show_dialog([["康裕","一文钱的事，你跑这么远？我可没说以后都赊账。"],["陆承安","那我只记这回。"],["康裕","……随你。账本别给我弄皱了。"]],func(): finish(g,"ledger","merchant"))
		return true
	return false
func offer(id: String,g: Node) -> bool:
	if str(g.flags.get("active_side",""))!="": return false
	var key: String={"elder":"roof","scout":"scout","merchant":"ledger"}.get(id,"")
	if key=="" or g.flags.get("side_done_"+key,false): return false
	if not g.relationships.hidden_ready(key,g): return false
	g.clear_modal(g.npc_life.PEOPLE[id].name+" · 未说完的话")
	var teasers: Dictionary={"roof":"田伯补衣时露出一枚旧军扣，与你爷爷遗物上的纹样相同。","scout":"韩守义想考考你，是否真的记得关外回来的路。","ledger":"康裕的账本里夹着一文钱，旁边记着杜家客栈。"}
	var intro: Label=g.label(teasers[key],16)
	intro.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	intro.custom_minimum_size.x=600
	g.modal_body.add_child(intro)
	g.modal_body.add_child(g.button("听他说下去",func(): g.modal.hide(); activate(g,key); g.show_dialog([[g.npc_life.PEOPLE[id].name,"这件事不急，你得空时替我看看。"]])))
	g.modal_body.add_child(g.button("以后再说",func(): g.modal.hide()))
	return true
func routine_menu(id: String,g: Node) -> void:
	g.relationships.show_menu(id,g)
func setup(g: Node) -> void:
	if g.scene_id=="field":
		g.actors.append({"id":"route_mark","name":"枯树下的回程路标","pos":Vector2(700,490)})
		if g.step>=11 and int(g.flags.get("search_stage",0))>=1:
			for entry in [["search_flask","刻名水壶与旧线轴",Vector2(1130,820)],["search_remains","秦二郎的遗物与遗骨",Vector2(1950,1120)]]:
				g.actors.append({"id":entry[0],"name":entry[1],"pos":entry[2]})
		if int(g.flags.get("search_stage",0))>=5: g.actors.append({"id":"cave_entry","name":"山洞入口 · 首次探查","pos":Vector2(2350,700)})
func interact(id: String,g: Node) -> bool:
	var stage: int=int(g.flags.get("search_stage",0))
	if id=="route_mark":
		if g.flags.get("active_side","")=="scout":
			g.show_dialog([["陆承安","枯树倒枝指向关门，石头背面能避风。这条退路，我记下了。"]],func(): g.flags["side_stage"]=1; record(g,"记下关外枯树路标"); g.mark_dirty())
		else: g.show_dialog([["路标","老斥候用小石块标出的回程方向。"]])
		return true
	if id in ["search_flask","search_remains"]:
		if g.flags.get(id,false):
			g.show_dialog([["已记录的线索","这里的发现已经记入任务与见闻，先去核实其他线索。"]])
			return true
		g.flags[id]=true
		if id=="search_flask": g.flags["roster_冯小川"]="发现遗物，生死未定"
		if id=="search_remains":
			g.flags["roster_秦二郎"]="确认遇难"
			g.show_dialog([["韩守义","姓名、旧伤和随身牌都对得上。秦二郎……这回总算有了确实的下落。"],["陆承安","登记的时候，别只写一个人数。把名字写全。"]])
		else: g.show_dialog([["韩守义","线轴是制革用的，壶上刻着小川。东西在这里，不等于人死在这里。带回去问冯厚。"]])
		record(g,"发现："+("秦二郎遗骨与遗物，确认遇难" if id=="search_remains" else "冯小川的刻名水壶和线轴，生死未定"))
		if g.flags.get("search_flask",false) and g.flags.get("search_remains",false): g.flags["search_stage"]=2; g.flags["escort_return"]=true
		g.update_hud()
		g.mark_dirty()
		return true
	if id=="captain" and g.step>=11:
		if stage==0:
			g.show_dialog([["裴肃","先查旧巡逻线。遗物、活人留下的标记，都要分别登记。韩守义带你去。"],["韩守义","这趟不比谁杀得多。找到东西先认位置，再动手。"]],func(): g.flags["search_stage"]=1; g.flags["patrol_active"]=true; record(g,"开始1.2：正式巡防，核实失踪线索"); g.setup_scene(); g.mark_dirty())
		elif stage==2:
			g.show_dialog([["裴肃","秦二郎列为遇难。冯小川暂记发现遗物，不填死亡。"],["陆承安","既然还不能确定，旧记录为什么写了失踪无望？"],["裴肃","那是前任的判断，不是证据。去找冯厚，再核一遍。"]],func(): g.flags["search_stage"]=3; g.flags["patrol_active"]=false; g.flags["escort_return"]=false; record(g,"回营汇报：区分确认遇难与尚无线索"); g.relationships.reward_once("patrol_report",{"scout":3.0,"captain":3.0},g); g.mark_dirty())
		elif stage==4:
			if int(g.inventory.get("回血药水",0))<1 or not has_food(g): g.show_dialog([["裴肃","洞口探查要带一份食物、一瓶药。没有补给就撤不回来。"]])
			else: g.show_dialog([["裴肃","痕迹还新。只看洞口，不深入。看清退路，回来再议。"]],func(): g.flags["search_stage"]=5; g.flags["patrol_active"]=true; g.setup_scene(); g.mark_dirty())
		elif stage==6:
			g.show_dialog([["裴肃","有人被拖进洞里，铁链上却有新结的布条……里面可能还有活人。"],["韩守义","入口窄，贸然进去只会把人堵在里面。先把这趟见到的记全，下一趟再定。"]],func(): g.flags["search_stage"]=7; g.flags["patrol_active"]=false; g.flags["escort_return"]=false; record(g,"洞口探查归营：发现囚禁痕迹，准备下一次搜寻"); g.relationships.reward_once("cave_report",{"scout":4.0,"captain":4.0},g); g.mark_dirty())
		else: g.show_dialog([["裴肃",SEARCH_GOALS[mini(stage,7)]]])
		return true
	if id=="leather" and stage==3:
		g.show_dialog([["冯厚","这是他的线轴。壶口这结，却不是他以前绑的。"],["陆承安","结上还有新布。有人用过它？"],["冯厚","我不敢说就是他。我只求你们，别替他把最后一页填了。"]],func(): g.flags["search_stage"]=4; record(g,"冯厚认出儿子的线轴；新布结提示近期有人活动"); g.mark_dirty())
		return true
	if id=="cave_entry":
		g.show_dialog([["洞口","岩壁上有被反复摩擦的铁链痕，缝隙里夹着新布。里面传来不止一种脚步声。"],["韩守义","先撤。能听见动静，至少比只有遗物好。别把这点希望断在莽撞上。"]],func(): g.flags["search_stage"]=6; g.flags["escort_return"]=true; record(g,"首次探洞：入口发现囚禁痕迹，依令撤回"); g.mark_dirty())
		return true
	return false
func has_food(g: Node) -> bool:
	for item in g.cooking.ENERGY:
		if int(g.inventory.get(item,0))>0: return true
	return false
func show_journal(g: Node) -> void:
	g.clear_modal("任务与见闻 · K")
	var scroll:=ScrollContainer.new()
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size=Vector2(630,440)
	var body:=VBoxContainer.new()
	scroll.add_child(body)
	g.modal_body.add_child(scroll)
	body.add_child(g.label("当前主线："+(g.OBJECTIVES[g.step] if g.step<11 else SEARCH_GOALS[mini(7,int(g.flags.get("search_stage",0)))]),16))
	body.add_child(g.label(goal(g),16))
	for i in range(mini(g.step,11)): body.add_child(g.label("已完成 · "+str(g.OBJECTIVES[i]),14))
	for entry in g.flags.get("journal",[]): body.add_child(g.label(str(entry),14))
	body.add_child(g.label("失踪名单",20))
	for name in g.npc_life.LOST: body.add_child(g.label(name+"："+str(g.flags.get("roster_"+name,"仍在搜寻")),14))
	for child in body.get_children():
		if child is Label: child.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; child.custom_minimum_size.x=600
	g.modal_body.add_child(g.button("关闭",func(): g.modal.hide()))
func draw(g: Node2D) -> void:
	for a in g.actors:
		if str(a.id).begins_with("search_"):
			g.draw_circle(a.pos,11,Color("ac9266"))
			g.draw_arc(a.pos,18,0,TAU,20,Color("d4c196"),2)
		if a.id=="route_mark":
			g.draw_line(a.pos+Vector2(-25,10),a.pos+Vector2(20,-30),Color("796147"),6)
		if a.id=="cave_entry":
			g.draw_circle(a.pos+Vector2(0,-30),75,Color("817661"))
			g.draw_circle(a.pos+Vector2(0,-20),53,Color("263731"))
