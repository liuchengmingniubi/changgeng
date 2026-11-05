extends RefCounted
var enemies: Array = []
var loot: Array = []
var numbers: Array = []
var effects: Array=[]
var attack_serial := 0
var serial_hits := {}
const SPAWNS := [Vector2(1100,650),Vector2(1630,470),Vector2(1900,1050),Vector2(1450,1230)]

func reset_enemies() -> void:
	enemies.clear(); numbers.clear(); effects.clear()
	for i in range(SPAWNS.size()):
		enemies.append({"kind":"厚甲甲壳虫" if i==2 else "甲壳虫","id":i,"pos":SPAWNS[i],"home":SPAWNS[i],"hp":100 if i==2 else 55,"max_hp":100 if i==2 else 55,"state":"idle","timer":0.8+float(i)*0.3,"facing":Vector2.LEFT,"hurt":0.0,"velocity":Vector2.ZERO})

func begin_swing() -> void:
	attack_serial += 1
	serial_hits.clear()

func tick(delta: float,game: Node) -> void:
	for effect in effects: effect.life-=delta
	effects=effects.filter(func(effect): return effect.life>0)
	for n in numbers:
		n.life-=delta
		n.pos.y-=delta*25
	numbers=numbers.filter(func(n): return n.life>0)
	if game.scene_id!="field": return
	game.commissions.ensure_elite(game)
	var scout: Dictionary=game.npc_life.live.get("scout",{})
	if game.flags.get("training_active",false) and game.hp<35 and scout.get("scene","")=="field" and game.player.distance_to(scout.get("pos",Vector2.ZERO))<200 and game.elapsed>=float(game.flags.get("han_aid_ready",0)):
		game.flags["han_aid_ready"]=game.elapsed+15.0
		game.hp=mini(game.max_hp,game.hp+35)
		game.toast("韩守义掩护你后退，包扎恢复35生命")
		game.invulnerability=1.5
	var progress: float=1.0-game.attack_time/game.attack_duration
	var previous: float=game.attack_previous_progress
	if (game.attack_time>0 or previous>=0) and progress>=0.22 and (previous<=0.68 if previous>=0 else progress<=0.68):
		for e in enemies:
			if game.swing_weapon.get("kind","")=="战锤" and not serial_hits.is_empty(): break
			if int(e.hp)<=0 or serial_hits.has(e.id): continue
			var offset: Vector2=e.pos-game.player
			if offset.length()<float(game.swing_weapon.get("reach",92)) and clear_strike(game.player,e.pos,game) and (offset.length()<22 or offset.normalized().dot(game.facing)>float(game.swing_weapon.get("cone",0.5))):
				serial_hits[e.id]=true
				hit_enemy(e,game)
				if game.dialogue_panel.visible: return
	for e in enemies:
		if int(e.hp)<=0: continue
		e.hurt=maxf(0,float(e.hurt)-delta)
		e.timer-=delta
		var displacement: Vector2=game.player-e.pos
		var distance:=displacement.length()
		match str(e.state):
			"idle":
				if distance<240 and game.player.x>650: e.state="chase"
				elif e.timer<=0:
					e.facing=Vector2(cos(game.elapsed+float(e.id)),sin(game.elapsed+float(e.id)))
					e.timer=2.0
				if (e.pos-e.home).length()>60: e.facing=(e.home-e.pos).normalized()
				move_enemy(e,e.facing*18*delta,game)
			"chase":
				if distance>350 or game.player.x<600:
					e.state="return"
				elif distance<110:
					e.state="windup"
					e.timer=0.85
					e.facing=displacement.normalized()
				else:
					e.facing=displacement.normalized()
					move_enemy(e,e.facing*65*delta,game)
			"windup":
				if e.timer<=0:
					e.state="lunge"
					e.timer=0.3
			"lunge":
				move_enemy(e,e.facing*230*delta,game)
				if game.player.distance_to(e.pos)<32: game.take_damage((8 if e.has("warrant_uid") else 0)+(16 if e.get("base_kind",e.get("kind",""))=="厚甲甲壳虫" else 12),e.pos)
				if game.life.waking: return
				if e.timer<=0:
					e.state="recover"
					e.timer=1.0
			"recover":
				if e.timer<=0: e.state="chase"
			"return":
				move_enemy(e,(e.home-e.pos).normalized()*75*delta,game)
				if e.pos.distance_to(e.home)<10:
					e.state="idle"
					e.hp=e.max_hp
		if e.velocity.length()>1:
			move_enemy(e,e.velocity*delta,game)
			e.velocity=e.velocity.move_toward(Vector2.ZERO,650*delta)
	for i in range(loot.size()-1,-1,-1):
		if game.player.distance_to(loot[i].pos)<43:
			var entry: Dictionary=loot[i]
			var gained:=int(entry.coins)
			game.change_coins(gained,"打怪拾取")
			entry.coins=0
			var picked: Array=[]
			var pending: Dictionary=entry.materials
			for key in pending.keys():
				if int(game.inventory.get(key,0))<=0 and game.equipment.count_items(game)>=42: continue
				game.inventory[key]=int(game.inventory.get(key,0))+int(pending[key])
				picked.append("%s ×%d" % [key,pending[key]])
				pending.erase(key)
			if pending.is_empty(): loot.remove_at(i)
			if gained>0 or not picked.is_empty():
				game.play_sound("pickup")
				game.toast("拾取：铜钱 +%d %s" % [gained,"、".join(picked)])
				game.update_hud(); game.mark_dirty()

