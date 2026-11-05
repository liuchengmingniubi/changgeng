"""主角陆承安的像素骨架。

不逐帧手绘，而是"关节参数 → 硬边像素"的确定性生成：
同一个骨架产出 4 个朝向 × (行走 4 帧 + 挥剑 6 帧 + 待机 2 帧)，
保证比例、配色、轮廓完全一致，并且可以随时改数值重出图。

坐标约定：画布 48×88，脚底基线 y=86，人物中轴 x=24。
左右朝向只画"朝右"，朝左整体镜像。
"""
from .canvas import Canvas

W, H = 48, 88
FLOOR = 86
CX = 24

CROWN = 10          # 头顶
CHIN = 30           # 下巴
SHOULDER = 36
SASH_Y = 49
HIP = 58
KNEE = 70
ANKLE = 80
BOOT_BOTTOM = 86

PIVOT_Y = -40.0     # 与 main.gd 的 draw_sword 保持一致


def _ik(shoulder, hand, length):
    """把手臂末端夹到可达范围内，避免把身体拉长。"""
    dx, dy = hand[0] - shoulder[0], hand[1] - shoulder[1]
    dist = (dx * dx + dy * dy) ** 0.5
    if dist <= length or dist == 0:
        return hand
    k = length / dist
    return (shoulder[0] + dx * k, shoulder[1] + dy * k)


# ---------------------------------------------------------------- 腿与靴
def _leg(cv, hip, foot):
    """hip: 髋部；foot: 脚底基线坐标（靴底正好压在这行）。"""
    ankle = (foot[0], foot[1] - 6)
    knee = ((hip[0] + ankle[0]) / 2, (hip[1] + ankle[1]) / 2)
    cv.limb(hip, knee, 5, "pants")
    cv.limb(knee, ankle, 4, "pants")
    cv.rect(hip[0] - 3, hip[1] - 1, 5, 2, "pants_lit")
    cv.rect(knee[0] - 2, knee[1] - 1, 4, 2, "pants_dark")
    bx, by = foot[0] - 3, foot[1] - 6
    cv.rect(bx, by, 7, 7, "boot")
    cv.rect(bx, by, 7, 1, "boot_lit")
    cv.rect(bx, by + 6, 7, 1, "ink_soft")
    cv.rect(bx + 1, by + 3, 5, 1, "boot_dark")


# ---------------------------------------------------------------- 手臂
def _arm(cv, shoulder, hand):
    mid = ((shoulder[0] + hand[0]) / 2, (shoulder[1] + hand[1]) / 2)
    cv.limb(shoulder, mid, 5, "tunic")
    cv.limb(mid, hand, 4, "tunic")
    cv.rect(shoulder[0] - 2, shoulder[1] - 1, 4, 2, "tunic_lit")
    cv.rect(hand[0] - 1, hand[1] - 1, 3, 4, "skin")
    cv.rect(hand[0] - 1, hand[1] + 2, 3, 1, "skin_dark")


# ---------------------------------------------------------------- 头
def _bun(cv, x, y):
    cv.rect(x, y, 6, 7, "hair")
    cv.rect(x, y, 6, 1, "hair_lit")
    cv.rect(x, y + 6, 6, 1, "gold")
    cv.rect(x + 2, y - 2, 2, 2, "gold_dark")


