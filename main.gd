extends Node2D

var ground_layer: Node2D
var world_layout=preload("res://world_layout.gd").new()
var actor_visual=preload("res://actor_visual.gd").new()
var life=preload("res://life_cycle.gd").new()
var weekly=preload("res://weekly_report.gd").new()
var ledger_muted:=false
var coin_reason: String="其他收支"
var eating_item: String=""
var eating_time:=0.0
var eating_duration:=0.8
var commissions=preload("res://commissions.gd").new()
var relationships=preload("res://relationships.gd").new()
var gifting=preload("res://gifting.gd").new()
var game_options=preload("res://game_options.gd").new()
var audio_players: Array=[]
var sfx_cursor:=0
var hurt_flash:=0.0
var hero_flash_texture: Texture2D
var commerce=preload("res://commerce.gd").new()
var task_tracker=preload("res://task_tracker.gd").new()
var quest_heading: Button
var quest_scroll: ScrollContainer
var bag_stacks=preload("res://bag_stacks.gd").new()
var attack_release_required:=false
var interaction_target: String=""
var last_quickbar_name: String=""
var recruitment=preload("res://recruitment.gd").new()
var npc_life = preload("res://npc_life.gd").new()
var story_events = preload("res://story_events.gd").new()
var side_objective: Label
var frontier = preload("res://frontier.gd").new()
const CraftCatalog=preload("res://craft_catalog.gd")
var craft_ui=preload("res://craft_ui.gd").new()
var attack_previous_progress:=-1.0
var attack_duration:=0.5
var attack_buffer:=0.0
var swing_weapon: Dictionary={}
var swing_power:=18
var equipment = preload("res://equipment.gd").new()
var attack_power := 18
var defense := 0
var quickbar: Array=["","","","", "", ""]
var quickbar_index := 0
var quickbar_panel: VBoxContainer
var quickbar_slots: Array=[]
var quickbar_caption: Label
var inventory_ui = preload("res://inventory_ui.gd").new()
var cooking = preload("res://cooking.gd").new()
var farming = preload("res://farming.gd").new()
var camera_offset := Vector2.ZERO
const VILLAGE_GATE := Vector2(4080,1410)
const VILLAGE_GATE_RETURN := Vector2(4020,1410)
const VILLAGE_SIZE := Vector2(4344,3258)
const HOUSE_DATA := [
 ["陆承安家",Rect2(90,55,190,105),Vector2(178,176)],
 ["周满仓家",Rect2(325,27,145,95),Vector2(390,139)],
 ["石家",Rect2(560,45,110,80),Vector2(615,143)],
 ["柳知微家",Rect2(890,35,150,100),Vector2(950,153)],
 ["赵成器家",Rect2(1090,58,135,85),Vector2(1250,125)],
 ["孟有田家",Rect2(385,185,170,100),Vector2(465,300)],
 ["田敬修家",Rect2(635,115,290,150),Vector2(795,287)],
 ["长城驻军",Rect2(1015,150,270,120),Vector2(1135,300)],
 ["杜芸娘客栈",Rect2(160,335,240,145),Vector2(275,500)],
 ["康裕商铺",Rect2(455,330,210,145),Vector2(555,494)],
 ["郭成铁匠铺",Rect2(940,365,280,125),Vector2(1080,512)],
 ["冯厚作坊",Rect2(135,545,290,115),Vector2(275,682)],
 ["陶冬生家",Rect2(510,615,155,87),Vector2(580,724)],
 ["秦二郎家",Rect2(795,640,120,83),Vector2(850,745)],
 ["许素问医馆",Rect2(940,550,280,125),Vector2(1085,697)],
 ["曹顺与孟秋娘家",Rect2(80,750,245,100),Vector2(193,875)],
 ["郑绣娘家",Rect2(385,745,245,105),Vector2(495,873)],
 ["罗长生家",Rect2(865,760,180,90),Vector2(950,875)],
 ["白景和家",Rect2(1080,755,180,95),Vector2(1160,875)]
]
var combat = preload("res://combat.gd").new()
var hp := 100
var max_hp := 100
var level := 1
var xp := 0
var coins: int=0:
	set(value):
		var difference: int=value-coins
		coins=value
		if is_node_ready() and not ledger_muted: weekly.record(self,difference,coin_reason)
var invulnerability := 0.0
var potion_cooldown := 0.0
var food_cooldown := 0.0
var energy := 100.0
const MAX_ENERGY := 100.0
var regen_timer := 0.0
var energy_bar: ProgressBar
var energy_caption: Label
var time_minutes := 360.0
var attack_recovery := 0.0
var combo := 0
var combo_window := 0.0

const SAVE := "user://east_sand_save.json"
const OBJECTIVES := ["查看家中的储物箱，重读父母的遗书", "出门拜访村长田敬修", "拜访铁匠郭成，领取《材料大全》", "拜访许素问，领取《草药大全》", "向许素问领取教学草药", "打开背包，合成一瓶回血药水", "回村向田敬修告别", "沿东侧道路前往长城，向裴肃报名", "跟随韩守义出关，击杀三只普通甲壳虫", "认识同袍，并查看长城失踪名单", "向裴肃领取军籍腰牌"]
var npc_texture: Texture2D
var npc_regions := {"elder":Rect2(100,32,230,471),"smith":Rect2(446,24,288,481),"doctor":Rect2(841,32,203,474),"merchant":Rect2(1199,39,239,466),"captain":Rect2(85,513,264,489),"scout":Rect2(464,528,256,474),"soldier":Rect2(834,528,226,474),"medic":Rect2(1219,526,213,476)}
var sound_bank := {}
var sound_player: AudioStreamPlayer
var step_clock := 0.0
var sound_enabled := true
var scene_art := {}
var hero_texture: Texture2D
var hero_regions := [Rect2(57,49,342,855), Rect2(458,49,326,852), Rect2(830,47,309,862), Rect2(1249,47,311,862)]
var font: Font
var scene_id := "home"
var player := Vector2(680, 510)
var step := 0
var inventory := {}
var flags := {}
var hearts := {}
var plants := []
var obstacles: Array[Rect2] = []
var actors := []
var elapsed := 0.0
var attack_time := 0.0
var strikes := 0
var facing := Vector2.RIGHT
var dialog_lines: Array = []
var dialog_index := 0
var dialog_callback := Callable()
var ui: CanvasLayer
var hud: Label
var objective: Label
var location_label: Label
var prompt: Label
var toast_panel: PanelContainer
var toast_label: Label
var toast_time := 0.0
var modal: PanelContainer
var modal_body: VBoxContainer
var dialogue_panel: PanelContainer
var dialogue_text: Label
var name_label: Label
var transition := false
var inventory_open := false
var movement_time := 0.0
var walk_blend := 0.0
var actual_walk := false
var inventory_page := 0
const ATTACK_DURATION := 0.42

func _ready() -> void:
	var local_font := FontFile.new()
	var font_error := local_font.load_dynamic_font("res://assets/font.otf")
	if font_error == OK:
		font = local_font
	else:
		var system_font := SystemFont.new()
		system_font.font_names = PackedStringArray(["Microsoft YaHei", "Noto Sans CJK SC", "sans-serif"])
		font = system_font
	RenderingServer.set_default_clear_color(Color("18252a"))
	for art_id in ["hero"]:
		var picture := Image.new()
		if picture.load("res://assets/art/"+art_id+".png") == OK:
			if art_id == "hero":
				hero_texture = ImageTexture.create_from_image(picture)
				var white: Image=picture.duplicate(); white.adjust_bcs(1.0,0.0,0.0); white.adjust_bcs(2.0,1.0,1.0); hero_flash_texture=ImageTexture.create_from_image(white)
			else: scene_art[art_id] = ImageTexture.create_from_image(picture)
	var npc_image:=Image.new()
	if npc_image.load("res://assets/art/npcs.png")==OK:
		for yy in range(npc_image.get_height()):
			for xx in range(npc_image.get_width()):
				var color:=npc_image.get_pixel(xx,yy)
				if color.a<0.95: npc_image.set_pixel(xx,yy,Color(0,0,0,0))
		npc_texture=ImageTexture.create_from_image(npc_image)
	sound_player=AudioStreamPlayer.new()
	sound_player.volume_db=-9
	add_child(sound_player)
	for sound_name in ["step","open","pickup","craft","sword","hit","hurt"]:
		var audio_path: String="res://assets/audio/"+sound_name+".wav"
		if FileAccess.file_exists(audio_path):
			var bytes:=FileAccess.get_file_as_bytes(audio_path)
			var stream:=AudioStreamWAV.new()
			stream.format=AudioStreamWAV.FORMAT_16_BITS
			stream.mix_rate=22050
			stream.data=bytes.slice(44)
			sound_bank[sound_name]=stream
	game_options.setup(self)
	actor_visual.setup()
	ground_layer=preload("res://world_ground.gd").new(); ground_layer.game=self; ground_layer.z_index=-100; add_child(ground_layer)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	relationships.initialize_new(self)
	build_ui()
	for child in ui.get_children():
		if child is PanelContainer: preload("res://jade_theme.gd").install(child)
	farming.initialize()
	life.initialize(self)
	weekly.data(self)
	combat.reset_enemies()
	setup_scene()
	if FileAccess.file_exists(SAVE):
		show_dialog([["东沙旧事", "发现已有旅程。按 F5 继续存档，或从此刻重新开始。"]])
	else:
		show_dialog([["第一章 · 魔怪危机", "东沙村，清晨。\n风掠过屋檐，你在熟悉的房间醒来。今天，你打算去长城报名。"], ["陆承安", "先收拾行李，再去看看田伯。他多半又在担心我。\n\nWASD 移动 · F 交互 · I 背包 · J 人物 · Esc 关闭界面"]])

func panel_style(bg: String,border: String="a98a50") -> StyleBoxFlat:
	var style=preload("res://jade_theme.gd").card(bg,border,10)
	style.content_margin_left=18; style.content_margin_right=18; style.content_margin_top=12; style.content_margin_bottom=12
	return style

func label(text_value: String, size: int = 18, color: String = "244b3d") -> Label:
	var l := Label.new()
	l.text = text_value
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", Color("72572f" if color=="efc888" else color))
	return l

func button(text_value: String, callback: Callable) -> Button:
	var b := Button.new()
	b.text = text_value
	b.add_theme_font_override("font", font)
	b.add_theme_font_size_override("font_size", 18)
	b.custom_minimum_size.y = 42
	for state in ["normal","hover","pressed","disabled"]:
		b.add_theme_stylebox_override(state,panel_style("d7dfbe" if state=="normal" else ("e8e8ca" if state=="hover" else "b9cbaa")))
	for state in ["font_color","font_hover_color","font_pressed_color"]: b.add_theme_color_override(state,Color("244b3d"))
	b.add_theme_color_override("font_disabled_color",Color("858c77"))
	b.pressed.connect(callback)
	return b

