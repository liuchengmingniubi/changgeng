extends RefCounted
func main_text(g: Node) -> String:
	var text: String=g.OBJECTIVES[g.step] if g.step<11 else g.story_events.SEARCH_GOALS[mini(7,int(g.flags.get("search_stage",0)))]
	var recruit: String=g.recruitment.objective(g)
	if recruit!="": text=recruit
	var target: String=["家中储物箱","田敬修 · 村中","郭成 · 铁匠铺","许素问 · 医馆","许素问 · 医馆","背包内合成大全","田敬修 · 村中","裴肃 · 关门营地","韩守义 · 关门／关外","同袍与失踪名单","裴肃 · 关门营地"][mini(g.step,10)]
	var progress: String=""
	if g.step==9:
		progress="已交谈 %d/2 · 名单 %d/1" % [int(bool(g.flags.get("soldier_talk",false)))+int(bool(g.flags.get("medic_talk",false))),int(bool(g.flags.get("roster_intro_seen",false)))]
	if g.step>=11:
		var stage: int=mini(7,int(g.flags.get("search_stage",0)))
		target=["裴肃 · 关门营地","旧巡逻线 · 关外","裴肃 · 关门营地","冯厚 · 制革作坊","裴肃 · 关门营地","东侧洞口 · 关外","裴肃 · 关门营地","待下一次搜寻"][stage]
		if stage==1: progress="已查线索 %d/2" % [int(bool(g.flags.get("search_flask",false)))+int(bool(g.flags.get("search_remains",false)))]
		if stage==4: progress="食物 %d/1 · 药水 %d/1" % [int(g.story_events.has_food(g)),mini(1,int(g.inventory.get("回血药水",0)))]
	return text+("\n"+progress if progress!="" else "")+"\n前往／交付："+target
func side_text(g: Node) -> String:
	var key: String=str(g.flags.get("active_side",""))
	if not g.story_events.SIDE_NAMES.has(key): return "暂无支线\n同时只能接取一条"
	var stage: int=clampi(int(g.flags.get("side_stage",0)),0,g.story_events.SIDE_GOALS[key].size()-1)
	var target: String={"roof":["郭成","田敬修"],"scout":["关外枯树路标","孙怀济","韩守义"],"ledger":["杜芸娘","康裕"]}[key][stage]
	return "%s · %d/%d\n%s\n前往／交付：%s" % [g.story_events.SIDE_NAMES[key],stage+1,g.story_events.SIDE_GOALS[key].size(),g.story_events.SIDE_GOALS[key][stage],target]
