extends RefCounted
var plots: Array=[]
var day:=1
var water:=0
const CROPS: Dictionary={"初始种子":{"name":"沙麦","days":3,"harvest":"沙麦","yield":2},"稀有种子":{"name":"沙金麦","days":6,"harvest":"沙金麦","yield":2},"药草种子":{"name":"药草","days":6,"harvest":"基础草药","yield":3}}
func initialize() -> void:
	if not plots.is_empty(): return
	for row in range(3):
		for col in range(4):
			plots.append({"tilled":false,"seed":"","growth":0,"watered":false,"pos":Vector2(200+col*84,430+row*84)*1.5})
func work(index: int,game: Node) -> void:
	if game.energy<=0: game.toast("精力耗尽，吃些东西再耕作"); return
	if index<0 or index>=plots.size(): return
	var p: Dictionary=plots[index]
	if not p.tilled:
		if int(game.inventory.get("锄头",0))<=0: game.toast("需要随身携带锄头，可从家中箱子取出"); return
		p.tilled=true
		game.toast("已开垦。再按F选择种子播种")
	elif str(p.seed)=="":
		game.clear_modal("选择种子")
		for key in CROPS:
			var seed: String=key
			var count:=int(game.inventory.get(seed,0))
			var b: Button=game.button("%s ×%d（需浇水生长%d天）" % [CROPS[seed].name,count,CROPS[seed].days],func():
				plant(index,seed,game)
				game.modal.hide())
			b.disabled=count<=0
			game.modal_body.add_child(b)
		game.modal_body.add_child(game.button("取消",func(): game.modal.hide()))
		return
	elif int(p.growth)>=int(CROPS[p.seed].days):
		var crop: Dictionary=CROPS[p.seed]
		game.inventory[crop.harvest]=int(game.inventory.get(crop.harvest,0))+int(crop["yield"])
		game.commissions.event(game,"harvest",str(crop.harvest),int(crop["yield"]))
		game.toast("收获 %s ×%d" % [crop.harvest,crop["yield"]])
		p.seed=""
		p.growth=0
		p.watered=false
		p["fertilized"]=false; p["fertilizer_pending"]=false
		game.play_sound("pickup")
	elif p.watered:
		game.toast("今天已浇水，睡到次日后生长；进度 %d/%d天" % [p.growth,CROPS[p.seed].days])
	else:
		if water<=0: game.toast("没有灌溉用水，到村井按F免费补充"); return
		water-=1
		p.watered=true
		game.toast("已浇水，睡到次日生长一天（余水 %d）" % water)
	game.mark_dirty()
	game.update_hud()
func plant(index: int,seed: String,game: Node) -> bool:
	if game.energy<=0: return false
	if index<0 or index>=plots.size() or not CROPS.has(seed): return false
	var p: Dictionary=plots[index]
	if not p.tilled or str(p.seed)!="" or int(game.inventory.get(seed,0))<=0: return false
	game.inventory[seed]=int(game.inventory[seed])-1
	p.seed=seed
	p.growth=0
	p.watered=false
	game.toast("已播种%s，记得浇水" % CROPS[seed].name)
	game.mark_dirty()
	return true
func next_day() -> void:
	day+=1
	for p in plots:
		if str(p.seed)!="" and p.watered:
			p.growth=mini(int(CROPS[p.seed].days),int(p.growth)+1)
			p["fertilizer_pending"]=false
		p.watered=false
func snapshot() -> Dictionary:
	var result: Dictionary={"day":day,"water":water,"plots":[]}
	for p in plots: result.plots.append({"tilled":p.tilled,"seed":p.seed,"growth":p.growth,"watered":p.watered,"fertilized":p.get("fertilized",false),"fertilizer_pending":p.get("fertilizer_pending",false)})
	return result
func restore(data: Dictionary) -> void:
	initialize()
	day=maxi(1,int(data.get("day",1)))
	water=clampi(int(data.get("water",0)),0,12)
	var saved: Array=data.get("plots",[])
	for i in range(mini(saved.size(),plots.size())):
		var item: Dictionary=saved[i]
		plots[i].tilled=bool(item.get("tilled",false))
		var seed: String=str(item.get("seed",""))
		plots[i].seed=seed if CROPS.has(seed) else ""
		plots[i].growth=maxi(0,int(item.get("growth",0)))
		plots[i].watered=bool(item.get("watered",false))
		plots[i]["fertilized"]=bool(item.get("fertilized",false))
		plots[i]["fertilizer_pending"]=false
		if CROPS.has(seed) and bool(item.get("fertilizer_pending",false)):
			var left:=maxi(0,int(CROPS[seed].days)-int(plots[i].growth))
			plots[i].growth=int(CROPS[seed].days)-int(ceil(left/2.0))
