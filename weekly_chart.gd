extends Control
var font: Font
var history: Array=[]
var metric: String="income"
var progress:=1.0
var reveal:=0.0
var previous: Array=[]
var values: Array=[]
var hover:=-1
func _ready() -> void:
	custom_minimum_size=Vector2(1040,305)
	mouse_filter=Control.MOUSE_FILTER_STOP
	set_metric(metric,true)
func set_metric(key: String,initial: bool=false) -> void:
	previous=display_values(); metric=key; values=[]
	for row in history: values.append(float(row.get(key,0)))
	if initial or previous.size()!=values.size(): previous=values.duplicate(); progress=1
	else: progress=0
func display_values() -> Array:
	var result: Array=[]
	for i in range(values.size()): result.append(lerpf(float(previous[i]) if i<previous.size() else float(values[i]),float(values[i]),smoothstep(0,1,progress)))
	return result
func _process(delta: float) -> void:
	progress=minf(1,progress+delta/0.6); reveal=minf(1,reveal+delta/1.2); queue_redraw()
func point(i: int,v: float,lo: float,hi: float) -> Vector2:
	return Vector2(75+(890.0*i/maxi(1,values.size()-1)),250-(v-lo)/(hi-lo)*205)
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		hover=clampi(int(round((event.position.x-75)/890*maxi(1,values.size()-1))),0,maxi(0,values.size()-1)); queue_redraw()
func text(at: Vector2,value: String,size_: int=14,color: Color=Color("35523f")) -> void:
	if font: draw_string(font,at,value,HORIZONTAL_ALIGNMENT_LEFT,-1,size_,color)
func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,size),Color("dce3c7"))
	var shown:=display_values(); var lo:=0.0; var hi:=1.0
	for v in shown: lo=minf(lo,v); hi=maxf(hi,v)
	var padding:=maxf(10,(hi-lo)*0.12); hi+=padding
	if lo<0: lo-=padding
	for j in range(5):
		var value:=lerpf(lo,hi,j/4.0); var y:=250-j*205.0/4
		draw_line(Vector2(75,y),Vector2(965,y),Color("afbea0"),1)
		text(Vector2(4,y+5),str(int(round(value))),13)
	var zero:=250-(0-lo)/(hi-lo)*205
	draw_line(Vector2(75,20),Vector2(75,250),Color("536c53"),2)
	draw_line(Vector2(75,zero),Vector2(980,zero),Color("536c53"),2)
	text(Vector2(5,18),"铜钱／文",13); text(Vector2(972,278),"周数",13)
	var path:=PackedVector2Array()
	for i in range(shown.size()):
		var at:=point(i,shown[i],lo,hi)
		if i==0: path.append(at)
		else:
			var from:=point(i-1,shown[i-1],lo,hi)
			for k in range(1,21):
				var fraction: float=(i-1+k/20.0)/maxi(1,shown.size()-1)
				if fraction>reveal: break
				var t:=k/20.0; path.append(Vector2(lerpf(from.x,at.x,t),lerpf(from.y,at.y,smoothstep(0,1,t))))
		if float(i)/maxi(1,shown.size()-1)<=reveal: draw_circle(at,4,Color("b38b42"))
		if i%maxi(1,int(ceil(shown.size()/10.0)))==0 or i==shown.size()-1: text(Vector2(at.x-13,275),"第%d周" % int(history[i].week),13)
	if path.size()>1: draw_polyline(path,Color("4c8069"),3,true)
	if hover>=0 and hover<history.size():
		var row: Dictionary=history[hover]; var at:=point(hover,shown[hover],lo,hi)
		draw_circle(at,7,Color("d1aa57")); text(Vector2(110,30),"第%d周：收入%d文　支出%d文　净收入%+d文" % [row.week,row.income,row.expense,row.net],16)