func roll_drop(kind: String) -> Dictionary:
	var table: Dictionary=preload("res://craft_catalog.gd").DROPS.get(kind,preload("res://craft_catalog.gd").DROPS["普通甲壳虫"])
	var result: Dictionary={"coins":randi_range(int(table.coins[0]),int(table.coins[1])),"materials":{}}
	for item in table.materials:
		var data: Array=table.materials[item]
		if randf()<float(data[0]): result.materials[item]=randi_range(int(data[1]),int(data[2]))
	return result

func clear_strike(origin: Vector2,target: Vector2,game: Node) -> bool:
	for i in range(1,9):
		if game.blocked(origin.lerp(target,float(i)/9.0)): return false
	return true

func move_enemy(e: Dictionary,offset: Vector2,game: Node) -> void:
	e.pos=game.sweep_move(e.pos,offset,Rect2(340,235,2180,1130))

func hit_enemy(e: Dictionary,game: Node) -> void:
	if int(e.hp)<=0: return
	var damage: int=game.swing_power
	if game.combo==2: damage=int(damage*1.1)
	elif game.combo==3: damage=int(damage*1.35)
	var frontal: bool=(game.player-e.pos).normalized().dot(e.facing)>0.55
	if frontal and e.state not in ["recover","windup"]:
		var reduction:=0.5 if e.get("base_kind",e.get("kind",""))=="厚甲甲壳虫" else 0.3
		damage=maxi(1,int(damage*(1.0-reduction*(1.0-float(game.swing_weapon.get("pierce",0))))))
	var critical: bool=randf()<float(game.swing_weapon.get("crit",0))
	if critical: damage=int(round(damage*1.5))
	e.hp-=damage
	e.hurt=0.16
	e.velocity=(e.pos-game.player).normalized()*150
	# Telegraph and lunge are committed moves; basic attacks cannot stunlock them.
	numbers.append({"pos":e.pos+Vector2(0,-44),"text":("暴击 " if critical else "")+str(damage),"life":0.7,"critical":critical,"color":Color("ffc66c") if critical else Color("fff1bc")})
	effects.append({"pos":e.pos+Vector2(0,-12),"life":0.18,"critical":critical})
	if effects.size()>48: effects.pop_front()
	game.play_sound("hit")
	if e.hp<=0:
		e.state="dead"
		var drop:=roll_drop(str(e.get("base_kind",e.get("kind","甲壳虫"))))
		drop["pos"]=e.pos
		loot.append(drop)
		game.gain_experience(25)
		game.flags["beetle_kills"]=int(game.flags.get("beetle_kills",0))+1
		game.commissions.event(game,"elite" if e.has("warrant_uid") else "kill",str(e.get("kind","甲壳虫")),1,int(e.get("warrant_uid",-1)))
		game.frontier.on_kill(game)
		game.mark_dirty()

func snapshot() -> Dictionary:
	var result: Dictionary={"enemies":[],"loot":[]}
	for e in enemies:
		result.enemies.append({"id":e.id,"pos":[e.pos.x,e.pos.y],"hp":e.hp,"kind":e.get("kind","甲壳虫"),"base_kind":e.get("base_kind",""),"warrant_uid":e.get("warrant_uid",-1),"max_hp":e.max_hp})
	for entry in loot: result.loot.append({"pos":[entry.pos.x,entry.pos.y],"coins":entry.coins,"materials":entry.get("materials",{})})
	return result

func restore(data: Dictionary) -> void:
	reset_enemies()
	loot.clear()
	for saved in data.get("enemies",[]):
		var id:=int(saved.get("id",-1))
		if int(saved.get("warrant_uid",-1))>=0:
			var at:=Vector2(saved.pos[0],saved.pos[1])
			enemies.append({"kind":saved.kind,"base_kind":saved.base_kind,"warrant_uid":saved.warrant_uid,"id":id,"pos":at,"home":at,"hp":maxi(0,int(saved.hp)),"max_hp":int(saved.max_hp),"state":"dead" if int(saved.hp)<=0 else "idle","timer":1.0,"facing":Vector2.LEFT,"hurt":0.0,"velocity":Vector2.ZERO})
			continue
		if id<0 or id>=enemies.size(): continue
		enemies[id].pos=Vector2(saved.pos[0],saved.pos[1])
		enemies[id].hp=clampi(int(saved.hp),0,int(enemies[id].max_hp))
		if enemies[id].hp<=0: enemies[id].state="dead"
	for saved in data.get("loot",[]):
		loot.append({"pos":Vector2(saved.pos[0],saved.pos[1]),"coins":int(saved.coins),"materials":saved.get("materials",{"甲壳":int(saved.get("shell",0))} if int(saved.get("shell",0))>0 else {})})