func build_ui() -> void:
	ui = CanvasLayer.new()
	add_child(ui)
	var top := PanelContainer.new()
	top.position = Vector2(24, 20)
	top.size = Vector2(1232, 90)
	top.add_theme_stylebox_override("panel", panel_style("1d3c35f5","b99b5a"))
	ui.add_child(top)
	var hud_rows:=VBoxContainer.new()
	top.add_child(hud_rows)
	hud = label("", 16,"efe2ba")
	hud_rows.add_child(hud)
	var energy_row:=HBoxContainer.new()
	hud_rows.add_child(energy_row)
	energy_bar=ProgressBar.new()
	energy_bar.max_value=MAX_ENERGY
	energy_bar.show_percentage=false
	energy_bar.custom_minimum_size=Vector2(180,16)
	energy_bar.add_theme_stylebox_override("background",panel_style("aab79a"))
	energy_bar.add_theme_stylebox_override("fill",panel_style("62885b"))
	energy_row.add_child(energy_bar)
	energy_caption=label("",14,"c5d7ba")
	energy_row.add_child(energy_caption)
	var quest := PanelContainer.new()
	quest.position = Vector2(24, 116)
	quest.custom_minimum_size = Vector2(270, 146)
	quest.add_theme_stylebox_override("panel", panel_style("d7dfc4f4","9e844f"))
	ui.add_child(quest)
	var shell:=VBoxContainer.new(); quest.add_child(shell)
	quest_heading=button("1.1 参军 ▾",func():
		quest_scroll.visible=not quest_scroll.visible
		flags["tasks_collapsed"]=not quest_scroll.visible
		update_hud(); mark_dirty())
	quest_heading.add_theme_font_size_override("font_size",14); shell.add_child(quest_heading)
	quest_scroll=ScrollContainer.new(); quest_scroll.custom_minimum_size=Vector2(250,360); quest_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	shell.add_child(quest_scroll)
	var box:=VBoxContainer.new(); box.custom_minimum_size.x=230; box.size_flags_horizontal=Control.SIZE_EXPAND_FILL; quest_scroll.add_child(box)
	box.add_child(label("主线",14,"72572f"))
	objective=label("",14); objective.custom_minimum_size.x=230; objective.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; box.add_child(objective)
	box.add_child(HSeparator.new()); box.add_child(label("支线",14,"72572f"))
	side_objective=label("",13); side_objective.custom_minimum_size.x=230; side_objective.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; box.add_child(side_objective)
	location_label = label("", 16, "365944")
	location_label.position = Vector2(32, 595)
	ui.add_child(location_label)
	prompt = label("", 19, "fff0c9")
	var prompt_card:=PanelContainer.new(); prompt_card.position=Vector2(410,684); prompt_card.custom_minimum_size=Vector2(520,44)
	prompt_card.visible=false
	prompt_card.add_theme_stylebox_override("panel",panel_style("203e38e8","a78c53")); ui.add_child(prompt_card); prompt_card.add_child(prompt)
	toast_panel=PanelContainer.new(); toast_panel.position=Vector2(370,102); toast_panel.z_index=100; toast_panel.mouse_filter=Control.MOUSE_FILTER_IGNORE
	toast_panel.add_theme_stylebox_override("panel",panel_style("e0e5cdf8","bd975c")); ui.add_child(toast_panel)
	toast_label=label("",16,"244b3d"); toast_label.custom_minimum_size.x=500; toast_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; toast_label.mouse_filter=Control.MOUSE_FILTER_IGNORE; toast_panel.add_child(toast_label); toast_panel.hide()
	var help := label("WASD 移动    F 交互 · Tab切换目标    左键 攻击    I 背包 / 合成    J 人物    K 任务记录    M 村庄地图    F5 读档    F6 存档", 14, "b8b9a4")
	help.position = Vector2(200, 770)
	ui.add_child(help)
	dialogue_panel = PanelContainer.new()
	dialogue_panel.position = Vector2(120, 534)
	dialogue_panel.size = Vector2(1040, 218)
	dialogue_panel.add_theme_stylebox_override("panel", panel_style("e0e5cdfb", "c09a60"))
	ui.add_child(dialogue_panel)
	var db := VBoxContainer.new()
	dialogue_panel.add_child(db)
	name_label = label("", 22, "72572f")
	db.add_child(name_label)
	dialogue_text = label("", 20)
	dialogue_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_text.custom_minimum_size = Vector2(990, 112)
	db.add_child(dialogue_text)
	db.add_child(label("F / Enter / 点击继续", 13, "506e56"))
	dialogue_panel.hide()
	modal = PanelContainer.new()
	modal.position = Vector2(300, 100)
	modal.size = Vector2(680, 620)
	modal.add_theme_stylebox_override("panel", panel_style("e0e5cdfc"))
	ui.add_child(modal)
	modal_body = VBoxContainer.new()
	modal.add_child(modal_body)
	modal.hide()
	modal.visibility_changed.connect(func():
		if not modal.visible: gifting.cancel(); relationships.cancel_question())
	quickbar_panel=VBoxContainer.new()
	quickbar_panel.position=Vector2(1178,156)
	quickbar_panel.add_theme_constant_override("separation",5)
	ui.add_child(quickbar_panel)
	quickbar_panel.add_child(label("物品栏",14,"efcf83"))
	for i in range(6):
		var index: int=i
		var slot=load("res://item_slot.gd").new()
		slot.icon_font=font
		slot.slot_minimum=Vector2(64,58)
		slot.golden=true
		slot.jade=true
		slot.pressed.connect(func(): quickbar_index=index; refresh_quickbar(); mark_dirty())
		slot.context_requested.connect(func(): quickbar_index=index; use_quickbar_item())
		quickbar_slots.append(slot)
		quickbar_panel.add_child(slot)
	quickbar_caption=label("滚轮切换\n右键使用",12,"355443")
	quickbar_panel.add_child(quickbar_caption)
	update_hud()

func migrate_bag_capacity() -> void:
	var keys:=[]
	for key in inventory:
		if int(inventory[key])>0 and not str(key).contains("《"): keys.append(key)
	if keys.size()<=42: return
	var storage: Dictionary=flags.get("storage",{})
	var pending: Dictionary=flags.get("pending_items",{})
	for i in range(42,keys.size()):
		var key: String=str(keys[i])
		if storage.has(key) or storage.size()<300: storage[key]=int(storage.get(key,0))+int(inventory[key])
		else: pending[key]=int(pending.get(key,0))+int(inventory[key])
		inventory.erase(key)
	flags["storage"]=storage
	flags["pending_items"]=pending
	toast("超出新布局容量的旧物品已保留到家中箱子或暂存区")

func ensure_quickbar() -> void:
	if flags.has("quickbar"):
		var saved: Array=flags.quickbar
		for i in range(6): quickbar[i]=str(saved[i]) if i<saved.size() else ""
	if not flags.get("quickbar_initialized",false):
		var keys:=[]
		for key in inventory:
			if int(inventory[key])>0 and not str(key).contains("《"): keys.append(key)
		for i in range(6): quickbar[i]=str(keys[i]) if i<keys.size() else ""
		if not keys.is_empty(): flags["quickbar_initialized"]=true
	var used:=[]
	for i in range(6):
		if quickbar[i] in used: quickbar[i]=""
		elif str(quickbar[i])!="": used.append(quickbar[i])
	flags["quickbar"]=quickbar.duplicate()

func assign_quickbar(index: int,key: String) -> void:
	if index<0 or index>=6: return
	if key!="" and (not inventory.has(key) or int(inventory[key])<=0): return
	var old: String=str(quickbar[index])
	var previous:=quickbar.find(key) if key!="" else -1
	if previous>=0: quickbar[previous]=old
	quickbar[index]=key
	if key!="": bag_stacks.merge_for_hot(self,key)
	flags["quickbar_edited"]=true
	flags["quickbar_initialized"]=true
	flags["quickbar"]=quickbar.duplicate()
	refresh_quickbar()
	mark_dirty()

func refresh_quickbar() -> void:
	if quickbar_slots.is_empty(): return
	ensure_quickbar()
	bag_stacks.sync(self)
	var chosen: String=str(quickbar[quickbar_index])
	if CraftCatalog.WEAPONS.has(chosen) and int(inventory.get(chosen,0))>0 and flags.get("held_weapon","")!=chosen:
		flags["held_weapon"]=chosen
		recalculate_stats()
	for i in range(6):
		var slot=quickbar_slots[i]
		var key: String=str(quickbar[i])
		slot.item_name=key if int(inventory.get(key,0))>0 else ""
		slot.quantity=bag_stacks.hot_count(key,self,false)
		slot.cooldown_seconds=potion_cooldown if key=="回血药水" else 0.0
		slot.selected=i==quickbar_index
		slot.tooltip_text=inventory_ui.tooltip(key,slot.quantity,self) if slot.item_name!="" else "空格"
		slot.queue_redraw()
	var selected_name: String=str(quickbar[quickbar_index])
	if selected_name!=last_quickbar_name:
		if last_quickbar_name!="" and CraftCatalog.WEAPONS.has(selected_name): toast("切换武器："+selected_name)
		last_quickbar_name=selected_name
	quickbar_caption.text=selected_name+"\n滚轮切换\n右键使用" if selected_name!="" else "滚轮切换\n右键使用"
	quickbar_panel.visible=not modal.visible and not dialogue_panel.visible

func use_quickbar_item() -> void:
	var key: String=str(quickbar[quickbar_index])
	if int(inventory.get(key,0))<=0: toast("选中的物品栏为空"); return
	if CraftCatalog.WEAPONS.has(key): wield(key)
	elif equipment.ITEMS.has(key): equipment.wear(key,self)
	elif key=="回血药水": use_potion()
	elif key=="肥料": farming.fertilize(self)
	elif cooking.ENERGY.has(key): cooking.eat(key,self)
	elif key=="锄头" or key in farming.CROPS:
		var target:=nearest()
		if not target.is_empty() and str(target.id).begins_with("farm_"):
			var index:=int(str(target.id).trim_prefix("farm_"))
			if key=="锄头" and not farming.plots[index].tilled: farming.work(index,self)
			elif key in farming.CROPS: farming.plant(index,key,self)
			else: toast("这块地已经开垦，可按F继续操作")
		else: toast("靠近家中农田使用")
	else: toast(key+"：当前可携带，暂无直接使用动作")

func update_hud() -> void:
	hud.text = "长庚 · 东沙旧事    陆承安 Lv.%d    生命 %d/%d    经验 %d/%d    铜钱 %d    药水[1] ×%d  第%d天" % [level,hp,max_hp,xp,xp_required(),coins,int(inventory.get("回血药水",0)),farming.day]
	hud.text+="  %02d:%02d" % [int(time_minutes)/60,int(time_minutes)%60]
	if is_instance_valid(energy_bar):
		energy_bar.value=energy
		energy_caption.text="精力 %d/100 · %s   食物无冷却 · 药水冷却 %ds" % [int(energy),"缓慢回血中" if energy>=70 and hp<max_hp else "精力达到70%时缓慢回血",int(ceil(potion_cooldown))]
	objective.text=task_tracker.main_text(self)
	if is_instance_valid(side_objective): side_objective.text=task_tracker.side_text(self)+commissions.summary(self)
	if is_instance_valid(quest_heading):
		quest_heading.text=("1.1 参军" if step<11 else "1.2 搜寻")+(" [+]" if flags.get("tasks_collapsed",false) else " [-]")
		quest_scroll.visible=not flags.get("tasks_collapsed",false)
	location_label.text = {"clinic":"东沙村 / 许氏医馆","home":"东沙村 / 陆家旧宅", "village":"东沙村 / 村中", "wall":"东境长城 / 驻军关口","field":"长城外 / 浅层沙地","barracks":"东境长城 / 食宿院","mill":"东沙村 / 南侧磨坊"}.get(scene_id, "")
	if scene_id.begins_with("home_"): location_label.text="东沙村 / "+str(npc_life.PEOPLE[scene_id.trim_prefix("home_")].name)+"的住处"

