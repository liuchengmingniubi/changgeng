extends RefCounted
const BASE_AFFINITY:=1.5
const PROTECTED=["父母遗书","军籍腰牌","《材料大全》","《草药大全》","旧军扣","写给姐姐的信","给姐姐的信"]
const REACTIONS={"elder":"你自己留够了么？好，我收着。往后路上也别亏待自己。","smith":"搁这儿吧。你的心意我记下，打甲的工序可不能因此省。","doctor":"谢谢你想着我。顾别人之前，也记得照顾好自己。","merchant":"送我的？……好，这回不跟你算价。","farmer":"东西收下了。过日子就得细水长流，别一下都送了人。","innkeeper":"你这孩子还想着别人。行，我收着，你得空也来坐坐。","leather":"我不大会说好听话。东西我收好了，谢谢。","captain":"这是你的私物，我领这份心意。值勤的规矩照旧。","scout":"收下了。出关前也检查检查自己，别光顾着旁人。","soldier":"给我的？那我收着。下次值守，我多替你留神些。","medic":"谢谢。容我先收好，可别学我把自己的事总搁到最后。","guard_day":"多谢惦记。轮到我值守，照样把关门看好。","guard_night":"……谢谢。夜里出门，记得带灯。"}
var bypass_npc: String=""
var pending: Dictionary={}
var serial:=0
func cancel() -> void:
	pending.clear(); serial+=1
func allowed(item: String,g: Node) -> bool:
	if item=="" or item in PROTECTED or item.contains("《"): return false
	if g.CraftCatalog.WEAPONS.has(item) or g.equipment.ITEMS.has(item): return false
	if item in ["锄头","斧子","镐子","稿子"] or g.inventory_ui.category(item)=="装备": return false
	if item.contains("遗物") or item.contains("遗骨") or item.contains("刻名") or item in g.flags.get("quest_items",[]): return false
	return true
func held_item(g: Node) -> String:
	g.ensure_quickbar()
	var item: String=str(g.quickbar[g.quickbar_index])
	return item if allowed(item,g) and g.bag_stacks.hot_count(item,g)>0 else ""
func near_npc(id: String,g: Node) -> bool:
	if not g.npc_life.PEOPLE.has(id): return false
	var person: Dictionary=g.npc_life.live.get(id,{})
	return person.get("scene","") == g.scene_id and g.player.distance_to(person.get("pos",Vector2(-99999,-99999)))<=90
func small(g: Node,text: String,callback: Callable) -> Button:
	var button: Button=g.button(text,callback); button.add_theme_font_size_override("font_size",14); return button
func continue_talk(id: String,g: Node) -> void:
	cancel(); bypass_npc=id; g.modal.hide(); g.interact(id)
func offer(id: String,g: Node) -> bool:
	if bypass_npc==id: bypass_npc=""; return false
	if g.flags.get("skip_npc_menu",false) or not near_npc(id,g): return false
	var item:=held_item(g)
	if item=="": return false
	cancel(); g.clear_modal(g.npc_life.PEOPLE[id].name+" · 交谈")
	g.modal_body.add_child(g.label("手持：%s ×%d" % [item,g.bag_stacks.hot_count(item,g)],14))
	var wait: int=g.relationships.gift_wait(id,g)
	var gift: Button=small(g,"赠送" if wait==0 else "赠送 · 还需%d天" % wait,func(): show_confirm(id,item,g)); gift.disabled=wait>0; g.modal_body.add_child(gift)
	g.modal_body.add_child(small(g,"正常交谈",func(): continue_talk(id,g)))
	g.modal_body.add_child(small(g,"离开",func(): cancel(); g.modal.hide()))
	return true
func show_confirm(id: String,item: String,g: Node) -> void:
	cancel()
	if not near_npc(id,g) or held_item(g)!=item: g.toast("请拿好物品，靠近对方再赠送"); return
	if g.relationships.gift_wait(id,g)>0: g.toast("每三个游戏日只能给同一人送一份礼物"); return
	var token: int=serial
	pending={"npc":id,"item":item,"slot":g.quickbar_index,"token":token}
	g.clear_modal("赠送给"+str(g.npc_life.PEOPLE[id].name))
	g.modal_body.add_child(g.label("%s · 手持%d件" % [item,g.bag_stacks.hot_count(item,g)],14))
	g.modal_body.add_child(g.label("每三天仅送一件；%s礼物，亲密度最多 +%.1f。" % ["喜欢的" if g.relationships.liked(id,item) else "普通",g.relationships.gift_gain(id,item)],14))
	var slot=load("res://item_slot.gd").new(); slot.icon_font=g.font; slot.jade=true; slot.item_name=item; slot.quantity=1; slot.slot_minimum=Vector2(90,75); slot.tooltip_text=g.inventory_ui.tooltip(item,1,g); g.modal_body.add_child(slot)
	var number:=SpinBox.new(); number.name="GiftQuantity"; number.min_value=1; number.max_value=1; number.editable=false; number.step=1; number.value=1; number.custom_minimum_size=Vector2(260,42); g.modal_body.add_child(number)
	number.value_changed.connect(func(value: float): slot.quantity=int(value); slot.queue_redraw())
	g.modal_body.add_child(small(g,"确认赠送",func(): accept(g,token,int(number.value))))
	g.modal_body.add_child(small(g,"取消",func(): cancel(); offer(id,g)))
func accept(g: Node,token: int,count: int) -> bool:
	if pending.is_empty() or int(pending.get("token",-1))!=token: g.toast("此次赠送已取消或完成"); return false
	var id: String=str(pending.npc); var item: String=str(pending.item)
	if not near_npc(id,g): g.toast("请靠近对方再赠送"); return false
	if not allowed(item,g) or held_item(g)!=item or g.quickbar_index!=int(pending.slot): g.toast("手持物品已改变，请重新选择"); return false
	if count!=1: g.toast("每次只能送一件礼物"); return false
	if count>g.bag_stacks.hot_count(item,g): g.toast("手持数量不足"); return false
	if g.relationships.gift_wait(id,g)>0: g.toast("每三个游戏日只能给同一人送一份礼物"); return false
	# No mutation until the target, item, quantity and confirmation are valid.
	cancel()
	g.inventory[item]=int(g.inventory.get(item,0))-count
	var gain: float=g.relationships.change(id,g.relationships.gift_gain(id,item),g)
	g.relationships.mark_gift(id,g)
	g.flags["gifts_"+id]=int(g.flags.get("gifts_"+id,0))+1
	g.bag_stacks.sync(g); g.update_hud(); g.mark_dirty()
	g.modal.hide(); g.play_sound("pickup")
	g.toast("赠出 %s ×%d · 亲密度 +%.1f" % [item,count,gain])
	g.show_dialog([[g.npc_life.PEOPLE[id].name,str(REACTIONS.get(id,"谢谢你的心意，我收下了。"))+(" 这正是我喜欢的，多谢。" if g.relationships.liked(id,item) else "")]])
	return true
