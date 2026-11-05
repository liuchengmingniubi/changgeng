extends RefCounted
# 由 tools/build_hero.py 生成，勿手改。坐标以每帧 48x88 画布左上角为原点。
const CELL := Vector2(48, 88)
const FOOT_LIFT := 87.0
const WALK_SHEET := "res://assets/art/hero_walk_v28.png"
const ATTACK_SHEET := "res://assets/art/hero_attack_v28.png"
const IDLE_SHEET := "res://assets/art/hero_idle_v28.png"
const WALK_FRAMES := 4
const ATTACK_FRAMES := 6
const IDLE_FRAMES := 4
# [朝向][帧] 朝向顺序：0 下 1 左 2 右 3 上
const WALK_HAND := [
	[Vector2(36,52), Vector2(35,51), Vector2(34,52), Vector2(35,51)],
	[Vector2(11,52), Vector2(13,51), Vector2(15,52), Vector2(13,51)],
	[Vector2(36,52), Vector2(34,51), Vector2(32,52), Vector2(34,51)],
	[Vector2(36,52), Vector2(35,51), Vector2(34,52), Vector2(35,51)]
]
const ATTACK_HAND := [
	[Vector2(33,42), Vector2(35,33), Vector2(33,29), Vector2(26,33), Vector2(18,40), Vector2(22,45)],
	[Vector2(29,42), Vector2(32,33), Vector2(27,29), Vector2(17,31), Vector2(12,42), Vector2(17,47)],
	[Vector2(18,42), Vector2(15,33), Vector2(20,29), Vector2(30,31), Vector2(35,42), Vector2(30,47)],
	[Vector2(15,42), Vector2(13,33), Vector2(16,29), Vector2(24,31), Vector2(31,40), Vector2(27,45)]
]
const IDLE_HAND := [
	[Vector2(35,52), Vector2(35,53), Vector2(36,53), Vector2(35,52)],
	[Vector2(13,52), Vector2(13,53), Vector2(11,53), Vector2(13,52)],
	[Vector2(34,52), Vector2(34,53), Vector2(36,53), Vector2(34,52)],
	[Vector2(35,52), Vector2(35,53), Vector2(36,53), Vector2(35,52)]
]
# 刀身角度（度，0=向右，90=向下）
const ATTACK_BLADE := [
	[-62, -92, -122, -150, 172, 148],
	[-150, -176, 156, 124, 88, 62],
	[-30, -4, 24, 56, 92, 118],
	[-70, -95, -120, -145, -170, 165]
]

static func hand(kind: String, dir: int, frame: int) -> Vector2:
	match kind:
		"walk": return WALK_HAND[dir][frame]
		"attack": return ATTACK_HAND[dir][minf(frame, ATTACK_FRAMES - 1)]
		_: return IDLE_HAND[dir][frame % IDLE_FRAMES]
