extends RefCounted
const RECIPES := {
 "馒头":{"materials":{"面粉":1},"heal":20,"book":"《材料大全》"},
 "面条":{"materials":{"面粉":2},"heal":45,"book":"《材料大全》"},
 "草药饼":{"materials":{"面粉":1,"基础草药":1},"heal":30,"book":"《材料大全》"},
 "回血药水":{"materials":{"基础草药":2},"heal":0,"book":"《草药大全》"}}
const ENERGY := {"馒头":20,"面条":45,"草药饼":30}
const MILL_POS := Vector2(435,2130)
func available(item: String,game: Node) -> int:
	if not RECIPES.has(item): return 0
	var recipe: Dictionary=RECIPES[item]
	if not game.inventory.has(recipe.book): return 0
	var amount:=9999
	for key in recipe.materials: amount=mini(amount,int(game.inventory.get(key,0))/int(recipe.materials[key]))
	return amount
func fits(item: String,amount: int,materials: Dictionary,game: Node) -> bool:
	var used: int=game.equipment.count_items(game)
	for key in materials:
		if int(game.inventory.get(key,0))==int(materials[key])*amount: used-=1
	if int(game.inventory.get(item,0))<=0: used+=1
	return used<=42
func make(item: String,game: Node,amount: int=1) -> bool:
	if amount<=0 or not RECIPES.has(item): return false
	if available(item,game)<amount: game.toast("材料不足或尚未获得对应手册"); return false
	var recipe: Dictionary=RECIPES[item]
	if not fits(item,amount,recipe.materials,game): game.toast("背包已满"); return false
	for key in recipe.materials: game.inventory[key]=int(game.inventory[key])-int(recipe.materials[key])*amount
	game.inventory[item]=int(game.inventory.get(item,0))+amount
	game.play_sound("craft")
	game.toast("制作完成：%s ×%d" % [item,amount])
	if item=="回血药水": game.flags["crafted_potion"]=true; game.advance(5)
	game.update_hud()
	game.mark_dirty()
	return true
func mill(game: Node,amount: int=1) -> bool:
	if game.scene_id!="mill" or game.player.distance_to(Vector2(780,410))>180: game.toast("请到公共农田南侧的周家磨坊磨面"); return false
	if not game.npc_life.service_open("farmer",game): game.toast("周满仓尚未到磨坊上工"); return false
	if amount<=0 or int(game.inventory.get("沙麦",0))<amount or game.coins<amount: game.toast("沙麦或铜钱不足"); return false
	if not fits("面粉",amount,{"沙麦":1},game): game.toast("背包已满"); return false
	game.inventory["沙麦"]=int(game.inventory["沙麦"])-amount
	game.change_coins(-amount,"磨面费")
	game.inventory["面粉"]=int(game.inventory.get("面粉",0))+amount
	game.flags["milled_flour"]=true
	game.play_sound("craft")
	game.toast("磨成面粉 ×%d，支付%d文" % [amount,amount])
	game.update_hud()
	game.mark_dirty()
	return true
func show_mill(game: Node) -> void:
	game.clear_modal("周满仓 · 磨面")
	game.modal_body.add_child(game.label("沙麦×1＋铜钱×1 → 面粉×1",20))
	game.modal_body.add_child(game.label("沙麦 %d份 · 铜钱 %d文" % [game.inventory.get("沙麦",0),game.coins],17))
	var amount:=SpinBox.new()
	amount.min_value=1
	amount.max_value=maxi(1,mini(int(game.inventory.get("沙麦",0)),game.coins))
	amount.value=1
	game.modal_body.add_child(amount)
	var action: Button=game.button("磨制所选数量",func():
		if mill(game,int(amount.value)):
			game.modal.hide()
			if not game.flags.get("mill_story",false):
				game.show_dialog([["周满仓","磨面一份收一文，磨盘也得有人照看。袋底那点也别倒掉。"],["陆承安","这么一点，也磨得出面？"],["周满仓","攒得出。荒年里，锅底多这一口，人就能多撑一程。"]],func(): game.flags["mill_story"]=true; game.mark_dirty(); show_mill(game))
			else: show_mill(game))
	action.disabled=int(game.inventory.get("沙麦",0))<1 or game.coins<1
	game.modal_body.add_child(action)
	game.modal_body.add_child(game.button("关闭",func(): game.modal.hide()))
func eat(item: String,game: Node) -> bool:
	if game.eating_time>0 or game.life.waking: return false
	if not ENERGY.has(item) or int(game.inventory.get(item,0))<=0: return false
	if game.energy>=game.MAX_ENERGY: game.toast("精力已满，不消耗食物"); return false
	game.eating_item=item; game.eating_time=game.eating_duration
	game.attack_time=0; game.attack_buffer=0; game.modal.hide()
	return true
func finish_eating(item: String,game: Node) -> bool:
	if not ENERGY.has(item) or int(game.inventory.get(item,0))<=0: return false
	if game.energy>=game.MAX_ENERGY: game.toast("精力已满，不消耗食物"); return false
	game.inventory[item]=int(game.inventory[item])-1
	var before: float=game.energy
	game.energy=minf(game.MAX_ENERGY,game.energy+int(ENERGY[item]))
	game.food_cooldown=0.0
	game.play_sound("pickup")
	game.toast("食用%s，恢复%d精力" % [item,int(game.energy-before)])
	game.update_hud()
	game.mark_dirty()
	return true
func show_menu(game: Node) -> void:
	game.inventory_ui.show_crafting(game)

func draw_mill(game: Node2D) -> void:
	game.draw_rect(Rect2(0,0,1280,800),Color("283933"))
	game.box(Rect2(260,150,760,500),Color("a8885e"))
	game.box(Rect2(280,195,720,435),Color("c8b17e"))
	for y in range(210,620,26): game.draw_line(Vector2(285,y),Vector2(995,y),Color("b89d6c"),1)
	game.box(Rect2(315,220,130,85),Color("86724e"))
	game.draw_circle(Vector2(850,310),48,Color("898572"))
	game.draw_circle(Vector2(850,300),42,Color("bfb497"))
	game.draw_line(Vector2(850,300),Vector2(920,275),Color("68583e"),8)
	pass # Farmer is rendered by npc_life.
	pass
	game.text_at(Vector2(790,235),"石磨",18,Color("34443d"))
	game.box(Rect2(605,615,75,35),Color("68583e"))
