extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var g=load("res://main.tscn").instantiate()
	root.add_child(g)
	await process_frame
	while g.dialogue_panel.visible: g.next_dialog()
	assert(g.equipment.SLOTS==["头盔","护甲","护腿","项链","戒指","手环","腰带","手套","鞋靴","时装"])
	g.flags={"held_weapon":"军用旧铁剑"}
	g.inventory={"军用旧铁剑":1,"破旧铁甲":1,"浅泉石坠":1,"赤铜戒":1,"皮绳手环":1}
	g.hp=70
	assert(g.equipment.wear("破旧铁甲",g) and g.defense==5)
	assert(g.inventory["破旧铁甲"]==0)
	assert(g.equipment.wear("浅泉石坠",g) and g.max_hp==115 and g.hp==70)
	assert(g.equipment.wear("赤铜戒",g) and g.attack_power==21)
	assert(g.equipment.wear("皮绳手环",g) and g.attack_power==23)
	g.scene_id="field"
	g.hp=100
	g.invulnerability=0
	g.take_damage(50,Vector2.ZERO)
	assert(g.hp==52,"defense reduces damage")
	g.hp=115
	assert(g.equipment.remove("项链",g))
	assert(g.max_hp==100 and g.hp==100,"unequip caps HP without healing")
	assert(g.inventory["浅泉石坠"]==1)
	assert(not g.equipment.wear("锄头",g))
	g.inventory={}
	for i in range(42): g.inventory["测试材料"+str(i)]=1
	assert(not g.equipment.remove("戒指",g),"full bag prevents unequip")
	assert(g.equipment.worn["戒指"]=="赤铜戒")
	g.inventory.erase("测试材料0")
	assert(g.equipment.remove("戒指",g))
	assert(g.inventory["赤铜戒"]==1 and g.attack_power==6)
	assert(g.equipment.wear("赤铜戒",g))
	g.save_game()
	g.equipment.worn.clear()
	g.load_game()
	assert(g.equipment.worn["戒指"]=="赤铜戒")
	assert(g.attack_power==9 and g.defense==5)
	g.inventory_ui.show_bag(g)
	g.show_market()
	print("PASS: expanded slots, wear/remove, HP/attack/defense, no heal exploit, full bag safety, saved equipment, UI")
	for child in root.get_children(): child.queue_free()
	await process_frame
	quit()
