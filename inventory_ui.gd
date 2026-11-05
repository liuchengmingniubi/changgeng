extends RefCounted
const CATEGORIES := ["全部","装备","材料","食物","药剂"]
var bag_filter := "全部"
var chest_filter := "全部"
var bag_page := 0
var chest_page := 0
var selected := ""
var selected_stack: int=-1
var selected_hot: int=-1
var details: RichTextLabel
var use_button: Button
var game: Node
var opened_as_chest := false

func category(item: String) -> String:
	if item.begins_with("制作书·"): return "材料"
	if game!=null and (game.equipment.ITEMS.has(item) or game.CraftCatalog.WEAPONS.has(item)): return "装备"
	if item in ["回血药水","回息药水","解毒药","止血绷带"] or item.contains("药水"): return "药剂"
	if item in ["馒头","面条","草药饼"]: return "食物"
	for part in ["锄头","斧子","镐子","刀","剑","枪","弓","头盔","护甲","护腿","项链","戒指","手环","腰带","皮甲"]:
		if item.contains(part): return "装备"
	return "材料"

func keys_for(data: Dictionary,filter_name: String) -> Array:
	var keys:=[]
	for key in data:
		if int(data[key])>0 and not str(key).contains("《") and (filter_name=="全部" or category(str(key))==filter_name): keys.append(str(key))
	return keys

func style(bg: String,border: String="a8894e") -> StyleBoxFlat:
	return preload("res://jade_theme.gd").card(bg,border,9)

func jl(text: String,size: int=16) -> Label: return game.label(text,size,"244b3d")

func jb(text: String,callback: Callable) -> Button:
	var b: Button=game.button(text,callback)
	b.add_theme_stylebox_override("normal",style("d7dfbe"))
	b.add_theme_stylebox_override("hover",style("e8e8ca","c6a759"))
	b.add_theme_stylebox_override("pressed",style("afc5a0","c6a759"))
	b.add_theme_stylebox_override("disabled",style("c9d0b7","a0a489"))
	for state in ["font_color","font_hover_color","font_pressed_color"]: b.add_theme_color_override(state,Color("244b3d"))
	b.add_theme_color_override("font_disabled_color",Color("858c77"))
	b.custom_minimum_size.y=36
	return b

func prepare(g: Node,title: String) -> void:
	game=g
	game.migrate_bag_capacity()
	game.clear_modal(title)
	game.modal.position=Vector2(64,64)
	game.modal.size=Vector2(1152,672)
	game.modal.add_theme_stylebox_override("panel",style("e0e5cd","a58b52"))
	preload("res://jade_theme.gd").install(game.modal)
	var title_label: Label=game.modal_body.get_child(0)
	title_label.add_theme_color_override("font_color",Color("244b3d"))

func tabs(source: String) -> HBoxContainer:
	var row:=HBoxContainer.new()
	for name in CATEGORIES:
		var filter_name: String=name
		var active: bool=(bag_filter if source=="bag" else chest_filter)==filter_name
		var b:=jb(filter_name,func():
			if source=="bag": bag_filter=filter_name; bag_page=0
			else: chest_filter=filter_name; chest_page=0
			if opened_as_chest: show_chest(game)
			else: show_bag(game))
		if active: b.add_theme_stylebox_override("normal",style("bacda9","ba9b50"))
		row.add_child(b)
	return row

func navigation(source: String) -> HBoxContainer:
	var row:=HBoxContainer.new()
	var page: int=bag_page if source=="bag" else chest_page
	var count:=3 if source=="bag" else 10
	var previous:=jb("◀ 上一页",func():
		if source=="bag": bag_page=maxi(0,bag_page-1)
		else: chest_page=maxi(0,chest_page-1)
		if opened_as_chest: show_chest(game)
		else: show_bag(game))
	previous.disabled=page==0
	row.add_child(previous)
	var text:=jl("  第 %d / %d 页  " % [page+1,count])
	row.add_child(text)
	var next:=jb("下一页 ▶",func():
		if source=="bag": bag_page=mini(2,bag_page+1)
		else: chest_page=mini(9,chest_page+1)
		if opened_as_chest: show_chest(game)
		else: show_bag(game))
	next.disabled=page==count-1
	row.add_child(next)
	return row

