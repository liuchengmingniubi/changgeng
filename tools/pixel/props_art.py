"""树木、栅栏、院门、菜畦与杂物：全部是独立素材，底部中心对齐。

光照统一：光从左上打来，左上亮、右下暗，每样东西只用自己的材质梯取色。
"""
import math

from .canvas import Canvas
from .scene_palette import T, rng


# ---------------- 通用 ----------------
def _column(cv, x, y0, y1, w, base, lit=None, dark=None):
    cv.rect(x - w / 2, y0, w, y1 - y0, T(base, 2))
    if lit:
        cv.rect(x - w / 2, y0, max(1, w // 3), y1 - y0, T(lit, 1))
    if dark:
        cv.rect(x + w / 2 - max(1, w // 3), y0, max(1, w // 3), y1 - y0, T(dark, 4))


def _canopy(cv, cx, cy, rx, ry, seed, base="leaf", holes=0.80):
    """一团树冠：按椭球法线取明暗档，边缘用噪声咬碎。"""
    for y in range(int(cy - ry), int(cy + ry) + 1):
        for x in range(int(cx - rx), int(cx + rx) + 1):
            dx = (x - cx) / rx
            dy = (y - cy) / ry
            d2 = dx * dx + dy * dy
            n = rng(x, y, seed)
            if d2 > 1.0 - 0.16 * n:
                continue
            if d2 > holes and n > 0.78:
                continue
            lum = (-0.52 * dx - 0.78 * dy) * 0.9 + 0.55
            lum += (rng(x // 3, y // 3, seed + 7) - 0.5) * 0.34
            lv = int(round((1.0 - lum) * 3.1 + 0.6))
            lv = max(0, min(6, lv))
            cv.px(x, y, T(base, lv))


def _shadow_ellipse(cv, cx, cy, rx, ry, level=5):
    # 大的投影（树、栅栏、院门、菜畦）已经烘进地面层了，素材里只留小物件的接触影，
    # 否则会和烘焙阴影叠成两层，出现参考图里没有的硬边褐色圆盘。
    if rx > 20:
        return
    cv.ellipse(cx, cy, rx, ry, T("loess", level))


# ---------------- 树 ----------------
def tree(kind="big"):
    if kind == "big":
        w, h = 250, 300
        trunk_h = 150
        blobs = [(0, -8, 96, 86), (-52, 22, 62, 56), (54, 18, 66, 58), (2, -62, 62, 52)]
    else:
        w, h = 168, 210
        trunk_h = 104
        blobs = [(0, -6, 66, 60), (-38, 16, 44, 40), (40, 12, 46, 42)]
    cv = Canvas(w, h)
    cx = w // 2
    _shadow_ellipse(cv, cx + 18, h - 6, int(w * 0.36), 12)
    # 树干：下粗上细，带树皮纹
    for i in range(trunk_h):
        t = i / float(trunk_h)
        y = h - 4 - i
        half = 7 - t * 3.2
        cv.rect(cx - half, y, half * 2, 1, T("bark", 2))
        cv.rect(cx - half, y, max(1, half * 0.45), 1, T("bark", 1))
        cv.rect(cx + half - max(1, half * 0.4), y, max(1, half * 0.4), 1, T("bark", 3))
    for i in range(14):
        y = h - 12 - rng(i, 1, 5) * (trunk_h - 16)
        cv.rect(cx - 5 + rng(i, 2, 6) * 9, y, 2, 5 + rng(i, 3, 7) * 6, T("bark", 4))
    # 树根外扒
    for s in (-1, 1):
        for k in range(10):
            cv.px(cx + s * (6 + k * 1.4), h - 6 - k // 3, T("bark", 3))
    # 枝
    for s in (-1, 1):
        cv.line(cx, h - trunk_h + 6, cx + s * 42, h - trunk_h - 16, T("bark", 2), 5)
        cv.line(cx, h - trunk_h + 24, cx + s * 34, h - trunk_h + 4, T("bark", 2), 4)
    # 树冠
    base_y = h - trunk_h - 40
    for (bx, by, brx, bry) in blobs:
        _canopy(cv, cx + bx, base_y + by, brx, bry, 11 + bx)
    # 冠下的暗部
    cv.out(T("ink", 0))
    return cv


# ---------------- 栅栏 ----------------
def fence_segment():
    w, h = 96, 66
    cv = Canvas(w, h)
    _shadow_ellipse(cv, w // 2 + 3, h - 4, w // 2 - 6, 5)
    # 两根横杆
    for yy in (24, 39):
        cv.rect(2, yy, w - 4, 6, T("wood", 1))
        cv.rect(2, yy, w - 4, 2, T("wood", 0))
        cv.rect(2, yy + 4, w - 4, 2, T("wood", 2))
    # 立柱 + 石础
    for px in (9, w // 2, w - 9):
        cv.rect(px - 4, 12, 9, 44, T("wood", 1))
        cv.rect(px - 4, 12, 3, 44, T("wood", 0))
        cv.rect(px + 3, 12, 2, 44, T("wood", 2))
        cv.rect(px - 5, 10, 11, 3, T("wood", 0))
        cv.rect(px - 6, 54, 13, 7, T("stone", 2))
        cv.rect(px - 6, 54, 13, 2, T("stone", 1))
    cv.out(T("ink", 0))
    return cv


def gate():
    w, h = 150, 100
    cv = Canvas(w, h)
    _shadow_ellipse(cv, w // 2 + 4, h - 5, w // 2 - 8, 7)
    # 两根门柱
    for px in (14, w - 14):
        cv.rect(px - 7, 6, 14, h - 16, T("wood", 1))
        cv.rect(px - 7, 6, 4, h - 16, T("wood", 0))
        cv.rect(px + 3, 6, 4, h - 16, T("wood", 2))
        cv.rect(px - 9, 2, 18, 5, T("wood", 0))
        cv.rect(px - 9, h - 12, 18, 8, T("stone", 2))
        cv.rect(px - 9, h - 12, 18, 2, T("stone", 1))
    # 门扇：两片对开，竖向板条
    for s in (0, 1):
        x0 = 24 if s == 0 else w // 2 + 1
        x1 = w // 2 - 1 if s == 0 else w - 24
        cv.rect(x0, 16, x1 - x0, h - 28, T("wood", 1))
        for i in range(5):
            px = x0 + 3 + i * ((x1 - x0 - 6) // 5)
            cv.rect(px, 16, 3, h - 28, T("wood", 0))
            cv.rect(px + 4, 16, 1, h - 28, T("wood", 2))
        cv.rect(x0, 16, x1 - x0, 3, T("wood", 0))
        # 两道横撑
        for yy in (34, h - 32):
            cv.rect(x0, yy, x1 - x0, 5, T("wood", 1))
            cv.rect(x0, yy, x1 - x0, 2, T("wood", 0))
    cv.out(T("ink", 0))
    return cv


# ---------------- 菜畦 ----------------
def _plot_frame(cv, w, h):
    cv.rect(0, 4, w, h - 4, T("wood", 1))
    cv.rect(0, 4, w, 2, T("wood", 0))
    cv.rect(0, h - 4, w, 4, T("wood", 2))
    cv.rect(3, 10, w - 6, h - 18, T("soil", 1))
    for y in range(10, h - 12, 8):
        cv.rect(4, y, w - 8, 2, T("soil", 2))
        cv.rect(4, y + 2, w - 8, 1, T("soil", 0))
    for i in range(16):
        cv.rect(6 + rng(i, 1, 9) * (w - 14), 12 + rng(i, 2, 10) * (h - 26), 3, 2, T("soil", 3))


def _crop_leafy(cv, w, h):
    for r in range(5):
        for c in range(7):
            x = 17 + c * ((w - 34) / 6.0) + (rng(r, c, 1) - 0.5) * 5
            y = 27 + r * ((h - 46) / 4.0) + (rng(r, c, 2) - 0.5) * 3
            r0 = 8 + rng(r, c, 3) * 4
            cv.ellipse(x, y + 4, r0, r0 * 0.62, T("leaf", 3))
            for k in range(6):
                a = -2.7 + k * 0.52
                cv.ellipse(x + math.cos(a) * r0 * 0.55, y + math.sin(a) * r0 * 0.4,
                           r0 * 0.6, r0 * 0.36, T("crop", 1))
            cv.ellipse(x - 1, y - 2, r0 * 0.34, r0 * 0.2, T("crop", 0))
            cv.px(x + 2, y + 2, T("crop", 2))


def _crop_scallion(cv, w, h):
    for r in range(5):
        for c in range(12):
            x = 14 + c * ((w - 28) / 11.0) + (rng(r, c, 4) - 0.5) * 3
            y = 26 + r * ((h - 46) / 4.0)
            hgt = 18 + rng(r, c, 5) * 9
            for k in (-1, 0, 1):
                cv.line(x + k * 1.7, y, x + k * 2.6, y - hgt, T("crop", 1 + (k == 0)), 1)
            cv.line(x, y - hgt + 2, x, y - hgt - 3, T("crop", 0))
            cv.px(x - 3, y + 1, T("crop", 2))


def _crop_sprout(cv, w, h):
    for r in range(6):
        for c in range(11):
            x = 15 + c * ((w - 30) / 10.0) + (rng(r, c, 6) - 0.5) * 4
            y = 24 + r * ((h - 44) / 5.0)
            cv.ellipse(x, y, 4, 2, T("crop", 1))
            cv.px(x - 3, y - 1, T("crop", 0))
            cv.px(x + 3, y - 1, T("crop", 0))
            cv.line(x, y + 1, x, y + 3, T("soil", 3))


def _crop_corn(cv, w, h):
    for r in range(4):
        for c in range(6):
            x = 19 + c * ((w - 38) / 5.0) + (rng(r, c, 7) - 0.5) * 4
            y = 32 + r * ((h - 56) / 3.0)
            hgt = 30 + rng(r, c, 8) * 8
            cv.line(x, y + 4, x, y - hgt, T("crop", 2), 1)
            for k in range(5):
                yy = y - 2 - k * 6
                cv.line(x, yy, x - 8, yy - 7, T("crop", 1))
                cv.line(x, yy, x + 8, yy - 7, T("crop", 1))
            cv.ellipse(x + 3, y - hgt + 7, 3, 7, T("crop_y", 1))
            cv.px(x + 2, y - hgt + 4, T("crop_y", 0))
            cv.line(x, y - hgt, x, y - hgt - 5, T("crop_y", 2))


def _crop_trellis(cv, w, h):
    for i in range(5):
        x = 22 + i * ((w - 44) / 4.0)
        cv.line(x, 26, x, h - 18, T("wood", 1), 2)
    for j in range(4):
        y = 34 + j * ((h - 50) / 3.0)
        cv.line(20, y, w - 20, y, T("wood", 2), 2)
    for r in range(5):
        for c in range(8):
            x = 18 + c * ((w - 36) / 7.0)
            y = 30 + r * ((h - 48) / 4.0) - 4
            cv.ellipse(x, y, 8, 5, T("crop", 1))
            cv.ellipse(x - 2, y - 2, 5, 3, T("crop", 0))
            cv.px(x + 3, y + 1, T("crop", 2))


def _crop_empty(cv, w, h):
    for y in range(26, h - 18, 8):
        cv.rect(14, y, w - 28, 3, T("soil", 1))
    for i in range(16):
        cv.px(16 + rng(i, 1, 11) * (w - 32), 28 + rng(i, 2, 12) * (h - 48), T("soil", 0))


def crops(stage):
    w, h = 160, 112
    cv = Canvas(w, h)
    _shadow_ellipse(cv, w // 2 + 6, h - 4, w // 2 - 6, 8)
    _plot_frame(cv, w, h)
    [_crop_sprout, _crop_leafy, _crop_scallion, _crop_corn, _crop_trellis, _crop_empty][stage % 6](cv, w, h)
    cv.out(T("ink", 0))
    return cv


# ---------------- 小道具 ----------------
def well():
    w, h = 140, 132
    cv = Canvas(w, h)
    _shadow_ellipse(cv, w // 2 + 8, h - 6, 56, 12)
    # 井台石圈
    cv.ellipse(w // 2, h - 26, 54, 24, T("stone", 3))
    cv.ellipse(w // 2, h - 30, 50, 21, T("stone", 2))
    for i in range(10):
        a = math.pi * 2 * i / 10
        cv.line(w // 2 + math.cos(a) * 50, h - 30 + math.sin(a) * 21,
                w // 2 + math.cos(a) * 50, h - 30 + math.sin(a) * 21 + 14, T("stone", 4))
    cv.ellipse(w // 2, h - 30, 44, 17, T("stone", 1))
    cv.ellipse(w // 2, h - 32, 38, 13, T("ink", 1))
    cv.ellipse(w // 2, h - 30, 36, 11, T("water", 2))
    cv.ellipse(w // 2 - 10, h - 32, 12, 4, T("water", 1))
    # 木架
    for s in (-1, 1):
        x = w // 2 + s * 44
        cv.rect(x - 5, 16, 10, h - 44, T("wood", 2))
        cv.rect(x - 5, 16, 3, h - 44, T("wood", 1))
        cv.rect(x - 5, 16, 10, 4, T("wood", 3))
    cv.rect(w // 2 - 52, 12, 104, 12, T("wood", 2))
    cv.rect(w // 2 - 52, 12, 104, 3, T("wood", 1))
    cv.rect(w // 2 - 52, 22, 104, 3, T("wood", 4))
    # 轱辘与绳
    cv.ellipse(w // 2, 30, 12, 10, T("wood", 2))
    cv.ellipse(w // 2, 30, 6, 5, T("wood", 4))
    cv.line(w // 2 + 10, 30, w // 2 + 10, 58, T("wood", 3))
    # 桶
    cv.rect(w // 2 + 2, 56, 20, 16, T("wood", 2))
    cv.rect(w // 2 + 2, 56, 20, 2, T("wood", 4))
    cv.rect(w // 2 + 2, 62, 20, 2, T("stone", 3))
    cv.out(T("ink", 0))
    return cv


def _jar(w, h, big=True):
    cv = Canvas(w, h)
    _shadow_ellipse(cv, w // 2 + 2, h - 5, w // 2 - 6, 7)
    body = T("red" if big else "wall", 1)
    cv.ellipse(w // 2, h - 20, w * 0.42, h * 0.34, T("ink", 0))
    cv.ellipse(w // 2, h - 21, w * 0.40, h * 0.32, body)
    cv.ellipse(w // 2 - w * 0.12, h - 28, w * 0.16, h * 0.16, T("red" if big else "wall", 0))
    cv.rect(w // 2 - w * 0.18, h - h * 0.72, w * 0.36, h * 0.18, body)
    cv.rect(w // 2 - w * 0.24, h - h * 0.76, w * 0.48, h * 0.10, T("red" if big else "wall", 2))
    cv.rect(w // 2 - w * 0.24, h - h * 0.76, w * 0.48, h * 0.04, T("red" if big else "wall", 1))
    cv.out(T("ink", 0))
    return cv


def jar_big():
    return _jar(56, 68, True)


def jar_small():
    return _jar(34, 42, False)


def woodpile():
    w, h = 96, 60
    cv = Canvas(w, h)
    _shadow_ellipse(cv, w // 2 + 4, h - 5, w // 2 - 8, 7)
    for r in range(3):
        for c in range(4):
            x = 14 + c * 20 + (r % 2) * 8
            y = h - 16 - r * 14
            cv.ellipse(x, y, 11, 7, T("wood", 3))
            cv.ellipse(x, y, 8, 5, T("wood", 1))
            cv.ellipse(x, y, 4, 2, T("wood", 2))
    cv.out(T("ink", 0))
    return cv


def rack():
    w, h = 130, 120
    cv = Canvas(w, h)
    _shadow_ellipse(cv, w // 2 + 4, h - 5, w // 2 - 10, 8)
    for s in (-1, 1):
        x = w // 2 + s * 46
        cv.rect(x - 4, 14, 8, h - 22, T("wood", 2))
        cv.rect(x - 4, 14, 3, h - 22, T("wood", 1))
    cv.rect(w // 2 - 52, 12, 104, 6, T("wood", 2))
    cv.rect(w // 2 - 52, 12, 104, 2, T("wood", 1))
    # 晾着的布
    cv.rect(w // 2 - 34, 18, 34, 56, T("plaster", 1))
    cv.rect(w // 2 - 34, 18, 34, 30, T("plaster", 0))
    for i in range(4):
        cv.rect(w // 2 - 34 + i * 9, 20, 2, 52, T("plaster", 2))
    # 挂辣椒
    for k in range(12):
        x = w // 2 + 6 + (k % 4) * 5
        y = 20 + k * 4
        cv.px(x, y, T("red", 0))
        cv.px(x, y + 1, T("red", 1))
    cv.out(T("ink", 0))
    return cv


def chicken(pose=0):
    w, h = 38, 34
    cv = Canvas(w, h)
    _shadow_ellipse(cv, w // 2 + 2, h - 4, 13, 4)
    body = (w // 2, h - 14)
    cv.ellipse(body[0], body[1], 12, 9, T("plaster", 0))
    cv.ellipse(body[0] - 2, body[1] - 2, 9, 6, T("plaster", 1))
    cv.ellipse(body[0] + 8, body[1] - 6, 6, 5, T("plaster", 0))
    cv.px(body[0] + 12, body[1] - 6, T("crop_y", 1))
    cv.px(body[0] + 13, body[1] - 6, T("crop_y", 1))
    cv.rect(body[0] + 8, body[1] - 12, 3, 3, T("red", 0))
    cv.px(body[0] + 11, body[1] - 7, T("ink", 0))
    for k in range(3):
        cv.line(body[0] - 4 + k * 3, body[1] + 8, body[0] - 4 + k * 3, h - 3, T("crop_y", 2))
    if pose == 1:
        cv.line(body[0] - 10, body[1] - 4, body[0] - 16, body[1] - 12, T("plaster", 1), 2)
    cv.out(T("ink", 0))
    return cv


def bucket():
    w, h = 30, 30
    cv = Canvas(w, h)
    _shadow_ellipse(cv, w // 2 + 2, h - 4, 10, 4)
    cv.rect(8, 10, 14, 16, T("wood", 2))
    cv.rect(8, 10, 14, 2, T("wood", 1))
    cv.rect(8, 14, 14, 2, T("stone", 2))
    cv.rect(8, 20, 14, 2, T("stone", 2))
    cv.ellipse(w // 2, 10, 8, 3, T("wood", 3))
    cv.out(T("ink", 0))
    return cv


def basket():
    w, h = 34, 28
    cv = Canvas(w, h)
    _shadow_ellipse(cv, w // 2 + 2, h - 4, 11, 4)
    cv.ellipse(w // 2, h - 12, 13, 8, T("straw", 1))
    cv.ellipse(w // 2, h - 14, 11, 5, T("straw", 2))
    for k in range(3):
        cv.line(6, h - 14 + k * 4, w - 6, h - 14 + k * 4, T("straw", 3))
    cv.ellipse(w // 2, h - 18, 6, 3, T("straw", 0))
    cv.out(T("ink", 0))
    return cv


def stool():
    w, h = 34, 32
    cv = Canvas(w, h)
    _shadow_ellipse(cv, w // 2 + 2, h - 4, 10, 4)
    cv.ellipse(w // 2, h - 20, 12, 5, T("wood", 2))
    cv.ellipse(w // 2, h - 21, 10, 4, T("wood", 1))
    for x in (w // 2 - 7, w // 2 + 7):
        cv.line(x, h - 20, x + (3 if x < w // 2 else -3), h - 6, T("wood", 3), 2)
    cv.out(T("ink", 0))
    return cv


def broom():
    w, h = 30, 66
    cv = Canvas(w, h)
    _shadow_ellipse(cv, w // 2 + 2, h - 4, 8, 4)
    cv.line(w // 2 + 4, 6, w // 2 - 2, h - 26, T("wood", 2), 3)
    for k in range(7):
        cv.line(w // 2 - 8 + k * 2.4, h - 28, w // 2 - 10 + k * 3.2, h - 4, T("straw", 2))
    cv.out(T("ink", 0))
    return cv


def hay():
    w, h = 76, 54
    cv = Canvas(w, h)
    _shadow_ellipse(cv, w // 2 + 6, h - 5, w // 2 - 8, 8)
    cv.ellipse(w // 2, h - 18, 32, 17, T("straw", 2))
    cv.ellipse(w // 2 - 4, h - 22, 26, 13, T("straw", 1))
    for k in range(10):
        cv.line(12 + k * 5, h - 10, 16 + k * 5, h - 30, T("straw", 3))
    cv.out(T("ink", 0))
    return cv


def crock():
    w, h = 32, 36
    cv = Canvas(w, h)
    _shadow_ellipse(cv, w // 2 + 2, h - 4, 9, 4)
    cv.ellipse(w // 2, h - 16, 11, 11, T("wall", 2))
    cv.rect(w // 2 - 6, h - 30, 12, 8, T("wall", 1))
    cv.rect(w // 2 - 8, h - 32, 16, 4, T("wall", 3))
    cv.out(T("ink", 0))
    return cv


def rock():
    w, h = 44, 30
    cv = Canvas(w, h)
    _shadow_ellipse(cv, w // 2 + 3, h - 4, 16, 5)
    cv.poly([(6, h - 6), (10, 12), (24, 6), (38, 14), (36, h - 6)], T("stone", 3))
    cv.poly([(10, 12), (24, 6), (30, 14), (16, 18)], T("stone", 1))
    cv.poly([(24, 6), (38, 14), (34, 18), (30, 14)], T("stone", 2))
    cv.out(T("ink", 0))
    return cv


def crate():
    w, h = 48, 44
    cv = Canvas(w, h)
    _shadow_ellipse(cv, w // 2 + 3, h - 4, 16, 5)
    cv.rect(6, 10, 36, 28, T("wood", 2))
    cv.rect(6, 10, 36, 3, T("wood", 1))
    cv.rect(6, 10, 3, 28, T("wood", 1))
    cv.rect(39, 10, 3, 28, T("wood", 4))
    cv.line(8, 12, 40, 36, T("wood", 3), 2)
    cv.line(40, 12, 8, 36, T("wood", 3), 2)
    cv.out(T("ink", 0))
    return cv


def bush():
    w, h = 96, 78
    cv = Canvas(w, h)
    _shadow_ellipse(cv, w // 2 + 6, h - 5, 32, 8)
    _canopy(cv, w // 2, h - 30, 40, 28, 71)
    _canopy(cv, w // 2 - 22, h - 24, 24, 18, 72)
    _canopy(cv, w // 2 + 22, h - 26, 24, 18, 73)
    cv.out(T("ink", 0))
    return cv


def cat():
    w, h = 36, 30
    cv = Canvas(w, h)
    _shadow_ellipse(cv, w // 2 + 2, h - 4, 11, 4)
    cv.ellipse(w // 2, h - 10, 16, 8, T("wall", 2))
    cv.ellipse(w // 2 - 14, h - 18, 8, 8, T("wall", 2))
    cv.poly([(w // 2 - 20, h - 26), (w // 2 - 16, h - 18), (w // 2 - 12, h - 24)], T("wall", 2))
    cv.poly([(w // 2 - 8, h - 26), (w // 2 - 4, h - 18), (w // 2, h - 24)], T("wall", 2))
    cv.line(w // 2 + 16, h - 14, w // 2 + 22, h - 24, T("wall", 3), 2)
    cv.out(T("ink", 0))
    return cv


DRAWERS = {
    "well": well, "jar_big": jar_big, "jar_small": jar_small, "woodpile": woodpile,
    "rack": rack, "chicken_a": lambda: chicken(0), "chicken_b": lambda: chicken(1),
    "bucket": bucket, "basket": basket, "stool": stool, "broom": broom, "hay": hay,
    "crock": crock, "rock": rock, "crate": crate, "bush": bush, "cat": cat,
}

PROP_NAMES = list(DRAWERS.keys())


def prop(name):
    return DRAWERS[name]()