func setup_scene() -> void:
	if scene_id=="clinic":
		actors=[{"id":"clinic_exit","name":"离开医馆","pos":Vector2(640,615)},{"id":"clinic_bed","name":"医馆床铺","pos":Vector2(440,395)},{"id":"clinic_treatment","name":"请许素问治疗","pos":Vector2(820,470)}]
		obstacles.assign([Rect2(320,210,165,145),Rect2(820,220,100,130)])
		world_layout.setup(self); npc_life.setup(self); update_hud(); update_camera(true); queue_redraw(); return
	actors.clear()
	obstacles.clear()
	if scene_id == "home":
		obstacles = [Rect2(365,235,115,150),Rect2(870,250,100,60),Rect2(640,270,165,65),Rect2(810,465,140,70),Rect2(305,200,50,180)]
		actors = [{"id":"chest","name":"家中储物箱","pos":Vector2(905,285)}, {"id":"letter","name":"父母的遗书","pos":Vector2(710,333)}, {"id":"bed","name":"休息与保存","pos":Vector2(440,395)}, {"id":"exit","name":"出门","pos":Vector2(640,615)}, {"id":"kitchen","name":"灶台 · 打开合成大全","pos":Vector2(835,535)}]
	elif scene_id.begins_with("home_"):
		obstacles=[Rect2(320,220,160,130),Rect2(820,220,110,125)]
		var resident: String=scene_id.trim_prefix("home_")
		actors=[{"id":"resident_exit","name":"返回村庄","pos":Vector2(640,615)}]
	elif scene_id=="mill":
		obstacles=[Rect2(310,220,140,90),Rect2(810,250,130,110)]
		actors=[{"id":"mill_work","name":"周满仓 · 付费磨面","pos":Vector2(850,410)},{"id":"mill_exit","name":"返回公共农田","pos":Vector2(640,615)}]
	elif scene_id == "village":
		for house in HOUSE_DATA:
			var r: Rect2=house[1]
			obstacles.append(Rect2(r.position*2,r.size*2))
			actors.append({"id":"house_"+str(HOUSE_DATA.find(house)),"name":str(house[0]),"pos":house[2]*2})
		# The Great Wall has an open passage at the eastern gate.
		obstacles.append(Rect2(2540,0,260,800))
		obstacles.append(Rect2(2640,1000,160,1172))
		obstacles.append(Rect2(1355,1000,220,110))
		actors.append_array([
			{"id":"home","name":"返回家中","pos":Vector2(356,352)},
			{"id":"elder","name":"田敬修 · 村长","pos":Vector2(1580,610)},
			{"id":"smith","name":"郭成 · 铁匠","pos":Vector2(2140,1040)},
			{"id":"doctor","name":"许素问 · 村医","pos":Vector2(2130,1410)},
			{"id":"merchant","name":"康裕 · 商人","pos":Vector2(1100,1020)},
			{"id":"wall","name":"前往长城关口 · F进入","pos":VILLAGE_GATE/world_layout.SCALE},
			{"id":"south_gate","name":"村庄南门","pos":Vector2(1440,1980)},
			{"id":"commission_board","name":"公告栏 · 委托／悬赏","pos":commissions.BOARD_POS/world_layout.SCALE},
			{"id":"mill_entry","name":"周家磨坊 · 进入","pos":cooking.MILL_POS/world_layout.SCALE},
			{"id":"well","name":"村井 · 补充灌溉用水","pos":Vector2(1200,1090)},
			{"id":"farmer","name":"周满仓 · 周家磨坊","pos":cooking.MILL_POS/world_layout.SCALE}])
		for i in range(farming.plots.size()):
			actors.append({"id":"farm_"+str(i),"name":"农田 · F开垦/播种/浇水/收获","pos":farming.plots[i].pos/world_layout.SCALE})
	elif frontier.SIZES.has(scene_id):
		frontier.setup(self)
	world_layout.setup(self)
	story_events.setup(self)
	npc_life.setup(self)
	update_hud()
	update_camera(true)
	queue_redraw()
	if scene_id=="field" and not flags.get("field_tutorial",false):
		flags["field_tutorial"]=true
		show_dialog([["关外巡防","甲壳虫正面甲壳较硬。看见前方橙色预警后向侧面走开，趁冲撞结束时反击。\n左键或按住连击；数字1喝药。开局没有闪避。\n家中或营房休息可恢复生命；关外草药稀少，每三日恢复一次。"]])

func _process(delta: float) -> void:
	weekly.tick(delta)
	var ui_open: bool=modal.visible or dialogue_panel.visible or transition
	if ui_open:
		attack_release_required=true
		attack_buffer=0
	elif attack_release_required and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT): attack_release_required=false
	refresh_quickbar()
	update_camera(false,delta)
	elapsed += delta
	step_clock=maxf(0,step_clock-delta)
	if actual_walk and step_clock<=0 and not dialogue_panel.visible and not modal.visible:
		play_sound("step")
		step_clock=0.36
	if not dialogue_panel.visible and not modal.visible and not transition:
		attack_previous_progress=1.0-attack_time/attack_duration if attack_time>0 else -1.0
		var old_attack_time := attack_time
		attack_time = maxf(0, attack_time-delta)
		if old_attack_time>0 and attack_time<=0: attack_recovery=0.04
		attack_recovery=maxf(0,attack_recovery-delta)
		combo_window=maxf(0,combo_window-delta)
		attack_buffer=maxf(0,attack_buffer-delta)
	walk_blend = move_toward(walk_blend,1.0 if actual_walk else 0.0,delta*9)
	actual_walk = false
	toast_time = maxf(0, toast_time-delta)
	toast_label.visible = toast_time > 0
	toast_panel.visible = toast_time>0 and not transition
	if not dialogue_panel.visible and not modal.visible and not transition:
		tick_clock(delta)
		if life.waking: queue_redraw(); return
		if eating_time>0: tick_eating(delta)
		npc_life.tick(delta,self)
		invulnerability=maxf(0,invulnerability-delta)
		hurt_flash=maxf(0,hurt_flash-delta)
		potion_cooldown=maxf(0,potion_cooldown-delta)
		food_cooldown=maxf(0,food_cooldown-delta)
		combat.tick(delta,self)
		if dialogue_panel.visible:
			queue_redraw()
			return
		if (Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or attack_buffer>0) and attack_time<=0 and attack_recovery<=0 and not pointer_over_ui() and not attack_release_required: start_attack()
		var v := Vector2(float(Input.is_physical_key_pressed(KEY_D))-float(Input.is_physical_key_pressed(KEY_A)),float(Input.is_physical_key_pressed(KEY_S))-float(Input.is_physical_key_pressed(KEY_W))).normalized()
		if v != Vector2.ZERO:
			if attack_time<=0: facing = v
			movement_time += delta
		var old_position := player
		player=sweep_move(player,v*(125 if attack_time>0 else 175)*(0.6 if energy<=0 else 1.0)*delta,movement_bounds())
		actual_walk = player.distance_to(old_position)>0.01
		tick_energy(delta,actual_walk)
		var near = nearest()
		prompt.text = interaction_prompt(near) if not near.is_empty() else ""
	else:
		prompt.text = ""
	prompt.get_parent().visible=prompt.text!=""
	queue_redraw()

func movement_bounds() -> Rect2:
	if scene_id=="village": return Rect2(40,40,VILLAGE_SIZE.x-80,VILLAGE_SIZE.y-80)
	if frontier.SIZES.has(scene_id): return Rect2(Vector2(35,35),frontier.SIZES[scene_id]-Vector2(70,70))
	return Rect2(275,200,725,430) if scene_id in ["home","mill","clinic"] or scene_id.begins_with("home_") else Rect2(24,105,1230,635)

func update_camera(snap: bool=false,delta: float=0.0) -> void:
	var target:=Vector2.ZERO
	if scene_id=="village":
		target=Vector2(clampf(player.x-640,0,VILLAGE_SIZE.x-1280),clampf(player.y-400,0,VILLAGE_SIZE.y-800))
	if frontier.SIZES.has(scene_id): target=frontier.camera_target(self)
	camera_offset=(target if snap else camera_offset.lerp(target,minf(1,delta*9))).round()
	position=-camera_offset

func sweep_move(origin: Vector2,offset: Vector2,bounds: Rect2) -> Vector2:
	var parts:=maxi(1,int(ceil(offset.length()/4.0))); var each:=offset/parts; var result:=origin
	for i in range(parts):
		var trial:=result+Vector2(each.x,0)
		if bounds.has_point(trial) and not blocked(trial): result.x=trial.x
		trial=result+Vector2(0,each.y)
		if bounds.has_point(trial) and not blocked(trial): result.y=trial.y
	return result

func blocked(p: Vector2) -> bool:
	for r in obstacles:
		if r.grow(9).has_point(p):
			return true
	return false

func nearby_targets() -> Array:
	var found: Array=[]
	for a in actors:
		if a.id!="house_0" and player.distance_to(a.pos)<(38 if str(a.id).begins_with("farm_") else 68): found.append(a)
	found.sort_custom(func(a,b):
		var da: float=player.distance_to(a.pos); var db: float=player.distance_to(b.pos)
		return str(a.id)<str(b.id) if absf(da-db)<0.01 else da<db)
	return found

func nearest() -> Dictionary:
	var targets:=nearby_targets()
	for a in targets:
		if str(a.id)==interaction_target: return a
	interaction_target=str(targets[0].id) if not targets.is_empty() else ""
	return targets[0] if not targets.is_empty() else {}

func cycle_target() -> void:
	var targets:=nearby_targets()
	if targets.is_empty(): interaction_target=""; return
	var index: int=-1
	for i in range(targets.size()):
		if str(targets[i].id)==interaction_target: index=i
	interaction_target=str(targets[(index+1)%targets.size()].id)
	prompt.text=interaction_prompt(nearest())

func interaction_prompt(a: Dictionary) -> String:
	var id: String=str(a.id)
	var action: String="交互"
	if npc_life.PEOPLE.has(id): action="交谈／赠送" if gifting.held_item(self)!="" else "交谈"
	elif id=="chest": action="打开"
	elif id=="roster" or id=="letter": action="查看"
	elif id.begins_with("field_herb_") or id.begins_with("herb_"): action="采集"
	elif id in ["bed","army_bed"]: action="休息"
	elif id.begins_with("farm_"): action="耕作"
	elif id in ["gate","return_gate","wall","village","barracks_entry","barracks_exit","exit","home"]: action="前往"
	return "F %s · %s%s" % [action,a.name,"  [Tab切换目标]" if nearby_targets().size()>1 else ""]

func pointer_over_ui() -> bool:
	if modal.visible or dialogue_panel.visible or transition: return true
	var control: Control=get_viewport().gui_get_hovered_control()
	while control!=null:
		if control.get_parent()==ui: return true
		control=control.get_parent() as Control
	return false

func _input(event: InputEvent) -> void:
	if weekly.active: return
	if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT and dialogue_panel.visible:
		attack_release_required=true
		next_dialog()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT and pointer_over_ui():
		attack_release_required=true
		attack_buffer=0
	if event is InputEventMouseButton and event.pressed and not modal.visible and not dialogue_panel.visible and not transition:
		if event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
			quickbar_index=posmod(quickbar_index+(-1 if event.button_index==MOUSE_BUTTON_WHEEL_UP else 1),6)
			refresh_quickbar()
			mark_dirty()
			get_viewport().set_input_as_handled()
			return
		if event.button_index==MOUSE_BUTTON_RIGHT and not pointer_over_ui():
			use_quickbar_item()
			get_viewport().set_input_as_handled()
			return