func tooltip(item: String,count: int,g: Node) -> String:
	if item=="": return "空格"
	var text: String=item+" ×"+str(count)+"\n"+g.item_description(item)
	if g.equipment.ITEMS.has(item): text+="\n"+g.equipment.comparison(item)
	if g.CraftCatalog.RECIPES.has(item): text+="\n制作处："+("铁匠" if g.CraftCatalog.RECIPES[item].owner=="smith" else "皮革匠")
	return text+"\n右键快捷操作 · Shift＋左键选择数量"

func quick_use(item: String) -> void:
	if game.CraftCatalog.WEAPONS.has(item): game.wield(item)
	elif game.equipment.ITEMS.has(item): game.equipment.wear(item,game)
	elif item=="回血药水": game.use_potion()
	elif game.cooking.ENERGY.has(item): game.cooking.eat(item,game)
	else: game.toast("该物品用于合成或任务，可选择数量拆分")

func grid(source: String,data: Dictionary,count: int,compact: bool=false) -> GridContainer:
	game.ensure_quickbar()
	var bag: bool=source=="bag"
	var result:=GridContainer.new(); result.name="BagGrid" if bag else "ChestGrid"; result.columns=6
	result.add_theme_constant_override("h_separation",6); result.add_theme_constant_override("v_separation",5)
	var keys:=keys_for(data,chest_filter)
	var cells: Array=game.bag_stacks.sync(game) if bag else []
	var visible_cells: Array=[]
	if bag:
		for i in range(36):
			if bag_filter=="全部" or (not cells[i].is_empty() and category(str(cells[i].key))==bag_filter): visible_cells.append(i)
	if bag and bag_filter!="全部":
		for i in range(36):
			if cells[i].is_empty(): visible_cells.append(i)
	var page: int=bag_page if bag else chest_page
	for index in range(count):
		var hot: bool=bag and index<6
		var at:=page*12+index-6 if bag else page*30+index
		var cell_index: int=int(visible_cells[at]) if bag and not hot and at>=0 and at<visible_cells.size() else -1
		var key: String=""
		var quantity: int=0
		if hot:
			key=str(game.quickbar[index]); quantity=game.bag_stacks.hot_count(key,game)
		elif bag and cell_index>=0:
			key=str(cells[cell_index].get("key","")); quantity=int(cells[cell_index].get("count",0))
		elif not bag and at<keys.size():
			key=str(keys[at]); quantity=int(data.get(key,0))
		if quantity<=0: key=""
		var slot=load("res://item_slot.gd").new(); slot.icon_font=game.font; slot.jade=true; slot.golden=hot
		slot.slot_minimum=Vector2(74,64) if compact else Vector2(88,76)
		slot.item_name=key; slot.quantity=quantity; slot.cooldown_seconds=game.potion_cooldown if key=="回血药水" else 0.0; slot.tooltip_text=tooltip(key,quantity,game)
		slot.selected=key!="" and key==selected
		slot.drag_payload={"source":source,"target":key,"locked":key=="父母遗书","quick_index":index if hot else -1,"stack_index":cell_index,"count":quantity}
		if key!="":
			slot.drag_payload["key"]=key
			slot.pressed.connect(func():
				if opened_as_chest: game.transfer_item(key,source,quantity,cell_index if bag and not hot else -1)
				else:
					selected=key; selected_stack=cell_index; selected_hot=index if hot else -1
					if hot: game.quickbar_index=index; game.mark_dirty()
					for other in result.get_children(): other.selected=other.item_name==key; other.queue_redraw()
					update_details())
			slot.context_requested.connect(func():
				if opened_as_chest: show_quantity(key,source,cell_index,index if hot else -1,true,quantity)
				else: quick_use(key); show_bag(game))
			slot.quantity_requested.connect(func(): show_quantity(key,source,cell_index,index if hot else -1,opened_as_chest,quantity))
		slot.dropped.connect(func(payload: Dictionary):
			if opened_as_chest and str(payload.get("source",""))!=source:
				game.transfer_item(str(payload.key),str(payload.source),int(payload.get("count",-1)),int(payload.get("stack_index",-1)))
			elif payload.get("source","")=="bag" and bag:
				if hot: game.assign_quickbar(index,str(payload.key))
				elif cell_index>=0:
					if int(payload.get("quick_index",-1))>=0:
						game.assign_quickbar(int(payload.quick_index),"")
						var now: Array=game.bag_stacks.sync(game)
						for i in range(36):
							if now[i].get("key","")==str(payload.key): game.bag_stacks.move(game,i,cell_index); break
					else: game.bag_stacks.move(game,int(payload.get("stack_index",-1)),cell_index)
				if opened_as_chest: show_chest(game)
				else: show_bag(game))
		result.add_child(slot)
	return result