def _head_front(cv, dy=0, lean=0):
    x = 16 + lean
    y = CROWN + dy
    _bun(cv, x + 5, y - 8)
    cv.rect(x, y, 16, 20, "hair")            # 头发底胎（含鬓角）
    cv.rect(x, y, 16, 1, "hair_lit")
    cv.rect(x, y + 1, 1, 4, "hair_lit")
    cv.rect(x + 2, y + 6, 12, 14, "skin")     # 脸
    cv.rect(x + 2, y + 6, 12, 1, "skin_dark")
    cv.rect(x + 2, y + 5, 12, 1, "hair")      # 刘海
    cv.rect(x + 4, y + 5, 3, 1, "hair_lit")
    cv.rect(x + 2, y + 6, 2, 1, "hair")
    cv.rect(x + 12, y + 6, 2, 1, "hair")
    cv.rect(x + 4, y + 11, 2, 2, "ink")       # 眼
    cv.rect(x + 10, y + 11, 2, 2, "ink")
    cv.rect(x + 4, y + 9, 2, 1, "hair")       # 眉
    cv.rect(x + 10, y + 9, 2, 1, "hair")
    cv.rect(x + 7, y + 13, 2, 2, "skin_dark")  # 鼻
    cv.rect(x + 6, y + 17, 4, 1, "ink_soft")   # 嘴
    cv.rect(x + 2, y + 18, 12, 1, "skin_dark")
    cv.rect(x + 4, y + 7, 6, 1, "skin_lit")


def _head_back(cv, dy=0, lean=0):
    x = 16 + lean
    y = CROWN + dy
    _bun(cv, x + 5, y - 8)
    cv.rect(x, y, 16, 20, "hair")
    cv.rect(x, y, 16, 1, "hair_lit")
    cv.rect(x, y + 1, 1, 6, "hair_lit")
    cv.rect(x + 3, y + 7, 10, 1, "hair_warm")
    cv.rect(x + 2, y + 13, 12, 1, "hair_warm")
    cv.rect(x + 4, y + 18, 8, 1, "hair_warm")
    cv.rect(x + 6, y + 19, 4, 1, "ink_soft")


def _head_side(cv, dy=0, lean=0):
    """朝右的侧面。"""
    x = 16 + lean
    y = CROWN + dy
    _bun(cv, x + 4, y - 8)
    cv.rect(x, y, 15, 20, "hair")             # 后脑 + 头顶
    cv.rect(x, y, 15, 1, "hair_lit")
    cv.rect(x + 7, y + 6, 8, 14, "skin")      # 侧脸
    cv.rect(x + 7, y + 6, 8, 1, "skin_dark")
    cv.rect(x + 7, y + 5, 8, 1, "hair")       # 刘海
    cv.rect(x, y + 6, 2, 9, "hair_lit")
    cv.rect(x + 10, y + 11, 2, 2, "ink")      # 眼
    cv.rect(x + 10, y + 9, 3, 1, "hair")      # 眉
    cv.rect(x + 14, y + 12, 2, 2, "skin_dark")  # 鼻尖
    cv.rect(x + 12, y + 17, 3, 1, "ink_soft")   # 嘴
    cv.rect(x + 2, y + 12, 2, 4, "skin_dark")   # 耳
    cv.rect(x + 2, y + 12, 1, 4, "skin")


# ---------------------------------------------------------------- 躯干
def _collar(cv, x, y, steps, color, shade):
    for i in range(steps):
        cv.rect(x + 3 + i, y + i, 2, 2, color)
        cv.rect(x + 12 - i, y + i, 2, 2, shade)


def _torso_front(cv, dy=0, lean=0):
    x = 16 + lean
    y = CHIN + 2 + dy
    cv.rect(x + 6, CHIN - 2 + dy, 4, 4, "skin")   # 脖子
    cv.rect(x + 6, CHIN + 1 + dy, 4, 1, "skin_dark")
    cv.rect(x, y, 16, 17, "tunic")
    cv.rect(x, y, 16, 1, "tunic_lit")
    cv.rect(x, y, 1, 17, "tunic_lit")
    cv.rect(x + 15, y, 1, 17, "tunic_dark")
    _collar(cv, x, y + 2, 4, "cream", "cream_dark")
    cv.rect(x + 7, y + 14, 2, 3, "cream_dark")
    # 腰带
    cv.rect(x - 1, SASH_Y + dy, 18, 4, "sash")
    cv.rect(x - 1, SASH_Y + dy, 18, 1, "sash_lit")
    cv.rect(x, SASH_Y + 3 + dy, 16, 1, "sash_dark")
    cv.rect(x + 6, SASH_Y + 1 + dy, 4, 2, "gold")
    cv.rect(x + 7, SASH_Y + 1 + dy, 2, 1, "gold_lit")
    # 下摆
    sy = SASH_Y + 4 + dy
    cv.rect(x, sy, 16, 6, "tunic_dark")
    cv.rect(x + 1, sy, 14, 5, "tunic")
    cv.rect(x + 4, sy, 1, 6, "tunic_dark")
    cv.rect(x + 11, sy, 1, 6, "tunic_dark")
    cv.rect(x + 1, sy, 14, 1, "tunic_lit")