func _unhandled_input(event: InputEvent) -> void:
	if weekly.active: return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			if dialogue_panel.visible and name_label.text in ["休息至次日","夜间休息","营房休息"]:
				dialogue_panel.hide()
				dialog_callback=Callable()
			elif modal.visible:
				modal.hide()
			elif not dialogue_panel.visible:
				show_menu()
			return
		if dialogue_panel.visible:
			if event.keycode in [KEY_F, KEY_ENTER, KEY_SPACE]:
				next_dialog()
			return
		if event.keycode == KEY_I:
			if modal.visible: modal.hide()
			else: show_inventory()
		elif event.keycode == KEY_J: show_people()
		elif event.keycode == KEY_K: story_events.show_journal(self)
		elif event.keycode == KEY_M: show_village_map()
		elif event.keycode == KEY_1 and not modal.visible: use_potion()
		elif event.keycode == KEY_2 and not modal.visible: cooking.eat("馒头",self)
		elif event.keycode == KEY_3 and not modal.visible: cooking.eat("面条",self)
		elif event.keycode == KEY_F6:
			if not life.waking and save_game(): toast("旅程已保存")
		elif event.keycode == KEY_F5: load_game()
		elif event.keycode == KEY_TAB and not modal.visible: cycle_target()
		elif event.keycode == KEY_F and not modal.visible:
			var a := nearest()
			if not a.is_empty(): interact(a.id)
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if dialogue_panel.visible: next_dialog()
		elif not modal.visible: start_attack()

func current_weapon_name() -> String:
	var selected: String=str(quickbar[quickbar_index])
	if CraftCatalog.WEAPONS.has(selected) and int(inventory.get(selected,0))>0: return selected
	var held: String=str(flags.get("held_weapon",""))
	return held if int(inventory.get(held,0))>0 and CraftCatalog.WEAPONS.has(held) else ""

func current_weapon() -> Dictionary:
	return CraftCatalog.WEAPONS.get(current_weapon_name(),{"kind":"徒手","attack":4,"duration":0.6,"crit":0.0,"pierce":0.0,"reach":45,"cone":0.5,"combo":1})

func wield(item: String) -> void:
	if not CraftCatalog.WEAPONS.has(item) or int(inventory.get(item,0))<=0: return
	flags["held_weapon"]=item
	var at: int=quickbar.find(item)
	if at>=0: quickbar_index=at
	elif CraftCatalog.WEAPONS.has(str(quickbar[quickbar_index])): assign_quickbar(quickbar_index,item)
	recalculate_stats()
	toast("已持用："+item)
	mark_dirty()

func start_attack() -> void:
	if energy<=0 or eating_time>0 or life.waking: return
	if attack_release_required and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT): attack_release_required=false
	if pointer_over_ui() or attack_release_required: return
	if transition or dialogue_panel.visible or modal.visible: return
	if attack_time>0 or attack_recovery>0:
		if attack_time+attack_recovery<0.18: attack_buffer=0.2
		return
	attack_previous_progress=-1.0
	swing_weapon=current_weapon().duplicate()
	combo=combo%int(swing_weapon.combo)+1 if combo_window>0 else 1
	attack_duration=float(swing_weapon.duration)
	combo_window=attack_duration+0.38
	attack_time=attack_duration
	attack_buffer=0
	swing_power=int(swing_weapon.attack)+2*(level-1)+int(equipment.stats().attack)
	energy=maxf(0,energy-0.5)
	facing=(get_global_mouse_position()+camera_offset-player).normalized()
	if facing==Vector2.ZERO: facing=Vector2.DOWN
	combat.begin_swing()
	play_sound("sword")

func grant_enlistment_gear() -> void:
	if flags.get("enlistment_gear",false): return
	flags["enlistment_gear"]=true
	# Reward is delivered to storage if a returning player's bag is full.
	for item in ["破旧铁甲","军用旧铁剑"]:
		if equipment.count_items(self)<42 or int(inventory.get(item,0))>0: inventory[item]=int(inventory.get(item,0))+1
		else:
			var storage: Dictionary=flags.get("storage",{})
			storage[item]=int(storage.get(item,0))+1; flags["storage"]=storage
	flags["held_weapon"]="军用旧铁剑"
	if int(inventory.get("军用旧铁剑",0))>0: assign_quickbar(0,"军用旧铁剑")
	recalculate_stats()

func migrate_craft_save() -> void:
	for data in [inventory,flags.get("storage",{})]:
		for pair in [["铜料","铜锭"],["铁料","铁锭"],["熟皮","皮革"],["硬鳞","岩鳞"],["完整硬鳞","岩鳞"]]:
			if data.has(pair[0]): data[pair[1]]=int(data.get(pair[1],0))+int(data[pair[0]]); data.erase(pair[0])
		for old in ["旧毡帽","粗布衣","粗布护腿"]: data.erase(old)
	if step>=8: grant_enlistment_gear()
	food_cooldown=0

func xp_required() -> int: return 80+(level-1)*35

func recalculate_stats() -> void:
	var bonuses: Dictionary=equipment.stats()
	max_hp=100+(level-1)*10+int(bonuses.hp)
	attack_power=int(current_weapon().attack)+2*(level-1)+int(bonuses.attack)
	defense=int(bonuses.defense)
	hp=mini(hp,max_hp)
	update_hud()

func grant_starter_equipment() -> void:
	if flags.get("starter_equipment_granted",false): return
	var storage: Dictionary=flags.get("storage",{})
	for item in ["旧布腰带"]:
		if int(inventory.get(item,0))<=0 and int(storage.get(item,0))<=0 and item not in equipment.worn.values(): storage[item]=1
	flags["storage"]=storage
	flags["starter_equipment_granted"]=true

func gain_experience(amount: int) -> void:
	if level>=20: return
	xp+=amount
	while level<20 and xp>=xp_required():
		xp-=xp_required()
		level+=1
		recalculate_stats()
		hp=mini(max_hp,hp+10)
		toast("升级！当前等级 %d，生命与攻击提高" % level)
	if level>=20: xp=0
	update_hud()

func use_potion() -> bool:
	if int(inventory.get("回血药水",0))<=0: toast("没有回血药水"); return false
	if potion_cooldown>0: toast("药水冷却中，还需 %d 秒" % int(ceil(potion_cooldown))); return false
	if hp>=max_hp: toast("生命已满，不消耗药水"); return false
	inventory["回血药水"]=int(inventory["回血药水"])-1
	hp=mini(max_hp,hp+int(ceil(max_hp*0.35)))
	potion_cooldown=30.0
	play_sound("craft")
	toast("恢复35%生命")
	update_hud()
	mark_dirty()
	return true

func take_damage(amount: int,source: Vector2) -> void:
	if invulnerability>0 or hp<=0 or scene_id!="field": return
	amount=maxi(1,int(round(float(amount)*100.0/(100.0+defense))))
	cancel_eating()
	hp=maxi(0,hp-amount)
	invulnerability=0.8
	hurt_flash=0.12
	combat.numbers.append({"pos":player+Vector2(0,-90),"text":"-"+str(amount),"life":0.7,"color":Color("ef9b81")})
	play_sound("hurt")
	var next:=player+(player-source).normalized()*15
	if not blocked(next) and movement_bounds().has_point(next): player=next
	update_hud()
	if hp==0: life.wake(self,"death")
	mark_dirty()

func tick_clock(delta: float) -> void:
	life.tick(self,delta)

func advance_calendar() -> void:
	life.advance_to(self,farming.day*1440.0+360)

func rest() -> void:
	life.sleep(self)

func show_dialog(lines: Array, callback: Callable = Callable()) -> void:
	attack_release_required=true
	attack_buffer=0
	dialog_lines = lines
	dialog_index = 0
	dialog_callback = callback
	dialogue_panel.show()
	refresh_dialog()

func refresh_dialog() -> void:
	name_label.text = str(dialog_lines[dialog_index][0])
	dialogue_text.text = str(dialog_lines[dialog_index][1])

func next_dialog() -> void:
	dialog_index += 1
	if dialog_index >= dialog_lines.size():
		dialogue_panel.hide()
		var cb := dialog_callback
		dialog_callback = Callable()
		if cb.is_valid(): cb.call()
	else: refresh_dialog()

func reconcile() -> void:
	if step == 2 and inventory.has("《材料大全》"): step = 3
	if step == 3 and inventory.has("《草药大全》"): step = 4
	if step == 4 and int(flags.get("herbs_collected",0)) >= 3: step = 5
	if step == 5 and flags.get("crafted_potion",false): step = 6
	if step == 8 and flags.get("training_done",false):
		step = 9
		flags["escort_return"]=true
	if step == 9 and flags.get("soldier_talk",false) and flags.get("medic_talk",false) and (int(flags.get("recruit_flow",0))<1 or (flags.get("training_returned",false) and flags.get("roster_intro_seen",false))): step = 10

func advance(expected: int) -> void:
	if step == expected:
		step += 1
		story_events.record(self,"完成任务："+str(OBJECTIVES[expected]))
		reconcile()
		update_hud()
		mark_dirty()
		toast("任务完成 · "+str(OBJECTIVES[expected]))
		var reflections: Dictionary={
			0:["陆承安","箱子里留下的，不只有出门用的东西。信还是放回原处，回来再看。"],
			1:["陆承安","田伯没有拦我。他问的那些事，我却一件也没准备好。"],
			2:["陆承安","郭叔说话总硬，可这本手册的书角，早替我包好了。"],
			3:["陆承安","认得药草，也要认得自己什么时候该求助。"],
			4:["陆承安","原来低头找三株草，也得记住回村的方向。"],
			5:["陆承安","第一瓶药做好了。愿它只是备着，可不能因为盼着用不上，就不带。"],
			6:["陆承安","那句回来喊一声，比出门时的行囊还沉。"],
			7:["陆承安","裴将军没问我有多想找到人。他先问我能不能听清规矩。"],
			8:["陆承安","第一次真正面对甲壳虫。老韩让我记住的，始终是退路。"],
			9:["陆承安","名单上的一个名字，是石大川的姐姐。我们要找的人，原来从来不是一串字。"],
			10:["陆承安","腰牌很轻。从今天起，回来时数的人里，也有我。"]}
		if expected==8: flags["escort_return"]=true
		if expected==7:
			flags["recruit_flow"]=1
			show_dialog([reflections[7],["韩守义","甲要穿在身上，剑要拿在手里。先整理好，别等虫子扑过来才翻包。"]],func(): recruitment.show_gear_guide(self))
			mark_dirty()
		elif reflections.has(expected): show_dialog([reflections[expected]])
		if expected==8:
			relationships.reward_once("main_training",{"scout":3.0},self)
			mark_dirty()

func toast(message: String) -> void:
	toast_label.text = message
	toast_time = 3.5
	toast_label.show()
	toast_panel.visible=not transition

func bond(id: String) -> void:
	if not flags.has("met_"+id):
		flags["met_"+id] = true
		relationships.change(id,relationships.FIRST_GAIN,self)

func change_scene(target: String, spawn: Vector2) -> void:
	if life.waking: return
	if target=="field" and time_minutes>=120 and time_minutes<360: toast("凌晨两点后禁止出关"); return
	if scene_id=="field": life.reset_survivors(self)
	cancel_eating()
	transition = true
	var cover := ColorRect.new()
	cover.size = Vector2(1280,800)
	cover.color = Color(0,0,0,0)
	ui.add_child(cover)
	var tw := create_tween()
	tw.tween_property(cover,"color:a",1.0,0.25)
	await tw.finished
	scene_id = target
	player = spawn
	setup_scene()
	if target=="wall" and flags.get("training_done",false): recruitment.returned(self)
	mark_dirty()
	tw = create_tween()
	tw.tween_property(cover,"color:a",0.0,0.3)
	await tw.finished
	cover.queue_free()
	transition = false