func show_quantity(item: String,source: String,index: int,hot: int,transfer: bool,limit: int) -> void:
	var chest: bool=opened_as_chest
	game.clear_modal(("选择存取数量 · " if transfer else "拆分物品 · ")+item)
	game.modal_body.add_child(jl("拆分不会消耗物品；拆出的材料放入下方空格。" if not transfer else "只移动所选数量，剩余物品保留原处。",15))
	var number:=SpinBox.new(); number.min_value=1; number.max_value=maxi(1,limit if transfer else limit-1); number.step=1; number.value=maxi(1,limit/2)
	number.add_theme_font_override("font",game.font); number.custom_minimum_size=Vector2(300,48); game.modal_body.add_child(number)
	var confirm:=jb("确认",func():
		if transfer: game.transfer_item(item,source,int(number.value),index if source=="bag" and hot<0 else -1)
		else:
			game.bag_stacks.split(game,index,hot,int(number.value)); show_bag(game))
	confirm.disabled=limit<=0 if transfer else limit<2
	game.modal_body.add_child(confirm)
	game.modal_body.add_child(jb("取消",func():
		if chest: show_chest(game)
		else: show_bag(game)))

func update_details() -> void:
	if not is_instance_valid(details): return
	if selected=="" or int(game.inventory.get(selected,0))<=0:
		details.text="选择物品查看说明。"
		use_button.disabled=true
		return
	details.text="%s ×%d\n%s" % [selected,game.inventory[selected],game.item_description(selected)]
	var positions: Array=game.bag_stacks.sync(game)
	if selected_hot>=0 and str(game.quickbar[selected_hot])!=selected: selected_hot=-1
	if selected_stack>=0 and positions[selected_stack].get("key","")!=selected: selected_stack=-1
	if selected_hot<0 and selected_stack<0:
		selected_hot=game.quickbar.find(selected)
		if selected_hot<0:
			for i in range(36):
				if positions[i].get("key","")==selected: selected_stack=i; break
	var wearable: bool=game.equipment.ITEMS.has(selected)
	if wearable: details.text+="\n"+game.equipment.comparison(selected)
	var edible: bool=selected=="回血药水" or game.cooking.ENERGY.has(selected)
	use_button.text="穿戴" if wearable else ("食用" if game.cooking.ENERGY.has(selected) else "使用")
	use_button.disabled=not (edible or wearable or game.CraftCatalog.WEAPONS.has(selected))

