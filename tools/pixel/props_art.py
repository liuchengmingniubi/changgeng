"""场景物件：树、栅栏、作物、小道具。

每个小道具都画在 32x32 的格子里，底边中心对齐 (16,30)，方便统一摆放。
"""
from .canvas import Canvas
from .scene_palette import rng

# ---------------------------------------------------------------- 树
def tree(kind="big"):
    if kind == "big":
        w, h = 156, 176
        blobs = [(-30, -96, 40, 34), (26, -104, 34, 30), (-2, -128, 38, 30),
                 (-46, -70, 28, 24), (44, -74, 28, 24), (0, -92, 44, 34)]
        trunk_h, trunk_w = 62, 15
    else:
        w, h = 112, 128
        blobs = [(-20, -70, 28, 23), (18, -76, 24, 21), (0, -92, 26, 20)]
        trunk_h, trunk_w = 46, 11
    cv = Canvas(w, h)
    cx, base = w // 2, h - 6
    # 树干 + 分枝
    top = base - trunk_h
    cv.rect(cx - trunk_w // 2, top, trunk_w, trunk_h, "wood")
    cv.rect(cx - trunk_w // 2, top, 3, trunk_h, "wood_lt")
    cv.rect(cx + trunk_w // 2 - 3, top, 3, trunk_h, "wood_dk")
    cv.line(cx - 2, top + 16, cx - 18, top - 8, "wood", 4)
    cv.line(cx + 2, top + 10, cx + 16, top - 12, "wood", 4)
    # 树根
    cv.rect(cx - trunk_w // 2 - 6, base - 4, trunk_w + 12, 6, "wood_dk")
    cv.rect(cx - trunk_w // 2 - 4, base - 4, trunk_w + 8, 2, "wood")
    # 冠层：先暗后亮，左上受光
    for (ox, oy, rx, ry) in blobs:
        cv.ellipse(cx + ox, base + oy, rx, ry, "leaf_dk")
    for (ox, oy, rx, ry) in blobs:
        cv.ellipse(cx + ox, base + oy - 3, rx - 2, ry - 3, "leaf")
    for (ox, oy, rx, ry) in blobs:
        cv.ellipse(cx + ox - 4, base + oy - 9, rx - 8, ry - 8, "leaf_lt")
    # 叶簇噪声：受光面亮点、背光面暗点
    for y in range(h):
        for x in range(w):
            if cv.img.getpixel((x, y))[3] == 0:
                continue
            r = rng(x, y, 9)
            dx = x - cx
            dy = y - base
            lit = dx < 0 and dy < -60
            if r > (0.90 if lit else 0.965):
                cv.px(x, y, "leaf_hi" if lit else "leaf_dk")
            elif r < 0.05:
                cv.px(x, y, "leaf_lt")
    cv.out("ink")
    return cv


# ---------------------------------------------------------------- 栅栏
def fence_segment(w=32, h=46):
    cv = Canvas(w, h)
    base = h - 4
    # 两根横杆
    for ry in (base - 30, base - 16):
        cv.rect(0, ry, w, 5, "wood")
        cv.rect(0, ry, w, 2, "wood_lt")
        cv.rect(0, ry + 4, w, 1, "wood_dk")
    # 立柱
    for px in (w // 2 - 9, w // 2 + 7):
        cv.rect(px, base - 40, 5, 40, "wood")
        cv.rect(px, base - 40, 2, 40, "wood_lt")
        cv.rect(px + 4, base - 40, 1, 40, "wood_dk")
        cv.rect(px, base - 44, 5, 4, "wood_dk")
    # 杆间缠草绳
    cv.rect(0, base - 24, w, 1, "straw_dk")
    cv.out("ink")
    return cv


def gate(w=100, h=70):
    cv = Canvas(w, h)
    base = h - 4
    for px in (2, w - 12):
        cv.rect(px, base - 56, 10, 56, "wood")
        cv.rect(px, base - 56, 3, 56, "wood_lt")
        cv.rect(px + 9, base - 56, 1, 56, "wood_dk")
        cv.rect(px - 2, base - 60, 14, 5, "wood_dk")
    cv.rect(0, base - 54, w, 7, "wood")
    cv.rect(0, base - 54, w, 2, "wood_lt")
    cv.rect(0, base - 48, w, 1, "wood_dk")
    # 半开的门板
    cv.rect(14, base - 46, 34, 42, "wood")
    for i in range(4):
        cv.rect(14 + 3 + i * 8, base - 44, 1, 38, "wood_dk")
    cv.rect(14, base - 46, 34, 2, "wood_lt")
    cv.rect(44, base - 42, 2, 6, "gold")
    cv.out("ink")
    return cv


# ---------------------------------------------------------------- 作物
def crops(stage):
    """96x64 一块田的作物层，stage 0..2。"""
    cv = Canvas(96, 64)
    rows = 4
    for r in range(rows):
        y = 8 + r * 14
        for i in range(9):
            x = 7 + i * 10 + (0 if r % 2 == 0 else 5)
            if stage == 0:
                cv.rect(x, y + 6, 2, 3, "sprout")
                cv.rect(x - 1, y + 4, 1, 2, "crop")
                cv.rect(x + 2, y + 4, 1, 2, "crop")
            elif stage == 1:
                cv.rect(x, y + 1, 2, 8, "sprout")
                cv.rect(x - 2, y + 2, 2, 4, "crop")
                cv.rect(x + 2, y, 2, 5, "crop_lit")
                cv.rect(x - 3, y + 5, 2, 3, "crop")
            else:
                cv.rect(x, y - 3, 2, 12, "sprout")
                cv.rect(x - 3, y - 1, 3, 6, "crop")
                cv.rect(x + 2, y - 3, 3, 6, "crop_lit")
                cv.rect(x - 5, y + 2, 3, 4, "crop")
                cv.rect(x + 4, y + 1, 3, 4, "crop_lit")
                cv.rect(x - 1, y - 6, 4, 4, "crop_lit")
    return cv


# ---------------------------------------------------------------- 小道具
def _jar(cv):
    cv.ellipse(16, 22, 9, 7, "wood")
    cv.rect(11, 12, 10, 10, "wood")
    cv.rect(9, 10, 14, 3, "wood_lt")
    cv.rect(13, 8, 6, 3, "wood_dk")
    cv.rect(12, 13, 2, 8, "wood_lt")
    cv.rect(20, 14, 2, 8, "wood_dk")
    cv.ellipse(16, 10, 7, 2, "ink_soft")


def _bucket(cv):
    cv.rect(10, 14, 12, 14, "wood")
    cv.rect(10, 14, 12, 2, "wood_lt")
    cv.rect(10, 20, 12, 2, "steel_dark")
    cv.rect(9, 12, 14, 3, "wood_lt")
    cv.rect(11, 8, 10, 2, "wood_dk")
    cv.rect(13, 6, 2, 3, "wood_dk")


def _basket(cv):
    cv.rect(9, 17, 14, 10, "straw")
    cv.rect(9, 17, 14, 2, "straw_lt")
    for x in range(10, 23, 3):
        cv.rect(x, 19, 1, 8, "straw_dk")
    cv.rect(9, 21, 14, 1, "straw_dk")
    cv.rect(11, 15, 10, 3, "straw_lt")


def _woodpile(cv):
    for i, y in enumerate((24, 19, 14)):
        n = 3 - (i // 2)
        for k in range(n):
            x = 6 + k * 7 + (i % 2) * 2
            cv.rect(x, y, 7, 5, "wood")
            cv.rect(x, y, 7, 1, "wood_lt")
            cv.rect(x + 6, y, 1, 5, "wood_dk")
            cv.px(x + 3, y + 2, "wood_hi")


def _stool(cv):
    cv.rect(10, 14, 12, 3, "wood")
    cv.rect(10, 14, 12, 1, "wood_lt")
    for x in (11, 19):
        cv.rect(x, 17, 2, 9, "wood_dk")


def _broom(cv):
    cv.line(14, 8, 20, 24, "wood", 2)
    cv.rect(17, 22, 8, 4, "straw")
    for i in range(4):
        cv.line(18 + i * 2, 26, 17 + i * 2, 30, "straw_dk", 1)
    cv.rect(12, 6, 6, 3, "wood_dk")


def _chicken(cv, peck=False, flip=False):
    cx = 16
    cv.ellipse(cx, 22, 8, 6, "cream_dark")
    cv.ellipse(cx - 1, 20, 7, 5, "cream")
    if peck:
        cv.ellipse(cx + 6, 26, 3, 3, "cream")
        cv.rect(cx + 8, 25, 3, 2, "gold")
        cv.rect(cx + 6, 23, 3, 2, "cloth_red")
    else:
        cv.rect(cx + 3, 12, 6, 6, "cream")
        cv.rect(cx + 8, 14, 3, 2, "gold")
        cv.rect(cx + 5, 10, 3, 2, "cloth_red")
        cv.px(cx + 7, 13, "ink")
    cv.rect(cx - 2, 18, 4, 3, "cream_dark")
    for x in (cx - 4, cx - 1):
        cv.rect(x, 27, 1, 2, "gold_dark")


def _cat(cv):
    cv.ellipse(16, 24, 10, 5, "pants_lit")
    cv.ellipse(22, 22, 4, 4, "pants")
    cv.rect(25, 19, 2, 2, "pants")
    cv.rect(24, 18, 1, 2, "pants")
    cv.px(26, 22, "ink")
    cv.rect(8, 22, 3, 2, "pants_dark")


def _crock(cv):
    cv.ellipse(16, 20, 12, 9, "stone_dk")
    cv.ellipse(16, 19, 11, 8, "stone")
    cv.ellipse(16, 12, 8, 3, "stone_dk")
    cv.ellipse(16, 12, 6, 2, "water")
    cv.rect(12, 13, 2, 6, "water_lt")


def _hay(cv):
    cv.ellipse(16, 22, 12, 7, "straw_dk")
    cv.ellipse(16, 21, 11, 6, "straw")
    for i in range(6):
        cv.line(8 + i * 3, 26, 12 + i * 3, 16, "straw_lt", 1)
    cv.rect(12, 14, 8, 1, "straw_dk")


def _well(cv):
    """石圈井台 + 木架吊桶，32 宽的格子放得下。"""
    cv.ellipse(16, 25, 12, 6, "stone_dk")
    cv.ellipse(16, 24, 11, 5, "stone")
    cv.ellipse(16, 23, 7, 3, "water_dk")
    cv.ellipse(16, 23, 6, 2, "water")
    cv.px(14, 23, "water_lt")
    # 木架
    for x in (6, 24):
        cv.rect(x, 8, 3, 15, "wood")
        cv.rect(x, 8, 1, 15, "wood_lt")
    cv.rect(6, 6, 21, 3, "wood_dk")
    cv.rect(9, 9, 15, 2, "wood")
    # 吊绳 + 小桶
    cv.rect(16, 11, 1, 6, "straw_dk")
    cv.rect(13, 17, 7, 5, "wood")
    cv.rect(13, 17, 7, 1, "wood_lt")
    cv.rect(13, 19, 7, 1, "steel_dark")


def _crate(cv):
    cv.rect(8, 15, 16, 13, "wood")
    cv.rect(8, 15, 16, 2, "wood_lt")
    cv.rect(8, 15, 2, 13, "wood_lt")
    cv.rect(22, 15, 2, 13, "wood_dk")
    cv.rect(8, 26, 16, 2, "wood_dk")
    cv.line(9, 16, 23, 27, "wood_dk", 1)
    cv.line(9, 27, 23, 16, "wood_dk", 1)


def _bush(cv):
    cv.ellipse(16, 24, 11, 7, "leaf_dk")
    cv.ellipse(16, 23, 10, 6, "leaf")
    cv.ellipse(12, 20, 6, 4, "leaf_lt")
    cv.ellipse(21, 22, 5, 4, "leaf_lt")
    for y in range(14, 31):
        for x in range(4, 29):
            if cv.img.getpixel((x, y))[3] and rng(x, y, 4) > 0.93:
                cv.px(x, y, "leaf_hi")


DRAWERS = {
    "jar": _jar, "bucket": _bucket, "basket": _basket, "woodpile": _woodpile,
    "stool": _stool, "broom": _broom, "chicken_a": lambda cv: _chicken(cv),
    "chicken_b": lambda cv: _chicken(cv, peck=True), "chicken_c": lambda cv: _chicken(cv, flip=True),
    "cat": _cat, "crock": _crock, "hay": _hay, "well": _well, "crate": _crate, "bush": _bush,
}

PROP_NAMES = list(DRAWERS.keys())


def prop(name):
    cv = Canvas(32, 32)
    DRAWERS[name](cv)
    cv.out("ink")
    return cv