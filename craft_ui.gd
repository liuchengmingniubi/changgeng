extends RefCounted
const Catalog=preload("res://craft_catalog.gd")
var owner_id: String="smith"
var book: String=""
var book_count:=1
var place_amount:=1
var batch_amount:=1
var materials: Array=["","","","","","","","",""]
var amounts: Array=[0,0,0,0,0,0,0,0,0]
var g: Node
var output_slot: Button
var result_label: RichTextLabel
var make_button: Button
func reserved() -> Dictionary:
	var result: Dictionary={}
	if book!="": result[book]=book_count
	for i in range(9):
		if materials[i]!="": result[materials[i]]=int(result.get(materials[i],0))+int(amounts[i])
	return result
func available(item: String) -> int: return maxi(0,int(g.inventory.get(item,0))-int(reserved().get(item,0)))
func put(item: String,index: int,is_book: bool=false,quantity: int=1) -> bool:
	if quantity<=0 or int(g.inventory.get(item,0))<=0: return false
	if is_book:
		if not item.begins_with("制作书·"): g.toast("此格只能放制作书"); return false
		var n: int=mini(quantity,available(item))
		if n<=0: return false
		if book!=item: book=item; book_count=0
		book_count+=n
	else:
		if index<0 or index>=9 or item.begins_with("制作书·"): return false
		var n: int=mini(quantity,available(item))
		if n<=0: g.toast("该物品已全部放入材料区"); return false
		if materials[index]!=item: materials[index]=item; amounts[index]=0
		amounts[index]=int(amounts[index])+n
	return true
func candidates() -> Array:
	var result: Array=[]
	var placed:=reserved()
	for item in Catalog.RECIPES:
		var r: Dictionary=Catalog.RECIPES[item]
		if r.owner!=owner_id: continue
		if book!="" and r.book!=book: continue
		var extra:=false
		for key in placed:
			if key==book: continue
			if not r.materials.has(key): extra=true
		if not extra and (book!="" or not placed.is_empty()): result.append(item)
	var complete: Array=[]
	for item in result:
		var recipe: Dictionary=Catalog.RECIPES[item]
		var enough: bool=recipe.book=="" or recipe.book==book
		for key in recipe.materials:
			if int(placed.get(key,0))<int(recipe.materials[key]): enough=false
		if enough: complete.append(item)
	return complete if not complete.is_empty() else result
func reason(item: String,quantity: int=1) -> String:
	if quantity<=0 or quantity>999: return "制作数量须为1—999"
	if not Catalog.RECIPES.has(item): return "请放入制作书或材料；每次拖入一份，点击材料格取回该组。"
	var r: Dictionary=Catalog.RECIPES[item]
	if r.owner!=owner_id: return "请找另一位工匠"
	if r.book!="" and (book!=r.book or book_count<quantity): return "缺少对应一次性制作书"
	var placed:=reserved()
	for key in placed:
		if key!=book and not r.materials.has(key): return "包含配方之外的材料"
	for key in r.materials:
		if int(placed.get(key,0))<int(r.materials[key])*quantity: return "缺少 %s ×%d" % [key,int(r.materials[key])*quantity-int(placed.get(key,0))]
	if g.coins<int(r.fee)*quantity: return "铜钱不足：工钱%d文（试玩价）" % (int(r.fee)*quantity)
	var after: Dictionary=g.inventory.duplicate()
	var needed: Dictionary={}
	for key in r.materials: needed[key]=int(r.materials[key])*quantity
	if r.book!="": needed[r.book]=quantity
	for key in needed:
		if int(after.get(key,0))<int(needed[key]): return "背包中的材料已不足"
		after[key]=int(after[key])-int(needed[key])
	after[item]=int(after.get(item,0))+quantity
	if g.inventory_ui.keys_for(after,"全部").size()>42: return "背包已满，无法放入成品"
	return ""