func draw_world(canvas: Node,game: Node) -> void:
	canvas.draw_set_transform(Vector2.ZERO,0,Vector2.ONE*1.5)
	for p in plots:
		var pos: Vector2=p.pos/1.5
		var soil:=Color("99744f") if p.tilled else Color("c2a36f")
		if p.watered: soil=Color("6d5c43")
		canvas.draw_rect(Rect2(pos-Vector2(28,23),Vector2(56,46)),soil)
		canvas.draw_rect(Rect2(pos-Vector2(28,23),Vector2(56,46)),Color("947647"),false,2)
		if p.get("fertilized",false):
			canvas.draw_rect(Rect2(pos-Vector2(31,26),Vector2(62,52)),Color("e1bc54"),false,3)
			preload("res://item_art.gd").draw(canvas,"肥料",Rect2(pos+Vector2(13,-36),Vector2(18,18)))
		if p.watered: canvas.draw_circle(pos+Vector2(-22,-17),3,Color("78bbd1"))
		if p.tilled:
			for y in range(3): canvas.draw_line(pos+Vector2(-22,-14+y*13),pos+Vector2(22,-14+y*13),soil.darkened(0.18),2)
		if str(p.seed)=="": continue
		var mature:=int(p.growth)>=int(CROPS[p.seed].days)
		for i in range(3):
			var root:=pos+Vector2((i-1)*13,10)
			var h:=12.0+float(p.growth)*7
			var color:=Color("d8bd6e") if mature and p.seed=="初始种子" else Color("61905a")
			canvas.draw_line(root,root+Vector2(sin(game.elapsed+i)*1.2,-h),color,3)
			canvas.draw_line(root+Vector2(0,-h*.5),root+Vector2(-7,-h*.7),color.lightened(0.1),3)
			canvas.draw_line(root+Vector2(0,-h*.65),root+Vector2(8,-h*.8),color.lightened(0.1),3)
			if mature: canvas.draw_circle(root+Vector2(0,-h),4,color.lightened(0.2))
		if mature: canvas.draw_circle(pos+Vector2(20,-28),3,Color("f8df93"))

	canvas.draw_set_transform(Vector2.ZERO)
	if game.scene_id=="village":
		var near: Dictionary=game.nearest()
		if str(near.get("id","")).begins_with("farm_"):
			var p: Dictionary=plots[int(str(near.id).trim_prefix("farm_"))]
			if str(p.seed)!="":
				game.world_layout.tag(canvas,p.pos+Vector2(0,-82),"%s · 余%d天%s" % [CROPS[p.seed].name,maxi(0,int(CROPS[p.seed].days)-int(p.growth))," · 已施肥" if p.get("fertilized",false) else ""],true)

func fertilize(game: Node) -> bool:
	if game.energy<=0: game.toast("精力耗尽，吃些东西再施肥"); return false
	var a: Dictionary=game.nearest()
	if game.scene_id!="village" or not str(a.get("id","")).begins_with("farm_"): game.toast("靠近家中已播种农田使用肥料"); return false
	var i:=int(str(a.id).trim_prefix("farm_")); var p: Dictionary=plots[i]
	if str(p.seed)=="" or p.get("fertilized",false) or int(p.growth)>=int(CROPS[p.seed].days): game.toast("需要未成熟、尚未施肥的作物"); return false
	if int(game.inventory.get("肥料",0))<=0: return false
	var before:=int(CROPS[p.seed].days)-int(p.growth)
	if before<=1: game.toast("只剩一天成熟，无需施肥"); return false
	game.inventory["肥料"]=int(game.inventory["肥料"])-1
	var remaining:=int(ceil(before/2.0))
	p.growth=int(CROPS[p.seed].days)-remaining
	p["fertilized"]=true; p["fertilizer_pending"]=false
	game.toast("施肥完成：剩余%d天 → %d天；金色边框为已施肥" % [before,remaining]); game.mark_dirty(); return true