func interact(id: String) -> void:
	if life.waking: return
	if id=="clinic_exit": change_scene("village",Vector2(2130,1410)*world_layout.SCALE); return
	if id=="clinic_bed": show_dialog([["夜间休息","下午16:00起可在医馆床铺休息，恢复10%生命、精力回满。F确认，Esc取消。"]],func(): rest()); return
	if id=="clinic_treatment": life.treatment(self,"doctor"); return
	if id=="garden_storage": show_chest(); return
	if id=="mill_entry": change_scene("mill",Vector2(640,580)); return
	if id=="commission_board": commissions.show(self); return
	if gifting.offer(id,self): return
	if story_events.side_talk(id,self): update_hud(); return
	if story_events.interact(id,self): update_hud(); return
	if npc_life.PEOPLE.has(id):
		var skip: bool=bool(flags.get("skip_npc_menu",false))
		flags.erase("skip_npc_menu")
		var critical: bool=(id=="elder" and step in [1,6]) or (id=="smith" and not inventory.has("《材料大全》")) or (id=="doctor" and (not inventory.has("《草药大全》") or step==4)) or (id=="captain" and step in [7,10]) or (id=="scout" and (step==8 or flags.get("training_active",false))) or (id in ["soldier","medic"] and step==9)
		if not skip and not critical and id in ["smith","leather"] and npc_life.service_open(id,self):
			bond(id)
			craft_ui.show_menu(self,id)
			return
		if not skip and not critical:
			bond(id)
			story_events.routine_menu(id,self)
			return
		if id in ["smith","leather","merchant","farmer"] and not critical and not npc_life.service_open(id,self):
			show_dialog([[npc_life.PEOPLE[id].name,"现在已经歇工了。你得空也歇一会，明天按告示上的时辰再来。"]])
			return
		if id=="leather": craft_ui.show_menu(self,"leather"); return
		if npc_life.talk(id,self): return
	if id.begins_with("field_herb_"):
		var index: int=int(id.trim_prefix("field_herb_"))
		if equipment.count_items(self)>=42 and int(inventory.get("基础草药",0))<=0: toast("背包已满"); return
		flags.field_plants[index].taken=true
		inventory["基础草药"]=int(inventory.get("基础草药",0))+1
		play_sound("pickup")
		toast("获得 基础草药 ×1")
		setup_scene()
		mark_dirty()
		return
	if id.begins_with("farm_"):
		farming.work(int(id.trim_prefix("farm_")),self)
		return
	if id.begins_with("house_"):
		var house_index: int=int(id.trim_prefix("house_"))
		for owner in npc_life.PEOPLE:
			if int(npc_life.PEOPLE[owner].get("house",-1))==house_index:
				if npc_life.working(owner,time_minutes): change_scene("clinic" if owner=="doctor" else "home_"+owner,Vector2(640,580))
				else: show_dialog([["已打烊",npc_life.PEOPLE[owner].name+"已经下班，住处暂不接待。请在工作时间或村中碰面时交谈，按J查看作息。"]])
				return
		var house: Array=HOUSE_DATA[house_index]
		show_dialog([[str(house[0]),"门前留着生活的痕迹。此住处的室内与人物事件尚未开放。"]])
		return
	if id.begins_with("herb_"):
		var index := int(id.trim_prefix("herb_"))
		plants[index].taken = true
		inventory["基础草药"] = int(inventory.get("基础草药",0))+1
		flags["herbs_collected"] = int(flags.get("herbs_collected",0))+1
		toast("获得 基础草药 ×1")
		play_sound("pickup")
		setup_scene()
		if int(flags.herbs_collected) >= 3: advance(4)
		mark_dirty()
		return
	match id:
		"farmer":
			if scene_id=="mill": cooking.show_mill(self)
			else: change_scene("mill",Vector2(640,580))
		"kitchen": cooking.show_menu(self)
		"mill_work":
			if npc_life.live.farmer.scene=="mill" and npc_life.service_open("farmer",self): cooking.show_mill(self)
			else: show_dialog([["磨面告示","周满仓上午十点起磨面，下午四点半收工，营业时间内不再午休。清早可在公共农田找到他。"]])
		"resident_exit":
			var owner: String=scene_id.trim_prefix("home_")
			change_scene("village",world_layout.door(int(npc_life.PEOPLE[owner].house))+Vector2(0,30))
		"mill_exit": change_scene("village",cooking.MILL_POS+Vector2(30,30))
		"chest": play_sound("open"); show_chest()
		"letter": read_letter()
		"bed": show_dialog([["夜间休息","下午16:00起可睡到次日06:00，恢复10%生命上限、精力回满。\n药水冷却不会因睡觉清除。F确认，Esc取消。"]],func(): rest())
		"exit": change_scene("village",Vector2(356,370)*world_layout.SCALE)
		"home": change_scene("home",Vector2(660,580))
		"wall":
			if step < 7: show_dialog([["陆承安", "先把村里的事情办妥，再去长城报名。"]])
			else: change_scene("wall",Vector2(200,825))
		"village": change_scene("village",VILLAGE_GATE_RETURN)
		"south_gate": show_dialog([["村庄南门","村外官道通往后续区域，目前暂未开放。"]])
		"well": farming.water=12; toast("灌溉用水已补满：12份"); mark_dirty()
		"west": show_dialog([["西行官道", "道路伸向汉泉驿与更远的平戎镇。\n当前开局版本尚未开放西行区域。"]])
		"elder":
			bond(id)
			if ambient_event(id): return
			if step == 1:
				show_dialog([["田敬修", "箱子收拾了？一早就往长城跑，你跟你爷爷当年一个脾气。"], ["陆承安", "田伯，我想去找阿微。名单上还有那么多人。"], ["田敬修", "你爷爷陆定山跟我一起当过兵。他没能回来，你爹娘后来也……\n我不能只听你说一句想去，就当你准备好了。"], ["田敬修", "先去找郭成，再向许先生学些药草知识。要出门，至少知道怎样照顾自己。"]],func(): advance(1))
			elif step == 6:
				show_dialog([["田敬修", "药备好了？我替你留了饭，别空着肚子去。"], ["陆承安", "我会准备好，也会告诉你我要去哪。"], ["田敬修", "到了找裴肃。还有……回来记得进屋喊我一声。"]],func(): advance(6))
			else: show_dialog([["田敬修", "别光顾着往外跑。你家的屋顶，我昨天又看过一回。\n等你有空，咱们一起修。"]])
		"smith":
			bond(id)
			if not inventory.has("《材料大全》"):
				show_dialog([["郭成", "参军？拿把刀就想上长城？先把材料认全。\n这本《材料大全》拿好，简单的绳子、布料，背包里就能做。"], ["郭成", "兵器和护甲得来我这儿。家里的斧子、镐子、锄头别扔，结实着呢，不用修。"]],func(): inventory["《材料大全》"]=1; advance(2); mark_dirty())
			else: equipment.show_forge(self)
		"doctor":
			bond(id)
			if ambient_event(id): return
			if not inventory.has("《草药大全》"):
				show_dialog([["许素问", "这是《草药大全》。先给你三株教学草药，认清了再动手。\n两株草药加清水，可在背包里合成一瓶简单回血药。"], ["许素问", "井水免费取，不必为装水的瓶子发愁。认不准的草药，不要随便入口。"]],func(): inventory["《草药大全》"]=1; inventory["基础草药"]=int(inventory.get("基础草药",0))+3; flags["herbs_collected"]=3; advance(3); mark_dirty())
			elif step==4:
				show_dialog([["许素问","这三株留给你练习辨药、合成。野生草药只在关外偶尔能找到，往后最好自己种。"]],func(): inventory["基础草药"]=int(inventory.get("基础草药",0))+3; flags["herbs_collected"]=3; advance(4))
			else: life.treatment(self,"doctor")
		"merchant": bond(id); show_market()
		"captain":
			bond(id)
			if step == 7:
				show_dialog([["裴肃", "陆承安。田村长已经托人问过几次你的事了。"], ["陆承安", "我要加入搜寻队，寻找失踪的村民。"], ["裴肃", "留下靠的不是决心。这件破旧铁甲和旧铁剑交给你。先找韩守义，学会出关的规矩。\n这里人少，每个人都得知道自己在做什么。"]],func(): grant_enlistment_gear(); advance(7); mark_dirty())
			elif step == 10:
				show_dialog([["裴肃", "从今天起，你是东沙关驻军的一员。这是你的军籍腰牌。"], ["韩守义", "下一趟巡防，我带路，你记路。出门前数一次人，回来前再数一次。"], ["陆承安", "名单上那些名字，我想一个个找回来。"], ["开局篇 · 完成", "你已完成参军前的准备与入营。\n1.2 搜寻：向裴肃领取正式巡防任务。也可继续采集、合成与交谈。\n\n当前可从长城关门出关练习战斗。技能与闪避仍未开放。"]],func(): inventory["军籍腰牌"]=1; advance(10))
			else: show_dialog([["裴肃", "先把分内的事做扎实。搜寻路线要核实，补给也得有人照管。"]])
		"scout":
			bond(id)
			if step==8:
				if flags.get("training_active",false): show_dialog([["韩守义","别急。压低身子是冲撞的前兆，绕到侧面。已完成 %d / 3。" % int(flags.get("training_kills",0))]])
				else:
					if not recruitment.ready(self): recruitment.show_gear_guide(self)
					else: show_dialog([["韩守义","只清靠近关门的三只，别往深处追。我带路，你跟紧。第一只先练出刀，另外两只，等你站稳了再说。"],["韩守义","左键攻击，鼠标定方向。缺血按1喝药；没把握，退到我身边。我备了包扎用的药。"]],func(): frontier.begin_training(self))
			elif not ambient_event(id): show_dialog([["韩守义","出门前数一次人，回来再数一次。认路和记人，都比抢着出刀要紧。"]])
		"soldier":
			bond(id)
			show_dialog([["石大川", "新来的？以后一起值勤。你别听老韩吓人，他就那脾气。"], ["石大川", "我姐叫石阿菱，也在名单上。真出关我也怕，轮到值守还是得去。\n我若只顾害怕，谁替后来的人看门？……这话可别跟老韩讲。"], ["陆承安","我也有想找的人。下次出去，咱们互相照应。"]],func(): flags["soldier_talk"]=true; check_members())
		"medic":
			bond(id)
			show_dialog([["孙怀济", "我是军医，也管军需。药别乱喝，领了什么要登记。"], ["孙怀济", "许先生教过你？她是我师姐。她说先救眼前的人，我就记着。\n老韩的药包总少一份，不是他自己用了，都是留给别人。"], ["陆承安","那你的饭呢？都凉了。"], ["孙怀济","凉了能热。回来了先报平安，再来看名单，别让等你的人再数一遍。"]],func(): flags["medic_talk"]=true; check_members())
		"dummy": toast("训练已改为跟随韩守义出关实战")
		"roster": recruitment.show_roster(self)
		"return_gate":
			if flags.get("training_done",false) and int(flags.get("search_stage",0))==0: flags["escort_return"]=false
			change_scene("wall",Vector2(1830,825))
		"gate":
			if step==8 and flags.get("training_active",false): change_scene("field",Vector2(550,805))
			elif step<11: show_dialog([["裴肃","先找韩守义，由他带你出关训练。"]])
			else: change_scene("field",Vector2(550,805))
		"barracks_entry": change_scene("barracks",Vector2(990,350))
		"barracks_exit": change_scene("wall",Vector2(870,1380))
		"army_bed": show_dialog([["营房休息","下午16:00起可睡到次日06:00，恢复10%生命、精力回满，不清除食物或药水冷却。F确认；Esc取消。"]],func(): rest())
		"army_meal": show_dialog([["石大川","刚出关？坐这儿。我第一回回来，连筷子都拿不稳。"],["孙怀济","先洗手再吃。药放在饭桌上，谁也别碰错了。"],["陆承安","这张桌子不大，每个人却都给我留了位置。"]])

func check_members() -> void:
	if flags.get("soldier_talk",false) and flags.get("medic_talk",false):
		if int(flags.get("recruit_flow",0))>=1 and (not flags.get("training_returned",false) or not flags.get("roster_intro_seen",false)): update_hud(); mark_dirty(); return
		advance(9)

