extends SceneTree
func _initialize() -> void: call_deferred("run")
func close(g: Node) -> void:
	while g.dialogue_panel.visible: g.next_dialog()
func run() -> void:
	var g=load("res://main.tscn").instantiate(); root.add_child(g); await process_frame; g.set_process(false); close(g)
	for scene in ["home","barracks","clinic"]:
		g.scene_id=scene; g.farming.day=2; g.time_minutes=959; g.hp=50; g.energy=10; g.flags={}; g.weekly.data(g)
		assert(not g.life.sleep(g) and g.time_minutes==959 and g.hp==50)
		g.time_minutes=960; assert(g.life.sleep(g))
		assert(g.farming.day==3 and g.time_minutes==360 and g.hp==60 and g.energy==100)
		close(g); assert(not g.life.waking)
	g.farming.day=3; g.time_minutes=1020; g.life.wake(g,"death")
	assert(g.farming.day==4 and g.time_minutes==360,"death threshold remains 20:00, not 16:00")
	close(g)
	print("PASS v261: 15:59 blocked, 16:00 allowed at home/barracks/clinic, next morning, 10% HP/full energy, wake save, death 20:00 threshold preserved")
	g.queue_free(); await process_frame; quit()