func craft(item: String,quantity: int=1) -> bool:
	var error:=reason(item,quantity)
	if error!="": g.toast(error); return false
	if g.scene_id!="village" or not g.npc_life.service_open(owner_id,g): g.toast("工匠已收工，请在工作时间来访"); return false
	var worker: Dictionary=g.npc_life.live.get(owner_id,{})
	if worker.get("scene","")!=g.scene_id or g.player.distance_to(worker.get("pos",Vector2.ZERO))>120: g.toast("请到工匠身边制作"); return false
	var r: Dictionary=Catalog.RECIPES[item]
	for key in r.materials: g.inventory[key]=int(g.inventory[key])-int(r.materials[key])*quantity
	if r.book!="": g.inventory[r.book]=int(g.inventory[r.book])-quantity
	g.change_coins(-int(r.fee)*quantity,"加工费" if item=="皮革" else "打造费")
	g.inventory[item]=int(g.inventory.get(item,0))+quantity
	g.flags["forged_armor"]=true
	g.play_sound("craft")
	g.toast("获得 %s ×%d" % [item,quantity])
	if r.book!="":
		book_count-=quantity
		if book_count<=0: book=""; book_count=1
	for key in r.materials:
		var left: int=int(r.materials[key])*quantity
		for i in range(9):
			if materials[i]!=key: continue
			var take: int=mini(int(amounts[i]),left); amounts[i]-=take; left-=take
			if int(amounts[i])<=0: materials[i]=""; amounts[i]=0
	batch_amount=1
	g.recalculate_stats(); g.mark_dirty()
	return true
func show_menu(game: Node,owner: String) -> void:
	g=game; owner_id=owner
	book=""; book_count=1; batch_amount=1; materials.fill(""); amounts.fill(0)
	g.clear_modal("郭成 · 铁匠" if owner=="smith" else "冯厚 · 皮革匠")
	g.modal_body.add_child(g.button("制作",func(): show_crafting()))
	var enhance: Button=g.button("强化 · 暂未开放",func(): pass)
	enhance.disabled=true
	enhance.tooltip_text="击败狼人后开放"
	g.modal_body.add_child(enhance)
	g.modal_body.add_child(g.button("合成书",func(): show_catalog()))
	g.modal_body.add_child(g.button("交谈",func(): g.story_events.routine_menu(owner_id,g)))
	g.modal_body.add_child(g.button("关闭",func(): g.modal.hide()))
func recipe_text(item: String) -> String:
	var r: Dictionary=Catalog.RECIPES[item]
	var text: String=item+"\n"+Catalog.describe(item)+"\n"
	if r.book!="": text+="%s %d/1（每件消耗一本；商人Lv.%d开放）\n" % [r.book,g.inventory.get(r.book,0),r.level]
	else: text+="不需要制作书\n"
	for key in r.materials: text+="%s %d/%d\n" % [key,g.inventory.get(key,0),r.materials[key]]
	return text+"工钱 %d文（试玩价，后续可调）" % int(r.fee)
func show_catalog() -> void:
	g.inventory_ui.prepare(g,"合成书 · 配方图鉴")
	var scroll:=ScrollContainer.new(); scroll.custom_minimum_size=Vector2(1080,360)
	var grid:=GridContainer.new(); grid.columns=3; scroll.add_child(grid); g.modal_body.add_child(scroll)
	for name in Catalog.RECIPES:
		var item: String=name
		if Catalog.RECIPES[item].owner!=owner_id: continue
		var b: Button=g.button(item,func():
			g.inventory_ui.prepare(g,item+" · 配方")
			var pane:=ScrollContainer.new(); pane.custom_minimum_size=Vector2(1080,360); g.modal_body.add_child(pane)
			var info: Label=g.label(recipe_text(item),17); pane.add_child(info)
			g.modal_body.add_child(compact_button("按配方放入",func(): prefill(item); show_crafting()))
			g.modal_body.add_child(compact_button("返回图鉴",func(): show_catalog())))
		b.tooltip_text=recipe_text(item); grid.add_child(b)
	g.modal_body.add_child(g.label("金属饰品模具由铁匠负责；皮革裁样板、时装和饰品新配方待确定。",14))
	g.modal_body.add_child(compact_button("返回",func(): show_menu(g,owner_id)))
