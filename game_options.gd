extends RefCounted
const PATH="user://settings.cfg"
var music_volume:=45.0
var sfx_volume:=75.0
var fullscreen:=false
var window_size:=Vector2i(1280,800)
var music: AudioStreamPlayer
var status_label: Label
func setup(g: Node) -> void:
	g.audio_players=[g.sound_player]
	for i in range(5):
		var player:=AudioStreamPlayer.new(); g.add_child(player); g.audio_players.append(player)
	music=AudioStreamPlayer.new(); g.add_child(music)
	var path: String="res://assets/audio/east_sand_theme.wav"
	if FileAccess.file_exists(path):
		var stream:=AudioStreamWAV.new(); stream.format=AudioStreamWAV.FORMAT_16_BITS; stream.mix_rate=22050
		stream.data=FileAccess.get_file_as_bytes(path).slice(44); stream.loop_mode=AudioStreamWAV.LOOP_FORWARD; stream.loop_end=stream.data.size()/2
		music.stream=stream; music.play()
	restore(g)
func restore(g: Node) -> void:
	var config:=ConfigFile.new()
	if config.load(PATH)==OK:
		music_volume=clampf(float(config.get_value("audio","music",45)),0,100)
		sfx_volume=clampf(float(config.get_value("audio","sfx",75)),0,100)
		fullscreen=bool(config.get_value("video","fullscreen",false))
		var size_value: Variant=config.get_value("video","size",Vector2i(1280,800))
		window_size=size_value if size_value is Vector2i and size_value in [Vector2i(1280,800),Vector2i(1600,1000),Vector2i(1920,1080)] else Vector2i(1280,800)
	else: sfx_volume=75.0 if g.sound_enabled else 0.0
	apply(g)
func apply(g: Node,video: bool=true) -> void:
	g.sound_enabled=sfx_volume>0
	for player in g.audio_players: player.volume_db=-9.0+linear_to_db(maxf(0.0001,sfx_volume/100.0))
	if is_instance_valid(music):
		music.volume_db=-14.0+linear_to_db(maxf(0.0001,music_volume/100.0)); music.stream_paused=music_volume<=0
	if video and DisplayServer.get_name()!="headless":
		g.get_window().mode=Window.MODE_FULLSCREEN if fullscreen else Window.MODE_WINDOWED
		if not fullscreen:
			var screen: Rect2i=DisplayServer.screen_get_usable_rect()
			g.get_window().size=Vector2i(mini(window_size.x,screen.size.x),mini(window_size.y,screen.size.y))
func save() -> bool:
	var config:=ConfigFile.new()
	config.set_value("audio","music",music_volume); config.set_value("audio","sfx",sfx_volume)
	config.set_value("video","fullscreen",fullscreen); config.set_value("video","size",window_size)
	var ok: bool=config.save(PATH)==OK
	if is_instance_valid(status_label): status_label.text="设置已保存" if ok else "设置保存失败，请检查可写空间"
	return ok
func set_volume(g: Node,kind: String,value: float) -> void:
	if kind=="music": music_volume=clampf(value,0,100)
	elif kind=="sfx": sfx_volume=clampf(value,0,100)
	else: return
	apply(g,false)
	if not save(): g.toast("设置保存失败")
func small(g: Node,text: String,callback: Callable) -> Button:
	var b: Button=g.inventory_ui.jb(text,callback); b.add_theme_font_size_override("font_size",14); return b
func show(g: Node) -> void:
	g.inventory_ui.prepare(g,"设置")
	var pane:=ScrollContainer.new(); pane.custom_minimum_size=Vector2(1080,350)
	var body:=VBoxContainer.new(); body.custom_minimum_size.x=1000; pane.add_child(body); g.modal_body.add_child(pane)
	for kind in ["music","sfx"]:
		var id: String=kind
		var caption: Label=g.label("",14); body.add_child(caption)
		var slider:=HSlider.new(); slider.min_value=0; slider.max_value=100; slider.step=1; slider.value=music_volume if id=="music" else sfx_volume; slider.custom_minimum_size=Vector2(700,36); body.add_child(slider)
		caption.text=("音乐" if id=="music" else "音效")+" %d%%" % int(slider.value)
		slider.value_changed.connect(func(value: float): caption.text=("音乐" if id=="music" else "音效")+" %d%%" % int(value); set_volume(g,id,value))
	body.add_child(g.label("显示模式",14))
	var mode:=OptionButton.new(); mode.add_item("窗口化"); mode.add_item("全屏"); mode.selected=1 if fullscreen else 0; mode.custom_minimum_size=Vector2(400,42); mode.add_theme_font_override("font",g.font); body.add_child(mode)
	mode.item_selected.connect(func(index: int): fullscreen=index==1; apply(g); save())
	var sizes:=OptionButton.new(); var choices: Array=[Vector2i(1280,800),Vector2i(1600,1000),Vector2i(1920,1080)]
	for size in choices: sizes.add_item("窗口 %d × %d" % [size.x,size.y])
	sizes.selected=maxi(0,choices.find(window_size)); sizes.add_theme_font_override("font",g.font); body.add_child(sizes)
	sizes.item_selected.connect(func(index: int): window_size=choices[index]; apply(g); save())
	status_label=g.label("设置调整后自动保存",14); body.add_child(status_label)
	g.modal_body.add_child(small(g,"按键说明",func(): show_controls(g)))
	g.modal_body.add_child(small(g,"返回旅程",func(): g.show_menu()))
func show_controls(g: Node) -> void:
	g.inventory_ui.prepare(g,"按键与操作")
	var pane:=ScrollContainer.new(); pane.custom_minimum_size=Vector2(1080,350); g.modal_body.add_child(pane)
	var note: Label=g.label("WASD：移动\n鼠标左键：攻击／按住连续攻击\nF：交互　Tab：切换附近交互目标\n鼠标滚轮：切换固定物品栏　右键：使用\n1：喝药　2：馒头　3：面条\nI：背包　J：人物　K：任务记录　M：地图\n背包右键：使用／穿戴　装备栏左右键：卸下\nShift＋点击：拆分或选择存取数量\nF5：读取唯一存档　F6：覆盖保存　Esc：返回／暂停菜单（设置、手动存档）\n合成界面：设置每次放入数量，拖放材料；制作书每件消耗一本。\n关菜单后先松开左键再攻击；初期无闪避，后续作为技能开放。\n食物进食0.8秒，被打断不消耗；精力耗尽移速降低40%。\n仅醒来自动保存，其他操作请手动保存；凌晨2点强制昏倒。",14)
	pane.add_child(note); g.modal_body.add_child(small(g,"返回设置",func(): show(g)))
