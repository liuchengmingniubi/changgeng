"""主角家：320x224 的正面偏俯视房屋精灵。

结构固定为四层：屋顶(青瓦) -> 檐口 -> 夯土墙(木构) -> 石台基。
所有装饰（辣椒串、玉米、灯笼、烟囱）都在这张图里，方便一次性替换。
"""
from .canvas import Canvas
from .scene_palette import rng

W, H = 320, 224
RIDGE_Y, EAVE_Y = 6, 104
RIDGE_HALF, EAVE_HALF = 100, 160
WALL_X0, WALL_X1 = 16, 304
WALL_Y0, WALL_Y1 = 112, 212


def _edge(y):
    """某一行的屋顶左右边界。"""
    t = (EAVE_Y - y) / float(EAVE_Y - RIDGE_Y)
    half = EAVE_HALF - (EAVE_HALF - RIDGE_HALF) * t
    return int(round(160 - half)), int(round(160 + half))


def _roof(cv):
    band = 9
    for y in range(EAVE_Y, RIDGE_Y - 1, -band):
        x0, x1 = _edge(y)
        cv.rect(x0, y - band, x1 - x0, band, "tile")
        cv.rect(x0, y - band, x1 - x0, 2, "tile_lt")
        cv.rect(x0, y - 1, x1 - x0, 1, "tile_dk")
        cv.rect(x0, y - band, 1, band, "tile_lt")
        cv.rect(x1 - 1, y - band, 1, band, "tile_dk")
        # 瓦垄竖缝，错位排列
        off = 7 if (y // band) % 2 else 0
        for x in range(x0 + off, x1, 14):
            cv.rect(x, y - band + 2, 1, band - 2, "tile_dk")
            # 每片瓦的边缘高光，避免整条带子读成平涂
            if rng(x, y, 2) > 0.45:
                cv.rect(x + 1, y - band + 2, 1, band - 3, "tile_lt")
        # 瓦面斑驳：旧瓦的深浅点
        for x in range(x0 + 2, x1 - 2, 3):
            if rng(x, y, 7) > 0.88:
                cv.rect(x, y - band + 3, 2, 2, "tile_dk")
            elif rng(x, y, 7) < 0.10:
                cv.px(x, y - band + 4, "tile_hi")

    # 屋脊
    cv.rect(60, RIDGE_Y - 4, 200, 8, "tile_dk")
    cv.rect(60, RIDGE_Y - 4, 200, 2, "tile_hi")
    cv.rect(60, RIDGE_Y + 2, 200, 2, "tile")
    for x in (56, 246):
        cv.rect(x, RIDGE_Y - 8, 16, 8, "tile_dk")
        cv.rect(x + 2, RIDGE_Y - 10, 12, 3, "tile_lt")
    # 檐口
    cv.rect(0, EAVE_Y - 4, W, 6, "wood_dk")
    cv.rect(0, EAVE_Y - 4, W, 2, "wood")
    cv.rect(0, EAVE_Y + 2, W, 5, "tile_dk")


def _eave_tiles(cv):
    """檐口下沿的瓦当，画在墙之后，才像探出墙头。"""
    for x in range(4, W - 4, 12):
        cv.ellipse(x, EAVE_Y + 8, 5, 7, "tile")
        cv.ellipse(x, EAVE_Y + 9, 4, 5, "tile_dk")
        cv.px(x, EAVE_Y + 10, "tile_hi")


def _chimney(cv):
    cv.rect(64, 26, 30, 34, "stone")
    cv.rect(64, 26, 30, 3, "stone_lt")
    cv.rect(64, 26, 3, 34, "stone_lt")
    cv.rect(91, 26, 3, 34, "stone_dk")
    cv.rect(61, 20, 36, 8, "stone_dk")
    cv.rect(61, 20, 36, 2, "stone_lt")
    cv.rect(66, 12, 26, 9, "stone_dk")
    cv.rect(66, 12, 26, 2, "stone_lt")


def _wall(cv):
    cv.rect(WALL_X0, WALL_Y0, WALL_X1 - WALL_X0, WALL_Y1 - WALL_Y0, "wall")
    # 墙面斑驳
    for y in range(WALL_Y0, WALL_Y1):
        for x in range(WALL_X0, WALL_X1):
            r = rng(x, y, 5)
            if r > 0.94:
                cv.px(x, y, "wall_lt")
            elif r < 0.06:
                cv.px(x, y, "wall_dk")
    # 木构：两根立柱 + 上枋 + 腰枋
    for x in (WALL_X0, WALL_X1 - 10):
        cv.rect(x, WALL_Y0, 10, WALL_Y1 - WALL_Y0, "wood")
        cv.rect(x, WALL_Y0, 2, WALL_Y1 - WALL_Y0, "wood_lt")
        cv.rect(x + 8, WALL_Y0, 2, WALL_Y1 - WALL_Y0, "wood_dk")
    cv.rect(WALL_X0, WALL_Y0, WALL_X1 - WALL_X0, 8, "wood")
    cv.rect(WALL_X0, WALL_Y0, WALL_X1 - WALL_X0, 2, "wood_lt")
    cv.rect(WALL_X0, WALL_Y0 + 6, WALL_X1 - WALL_X0, 2, "wood_dk")
    # 檐下阴影
    cv.rect(WALL_X0 + 2, WALL_Y0 + 8, WALL_X1 - WALL_X0 - 4, 10, "wall_dk")


def _door(cv):
    x0, x1 = 132, 188
    y0, y1 = 140, 206
    cv.rect(x0 - 8, y0 - 8, (x1 - x0) + 16, 8, "wood")
    cv.rect(x0 - 8, y0 - 8, (x1 - x0) + 16, 2, "wood_lt")
    cv.rect(x0 - 8, y0, 8, y1 - y0 + 6, "wood")
    cv.rect(x1, y0, 8, y1 - y0 + 6, "wood")
    cv.rect(x0, y0, x1 - x0, y1 - y0, "wood_dk")
    for leaf in (0, 1):
        lx = x0 + leaf * 28
        cv.rect(lx + 1, y0 + 1, 26, y1 - y0 - 2, "wood")
        for px in range(lx + 5, lx + 26, 6):
            cv.rect(px, y0 + 2, 1, y1 - y0 - 4, "wood_dk")
        cv.rect(lx + 1, y0 + 1, 26, 1, "wood_lt")
        for sy in (y0 + 12, y0 + 32):
            for sx in (lx + 6, lx + 14, lx + 22):
                cv.rect(sx, sy, 2, 2, "gold_dark")
        cv.rect(lx + (22 if leaf == 0 else 4), y0 + 26, 2, 8, "gold")
    # 门槛 + 门墩
    cv.rect(x0 - 8, y1, (x1 - x0) + 16, 6, "stone")
    cv.rect(x0 - 8, y1, (x1 - x0) + 16, 2, "stone_lt")
    # 门内暗部
    cv.rect(x0, y0, x1 - x0, 3, "shadow")


def _window(cv, x0, y0, w, h):
    cv.rect(x0, y0, w, h, "wood")
    cv.rect(x0, y0, w, 3, "wood_lt")
    cv.rect(x0, y0 + h - 2, w, 2, "wood_dk")
    cv.rect(x0 + 5, y0 + 4, w - 10, h - 8, "ink_soft")
    cv.rect(x0 + 5, y0 + 4, w - 10, 2, "ink")
    # 窗棂
    for i in range(1, 3):
        cx = x0 + 5 + i * (w - 10) // 3
        cv.rect(cx, y0 + 4, 2, h - 8, "wood_lt")
    cv.rect(x0 + 5, y0 + 4 + (h - 8) // 2, w - 10, 2, "wood_lt")
    # 窗台
    cv.rect(x0 - 4, y0 + h, w + 8, 4, "wood")
    cv.rect(x0 - 4, y0 + h, w + 8, 2, "wood_lt")


def _hangings(cv):
    # 辣椒串
    for i in range(2):
        x = 214 + i * 9
        cv.rect(x, 118, 2, 12, "straw_dk")
        for k in range(5):
            cv.rect(x - 1 + (k % 2), 122 + k * 4, 4, 3, "cloth_red")
            cv.rect(x - 1 + (k % 2), 122 + k * 4, 2, 1, "cloth_red_lt")
    # 玉米
    for i in range(3):
        x = 240 + i * 7
        cv.rect(x, 120, 4, 16, "straw_lt")
        cv.rect(x, 120, 1, 16, "straw_hi")
        cv.rect(x, 136, 4, 4, "straw_dk")
    # 灯笼
    lx = 118
    cv.rect(lx, 116, 1, 8, "gold_dark")
    cv.rect(lx - 7, 124, 15, 16, "cloth_red")
    cv.rect(lx - 7, 124, 15, 2, "cloth_red_lt")
    cv.rect(lx - 7, 138, 15, 2, "cloth_red")
    for i in range(1, 5):
        cv.rect(lx - 7 + i * 3, 126, 1, 12, "cloth_red_lt")
    cv.rect(lx - 4, 120, 9, 4, "gold_dark")
    cv.rect(lx - 4, 140, 9, 4, "gold_dark")
    cv.rect(lx - 2, 144, 3, 5, "gold")


def _base(cv):
    cv.rect(WALL_X0 - 4, WALL_Y1, (WALL_X1 - WALL_X0) + 8, 12, "stone")
    cv.rect(WALL_X0 - 4, WALL_Y1, (WALL_X1 - WALL_X0) + 8, 3, "stone_lt")
    cv.rect(WALL_X0 - 4, WALL_Y1 + 9, (WALL_X1 - WALL_X0) + 8, 3, "stone_dk")
    for x in range(WALL_X0 - 4, WALL_X1 + 4, 24):
        cv.rect(x, WALL_Y1 + 3, 1, 9, "stone_dk")


def draw():
    cv = Canvas(W, H)
    _chimney(cv)
    _roof(cv)
    _wall(cv)
    _eave_tiles(cv)
    _window(cv, 44, 150, 46, 34)
    _window(cv, 214, 146, 60, 40)
    _door(cv)
    _base(cv)
    _hangings(cv)
    cv.out("ink")
    return cv