func clear_modal(title: String) -> void:
	modal.add_theme_stylebox_override("panel",panel_style("e0e5cdfc"))
	for c in modal_body.get_children():
		modal_body.remove_child(c)
		c.queue_free()
	modal.position=Vector2(300,100)
	modal.size=Vector2(680,620)
	modal_body.add_child(label(title,28,"72572f"))
	attack_release_required=true
	attack_buffer=0
	modal.show()

func play_sound(sound_name: String) -> void:
	if not sound_enabled or not sound_bank.has(sound_name): return
	if audio_players.is_empty(): return
	var selected: AudioStreamPlayer=null
	for player in audio_players:
		if not player.playing: selected=player; break
	if selected==null:
		if sound_name=="step": return
		selected=audio_players[sfx_cursor%audio_players.size()]; sfx_cursor+=1
	selected.stream=sound_bank[sound_name]; selected.play()

func transfer_item(key: String, source: String, amount: int=-1, stack_index: int=-1) -> void:
	if key=="父母遗书":
		modal.hide()
		read_letter()
		return
	if key.contains("《"): return
	var storage: Dictionary=flags.get("storage",{})
	var origin: Dictionary=inventory if source=="bag" else storage
	var dest: Dictionary=storage if source=="bag" else inventory
	var count:=int(origin.get(key,0))
	if amount>=0: count=mini(count,amount)
	if count<=0: return
	var used:=0
	for item in dest:
		if int(dest[item])>0 and not str(item).contains("《"): used+=1
	var capacity:=300 if source=="bag" else 42
	if int(dest.get(key,0))<=0 and used>=capacity:
		toast("目标容器已满，请先整理物品")
		return
	if source=="bag" and stack_index>=0:
		var cells: Array=bag_stacks.sync(self)
		if stack_index>=cells.size() or cells[stack_index].get("key","")!=key: return
		count=mini(count,int(cells[stack_index].count))
		cells[stack_index].count-=count
		if int(cells[stack_index].count)<=0: cells[stack_index]={}
		flags["bag_stacks"]=cells
	dest[key]=int(dest.get(key,0))+count
	origin[key]=int(origin.get(key,0))-count
	if int(origin[key])<=0: origin.erase(key)
	flags["storage"]=storage
	if inventory.has("锄头") and inventory.has("斧子") and inventory.has("镐子"): flags["chest_taken"]=true
	check_home()
	update_hud()
	play_sound("pickup")
	mark_dirty()
	show_chest()

func show_chest() -> void:
	grant_starter_equipment()
	if not flags.get("chest_initialized",false):
		var initial: Dictionary=flags.get("storage",{})
		initial["父母遗书"]=1
		if not flags.get("chest_taken",false):
			for key in ["锄头","斧子","镐子"]:
				if not inventory.has(key): initial[key]=1
			if not inventory.has("初始种子"): initial["初始种子"]=6
		flags["storage"]=initial
		flags["chest_initialized"]=true
	inventory_ui.show_chest(self)

func read_letter() -> void:
	show_dialog([["父母的遗书 · 剧情草稿", "承安：\n家中的东西都收在旧箱里。往后无论走多远，记得好好吃饭，照顾自己。\n我们盼你平安，也盼你能做自己认定的事。"], ["陆承安", "父亲陆怀朴，母亲沈宜宁。\n信纸已经泛黄，折痕处被仔细补过。里面的话，我早已记得。\n\n〔遗书正文为可替换草稿，未作为最终设定。〕"]],func(): flags["letter_read"]=true; check_home(); mark_dirty())

func check_home() -> void:
	if flags.get("chest_taken",false) and flags.get("letter_read",false): advance(0)

func show_inventory() -> void:
	inventory_ui.bag_page=clampi(inventory_page,0,2)
	inventory_ui.show_bag(self)

func swap_bag_order(first: String,second: String) -> void:
	if first==second or not inventory.has(first) or not inventory.has(second): return
	var keys:=inventory.keys()
	var a:=keys.find(first)
	var b:=keys.find(second)
	keys[a]=second
	keys[b]=first
	var reordered: Dictionary={}
	for key in keys: reordered[key]=inventory[key]
	inventory=reordered
	play_sound("pickup")
	mark_dirty()
	show_inventory()

func item_description(key: String) -> String:
	if key in ["白银","黄金"]: return "珍贵金属材料，供后续制作饰品使用；当前保留，不设置饰品配方。"
	if key.ends_with("模具"): return "饰品制作模具，后续制作一件饰品消耗一个。"
	if key.begins_with("通用") and key.ends_with("制作书"): return "皮革饰品一次性制作书，每制作一件消耗一本。"
	if key=="肥料": return "在已播种、未施肥的家中农田使用；剩余生长天数立即减半（向上取整），每茬限一次。"
	if key=="稀有种子": return "可种植沙金麦，需每日浇水生长六天；收获物暂存，后续完善用途。"
	if CraftCatalog.WEAPONS.has(key): return CraftCatalog.describe(key)+" · 暴击伤害150% · 使用或物品栏选中持用"
	if key.begins_with("制作书·"): return "一次性制作书；制作一件消耗一本，不会永久学习。"
	if equipment.ITEMS.has(key): return equipment.description(key)
	var uses: Array=[]
	for product in CraftCatalog.RECIPES:
		if CraftCatalog.RECIPES[product].materials.has(key): uses.append(str(product))
	if not uses.is_empty(): return "制作材料，用于："+"、".join(uses.slice(0,4))+("等" if uses.size()>4 else "")
	match key:
		"沙麦": return "可出售，或到周家磨坊付费磨成面粉。"
		"馒头": return "进食0.8秒，受伤打断不消耗 · 恢复20精力 · 无冷却 · 按2食用 · 不直接回血。"
		"面条": return "进食0.8秒，受伤打断不消耗 · 恢复45精力 · 无冷却 · 按3食用 · 不直接回血。"
		"锄头": return "开垦家中院内12块农田 · 随身携带后在地块按F。"
		"斧子": return "砍伐用工具 · 无耐久。伐木功能尚未开放。"
		"镐子": return "开采用工具 · 无耐久。采矿功能尚未开放。"
		"基础草药": return "长城外偶尔能找到，主要靠种植，可合成回血药水。"
		"草药饼": return "进食0.8秒，受伤打断不消耗 · 恢复30精力 · 无冷却 · 不直接回血。"
		"面粉": return "沙麦在公共农田旁的周家磨坊加工，每份支付1文。"
		"回血药水": return "恢复35%生命 · 按1使用 · 冷却30秒，满血不消耗。"
		"初始种子": return "沙麦种子 · 已开垦农田按F播种，浇水生长3天后收获。"
		"军籍腰牌": return "东沙关驻军身份凭证。"
	return "可保存到家中储物箱。"

func show_village_map() -> void:
	clear_modal("东沙村 · 地图")
	var overview=load("res://village_map.gd").new()
	overview.picture=scene_art.get("village_large")
	overview.marker=player if scene_id=="village" else Vector2(356,370)*world_layout.SCALE
	overview.text_font=font
	modal_body.add_child(overview)
	modal_body.add_child(label("浅色圆点为位置；南门入村，东侧长城出关。",14))
	modal_body.add_child(button("关闭",func(): modal.hide()))

func show_market() -> void:
	commerce.show(self)

func show_people() -> void:
	npc_life.show_people(self)

func show_menu() -> void:
	if life.waking or weekly.active: return
	inventory_ui.prepare(self,"东沙旧事 · 暂停")
	modal_body.add_child(game_options.small(self,"设置",func(): game_options.show(self)))
	modal_body.add_child(game_options.small(self,"手动存档",func():
		if save_game(): toast("旅程已保存")))

func mark_dirty() -> bool:
	return true

func change_coins(amount: int,reason: String) -> void:
	var before: String=coin_reason; coin_reason=reason
	coins=maxi(0,coins+amount); coin_reason=before

func save_game() -> bool:
	if weekly.active: return false
	ensure_quickbar()
	flags["quickbar_index"]=quickbar_index
	var f := FileAccess.open(SAVE,FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"version":14,"equipment":equipment.worn,"farming":farming.snapshot(),"map_revision":4,"combat":combat.snapshot(),"hp":hp,"level":level,"xp":xp,"coins":coins,"energy":energy,"food_cooldown":food_cooldown,"regen_timer":regen_timer,"npc_life":npc_life.snapshot(),"time_minutes":time_minutes,"potion_cooldown":potion_cooldown,"scene":scene_id,"player":[player.x,player.y],"step":step,"inventory":inventory,"flags":flags,"hearts":hearts,"plants":plants,"strikes":strikes}))

		f.flush()
		if f.get_error()==OK: return true
	toast("旅程保存失败，请检查可写空间")
	return false

func load_game() -> void:
	cancel_eating()
	if life.waking or weekly.active: return
	if not FileAccess.file_exists(SAVE): toast("还没有存档"); return
	var value = JSON.parse_string(FileAccess.get_file_as_string(SAVE))
	if not value is Dictionary: toast("存档无法读取"); return
	gifting.cancel(); gifting.bypass_npc=""; relationships.cancel_question()
	modal.hide(); dialogue_panel.hide(); dialog_callback=Callable()
	attack_buffer=0; attack_release_required=true; interaction_target=""; hurt_flash=0
	inventory_ui.selected=""; inventory_ui.selected_stack=-1; inventory_ui.selected_hot=-1
	scene_id = value.get("scene","home")
	step = clampi(int(value.get("step",0)),0,OBJECTIVES.size())
	inventory = value.get("inventory",{})
	flags = value.get("flags",{})
	quickbar_index=clampi(int(flags.get("quickbar_index",0)),0,5)
	ensure_quickbar()
	sound_enabled=bool(flags.get("sound_enabled",true))
	game_options.restore(self)
	hearts = value.get("hearts",{})
	npc_life.restore(value.get("npc_life",{}))
	if int(value.get("map_revision",0))<4:
		for person in npc_life.live.values():
			if person.scene=="village": person.pos*=world_layout.SCALE
	plants = value.get("plants",[])
	strikes = int(value.get("strikes",0))
	level=clampi(int(value.get("level",1)),1,20)
	equipment.restore(value.get("equipment",{}))
	max_hp=100+(level-1)*10+int(equipment.stats().hp)
	attack_power=18+2*(level-1)+int(equipment.stats().attack)
	defense=int(equipment.stats().defense)
	hp=clampi(int(value.get("hp",max_hp)),1,max_hp)
	xp=maxi(0,int(value.get("xp",0)))
	ledger_muted=true
	coins=maxi(0,int(value.get("coins",0)))
	ledger_muted=false
	potion_cooldown=maxf(0,float(value.get("potion_cooldown",0)))
	food_cooldown=maxf(0,float(value.get("food_cooldown",0)))
	if not value.has("food_cooldown") and potion_cooldown>8:
		food_cooldown=potion_cooldown
		potion_cooldown=0
	energy=clampf(float(value.get("energy",MAX_ENERGY)),0,MAX_ENERGY)
	regen_timer=clampf(float(value.get("regen_timer",0)),0,9.99)
	time_minutes=clampf(float(value.get("time_minutes",360)),0,1439.99)
	migrate_craft_save()
	recalculate_stats()
	combat.restore(value.get("combat",{}))
	if int(value.get("map_revision",0))<3:
		for enemy in combat.enemies: enemy.pos=enemy.home
		for i in range(combat.loot.size()): combat.loot[i].pos=Vector2(900+i*30,850)
	farming.restore(value.get("farming",{}))
	life.initialize(self)
	weekly.data(self)
	relationships.normalize(self)
	commissions.last_minute=-1
	commissions.update(self,true)
	attack_time=0
	invulnerability=0.8
	player = Vector2(value.player[0],value.player[1])
	if scene_id=="village" and int(value.get("map_revision",0))<4: player*=world_layout.SCALE
	reconcile()
	setup_scene()
	if scene_id == "home": player = Vector2(680,510)
	elif scene_id.begins_with("home_") and not npc_life.working(scene_id.trim_prefix("home_"),time_minutes):
		var owner: String=scene_id.trim_prefix("home_")
		scene_id="village"
		player=world_layout.door(int(npc_life.PEOPLE[owner].house))+Vector2(0,30)
		setup_scene()
	elif scene_id == "village":
		if int(value.get("map_revision",0))<2: player=Vector2(356,370)*world_layout.SCALE
		elif blocked(player): player=Vector2(1440,1850)*world_layout.SCALE
	if scene_id in ["wall","field","barracks"]:
		if int(value.get("map_revision",0))<3 or blocked(player) or not movement_bounds().has_point(player):
			player={"wall":Vector2(200,825),"field":Vector2(550,805),"barracks":Vector2(990,350)}[scene_id]
	if flags.get("training_active",false):
		recruitment.configure_training(self,false)
	update_camera(true)
	toast("旅程已继续")