func show_bag(g: Node) -> void:
	g.inventory_page=bag_page
	opened_as_chest=false
	g.update_hud()
	prepare(g,"行囊")
	var columns:=HBoxContainer.new()
	columns.add_theme_constant_override("separation",28)
	game.modal_body.add_child(columns)
	var left:=VBoxContainer.new()
	left.custom_minimum_size.x=568
	var left_scroll:=ScrollContainer.new(); left_scroll.custom_minimum_size=Vector2(590,500); left_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED; columns.add_child(left_scroll); left_scroll.add_child(left)
	left.add_child(jl("金框6格固定 · 下方分页 · 右键使用／Shift点击拆分",14))
	left.add_child(tabs("bag"))
	left.add_child(grid("bag",game.inventory,18))
	left.add_child(navigation("bag"))
	details=RichTextLabel.new()
	details.bbcode_enabled=true
	details.fit_content=true
	details.add_theme_font_override("normal_font",game.font)
	details.add_theme_font_size_override("normal_font_size",15)
	details.add_theme_color_override("default_color",Color("244b3d"))
	details.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	details.custom_minimum_size=Vector2(550,58)
	left.add_child(details)
	var actions:=HBoxContainer.new()
	use_button=jb("使用",func(): quick_use(selected); show_bag(game))
	actions.add_child(use_button)
	actions.add_child(jb("拆分",func():
		var cells: Array=game.bag_stacks.sync(game)
		var count: int=game.bag_stacks.hot_count(selected,game) if selected_hot>=0 else (int(cells[selected_stack].get("count",0)) if selected_stack>=0 else 0)
		show_quantity(selected,"bag",selected_stack,selected_hot,false,count)))
	actions.add_child(jb("整理",func(): game.bag_stacks.sort_bag(game); show_bag(game)))
	left.add_child(actions)
	var books:=HBoxContainer.new()
	for name in ["《材料大全》","《草药大全》"]:
		var book: String=name
		var b:=jb(book.trim_prefix("《").trim_suffix("》"),func():
			game.modal.hide()
			game.show_dialog([[book,"材料用于制作与加工，草药用于药品。\n工具无耐久，农田可种植沙麦与药草。\n回血药水：基础草药×2加清水，在家中或村内合成。"]]))
		b.disabled=not game.inventory.has(book)
		books.add_child(b)
	books.add_child(jb("合成大全",func(): show_crafting(game)))
	left.add_child(books)
	var right:=VBoxContainer.new()
	right.custom_minimum_size.x=440
	var right_scroll:=ScrollContainer.new(); right_scroll.custom_minimum_size=Vector2(460,500); right_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED; columns.add_child(right_scroll); right_scroll.add_child(right)
	right.add_child(jl("陆承安 · Lv.%d" % game.level,23))
	var profile=load("res://inventory_profile.gd").new()
	profile.hero=game.actor_visual.walk
	profile.region=game.actor_visual.frames[0][1]
	profile.font=game.font
	profile.owner_game=game
	profile.slot_clicked.connect(func(slot: String):
		if str(game.equipment.worn.get(slot,""))!="": game.equipment.remove(slot,game); show_bag(game))
	right.add_child(profile)
	right.add_child(jl("生命  %d / %d\n攻击  %d\n防御  %d\n铜钱  %d" % [game.hp,game.max_hp,game.attack_power,game.defense,game.coins],21))
	right.add_child(jl("左侧防具3栏 · 右侧饰品4栏；点击已穿戴栏卸下。",14))
	right.add_child(jb("关闭",func(): game.modal.hide()))
	if not game.flags.get("pending_items",{}).is_empty():
		right.add_child(jb("取回暂存物品",func(): show_pending(game)))
	update_details()

func show_pending(g: Node) -> void:
	prepare(g,"旧存档暂存物品")
	var pending: Dictionary=game.flags.get("pending_items",{})
	for item in pending:
		var key: String=item
		var b:=jb("取回 %s ×%d" % [key,pending[key]],func():
			if not game.inventory.has(key) and keys_for(game.inventory,"全部").size()>=42: return
			game.inventory[key]=int(game.inventory.get(key,0))+int(pending[key])
			pending.erase(key)
			game.flags["pending_items"]=pending
			game.mark_dirty()
			show_pending(game))
		b.disabled=not game.inventory.has(key) and keys_for(game.inventory,"全部").size()>=42
		game.modal_body.add_child(b)
	game.modal_body.add_child(jb("返回",func(): show_bag(game)))

