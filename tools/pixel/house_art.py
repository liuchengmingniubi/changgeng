"""主角家：700x440 的 3/4 视角屋舍。

结构（从后到前）：
    屋脊 + 两坡瓦面 + 瓦当一排 → 檐口木枋 → 夯土墙（立柱、门窗、挂饰）→ 石台基
瓦面用"每一列筒瓦一条竖向条带"来画，列间一明一暗，形成参考图那种纵向瓦垄。
"""
from .canvas import Canvas
from .scene_palette import T, rng

W, H = 700, 440
CX = W // 2
RIDGE_Y, EAVE_Y = 26, 246
RIDGE_HALF, EAVE_HALF = 148, 336
WALL_Y0, WALL_Y1 = 252, 404
PLINTH_Y1 = 440


def _half(y):
    t = (y - RIDGE_Y) / float(EAVE_Y - RIDGE_Y)
    t = max(0.0, min(1.0, t))
    t = t ** 0.92
    return RIDGE_HALF + (EAVE_HALF - RIDGE_HALF) * t


def _roof(cv):
    # 瓦面：先铺底，再一列列画筒瓦（每列横向做明暗，形成瓦垄），最后压横向瓦口
    for y in range(RIDGE_Y, EAVE_Y + 1):
        hw = _half(y)
        cv.line(CX - hw, y, CX + hw, y, T("tile", 4))

    # 后坡（屋脊另一侧）只露一条窄边
    for y in range(RIDGE_Y - 12, RIDGE_Y + 2):
        hw = _half(RIDGE_Y) * 0.97
        cv.line(CX - hw, y, CX + hw, y, T("tile", 5))

    step = 22
    for i in range(-16, 17):
        x0 = i * step
        for y in range(RIDGE_Y, EAVE_Y + 1):
            hw = _half(y)
            if abs(x0) > hw:
                continue
            t = (y - RIDGE_Y) / float(EAVE_Y - RIDGE_Y)
            for dx, lv in ((-9, 3), (-6, 2), (-2, 1), (3, 2), (7, 3), (9, 4)):
                if abs(x0 + dx) > hw:
                    continue
                cv.px(CX + x0 + dx, y, T("tile", lv + (1 if t > 0.78 else 0)))

    # 横向瓦口：每 13 像素一道，瓦头压出半圆的暗影，读起来才像一片片瓦
    for y in range(RIDGE_Y + 6, EAVE_Y, 13):
        hw = _half(y)
        for i in range(-16, 17):
            x = CX + i * step
            if abs(i * step) > hw:
                continue
            for dx in range(-9, 10):
                xx = x + dx
                if abs(xx - CX) > hw:
                    continue
                cv.px(xx, y + (abs(dx) // 6), T("tile", 5))
            cv.px(x, y + 2, T("tile", 4))

    # 檐口的一排瓦当（半圆头）
    for i in range(-20, 21):
        x = CX + i * step
        hw = _half(EAVE_Y)
        if abs(i * step) > hw - 5:
            continue
        yy = EAVE_Y
        cv.ellipse(x, yy + 5, 8, 7, T("tile", 3))
        cv.ellipse(x, yy + 3, 7, 5, T("tile", 1))
        cv.ellipse(x, yy + 1, 5, 3, T("tile", 0))
        cv.px(x, yy + 7, T("tile", 5))

    # 屋脊：一条压顶 + 两端翘头
    for x in range(-RIDGE_HALF - 6, RIDGE_HALF + 7):
        cv.px(CX + x, RIDGE_Y - 13, T("tile", 4))
        cv.px(CX + x, RIDGE_Y - 12, T("tile", 2))
        cv.px(CX + x, RIDGE_Y - 11, T("tile", 1))
        cv.px(CX + x, RIDGE_Y - 10, T("tile", 2))
        cv.px(CX + x, RIDGE_Y - 9, T("tile", 4))
    for s in (-1, 1):
        x = CX + s * RIDGE_HALF
        for k in range(8):
            cv.px(x + s * k, RIDGE_Y - 13 - k // 2, T("tile", 1))
            cv.px(x + s * k, RIDGE_Y - 12 - k // 2, T("tile", 3))
        cv.ellipse(x + s * 8, RIDGE_Y - 22, 5, 5, T("tile", 2))
        cv.ellipse(x + s * 8, RIDGE_Y - 23, 3, 3, T("tile", 0))

    # 檐下阴影：檐口压一条深色，墙面接一条渐变
    for x in range(-EAVE_HALF - 4, EAVE_HALF + 5):
        cv.px(CX + x, EAVE_Y + 1, T("tile", 6))
        cv.px(CX + x, EAVE_Y + 2, T("tile", 5))
        cv.px(CX + x, EAVE_Y + 3, T("tile", 4))

    # 屋面檐板：沿两侧斜边压一条厚边，屋子才有厚度
    for y in range(RIDGE_Y + 4, EAVE_Y + 1):
        hw = _half(y)
        for s in (-1, 1):
            x = int(round(CX + s * hw))
            cv.px(x, y, T("tile", 6))
            cv.px(x - s, y, T("tile", 5))
            cv.px(x - 2 * s, y, T("tile", 3))


def _eave_beam(cv):
    # 檐枋：一根横木 + 斗拱块
    cv.rect(CX - EAVE_HALF + 6, EAVE_Y - 4, EAVE_HALF * 2 - 12, 14, T("wood", 2))
    cv.rect(CX - EAVE_HALF + 6, EAVE_Y - 4, EAVE_HALF * 2 - 12, 2, T("wood", 1))
    cv.rect(CX - EAVE_HALF + 6, EAVE_Y + 8, EAVE_HALF * 2 - 12, 2, T("wood", 4))
    for i in range(-8, 9):
        x = CX + i * 38
        cv.rect(x - 7, EAVE_Y - 10, 14, 8, T("wood", 2))
        cv.rect(x - 7, EAVE_Y - 10, 14, 2, T("wood", 1))
        cv.rect(x - 7, EAVE_Y - 4, 14, 2, T("wood", 4))


def _wall(cv):
    x0, x1 = CX - 296, CX + 296
    cv.rect(x0, WALL_Y0, x1 - x0, WALL_Y1 - WALL_Y0, T("wall", 2))
    # 横向明暗：左受光
    for x in range(x0, x1):
        t = (x - x0) / float(x1 - x0)
        lv = 1 if t < 0.18 else (2 if t < 0.62 else 3)
        cv.rect(x, WALL_Y0, 1, WALL_Y1 - WALL_Y0, T("wall", lv))
    # 斑驳：先压几块小的墙皮深色，再撒细颗粒，土墙才不像一整块塑料
    for i in range(22):
        cxp = x0 + 20 + rng(i, 1, 31) * (x1 - x0 - 40)
        cyp = WALL_Y0 + 30 + rng(i, 2, 32) * (WALL_Y1 - WALL_Y0 - 56)
        rx = 5 + rng(i, 3, 33) * 13
        ry = 3 + rng(i, 4, 34) * 6
        cv.ellipse(cxp, cyp, rx, ry, T("wall", 3))
    for y in range(WALL_Y0, WALL_Y1):
        for x in range(x0, x1):
            r = rng(x, y, 3)
            if r > 0.995:
                cv.px(x, y, T("wall", 3))
            elif r < 0.004:
                cv.px(x, y, T("wall", 1))
    # 檐下阴影带
    for i in range(18):
        lv = 3 + min(2, i // 7)
        cv.rect(x0, WALL_Y0 + i, x1 - x0, 1, T("wall", lv))
    # 墙裙返潮
    cv.rect(x0, WALL_Y1 - 26, x1 - x0, 26, T("wall", 3))
    cv.rect(x0, WALL_Y1 - 26, x1 - x0, 2, T("wall", 4))
    for i in range(26):
        if i % 5 == 0:
            cv.rect(x0 + 20 + i * 17, WALL_Y1 - 24, 3, 10, T("wall", 4))
    # 立柱
    for px in (-296, -238, 238, 296):
        cv.rect(CX + px - 9, WALL_Y0, 18, WALL_Y1 - WALL_Y0, T("wood", 2))
        cv.rect(CX + px - 9, WALL_Y0, 3, WALL_Y1 - WALL_Y0, T("wood", 1))
        cv.rect(CX + px + 6, WALL_Y0, 3, WALL_Y1 - WALL_Y0, T("wood", 3))
        cv.rect(CX + px - 11, WALL_Y0, 22, 6, T("wood", 3))
    # 上枋
    cv.rect(x0 - 6, WALL_Y0 + 18, (x1 - x0) + 12, 10, T("wood", 2))
    cv.rect(x0 - 6, WALL_Y0 + 18, (x1 - x0) + 12, 2, T("wood", 1))
    cv.rect(x0 - 6, WALL_Y0 + 26, (x1 - x0) + 12, 2, T("wood", 4))


def _door(cv):
    x0, x1 = CX - 62, CX + 62
    y0, y1 = 276, WALL_Y1
    cv.rect(x0 - 12, y0 - 12, (x1 - x0) + 24, (y1 - y0) + 12, T("wood", 3))
    cv.rect(x0 - 6, y0 - 6, (x1 - x0) + 12, (y1 - y0) + 6, T("wood", 4))
    # 门扇
    cv.rect(x0, y0, x1 - x0, y1 - y0, T("wood", 2))
    for i in range(6):
        px = x0 + 4 + i * 20
        cv.rect(px, y0, 2, y1 - y0, T("wood", 3))
        cv.rect(px + 2, y0, 2, y1 - y0, T("wood", 1))
    # 门缝
    cv.rect(CX - 1, y0, 2, y1 - y0, T("wood", 4))
    # 门钉与门环
    for yy in (y0 + 22, y0 + 62, y0 + 100):
        for xx in (x0 + 16, x0 + 40, x1 - 40, x1 - 16):
            cv.px(xx, yy, T("ink", 0))
    for xx in (CX - 16, CX + 16):
        cv.ellipse(xx, y0 + 54, 6, 6, T("ink", 0))
        cv.ellipse(xx, y0 + 54, 5, 5, T("wood", 1))
        cv.ellipse(xx, y0 + 54, 3, 3, T("ink", 0))
    # 门槛石
    cv.rect(x0 - 8, y1 - 6, (x1 - x0) + 16, 8, T("stone", 2))
    cv.rect(x0 - 8, y1 - 6, (x1 - x0) + 16, 2, T("stone", 1))


def _window(cv, cx, cy, w, h):
    x0, y0 = cx - w // 2, cy - h // 2
    cv.rect(x0 - 6, y0 - 6, w + 12, h + 12, T("wood", 2))
    cv.rect(x0 - 6, y0 - 6, w + 12, 2, T("wood", 1))
    cv.rect(x0 - 6, y0 + h + 4, w + 12, 2, T("wood", 3))
    # 窗纸
    cv.rect(x0, y0, w, h, T("plaster", 2))
    cv.rect(x0, y0, w, h // 2, T("plaster", 1))
    # 窗棂
    for i in range(1, 4):
        cv.rect(x0 + i * w // 4, y0, 2, h, T("wood", 3))
    for j in range(1, 3):
        cv.rect(x0, y0 + j * h // 3, w, 2, T("wood", 3))
    cv.rect(x0, y0, w, 2, T("wood", 4))
    # 窗台
    cv.rect(x0 - 8, y0 + h + 6, w + 16, 5, T("stone", 2))
    cv.rect(x0 - 8, y0 + h + 6, w + 16, 2, T("stone", 1))


def _plinth(cv):
    x0, x1 = CX - 306, CX + 306
    cv.rect(x0, WALL_Y1, x1 - x0, PLINTH_Y1 - WALL_Y1, T("stone", 2))
    cv.rect(x0, WALL_Y1, x1 - x0, 3, T("stone", 1))
    cv.rect(x0, PLINTH_Y1 - 4, x1 - x0, 4, T("stone", 4))
    # 石块缝
    for i in range(0, (x1 - x0) // 44 + 1):
        px = x0 + i * 44 + (10 if i % 2 else 0)
        cv.rect(px, WALL_Y1 + 4, 2, PLINTH_Y1 - WALL_Y1 - 8, T("stone", 3))
    cv.rect(x0, WALL_Y1 + 20, x1 - x0, 2, T("stone", 3))
    # 青苔
    for i in range(90):
        x = x0 + rng(i, 1, 6) * (x1 - x0)
        y = WALL_Y1 + 8 + rng(i, 2, 7) * (PLINTH_Y1 - WALL_Y1 - 14)
        cv.px(x, y, T("grass", 4))
    # 台阶
    sx, sy, sw, sh = 320, WALL_Y1 + 22, 60, 18
    cv.rect(sx, sy, sw, sh, T("stone", 2))
    cv.rect(sx, sy, sw, 3, T("stone", 1))
    cv.rect(sx - 4, sy + sh, sw + 8, 10, T("stone", 3))
    cv.rect(sx - 4, sy + sh, sw + 8, 2, T("stone", 2))
    cv.rect(sx - 8, sy + sh + 10, sw + 16, 8, T("stone", 4))


def _hangings(cv):
    # 左侧灯笼
    lx, ly = CX - 250, 286
    cv.rect(lx - 1, ly - 14, 2, 14, T("ink", 1))
    cv.ellipse(lx, ly + 8, 11, 13, T("red", 1))
    cv.ellipse(lx - 3, ly + 5, 6, 8, T("red", 0))
    cv.rect(lx - 8, ly - 4, 16, 3, T("wood", 3))
    cv.rect(lx - 8, ly + 20, 16, 3, T("wood", 3))
    for i in range(5):
        cv.rect(lx - 5 + i * 3, ly + 23, 1, 5, T("red", 1))
    # 右侧辣椒串 + 玉米
    for k in range(9):
        x = CX + 196 + (k % 3) * 7
        y = 284 + k * 6
        cv.px(x, y, T("red", 0))
        cv.px(x, y + 1, T("red", 1))
        cv.px(x, y + 2, T("red", 2))
    for k in range(4):
        x = CX + 238 + (k % 2) * 8
        y = 288 + k * 9
        cv.ellipse(x, y, 4, 6, T("crop_y", 1))
        cv.px(x - 1, y - 1, T("crop_y", 0))
        cv.px(x, y + 5, T("wood", 3))


def draw():
    cv = Canvas(W, H)
    _roof(cv)
    _eave_beam(cv)
    _wall(cv)
    _door(cv)
    _window(cv, CX - 190, 312, 78, 46)
    _window(cv, CX + 190, 312, 78, 46)
    _plinth(cv)
    _hangings(cv)
    cv.out(T("ink", 0))
    return cv