func draw_world(canvas: Node2D,game: Node) -> void:
	for drop in loot:
		canvas.draw_circle(drop.pos+Vector2(0,4),11,Color("7c653e"))
		canvas.draw_colored_polygon(PackedVector2Array([drop.pos+Vector2(-8,0),drop.pos+Vector2(0,-10),drop.pos+Vector2(8,0),drop.pos+Vector2(0,7)]),Color("a8b776"))
		canvas.draw_arc(drop.pos,16,0,TAU,16,Color(1,0.87,0.45,0.45+sin(game.elapsed*4)*0.2),1)
	for e in enemies:
		if int(e.hp)<=0: continue
		var p: Vector2=e.pos
		if e.state=="windup":
			var end: Vector2=p+e.facing*69
			var side: Vector2=e.facing.orthogonal()*19
			canvas.draw_line(p,end,Color(0.95,0.47,0.15,0.10),38,true)
			canvas.draw_line(p+side,end+side,Color("f3a14e"),2,true)
			canvas.draw_line(p-side,end-side,Color("f3a14e"),2,true)
			canvas.draw_arc(end,19,e.facing.angle()-PI/2,e.facing.angle()+PI/2,24,Color("f3a14e"),2,true)
			var warning: float=clampf(1.0-float(e.timer)/0.85,0.0,1.0)
			canvas.draw_arc(p,30,-PI/2,-PI/2+TAU*warning,40,Color("ffd687"),2,true)
		game.draw_ellipse_shadow(p)
		var wiggle:=sin(game.elapsed*12+float(e.id))*3
		for side in [-1,1]:
			for i in range(3):
				canvas.draw_polyline(PackedVector2Array([p+Vector2(side*13,(i-1)*10),p+Vector2(side*24,(i-1)*13+wiggle),p+Vector2(side*28,(i-1)*16+5)]),Color("594731"),3)
		var shell:=Color("9a8250") if e.get("base_kind",e.get("kind",""))=="厚甲甲壳虫" else Color("798d55")
		if e.state=="windup": shell=Color("be8051")
		if e.hurt>0: shell=Color("fffbed")
		canvas.draw_set_transform(p,e.facing.angle()+PI/2,Vector2(1,0.82))
		canvas.draw_circle(Vector2(0,-5),23,Color("3d513c"))
		canvas.draw_circle(Vector2(0,-7),20,shell)
		canvas.draw_circle(Vector2(-5,-13),10,shell.lightened(0.17))
		canvas.draw_line(Vector2(0,-26),Vector2(0,10),Color("445739"),3)
		canvas.draw_circle(Vector2(0,-28),11,Color("566344"))
		canvas.draw_circle(Vector2(-5,-32),2,Color("edcf7c"))
		canvas.draw_circle(Vector2(5,-32),2,Color("edcf7c"))
		canvas.draw_set_transform(Vector2.ZERO)
		canvas.draw_rect(Rect2(p+Vector2(-25,-53),Vector2(50,5)),Color("4f493b"))
		canvas.draw_rect(Rect2(p+Vector2(-25,-53),Vector2(50*maxf(0,float(e.hp)/float(e.max_hp)),5)),Color("a9bb78"))
		if e.get("base_kind",e.get("kind",""))=="厚甲甲壳虫": game.text_at(p+Vector2(-35,-69),"厚甲",14,Color("e8d5a1"))
		if e.has("warrant_uid"): game.text_at(p+Vector2(-60,-88),str(e.kind),16,Color("e8bc62"))
		if e.state=="windup": game.text_at(p+Vector2(-5,-62),"!",22,Color("f6b16c"))
	for effect in effects:
		var fade: float=clampf(float(effect.life)/0.18,0,1)
		for i in range(6):
			var direction:=Vector2.from_angle(float(i)*TAU/6)
			canvas.draw_line(effect.pos+direction*(4+(1-fade)*6),effect.pos+direction*(10+(1-fade)*10),Color(1.0,0.85 if effect.critical else 0.97,0.5 if effect.critical else 0.85,fade),2,true)
	for n in numbers: game.text_at(n.pos,n.text,26 if n.get("critical",false) else 19,n.color)
