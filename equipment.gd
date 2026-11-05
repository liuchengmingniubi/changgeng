extends RefCounted
const SLOTS := ["头盔","护甲","护腿","项链","戒指","手环","腰带","手套","鞋靴","时装"]
# Ordinary starter items only; story rewards remain undefined.
const ITEMS := preload("res://craft_catalog.gd").ARMOR
var worn: Dictionary={}
func stats() -> Dictionary:
	var total: Dictionary={"hp":0,"attack":0,"defense":0}
	for slot in SLOTS:
		var item: String=str(worn.get(slot,""))
		if not ITEMS.has(item): continue
		for key in total: total[key]+=int(ITEMS[item].get(key,0))
	return total
func count_items(game: Node) -> int:
	var count:=0
	for key in game.inventory:
		if int(game.inventory[key])>0 and not str(key).contains("《"): count+=1
	return count
func wear(item: String,game: Node) -> bool:
	if not ITEMS.has(item) or int(game.inventory.get(item,0))<=0: return false
	var slot: String=str(ITEMS[item].slot)
	var old: String=str(worn.get(slot,""))
	var used:=count_items(game)
	if int(game.inventory[item])==1: used-=1
	if old!="" and int(game.inventory.get(old,0))<=0: used+=1
	if used>42: game.toast("背包已满，无法放回原装备"); return false
	game.inventory[item]=int(game.inventory[item])-1
	if old!="": game.inventory[old]=int(game.inventory.get(old,0))+1
	worn[slot]=item
	game.recalculate_stats()
	game.play_sound("pickup")
	game.toast("已穿戴："+item)
	game.mark_dirty()
	return true
func remove(slot: String,game: Node) -> bool:
	var item: String=str(worn.get(slot,""))
	if item=="": return false
	if int(game.inventory.get(item,0))<=0 and count_items(game)>=42: game.toast("背包已满，无法卸下"); return false
	game.inventory[item]=int(game.inventory.get(item,0))+1
	worn.erase(slot)
	game.recalculate_stats()
	game.play_sound("pickup")
	game.toast("已卸下："+item)
	game.mark_dirty()
	return true
func restore(data: Dictionary) -> void:
	worn.clear()
	for slot in SLOTS:
		var item: String=str(data.get(slot,""))
		if ITEMS.has(item) and str(ITEMS[item].slot)==slot: worn[slot]=item
func description(item: String) -> String:
	if not ITEMS.has(item): return ""
	var data: Dictionary=ITEMS[item]
	return "%s · 攻击+%d 防御+%d 生命上限+%d" % [data.slot,data.attack,data.defense,data.hp]

func comparison(item: String) -> String:
	if not ITEMS.has(item): return ""
	var data: Dictionary=ITEMS[item]
	var old_name: String=str(worn.get(data.slot,""))
	var old: Dictionary=ITEMS.get(old_name,{"attack":0,"defense":0,"hp":0})
	var result: String="当前："+(old_name if old_name!="" else "未穿戴")
	for pair in [["attack","攻击"],["defense","防御"],["hp","生命上限"]]:
		var delta: int=int(data[pair[0]])-int(old[pair[0]])
		var color: String="37734b" if delta>0 else ("a34535" if delta<0 else "697464")
		result+="  [color=#%s]%s %s%d[/color]" % [color,pair[1],"+" if delta>=0 else "",delta]
	return result
func show_forge(game: Node) -> void:
	game.craft_ui.show_menu(game,"smith")
