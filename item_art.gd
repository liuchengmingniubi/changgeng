extends RefCounted
static var texture: Texture2D
static var dimensions:=Vector2.ZERO
const NAMES=["军用旧铁剑","甲锋剑","岩鳞剑","铁钩镰","蝎尾镰","蝠翼镰","军用铁锤","厚甲锤","岩背重锤","破旧铁甲","甲壳盔","甲壳护甲","甲壳护腿","蝎壳盔","蝎壳护甲","蝎壳护腿","厚甲盔","厚甲护甲","厚甲护腿","岩鳞盔","岩鳞护甲","岩鳞护腿","手套","鞋靴","腰带","项链","戒指","手环","铁锭","铜锭","白银","黄金","兽皮","皮革","粗布","甲壳","厚甲片","蝎壳","蝎尾","岩鳞","蝠牙","蝠翼","基础草药","甘草","清心草","回血药水","面粉","馒头","面条","草药饼","沙麦","初始种子","药草种子","稀有种子","肥料","制作书","锄头","斧子","镐子","父母遗书","军籍腰牌","项链模具","戒指模具","手环模具"]
static func setup() -> void:
	if texture!=null: return
	var source:=Image.new()
	if source.load("res://assets/art/items_v26.png")==OK: texture=ImageTexture.create_from_image(source); dimensions=Vector2(source.get_size())
static func index_for(item: String) -> int:
	if NAMES.has(item): return NAMES.find(item)
	if item.contains("模具"): return 61+(1 if item.contains("戒指") else (2 if item.contains("手环") else 0))
	if item.contains("制作书") or item.contains("大全"): return 55
	for pair in [["手套",22],["鞋靴",23],["靴",23],["腰带",24],["项链",25],["石坠",25],["戒",26],["手环",27],["种子",51],["草",42],["面",46],["绳",33],["衬带",33],["信",59],["遗物",59],["旧军扣",60],["药",45],["皮",33],["布",34],["麦",50],["铁",28],["壳",35],["鳞",39],["瓶",45],["水",45]]:
		if item.contains(pair[0]): return pair[1]
	return 55
static func draw(canvas: Node,item: String,area: Rect2) -> void:
	setup()
	if texture==null: return
	var index:=index_for(item); var col:=index%8; var row:=index/8
	var from:=Vector2(round(col*dimensions.x/8),round(row*dimensions.y/8))
	var end:=Vector2(round((col+1)*dimensions.x/8),round((row+1)*dimensions.y/8))
	canvas.draw_texture_rect_region(texture,area,Rect2(from,end-from),Color("bca78c") if item.begins_with("破旧皮革") else Color.WHITE)
	# A material-family base remains recognizable while books/equipment variants get their own seal.
	if not NAMES.has(item):
		var key:=posmod(hash(item),5); var colors=["ba9458","719b85","b88763","9c9b69","d2bf83"]
		canvas.draw_rect(Rect2(area.end-Vector2(10,10),Vector2(8,8)),Color(colors[key]))
		canvas.draw_rect(Rect2(area.end-Vector2(8,8),Vector2(4,4)),Color("eff0cc"),false,1)