func text_at(p: Vector2, s: String, size: int=15, color: Color=Color("eadfc5")) -> void:
	if font != null:
		draw_string(font,p+Vector2(0,1),s,HORIZONTAL_ALIGNMENT_LEFT,-1,size,Color(0.1,0.12,0.1,0.35))
		draw_string(font,p,s,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)

func box(r: Rect2, fill: Color, outline: Color = Color("5d4939")) -> void:
	draw_rect(r, outline)
	draw_rect(r.grow(-2), fill)

func roof_tiles(r: Rect2, c: Color) -> void:
	box(r,c,c.darkened(0.4))
	for y in range(int(r.position.y)+5,int(r.end.y)-2,9):
		draw_line(Vector2(r.position.x+3,y),Vector2(r.end.x-3,y),c.lightened(0.14),2)
		for x in range(int(r.position.x)+5,int(r.end.x)-3,17):
			draw_line(Vector2(x,y-6),Vector2(x+2,y),c.darkened(0.18),2)
	draw_line(r.position+Vector2(1,2),Vector2(r.end.x-1,r.position.y+2),c.lightened(0.35),3)

func building(r: Rect2, title: String, roof: String="92724c") -> void:
	draw_rect(Rect2(r.position+Vector2(10,14),r.size),Color("493c2a40"))
	box(r,Color("bba377"))
	for y in range(int(r.position.y)+40,int(r.end.y),13):
		draw_line(Vector2(r.position.x+3,y),Vector2(r.end.x-3,y),Color("aa9068"),1)
		for x in range(int(r.position.x)+9,int(r.end.x)-3,27):
			draw_line(Vector2(x+int(y)%2*10,y-12),Vector2(x+int(y)%2*10,y),Color("ae956f"),1)
	roof_tiles(Rect2(r.position-Vector2(7,3),Vector2(r.size.x+14,55)),Color(roof))
	box(Rect2(r.position+Vector2(7,54),Vector2(r.size.x-14,24)),Color("67513b"))
	text_at(r.position+Vector2(19,73),title,16,Color("efd4a0"))
	for x in [r.position.x+22,r.end.x-49]:
		box(Rect2(x,r.end.y-75,28,32),Color("52776d"))
		for offset in [8,17]:
			draw_line(Vector2(x+offset,r.end.y-73),Vector2(x+offset,r.end.y-45),Color("c5a46a"),2)
		draw_line(Vector2(x+2,r.end.y-61),Vector2(x+26,r.end.y-61),Color("c5a46a"),2)
		box(Rect2(x-3,r.end.y-43,34,6),Color("8e7050"))
	var d := Vector2(r.get_center().x-18,r.end.y-46)
	box(Rect2(d,Vector2(36,47)),Color("57402e"))
	for i in range(4): draw_line(d+Vector2(6+i*8,3),d+Vector2(6+i*8,43),Color("735439"),2)
	draw_rect(Rect2(d+Vector2(25,23),Vector2(3,4)),Color("d8b16b"))
	box(Rect2(d+Vector2(-6,46),Vector2(48,9)),Color("9b9071"))
	pot(r.position+Vector2(11,r.size.y-4))
	pot(r.position+Vector2(r.size.x-12,r.size.y-4))

func pot(p: Vector2, green: bool=true) -> void:
	box(Rect2(p-Vector2(8,15),Vector2(16,16)),Color("ad7151"))
	draw_line(p-Vector2(10,16),p+Vector2(10,-16),Color("d59b6a"),3)
	if green:
		for i in range(5):
			var end := p+Vector2((i-2)*5,-25-abs(i-2)*2)
			draw_line(p+Vector2(0,-15),end,Color("557953"),3)

func tree(p: Vector2, scale_value: float=1.0) -> void:
	draw_ellipse_shadow(p)
	draw_rect(Rect2(p+Vector2(-4,-42)*scale_value,Vector2(8,45)*scale_value),Color("7a593c"))
	for i in range(5):
		var off := Vector2(sin(i*2.1)*17,-45-i*7)*scale_value
		var col := Color("7e9251") if i%2==0 else Color("647f4b")
		draw_circle(p+off,21*scale_value,col.darkened(0.12))
		draw_circle(p+off+Vector2(-4,-4),16*scale_value,col)
		for j in range(3):
			draw_rect(Rect2(p+off+Vector2(-10+j*7,-7+j%2*8),Vector2(6,3)),col.lightened(0.2))

func person(p: Vector2,coat: Color,is_player: bool=false) -> void:
	if is_player: actor_visual.hero(self,p)

func swing_angle(progress: float) -> float:
	var reverse:= -1.0 if combo==2 else 1.0
	var wind:=smoothstep(0.0,0.22,progress)
	var cut:=smoothstep(0.22,0.68,progress)
	var settle:=smoothstep(0.68,1.0,progress)
	return facing.angle()+reverse*(-0.7-0.8*wind+2.9*cut-0.7*settle)

func draw_sword(p: Vector2, progress: float) -> void:
	var angle:=swing_angle(progress)
	var kind: String=str(swing_weapon.get("kind","剑"))
	var pivot:=p+Vector2(0,-40)
	var hand:=pivot+Vector2.from_angle(angle)*22
	if progress>0.22 and progress<0.76:
		var trail:=PackedVector2Array()
		for i in range(25):
			var t:=maxf(0.22,progress-float(24-i)*0.004)
			trail.append(pivot+Vector2.from_angle(swing_angle(t))*(105 if kind=="镰刀" else 67))
		draw_polyline(trail,Color(0.9,0.94,0.76,sin(progress*PI)*0.65),5,true)
	draw_set_transform(hand,angle,Vector2.ONE)
	if kind=="徒手":
		draw_circle(Vector2(10,0),6,Color("d9ae80"))
	elif kind=="战锤":
		draw_line(Vector2(-5,0),Vector2(40,0),Color("79583b"),7,true)
		draw_rect(Rect2(33,-16,23,32),Color("a5b7ae"))
		draw_rect(Rect2(36,-13,17,7),Color("dbe3c9"))
	elif kind=="镰刀":
		draw_line(Vector2(-5,0),Vector2(78,0),Color("79583b"),6,true)
		draw_colored_polygon(PackedVector2Array([Vector2(78,3),Vector2(83,-15),Vector2(64,-38),Vector2(40,-44),Vector2(58,-29),Vector2(72,-11)]),Color("d3e1d5"))
	else:
		draw_rect(Rect2(-4,-3,15,6),Color("6b4b32"))
		draw_rect(Rect2(7,-9,4,18),Color("e1bd72"))
		draw_colored_polygon(PackedVector2Array([Vector2(11,-4),Vector2(45,-3),Vector2(54,0),Vector2(45,4),Vector2(11,4)]),Color("cbdcd4"))
		draw_line(Vector2(13,-2),Vector2(46,-1),Color("f1f5d6"),2,true)
	draw_set_transform(Vector2.ZERO)

func draw_ellipse_shadow(p: Vector2) -> void:
	draw_set_transform(p,0,Vector2(1,0.35))
	draw_circle(Vector2.ZERO,19,Color("232c3045"))
	draw_set_transform(Vector2.ZERO)

func ground_detail() -> void:
	for i in range(1150):
		var p := Vector2(fmod(i*137.7,1280),104+fmod(i*73.31,640))
		var c := Color("b69a64") if i%3==0 else Color("dac18b")
		draw_rect(Rect2(p,Vector2(2+i%3,1+i%2)),c)
	for i in range(32):
		var p := Vector2(fmod(i*191.3,1250)+15,115+fmod(i*127.8,610))
		if p.y<345 or p.y>465:
			draw_line(p,p+Vector2(-4,-8),Color("9b9d62"),2)
			draw_line(p,p+Vector2(2,-11),Color("8b9257"),2)

func interior_detail() -> void:
	# Warm adobe walls, timber flooring and handwoven rug.
	for y in range(186,650,28):
		for x in range(334,945,64):
			var off := 30 if y%3==0 else 0
			var r := Rect2(x+off,y,60,25).intersection(Rect2(334,184,612,467))
			if r.size.x>0:
				draw_rect(r,Color("b49b70") if x%3==0 else Color("c0a67b"))
				draw_line(r.position+Vector2(3,4),Vector2(r.end.x-3,r.position.y+4),Color("cbb58a"),1)
	box(Rect2(500,400,260,160),Color("a26d50"))
	box(Rect2(510,410,240,140),Color("5d7d74"),Color("d2b17a"))
	for y in range(419,545,8): draw_line(Vector2(518,y),Vector2(742,y),Color("6a8879"),2)
	for x in range(530,740,30):
		draw_polyline(PackedVector2Array([Vector2(x,450),Vector2(x+12,468),Vector2(x,486),Vector2(x-12,468),Vector2(x,450)]),Color("cbb17c"),2)
	for x in [520,735]:
		box(Rect2(x,151,80,28),Color("4f655f"))
		for j in range(4): draw_line(Vector2(x+10+j*18,154),Vector2(x+10+j*18,177),Color("c2a26e"),3)
	draw_colored_polygon(PackedVector2Array([Vector2(735,180),Vector2(815,180),Vector2(925,580),Vector2(790,580)]),Color(1.0,0.89,0.59,0.07))