func prefill(item: String) -> void:
	book=""; book_count=1; batch_amount=1; materials.fill(""); amounts.fill(0)
	var r: Dictionary=Catalog.RECIPES[item]
	if int(g.inventory.get(r.book,0))>0: book=r.book
	var i:=0
	for key in r.materials:
		if int(g.inventory.get(key,0))>0: materials[i]=key; amounts[i]=mini(int(g.inventory[key]),int(r.materials[key])); i+=1
func create_slot(item: String,count: int,index: int,is_book: bool=false) -> Button:
	var b=load("res://item_slot.gd").new()
	b.icon_font=g.font; b.jade=true; b.golden=is_book; b.slot_minimum=Vector2(85,70); b.item_name=item; b.quantity=count
	b.drag_payload={"source":"craft","key":item,"slot":index,"book":is_book}
	b.dropped.connect(func(data: Dictionary):
		if data.get("source","")=="bag":
			if put(str(data.key),index,is_book,place_amount): show_crafting()
		elif data.get("source","")=="craft" and not is_book and not data.get("book",false):
			var other: int=int(data.slot)
			var k: String=materials[index]; var n: int=amounts[index]
			materials[index]=materials[other]; amounts[index]=amounts[other]; materials[other]=k; amounts[other]=n; show_crafting())
	b.pressed.connect(func():
		if is_book: book=""
		else: materials[index]=""; amounts[index]=0
		show_crafting())
	return b
func show_crafting() -> void:
	g.inventory_ui.prepare(g,"制作 · "+("铁匠铺" if owner_id=="smith" else "皮革铺"))
	g.modal_body.add_child(g.label("制作书每件消耗一本；材料格无需排列顺序。关闭窗口不会消耗暂放物品。",15))
	var columns:=HBoxContainer.new(); columns.add_theme_constant_override("separation",24); g.modal_body.add_child(columns)
	var left:=VBoxContainer.new(); left.custom_minimum_size.x=290; columns.add_child(left)
	left.add_child(g.label("一次性制作书",17)); left.add_child(create_slot(book,book_count if book!="" else 0,-1,true))
	left.add_child(g.label("材料 · 3×3",17)); var grid:=GridContainer.new(); grid.columns=3; left.add_child(grid)
	for i in range(9): grid.add_child(create_slot(materials[i],int(amounts[i]),i))
	var middle:=VBoxContainer.new(); middle.custom_minimum_size.x=250; columns.add_child(middle)
	middle.add_child(g.label("→ 成品预览",16))
	var counter:=HBoxContainer.new(); counter.add_child(g.label("制作件数",12))
	var batch:=SpinBox.new(); batch.name="CraftQuantity"; batch.min_value=1; batch.max_value=999; batch.step=1; batch.value=batch_amount; counter.add_child(batch); middle.add_child(counter)
	var choices:=candidates(); var item: String=str(choices[0]) if choices.size()==1 else ""
	output_slot=load("res://item_slot.gd").new(); output_slot.icon_font=g.font; output_slot.jade=true; output_slot.item_name=item; output_slot.quantity=1; output_slot.slot_minimum=Vector2(100,75); middle.add_child(output_slot)
	result_label=rich_label("")
	var info_scroll:=ScrollContainer.new(); info_scroll.custom_minimum_size=Vector2(250,120); info_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED; middle.add_child(info_scroll); info_scroll.add_child(result_label); result_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	var error:=reason(item,batch_amount)
	var actions:=GridContainer.new(); actions.columns=2; middle.add_child(actions)
	make_button=compact_button("制作",func():
		if craft(item,batch_amount): show_crafting())
	make_button.disabled=item=="" or error!=""; actions.add_child(make_button)
	actions.add_child(compact_button("合成书",func(): show_catalog()))
	actions.add_child(compact_button("基础材料",func(): show_supplies()))
	actions.add_child(compact_button("返回",func(): show_menu(g,owner_id)))
	var right:=VBoxContainer.new(); columns.add_child(right)
	right.add_child(g.label("背包 · 点击或拖放材料",14))
	var placing:=HBoxContainer.new(); placing.add_child(g.label("每次放入",12))
	var amount:=SpinBox.new(); amount.name="PlaceQuantity"; amount.min_value=1; amount.max_value=999; amount.value=place_amount; amount.step=1; amount.value_changed.connect(func(value: float): place_amount=int(value)); placing.add_child(amount); right.add_child(placing)
	var scroll:=ScrollContainer.new(); scroll.custom_minimum_size=Vector2(440,350); right.add_child(scroll)
	var bag:=GridContainer.new(); bag.columns=4; scroll.add_child(bag)
	for key in g.inventory:
		var name: String=key
		var count:=available(name)
		if count<=0 or name.contains("《"): continue
		var slot=load("res://item_slot.gd").new(); slot.icon_font=g.font; slot.jade=true; slot.slot_minimum=Vector2(95,72); slot.item_name=name; slot.quantity=count; slot.drag_payload={"source":"bag","key":name}
		slot.pressed.connect(func():
			if name.begins_with("制作书·"): put(name,-1,true,place_amount)
			else:
				var index: int=materials.find(name)
				if index<0: index=materials.find("")
				if index>=0: put(name,index,false,place_amount)
			show_crafting())
		slot.dropped.connect(func(data: Dictionary):
			if data.get("source","")=="craft":
				if data.get("book",false): book=""
				else: materials[int(data.slot)]=""; amounts[int(data.slot)]=0
				show_crafting())
		bag.add_child(slot)
	refresh_preview(item)
	batch.value_changed.connect(func(value: float): batch_amount=int(value); refresh_preview(item))