def _torso_back(cv, dy=0, lean=0):
    x = 16 + lean
    y = CHIN + 2 + dy
    cv.rect(x + 6, CHIN - 2 + dy, 4, 4, "skin")
    cv.rect(x + 6, CHIN + 1 + dy, 4, 1, "skin_dark")
    cv.rect(x, y, 16, 17, "tunic")
    cv.rect(x, y, 16, 1, "tunic_lit")
    cv.rect(x, y, 1, 17, "tunic_lit")
    cv.rect(x + 15, y, 1, 17, "tunic_dark")
    cv.rect(x + 3, y + 2, 10, 1, "cream_dark")
    cv.rect(x + 2, y + 8, 12, 1, "tunic_lit")
    cv.rect(x - 1, SASH_Y + dy, 18, 4, "sash")
    cv.rect(x - 1, SASH_Y + dy, 18, 1, "sash_lit")
    cv.rect(x, SASH_Y + 3 + dy, 16, 1, "sash_dark")
    cv.rect(x + 6, SASH_Y + 1 + dy, 4, 2, "gold_dark")
    sy = SASH_Y + 4 + dy
    cv.rect(x, sy, 16, 6, "tunic_dark")
    cv.rect(x + 1, sy, 14, 5, "tunic")
    cv.rect(x + 4, sy, 1, 6, "tunic_dark")
    cv.rect(x + 11, sy, 1, 6, "tunic_dark")


def _torso_side(cv, dy=0, lean=0):
    x = 16 + lean
    y = CHIN + 2 + dy
    cv.rect(x + 6, CHIN - 2 + dy, 4, 4, "skin")
    cv.rect(x + 6, CHIN + 1 + dy, 4, 1, "skin_dark")
    cv.rect(x + 1, y, 14, 17, "tunic")
    cv.rect(x + 1, y, 14, 1, "tunic_lit")
    cv.rect(x + 1, y, 1, 17, "tunic_lit")
    cv.rect(x + 14, y, 1, 17, "tunic_dark")
    for i in range(4):
        cv.rect(x + 11 - i, y + 2 + i, 2, 2, "cream")
    cv.rect(x, SASH_Y + dy, 16, 4, "sash")
    cv.rect(x, SASH_Y + dy, 16, 1, "sash_lit")
    cv.rect(x + 1, SASH_Y + 3 + dy, 14, 1, "sash_dark")
    cv.rect(x + 10, SASH_Y + 1 + dy, 4, 2, "gold")
    sy = SASH_Y + 4 + dy
    cv.rect(x, sy, 16, 6, "tunic_dark")
    cv.rect(x + 1, sy, 14, 5, "tunic")
    cv.rect(x + 1, sy, 14, 1, "tunic_lit")
    cv.rect(x + 6, sy, 1, 6, "tunic_dark")