func draw_legacy_map() -> void:
	draw_rect(Rect2(0,0,1280,800),Color("c4aa74"))
	if scene_id != "home": ground_detail()
	if scene_id in ["home","clinic"]:
		draw_rect(Rect2(0,0,1280,800),Color("263536"))
		draw_rect(Rect2(305,145,670,535),Color("77553d"))
		draw_rect(Rect2(330,180,620,475),Color("bba079"))
		for y in range(180,650,30): draw_line(Vector2(330,y),Vector2(950,y),Color("a48a65"),2)
		draw_rect(Rect2(500,400,260,160),Color("857b5b"))
		draw_rect(Rect2(510,410,240,140),Color("a29c70"),false,3)
		interior_detail()
		draw_rect(Rect2(360,185,126,150),Color("664e3e"))
		draw_rect(Rect2(370,210,106,110),Color("8caba0"))
		draw_rect(Rect2(370,195,106,35),Color("d7caac"))
		draw_rect(Rect2(600,285,120,70),Color("6f513b"))
		draw_rect(Rect2(643,303,42,25),Color("ecdbb4"))
		draw_rect(Rect2(818,220,100,70),Color("805d3c"))
		draw_rect(Rect2(820,250,96,9),Color("b59754"))
		draw_rect(Rect2(860,248,15,20),Color("dbb264"))
		for x in [380,405,430,455]:
			draw_line(Vector2(x,238),Vector2(x,310),Color("7d9f95"),2)
		for x in [827,851,878,901]:
			draw_line(Vector2(x,227),Vector2(x,284),Color("6a4a32"),2)
		box(Rect2(860,248,15,20),Color("d9b667"))
		pot(Vector2(900,440))
		box(Rect2(825,348,95,50),Color("6c5840"))
		for i in range(8):
			box(Rect2(832+i*10,352,7,36),Color("9a7753") if i%2==0 else Color("6a8b7c"))
		draw_rect(Rect2(625,640,70,30),Color("dec98e"))
		text_at(Vector2(505,214),"陆家旧宅",22)
		text_at(Vector2(440,615),"屋檐之下，旧日生活仍有痕迹。",15,Color("5d5141"))
	elif scene_id=="village":
		for i in range(180):
			var p := Vector2(fmod(i*137.7,1280),110+fmod(i*73.3,625))
			draw_rect(Rect2(p,Vector2(3,2)),Color("ae9764"))
		draw_rect(Rect2(0,365,1280,90),Color("d9c18b"))
		draw_rect(Rect2(465,280,75,420),Color("d9c18b"))
		building(Rect2(80,115,220,180),"陆家旧宅")
		building(Rect2(390,130,220,155),"田家 · 村长")
		building(Rect2(860,115,230,170),"郭记铁铺","76594b")
		building(Rect2(850,490,230,160),"许氏医馆","667c68")
		building(Rect2(80,470,210,180),"村舍")
		draw_circle(Vector2(720,320),40,Color("8f8b67"))
		draw_circle(Vector2(720,320),28,Color("588a8a"))
		text_at(Vector2(690,374),"浅泉",15,Color("526a60"))
		for i in range(5):
			var x := 330+i*85
			draw_rect(Rect2(x,650,8,40),Color("81613e"))
			draw_circle(Vector2(x+4,638),23,Color("738b51"))
			draw_circle(Vector2(x-8,650),18,Color("89985b"))
		for a in actors:
			if str(a.id).begins_with("herb_"):
				draw_line(a.pos,a.pos+Vector2(0,-15),Color("4c794d"),3)
				draw_circle(a.pos+Vector2(-6,-9),5,Color("6a9657"))
				draw_circle(a.pos+Vector2(6,-14),5,Color("8aa862"))
		for tp in [Vector2(325,260),Vector2(800,300),Vector2(1150,620),Vector2(610,700)]: tree(tp,0.8)
		# Medical drying rack and smith's tools stay within existing collision areas.
		box(Rect2(1094,517,12,90),Color("836441"))
		for yy in [530,555,580]:
			draw_line(Vector2(1098,yy),Vector2(1160,yy),Color("8c6f48"),4)
			for xx in range(1110,1150,12): draw_line(Vector2(xx,yy-7),Vector2(xx+5,yy-4),Color("6e8551"),4)
		box(Rect2(805,225,32,50),Color("6a6559"))
		draw_rect(Rect2(810,230,22,13),Color("dc8f4b"))
		for i in range(3):
			draw_circle(Vector2(820+sin(elapsed+i)*5,215-fmod(elapsed*10+i*14,50)),5,Color(0.72,0.67,0.53,0.12))
		box(Rect2(340,535,92,20),Color("876346"))
		for xx in range(347,430,15): box(Rect2(xx,520,10,15),Color("bd9a61"))
		for i in range(9):
			var angle := i*TAU/9
			box(Rect2(Vector2(720,320)+Vector2(cos(angle)*34,sin(angle)*31)-Vector2(6,4),Vector2(12,8)),Color("ada68a"))
		draw_arc(Vector2(720,321),20+sin(elapsed)*2,0.2,2.8,20,Color("9abcb1"),1)
		text_at(Vector2(1100,392),"长城 →",20,Color("68583d"))
	else:
		draw_rect(Rect2(0,160,1280,86),Color("8b806a"))
		for x in range(0,1280,48):
			draw_rect(Rect2(x,139,28,25),Color("92876f"))
			draw_line(Vector2(x,185),Vector2(x+45,185),Color("ada080"),2)
		draw_rect(Rect2(510,125,260,125),Color("696957"))
		draw_rect(Rect2(588,165,104,85),Color("343e39"))
		for yy in range(166,245,16):
			for xx in range(0,1280,40):
				if xx<500 or xx>770:
					draw_rect(Rect2(xx+(int(yy)%3)*6,yy,36,13),Color("948a72"),false,1)
		for xx in [540,725]:
			box(Rect2(xx,260,7,108),Color("716044"))
			draw_colored_polygon(PackedVector2Array([Vector2(xx+6,264),Vector2(xx+42,269),Vector2(xx+32,300),Vector2(xx+6,297)]),Color("805944"))
			text_at(Vector2(xx+12,289),"庚",17,Color("d8bf83"))
		text_at(Vector2(580,151),"东 沙 关",22)
		building(Rect2(85,450,220,170),"驻军营房","6e7560")
		draw_rect(Rect2(367,245,90,65),Color("66513a"))
		draw_rect(Rect2(375,250,74,48),Color("d6c89f"))
		text_at(Vector2(385,274),"名单",17,Color("5b4b38"))
		draw_rect(Rect2(1022,510,16,60),Color("87633f"))
		draw_rect(Rect2(1003,524,54,10),Color("a17a48"))
		draw_circle(Vector2(1030,505),14,Color("ac8550"))
		for yy in range(420,620,25):
			for xx in range(820,1150,30):
				draw_rect(Rect2(xx,yy,28,23),Color("b29b70"),false,1)
		for i in range(4):
			box(Rect2(80+i*24,645,20,25),Color("9b8055"))
			for j in range(3): draw_line(Vector2(84+i*24+j*5,648),Vector2(84+i*24+j*5,667),Color("c1a76e"),2)
		text_at(Vector2(956,610),"演武场",20,Color("68583d"))
func _draw() -> void:
	draw_set_transform(Vector2.ZERO)
	if scene_id=="village": farming.draw_world(self,self)
	story_events.draw(self)
	if scene_id=="field": combat.draw_world(self,self)
	var ordered: Array=[{"kind":"hero","y":player.y}]
	for a in actors:
		if npc_life.PEOPLE.has(a.id): ordered.append({"kind":"npc","y":a.pos.y,"actor":a})
	if scene_id=="village":
		for i in range(HOUSE_DATA.size()): ordered.append({"kind":"house","y":HOUSE_DATA[i][1].end.y*2*world_layout.SCALE,"index":i})
		for prop in world_layout.props: ordered.append({"kind":"prop","y":prop.rect.end.y*world_layout.SCALE,"data":prop})
		for tree in world_layout.trees: ordered.append({"kind":"tree","y":tree.y*world_layout.SCALE,"pos":tree})
	ordered.sort_custom(func(a,b): return float(a.y)<float(b.y))
	for item in ordered:
		match item.kind:
			"hero":
				if invulnerability<=0 or int(elapsed*14)%2==0: person(player,Color("416f78"),true)
			"npc": npc_life.draw_person(self,item.actor)
			"house":
				draw_set_transform(Vector2.ZERO,0,Vector2.ONE*world_layout.SCALE); world_layout.house(self,int(item.index)); draw_set_transform(Vector2.ZERO)
			"prop":
				draw_set_transform(Vector2.ZERO,0,Vector2.ONE*world_layout.SCALE); world_layout.prop(self,item.data); draw_set_transform(Vector2.ZERO)
			"tree":
				draw_set_transform(Vector2.ZERO,0,Vector2.ONE*world_layout.SCALE); world_layout.tree(self,item.pos); draw_set_transform(Vector2.ZERO)
	world_layout.markers(self)
	if eating_time>0: draw_arc(player+Vector2(0,-100),10,-PI/2,-PI/2+TAU*(1-eating_time/eating_duration),24,Color("e5c98b"),3)

func draw_field() -> void:
	draw_rect(Rect2(0,0,1280,800),Color("c9ac76"))
	ground_detail()
	draw_rect(Rect2(585,105,110,170),Color("dbc38f"))
	for i in range(28):
		var x:=i*49
		draw_rect(Rect2(x,120,46,32),Color("8a8068"))
		draw_rect(Rect2(x,105,24,18),Color("9b9177"))
	box(Rect2(584,105,112,58),Color("5d6358"))
	text_at(Vector2(601,144),"返回长城",15)
	for r in obstacles:
		draw_colored_polygon(PackedVector2Array([r.position+Vector2(0,25),r.position+Vector2(22,0),r.position+Vector2(r.size.x-20,0),r.position+Vector2(r.size.x,30),r.end,r.position+Vector2(8,r.size.y)]),Color("9d8a66"))
		draw_line(r.position+Vector2(23,8),r.position+Vector2(r.size.x-20,8),Color("c2ae7d"),4)
	text_at(Vector2(850,700),"长城外 · 浅层沙地",19,Color("695437"))
	text_at(Vector2(330,745),"左键连击 / 按住连续攻击    1 使用药水    靠近掉落自动拾取",14,Color("695437"))

func ambient_event(id: String) -> bool:
	var event: String=""
	var lines: Array=[]
	if id=="doctor" and hp<max_hp and not flags.get("wound_conversation",false):
		event="wound_conversation"
		lines=[["许素问","衣袖放下来做什么？伤在你身上，瞒着我也不会自己好。"],["陆承安","怕田伯看见，又一夜睡不安稳。"],["许素问","那就把伤处理好，再亲口告诉他。别让他只能靠猜。"]]
	elif id=="elder" and flags.get("forged_armor",false) and not flags.get("armor_conversation",false):
		event="armor_conversation"
		lines=[["田敬修","新甲？郭成肯接你的活，说明你知道回来找人商量了。"],["陆承安","我原以为准备得越快，就能越早找到阿微。"],["田敬修","你爷爷也急。后来他说，回来的人，才有下一趟路。饭还热着，坐一会。"]]
	elif id=="scout" and int(flags.get("beetle_kills",0))>0 and not flags.get("patrol_conversation",false):
		event="patrol_conversation"
		lines=[["韩守义","第一次出关，记住了几个岔口？"],["陆承安","我只顾着盯怪……"],["韩守义","杀了几个我不问。下次记树、记石头，记哪儿能退。搜人靠的是能把人带回来。"]]
	if event=="": return false
	show_dialog(lines,func(): flags[event]=true; mark_dirty())
	return true

func draw_residence() -> void:
	draw_rect(Rect2(0,0,1280,800),Color("263b34"))
	box(Rect2(260,150,760,500),Color("aa8a60"))
	box(Rect2(280,195,720,435),Color("cbb78a"))
	for y in range(210,620,28): draw_line(Vector2(285,y),Vector2(995,y),Color("b6a077"),1)
	box(Rect2(325,225,150,120),Color("7a715a"))
	box(Rect2(335,230,130,35),Color("d6c7a2"))
	box(Rect2(820,225,105,110),Color("8d7651"))
	var owner: String=scene_id.trim_prefix("home_")
	text_at(Vector2(525,180),npc_life.PEOPLE[owner].name+"的住处",22)
	box(Rect2(605,615,75,35),Color("68583e"))

func tick_energy(delta: float,walking: bool=false) -> void:
	if walking: energy=maxf(0,energy-delta*0.05)
	if energy>=MAX_ENERGY*0.7 and hp<max_hp:
		regen_timer+=delta
		while regen_timer>=10.0:
			regen_timer-=10.0
			hp=mini(max_hp,hp+maxi(1,int(ceil(max_hp*0.01))))
	else: regen_timer=0
	update_hud()

func army_treatment() -> bool:
	return life.treatment(self,"medic")

func cancel_eating() -> void:
	eating_item=""; eating_time=0

func tick_eating(delta: float) -> void:
	eating_time=maxf(0,eating_time-delta)
	if eating_time<=0 and eating_item!="":
		var item: String=eating_item; eating_item=""; cooking.finish_eating(item,self)