func show_supplies() -> void:
	g.commerce.show(g,owner_id)
func show_bookshop(game: Node) -> void:
	g=game; g.commerce.show(g,"merchant",true)

func compact_button(text: String,callback: Callable) -> Button:
	var b: Button=g.inventory_ui.jb(text,callback)
	b.add_theme_font_size_override("font_size",14)
	b.custom_minimum_size.x=120
	return b

func rich_label(text: String) -> RichTextLabel:
	var label:=RichTextLabel.new(); label.bbcode_enabled=true; label.fit_content=true; label.custom_minimum_size.x=230
	label.add_theme_font_override("normal_font",g.font); label.add_theme_font_size_override("normal_font_size",14); label.add_theme_color_override("default_color",Color("244b3d")); label.text=text
	return label
func refresh_preview(item: String) -> void:
	output_slot.quantity=batch_amount; output_slot.queue_redraw()
	var error:=reason(item,batch_amount)
	make_button.disabled=item=="" or error!=""
	if item=="": result_label.text="请放入制作书或材料，选择唯一配方。"; return
	var r: Dictionary=Catalog.RECIPES[item]; var placed:=reserved()
	var text: String=item+" ×%d\n" % batch_amount
	if r.book!="": text+="[color=#%s]%s %d/%d[/color]\n" % ["37734b" if book==r.book and book_count>=batch_amount else "a34535",r.book,book_count if book==r.book else 0,batch_amount]
	else: text+="无需制作书\n"
	for key in r.materials:
		var need: int=int(r.materials[key])*batch_amount; var have: int=int(placed.get(key,0))
		text+="[color=#%s]%s 已放%d／需%d[/color]\n" % ["37734b" if have>=need else "a34535",key,have,need]
	text+="工钱 %d文（试玩价）" % (int(r.fee)*batch_amount)
	if error!="": text+="\n[color=#a34535]"+error+"[/color]"
	result_label.text=text