# ---------------------------------------------------------------- 组装
def _body(direction, bob, lean, arms, feet):
    """feet 为 (左, 右) 的脚底坐标；direction 只接受 0 / 2 / 3。"""
    cv = Canvas(W, H)
    dy = bob
    if direction in (0, 3):
        _leg(cv, (CX - 3, HIP + dy), (feet[0][0], feet[0][1]))
        _leg(cv, (CX + 3, HIP + dy), (feet[1][0], feet[1][1]))
        if direction == 0:
            _torso_front(cv, dy, lean)
        else:
            _torso_back(cv, dy, lean)
        _arm(cv, (CX - 10 + lean, SHOULDER + dy), arms[0])
        _arm(cv, (CX + 10 + lean, SHOULDER + dy), arms[1])
        if direction == 0:
            _head_front(cv, dy, lean)
        else:
            _head_back(cv, dy, lean)
    else:
        _leg(cv, (CX - 1, HIP + dy), feet[1])
        _leg(cv, (CX + 1, HIP + dy), feet[0])
        _torso_side(cv, dy, lean)
        _arm(cv, (CX + 5 + lean, SHOULDER + dy), arms[1])
        _head_side(cv, dy, lean)
    cv.out("ink")
    return cv


def _walk(direction, index):
    """行走 4 帧：0/2 触地，1/3 过渡并整体抬高 1 像素。"""
    bob = 0 if index % 2 == 0 else -1
    phase = [1, 0, -1, 0][index]
    if direction in (0, 3):
        feet = [(CX - 4, FLOOR + bob), (CX + 4, FLOOR + bob - abs(phase))]
        hands = [(CX - 11 - phase, 52 + bob), (CX + 11 + phase, 52 + bob)]
    else:
        feet = [(CX + 1 + phase * 5, FLOOR + bob), (CX - 1 - phase * 5, FLOOR + bob)]
        hands = [(CX - 6 - phase * 3, 52 + bob), (CX + 10 + phase * 2, 52 + bob)]
    return _body(direction, bob, 0, hands, feet), hands[1]


# 挥剑 6 帧：手相对躯干中心的偏移（像素），配合 main.gd 的 swing_angle
ATTACK_HANDS = {
    0: [(9, -2), (11, -11), (9, -15), (2, -11), (-6, -4), (-2, 1)],
    2: [(-6, -2), (-9, -11), (-4, -15), (6, -13), (11, -2), (6, 3)],
    3: [(-9, -2), (-11, -11), (-8, -15), (0, -13), (7, -4), (3, 1)],
}
ATTACK_BODY = [(0, 0), (0, -1), (1, -1), (2, 1), (1, 1), (0, 0)]


def _attack(direction, index):
    hand_off = ATTACK_HANDS[direction][index]
    lean, step = ATTACK_BODY[index]
    bob = -1 if index in (1, 2) else 0
    target = (CX + hand_off[0], 44 + hand_off[1])
    if direction == 2:
        sh = (CX + 6 + lean, SHOULDER + bob)
        hands = [(CX - 9, 52 + bob), _ik(sh, target, 21)]
        feet = [(CX + 2 + step * 5, FLOOR), (CX - 2 - step * 4, FLOOR)]
    else:
        sh = (CX + 10 + lean, SHOULDER + bob)
        hands = [(CX - 11 + lean, 52 + bob), _ik(sh, target, 21)]
        feet = [(CX - 4 - step, FLOOR), (CX + 4 + step, FLOOR)]
    return _body(direction, bob, lean, hands, feet), hands[1]


def _idle(direction, index):
    bob = 0 if index == 0 else 1
    if direction in (0, 3):
        hands = [(CX - 11, 52 + bob), (CX + 11, 52 + bob)]
        feet = [(CX - 4, FLOOR), (CX + 4, FLOOR)]
    else:
        hands = [(CX - 6, 52 + bob), (CX + 10, 52 + bob)]
        feet = [(CX + 2, FLOOR), (CX - 2, FLOOR)]
    return _body(direction, bob, 0, hands, feet), hands[1]


_BUILDERS = {"walk": _walk, "attack": _attack, "idle": _idle}


def render(kind, direction, index):
    """返回 (画布, 持械手坐标)。direction: 0 下 1 左 2 右 3 上。"""
    mirrored = direction == 1
    cv, hand = _BUILDERS[kind](2 if mirrored else direction, index)
    if mirrored:
        cv = cv.flipped()
        hand = (W - 1 - hand[0], hand[1])
    return cv, (int(round(hand[0])), int(round(hand[1])))