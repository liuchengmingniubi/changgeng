extends RefCounted
# Recruitment-only guidance. Existing saves beyond recruitment are never rolled back.
func ready(g: Node) -> bool:
	return str(g.equipment.worn.get("护甲",""))!="" and g.current_weapon_name()!=""
func objective(g: Node) -> String:
	if g.step==8:
		if not ready(g): return "出关准备\nI打开背包：穿戴护甲，持用武器\n准备好后找韩守义"
		if not g.flags.get("training_active",false): return "与韩守义交谈，开始关外实战"
		var count: int=int(g.flags.get("training_kills",0))
		return "随韩守义实战 %d / 3\n%s" % [count,["第一只：左键攻击，鼠标定方向","第二只：橙色预警后向侧面走","第三只：等待冲撞结束再反击"][mini(count,2)]]
	if g.step==9 and g.flags.get("recruit_flow",0)>=1:
		if not g.flags.get("training_returned",false): return "三只已清理：随老韩向西返回长城"
		if not g.flags.get("soldier_talk",false): return "前往食宿院，与石大川交谈"
		if not g.flags.get("medic_talk",false): return "在食宿院与军医孙怀济交谈"
		if not g.flags.get("roster_intro_seen",false): return "返回关门营地，查看失踪村民名单"
	return ""
func show_gear_guide(g: Node) -> void:
	g.clear_modal("出关前 · 整理军装")
	var text: String="护甲："+str(g.equipment.worn.get("护甲","未穿戴"))+"\n武器："+(g.current_weapon_name() if g.current_weapon_name()!="" else "未持用")
	text+="\nI打开背包，选择破旧铁甲，点击穿戴。\n选择旧铁剑点击使用；也可放在金框物品栏中选中。\n背包满时，军需会放到家中箱子。准备好再找老韩。"
	var note: Label=g.label(text,16); note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; note.custom_minimum_size.x=600
	g.modal_body.add_child(note)
	g.modal_body.add_child(g.button("打开背包",func(): g.show_inventory()))
	g.modal_body.add_child(g.button("准备好了再出发",func(): g.modal.hide()))
func show_roster(g: Node) -> void:
	if g.step==9 and g.flags.get("recruit_flow",0)>=1 and not g.flags.get("roster_intro_seen",false):
		g.show_dialog([["韩守义","这块板，你得仔细认认。大川的姐姐、冯厚的儿子、杜掌柜的弟弟……家里都还留着他们的东西。"],["陆承安","柳知微。她的名字还在。"],["韩守义","没有确凿消息，就不擅自划掉。有遗物也要核实是谁的、何时留下的，不能见了旧东西，就替一家人定生死。"],["陆承安","我想先找到她。可其他名字，也该有人认真找。"]],func():
			g.flags["roster_intro_seen"]=true
			g.story_events.record(g,"查看失踪名单：柳知微、石阿菱等十四人仍待核实")
			g.mark_dirty(); g.update_hud(); show_board(g))
	else: show_board(g)
func show_board(g: Node) -> void:
	g.inventory_ui.prepare(g,"长城驻军 · 失踪村民名单")
	g.modal_body.add_child(g.label("未发现消息不代表遇难；所有结论须有线索支持。",14))
	var pane:=ScrollContainer.new(); pane.custom_minimum_size=Vector2(1060,350)
	var list:=VBoxContainer.new(); pane.add_child(list); g.modal_body.add_child(pane)
	for name in g.npc_life.LOST:
		var relation: String={"柳知微":"与你一同长大","石阿菱":"石大川的姐姐","冯小川":"冯厚的儿子","杜仲平":"杜芸娘的弟弟"}.get(name,"")
		list.add_child(g.label(name+(" · "+relation if relation!="" else "")+"  ｜  "+str(g.flags.get("roster_"+name,"暂无确切消息")),16))
	var close: Button=g.inventory_ui.jb("记下名字，收起名单",func(): g.modal.hide(); g.check_members(); g.mark_dirty())
	close.add_theme_font_size_override("font_size",14); g.modal_body.add_child(close)
func configure_training(g: Node,reset: bool) -> void:
	if reset: g.combat.reset_enemies()
	g.combat.enemies.resize(3)
	for i in range(3):
		var e: Dictionary=g.combat.enemies[i]
		e.kind="甲壳虫"; e.max_hp=55; e.hp=mini(int(e.hp),55); e.home=Vector2(1100+i*400,800)
		if reset:
			e.pos=Vector2(1100+i*400,800); e.home=e.pos; e.hp=55
		if i<int(g.flags.get("training_kills",0)): e.hp=0; e.state="dead"
func returned(g: Node) -> void:
	if g.flags.get("training_done",false) and not g.flags.get("training_returned",false):
		g.flags["training_returned"]=true
		g.story_events.record(g,"实战训练归营：清理三只甲壳虫，准备认识同袍")
		g.update_hud(); g.mark_dirty()