func show_crafting(g: Node) -> void:
	prepare(g,"合成大全")
	game.modal_body.add_child(jl("简单食物与药品可随身合成；沙麦须到周满仓处付费磨面。",16))
	var scroll:=ScrollContainer.new()
	scroll.custom_minimum_size=Vector2(1050,380)
	var content:=VBoxContainer.new()
	content.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	scroll.add_child(content)
	game.modal_body.add_child(scroll)
	for key in game.cooking.RECIPES:
		var item: String=key
		var recipe: Dictionary=game.cooking.RECIPES[item]
		var info:=RichTextLabel.new(); info.bbcode_enabled=true; info.fit_content=true; info.custom_minimum_size.x=1000
		info.add_theme_font_override("normal_font",game.font); info.add_theme_font_size_override("normal_font_size",14); info.add_theme_color_override("default_color",Color("244b3d")); content.add_child(info)
		if not game.inventory.has(recipe.book): content.add_child(jl("尚需"+str(recipe.book),15))
		var row:=HBoxContainer.new()
		var amount:=SpinBox.new()
		amount.min_value=1
		amount.max_value=maxi(1,game.cooking.available(item,game))
		amount.value=1
		row.add_child(amount)
		var craft:=jb("合成一瓶回血药水" if item=="回血药水" else "合成"+item,func():
			game.cooking.make(item,game,int(amount.value))
			if game.dialogue_panel.visible: game.modal.hide()
			else: show_crafting(game))
		craft.disabled=game.cooking.available(item,game)<1
		row.add_child(craft)
		var update:=func(_value: float):
			var text: String=item+" ×%d\n" % int(amount.value)
			for material in recipe.materials:
				var need: int=int(recipe.materials[material])*int(amount.value); var have: int=int(game.inventory.get(material,0))
				text+="[color=#%s]%s %d/%d[/color]  " % ["37734b" if have>=need else "a34535",material,have,need]
			text+="\n恢复35%生命 · 药水冷却30秒" if item=="回血药水" else "\n恢复%d精力 · 食物无冷却" % recipe.heal
			info.text=text
			craft.disabled=game.cooking.available(item,game)<int(amount.value) or not game.cooking.fits(item,int(amount.value),recipe.materials,game)
		amount.value_changed.connect(update); update.call(amount.value)
		content.add_child(row)
	game.modal_body.add_child(jl("清水与简单处理不额外消耗；食物无冷却，药水冷却30秒；食物不直接回血，精力达到70%时缓慢回血。",15))
	game.modal_body.add_child(jb("返回行囊",func(): show_bag(game)))

func show_chest(g: Node) -> void:
	g.inventory_page=bag_page
	opened_as_chest=true
	prepare(g,"陆家旧宅 · 储物箱")
	game.modal_body.add_child(jl("点击或跨栏拖动整组存取；右键或Shift点击选择数量。遗书留存家中。",15))
	var columns:=HBoxContainer.new()
	columns.add_theme_constant_override("separation",34)
	game.modal_body.add_child(columns)
	var left:=VBoxContainer.new()
	var left_scroll:=ScrollContainer.new(); left_scroll.custom_minimum_size=Vector2(500,500); left_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED; columns.add_child(left_scroll); left_scroll.add_child(left)
	left.add_child(jl("箱中物品 · 300格",20))
	left.add_child(tabs("chest"))
	left.add_child(grid("chest",game.flags.get("storage",{}),30,true))
	left.add_child(navigation("chest"))
	var right:=VBoxContainer.new()
	var right_scroll:=ScrollContainer.new(); right_scroll.custom_minimum_size=Vector2(570,500); right_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED; columns.add_child(right_scroll); right_scroll.add_child(right)
	right.add_child(jl("随身行囊 · 6固定＋36分页",20))
	right.add_child(tabs("bag"))
	right.add_child(grid("bag",game.inventory,18,true))
	right.add_child(navigation("bag"))
	right.add_child(jl("手册附件独立保存，不占物品格。",14))
	if not game.flags.get("chest_taken",false):
		right.add_child(jb("取出工具和种子",func():
			for key in ["锄头","斧子","镐子","初始种子"]:
				game.transfer_item(key,"chest")
			show_chest(game)))
	right.add_child(jb("关闭",func(): game.modal.hide()))
