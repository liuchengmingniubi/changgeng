extends RefCounted
const Catalog=preload("res://craft_catalog.gd")
const SELL={"沙麦":6}
func stock(g: Node,owner: String) -> Dictionary:
	if owner=="smith": return {}
	if owner=="leather": return {"粗布":{"price":3,"level":1}}
	var result: Dictionary={"铁锭":{"price":50,"level":1,"limit":5},"铜锭":{"price":45,"level":1,"limit":5},"兽皮":{"price":20,"level":1,"limit":16},"初始种子":{"price":8,"level":1},"药草种子":{"price":12,"level":1},"浅泉石坠":{"price":30,"level":1},"赤铜戒":{"price":40,"level":1},"皮绳手环":{"price":35,"level":1},"旧布腰带":{"price":20,"level":1}}
	if g.flags.get("chapter1_complete",false): result.merge({"甘草":{"price":18,"level":1},"清心草":{"price":25,"level":1}})
	for item in Catalog.RECIPES:
		var r: Dictionary=Catalog.RECIPES[item]
		if r.book!="": result[r.book]={"price":int(r.price),"level":int(r.level)}
	return result
func service_error(g: Node,owner: String) -> String:
	if g.scene_id!="village" or not g.npc_life.service_open(owner,g): return "已经歇业，请在营业时间再来"
	var worker: Dictionary=g.npc_life.live.get(owner,{})
	if worker.get("scene","")!=g.scene_id or g.player.distance_to(worker.get("pos",Vector2.ZERO))>120: return "请到店主身边交易"
	return ""
func error(g: Node,owner: String,item: String,count: int,selling: bool=false) -> String:
	if count<=0 or count>999: return "数量须为1—999"
	var service:=service_error(g,owner)
	if service!="": return service
	if selling:
		if owner!="merchant" or not SELL.has(item): return "店主不收购此物品"
		if int(g.inventory.get(item,0))<count: return "持有数量不足"
		return ""
	var listing: Dictionary=stock(g,owner).get(item,{})
	if listing.is_empty(): return "此商品尚未开放"
	if g.level<int(listing.level): return "达到%d级才可购买" % int(listing.level)
	if listing.has("limit") and count>remaining(g,item,int(listing.limit)): return "本周限购剩余%d个" % remaining(g,item,int(listing.limit))
	if g.coins<int(listing.price)*count: return "铜钱不足，还差%d文" % (int(listing.price)*count-g.coins)
	if int(g.inventory.get(item,0))<=0 and g.equipment.count_items(g)>=42: return "背包已满，请先整理物品"
	return ""
func transact(g: Node,owner: String,item: String,count: int,selling: bool=false) -> bool:
	var reason:=error(g,owner,item,count,selling)
	if reason!="": g.toast(reason); return false
	if selling:
		g.inventory[item]=int(g.inventory[item])-count; g.change_coins(int(SELL[item])*count,"出售物品·"+item)
	else:
		var price: int=int(stock(g,owner)[item].price)
		if stock(g,owner)[item].has("limit"):
			var usage: Dictionary=g.flags.get("weekly_supply",{}); var key:=str(int((g.farming.day-1)/7))+":"+item; usage[key]=int(usage.get(key,0))+count; g.flags.weekly_supply=usage
		g.change_coins(-price*count,"购买物品·"+item); g.inventory[item]=int(g.inventory.get(item,0))+count
	g.play_sound("pickup"); g.update_hud(); g.mark_dirty()
	g.toast(("售出" if selling else "获得")+" %s ×%d" % [item,count])
	return true
func small(g: Node,text: String,callback: Callable) -> Button:
	var button: Button=g.inventory_ui.jb(text,callback); button.add_theme_font_size_override("font_size",14); return button
func show(g: Node,owner: String="merchant",books_only: bool=false) -> void:
	g.inventory_ui.prepare(g,"康裕 · 一次性制作书" if books_only else ("康裕 · 商铺" if owner=="merchant" else "基础材料"))
	g.modal_body.add_child(g.label("铜钱 %d文 · 点击商品选择数量；制作书每制作一件消耗一本。" % g.coins,14))
	var pane:=ScrollContainer.new(); pane.custom_minimum_size=Vector2(1080,360)
	var list:=VBoxContainer.new(); pane.add_child(list); g.modal_body.add_child(pane)
	for key in stock(g,owner):
		var item: String=key; var r: Dictionary=stock(g,owner)[item]
		if item.begins_with("制作书·")!=books_only: continue
		var quota: String=" · 本周剩余%d/%d" % [remaining(g,item,int(r.limit)),r.limit] if r.has("limit") else ""
		var lock: String=" · Lv.%d解锁" % int(r.level) if g.level<int(r.level) else ""
		var b:=small(g,"%s · 单价%d文%s" % ["沙麦种子" if item=="初始种子" else item,r.price,lock+quota],func(): show_quantity(g,owner,item,false,books_only))
		b.tooltip_text=g.item_description(item)+lock; list.add_child(b)
	if owner=="merchant" and not books_only:
		list.add_child(small(g,"制作书 · 按等级开放",func(): show(g,owner,true)))
		list.add_child(small(g,"出售沙麦 · 单价6文 · 持有%d" % int(g.inventory.get("沙麦",0)),func(): show_quantity(g,owner,"沙麦",true,false)))
		if not g.flags.get("chapter1_complete",false): list.add_child(g.label("甘草、清心草：完成第一章后开放购买。",14))
	g.modal_body.add_child(small(g,"返回商铺" if books_only else ("返回制作" if owner!="merchant" else "关闭"),func():
		if books_only: show(g,"merchant",false)
		elif owner!="merchant": g.craft_ui.show_crafting()
		else: g.modal.hide()))
func show_quantity(g: Node,owner: String,item: String,selling: bool,books_only: bool) -> void:
	g.inventory_ui.prepare(g,("出售 · " if selling else "购买 · ")+item)
	var listing: Dictionary=stock(g,owner).get(item,{})
	var price: int=int(SELL.get(item,0)) if selling else int(listing.get("price",0))
	var pane:=ScrollContainer.new(); pane.custom_minimum_size=Vector2(1080,350); pane.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	var body:=VBoxContainer.new(); pane.add_child(body); g.modal_body.add_child(pane)
	var info: Label=g.label(g.item_description(item),14); info.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; info.custom_minimum_size.x=1000; body.add_child(info)
	body.add_child(g.label("单价 %d文 · 持有%d" % [price,int(g.inventory.get(item,0))],14))
	var number:=SpinBox.new(); number.name="TradeQuantity"; number.min_value=1; number.max_value=999; number.step=1; number.value=1; number.custom_minimum_size=Vector2(300,40); body.add_child(number)
	var total: Label=g.label("",14); body.add_child(total)
	var reason: Label=g.label("",14,"a34535"); body.add_child(reason)
	var confirm:=small(g,"确认出售" if selling else "确认购买",func():
		if transact(g,owner,item,int(number.value),selling): show(g,owner,books_only))
	g.modal_body.add_child(confirm)
	var update:=func(_value: float):
		total.text=("获得" if selling else "总价")+" %d文" % (price*int(number.value))
		reason.text=error(g,owner,item,int(number.value),selling)
		confirm.disabled=reason.text!=""
	number.value_changed.connect(update); update.call(1.0)
	g.modal_body.add_child(small(g,"取消",func(): show(g,owner,books_only)))

func remaining(g: Node,item: String,limit: int) -> int:
	var usage: Dictionary=g.flags.get("weekly_supply",{})
	return maxi(0,limit-int(usage.get(str(int((g.farming.day-1)/7))+":"+item,0)))
