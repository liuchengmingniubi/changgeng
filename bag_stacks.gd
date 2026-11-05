extends RefCounted
# Inventory totals remain authoritative for recipes, loot and old saves.
# These 36 persistent views allocate totals into the lower bag cells.
func sync(g: Node) -> Array:
	var raw: Array=g.flags.get("bag_stacks",[])
	var cells: Array=[]
	for i in range(36):
		var cell: Dictionary=raw[i].duplicate() if i<raw.size() and raw[i] is Dictionary else {}
		if int(g.inventory.get(str(cell.get("key","")),0))<=0 or int(cell.get("count",0))<=0: cell={}
		cells.append(cell)
	for key in g.inventory:
		if int(g.inventory[key])<=0 or str(key).contains("《"): continue
		var ids: Array=[]; var allocated:=0
		for i in range(36):
			if cells[i].get("key","")==key: ids.append(i); allocated+=int(cells[i].count)
		var hot: bool=key in g.quickbar
		var limit: int=maxi(0,int(g.inventory[key])-(1 if hot else 0))
		for i in range(ids.size()-1,-1,-1):
			if allocated<=limit: break
			var at: int=ids[i]; var take: int=mini(int(cells[at].count),allocated-limit)
			cells[at].count-=take; allocated-=take
			if int(cells[at].count)<=0: cells[at]={}
		if hot or allocated>=int(g.inventory[key]): continue
		var missing: int=int(g.inventory[key])-allocated
		var target: int=-1
		for i in range(36):
			if cells[i].get("key","")==key: target=i; break
		if target<0: target=empty(cells)
		if target<0:
			# Merge a split stack to admit a new item rather than losing it.
			for a in range(36):
				for b in range(a+1,36):
					if not cells[a].is_empty() and cells[a].get("key","")==cells[b].get("key",""):
						cells[a].count+=int(cells[b].count); cells[b]={}; target=b; break
				if target>=0: break
		if target<0:
			for i in range(6):
				if str(g.quickbar[i])=="" or int(g.inventory.get(str(g.quickbar[i]),0))<=0:
					g.quickbar[i]=key; g.flags["quickbar"]=g.quickbar.duplicate(); break
			continue
		if cells[target].is_empty(): cells[target]={"key":key,"count":missing}
		else: cells[target].count+=missing
	g.flags["bag_stacks"]=cells
	return cells
func empty(cells: Array) -> int:
	for i in range(cells.size()):
		if cells[i].is_empty(): return i
	return -1
func hot_count(key: String,g: Node,refresh: bool=true) -> int:
	if key=="": return 0
	var count: int=int(g.inventory.get(key,0))
	for cell in (sync(g) if refresh else g.flags.get("bag_stacks",[])):
		if cell.get("key","")==key: count-=int(cell.get("count",0))
	return maxi(0,count)
func split(g: Node,index: int,hot_index: int,amount: int) -> bool:
	if hot_index>=6 or (hot_index<0 and (index<0 or index>=36)): return false
	var cells:=sync(g); var at:=empty(cells)
	if at<0: g.toast("下方物品格已满，无法拆分"); return false
	var key: String=str(g.quickbar[hot_index]) if hot_index>=0 else str(cells[index].get("key",""))
	var count: int=hot_count(key,g) if hot_index>=0 else int(cells[index].get("count",0))
	if amount<=0 or amount>=count: return false
	if hot_index<0: cells[index].count-=amount
	cells[at]={"key":key,"count":amount}
	g.flags["bag_stacks"]=cells; g.mark_dirty()
	return true
func move(g: Node,from: int,to: int) -> void:
	var cells:=sync(g)
	if from<0 or from>=36 or to<0 or to>=36 or from==to: return
	if cells[from].is_empty(): return
	if cells[from].get("key","")==cells[to].get("key",""):
		cells[to].count+=int(cells[from].count); cells[from]={}
	else:
		var old: Dictionary=cells[to]; cells[to]=cells[from]; cells[from]=old
	g.flags["bag_stacks"]=cells; g.mark_dirty()
func merge_for_hot(g: Node,key: String) -> void:
	var cells: Array=g.flags.get("bag_stacks",[])
	for i in range(cells.size()):
		if cells[i].get("key","")==key: cells[i]={}
	g.flags["bag_stacks"]=cells
func sort_bag(g: Node) -> void:
	var keys: Array=g.inventory.keys(); keys.sort()
	var ordered: Dictionary={}
	for key in keys: ordered[key]=g.inventory[key]
	g.inventory=ordered; g.flags["bag_stacks"]=[]; sync(g); g.mark_dirty()
