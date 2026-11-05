extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var g=load("res://main.tscn").instantiate(); root.add_child(g); await process_frame; g.set_process(false)
	while g.dialogue_panel.visible: g.next_dialog()
	g.step=11; g.flags={"training_done":true}
	var issues: Array=[]
	for time in [360,480,600,780,1080,1200]:
		g.time_minutes=time
		for scene in ["home","village","wall","barracks","field"]:
			g.scene_id=scene; g.npc_life.live.clear(); g.setup_scene()
			var actors: Array=g.actors.filter(func(a): return a.id!="house_0" and not str(a.id).begins_with("farm_"))
			for i in range(actors.size()):
				for j in range(i+1,actors.size()):
					if actors[i].pos.distance_to(actors[j].pos)<68: issues.append([time,scene,actors[i].id,actors[j].id,actors[i].pos.distance_to(actors[j].pos)])
	print("TARGET ISSUES ",JSON.stringify(issues))
	g.queue_free(); await process_frame; quit()
