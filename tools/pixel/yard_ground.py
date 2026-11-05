"""地面层绘制：草地、院子泥地、小路、村道、农田、接触阴影、村口树线。

整屏 1280x800 一次性画成一张背景图。凡是"贴地"的东西（阴影、土色渐变、
车辙、脚印）都烘进这一层；立体物件画成独立精灵，由 Godot 场景按 y 排序绘制。
"""
import numpy as np
from PIL import Image, ImageDraw

from . import yard_layout as L
from .scene_palette import PALETTE, c

GRASS, DIRT, SOIL, ROAD = 0, 1, 2, 3


def _field(h, w, block, seed):
    rng = np.random.default_rng(seed)
    gh, gw = h // block + 2, w // block + 2
    g = rng.random((gh, gw))
    return np.kron(g, np.ones((block, block)))[:h, :w]


def _noise(h, w, seed):
    a = _field(h, w, 6, seed)
    b = _field(h, w, 17, seed + 7)
    d = _field(h, w, 1, seed + 13)
    return (a * 0.55 + b * 0.33 + d * 0.12)


class Ground:
    def __init__(self):
        self.h, self.w = L.H, L.W
        self.rgb = np.zeros((self.h, self.w, 3), np.uint8)
        self.kind = np.zeros((self.h, self.w), np.uint8)

    # ---------- 基础 ----------
    def fill(self, mask, color):
        self.rgb[mask] = np.array(c(color)[:3], np.uint8)

    def poly_mask(self, pts):
        img = Image.new("L", (self.w, self.h), 0)
        ImageDraw.Draw(img).polygon([(int(x), int(y)) for x, y in pts], fill=255)
        return np.array(img) > 0

    def ragged(self, mask, grow=2, seed=3):
        """给硬边多边形加毛边：边界像素随机吃掉/长出 1-2 像素。"""
        r = _field(self.h, self.w, 1, seed)
        m = mask.copy()
        for _ in range(grow):
            nb = np.zeros_like(m)
            nb[1:, :] |= m[:-1, :]
            nb[:-1, :] |= m[1:, :]
            nb[:, 1:] |= m[:, :-1]
            nb[:, :-1] |= m[:, 1:]
            grow_to = (~m) & nb & (r > 0.42)
            m |= grow_to
        return m

    # ---------- 草地 ----------
    def grass(self):
        n = _noise(self.h, self.w, 11)
        self.fill(np.ones_like(self.kind, bool), "grass")
        self.fill(n > 0.58, "grass_lt")
        self.fill(n > 0.80, "grass_hi")
        self.fill(n < 0.24, "grass_dk")
        self.tufts(1200, "grass_lt", "grass_hi")
        self.tufts(500, "grass_dk", "grass_lt")

    def tufts(self, count, dark, lit, area=None):
        rng = np.random.default_rng(count)
        for _ in range(count):
            x = int(rng.integers(2, self.w - 3))
            y = int(rng.integers(2, self.h - 3))
            if area is not None and not area[y, x]:
                continue
            if self.kind[y, x] != GRASS:
                continue
            ln = int(rng.integers(2, 5))
            for i in range(ln):
                xx = x + (1 if i >= ln - 2 else 0)
                yy = y - i
                if 0 <= yy < self.h:
                    self.rgb[yy, xx] = np.array(c(lit if i >= ln - 2 else dark)[:3], np.uint8)
            if rng.random() < 0.35:
                self.rgb[y, x - 1] = np.array(c(dark)[:3], np.uint8)

    def flowers(self, count=140):
        rng = np.random.default_rng(count + 5)
        for _ in range(count):
            x = int(rng.integers(2, self.w - 2))
            y = int(rng.integers(2, self.h - 2))
            if self.kind[y, x] != GRASS or not self.rgb[y, x, 1] > 60:
                continue
            col = "cream" if rng.random() < 0.55 else "gold_lit"
            if rng.random() < 0.3:
                col = "cloth_red_lt"
            self.rgb[y, x] = np.array(c(col)[:3], np.uint8)

    # ---------- 院子 / 路 / 田 ----------
    def yard(self):
        m = self.ragged(self.poly_mask(L.YARD), 3, 21)
        self.kind[m] = DIRT
        n = _noise(self.h, self.w, 31)
        self.fill(m, "dirt")
        self.fill(m & (n > 0.56), "dirt_lt")
        self.fill(m & (n > 0.80), "dirt_hi")
        self.fill(m & (n < 0.26), "dirt_dk")
        # 草籽、碎秸、脚印
        rng = np.random.default_rng(77)
        for _ in range(700):
            x, y = int(rng.integers(0, self.w)), int(rng.integers(0, self.h))
            if self.kind[y, x] != DIRT:
                continue
            r = rng.random()
            if r < 0.45:
                self.rgb[y, x] = np.array(c("straw")[:3], np.uint8)
            elif r < 0.7:
                self.rgb[y, x] = np.array(c("dirt_dk")[:3], np.uint8)
            else:
                self.rgb[y, x] = np.array(c("stone_dk")[:3], np.uint8)

    def path(self):
        pts = L.PATH + L.PATH_TO_ROAD
        img = Image.new("L", (self.w, self.h), 0)
        d = ImageDraw.Draw(img)
        d.line([(int(x), int(y)) for x, y in pts], fill=255, width=44, joint="curve")
        m = self.ragged(np.array(img) > 0, 2, 41)
        self.kind[m] = DIRT
        self.fill(m, "dirt_lt")
        n = _noise(self.h, self.w, 43)
        self.fill(m & (n > 0.62), "dirt_hi")
        self.fill(m & (n < 0.3), "dirt")
        # 踏石
        for (sx, sy) in [(352, 546), (392, 580), (446, 604), (512, 626), (578, 644)]:
            self.stone(sx, sy, 13, 8, "stone")

    def stone(self, cx, cy, rx, ry, base, lit="stone_lt", dark="stone_dk"):
        img = Image.new("L", (self.w, self.h), 0)
        ImageDraw.Draw(img).ellipse([cx - rx, cy - ry, cx + rx, cy + ry], fill=255)
        m = np.array(img) > 0
        self.fill(m, base)
        top = np.roll(m, -1, axis=0) & m
        self.fill(top, lit)
        bot = np.roll(m, 1, axis=0) & m
        self.fill(bot & ~top, dark)

    def road(self):
        y0, y1 = L.ROAD_Y
        m = np.zeros((self.h, self.w), bool)
        m[y0:y1, :] = True
        edge = _field(self.h, self.w, 1, 55)
        m &= (~(edge > 0.86)) | (np.arange(self.h)[:, None] < y0 + 2) | (np.arange(self.h)[:, None] > y1 - 2)
        spur = np.zeros_like(m)
        x0, x1 = L.ROAD_SPUR_X
        spur[y0 - 76:y1, x0:x1] = True
        m |= spur
        m = self.ragged(m, 2, 57)
        self.kind[m] = ROAD
        self.fill(m, "dirt")
        n = _noise(self.h, self.w, 59)
        self.fill(m & (n > 0.5), "dirt_lt")
        self.fill(m & (n < 0.3), "dirt_dk")
        # 车辙
        for yy in (y0 + 22, y0 + 46):
            self.rgb[yy:yy + 2, 40:self.w - 40] = np.array(c("dirt_dk")[:3], np.uint8)
        # 碎石
        rng = np.random.default_rng(88)
        for _ in range(260):
            x, y = int(rng.integers(0, self.w)), int(rng.integers(y0 - 4, y1))
            if 0 <= y < self.h and self.kind[y, x] == ROAD:
                self.rgb[y, x] = np.array(c("stone" if rng.random() < 0.5 else "dirt_hi")[:3], np.uint8)

    def plots(self):
        for (x, y) in L.PLOTS:
            w, h = L.PLOT_W, L.PLOT_H
            m = np.zeros((self.h, self.w), bool)
            m[y:y + h, x:x + w] = True
            m = self.ragged(m, 1, x + y)
            self.kind[m] = SOIL
            self.fill(m, "soil")
            # 垄沟：横向 8 像素一条
            for row in range(4, h - 4, 9):
                self.rgb[y + row:y + row + 2, x + 3:x + w - 3] = np.array(c("soil_dk")[:3], np.uint8)
                self.rgb[y + row + 2:y + row + 4, x + 3:x + w - 3] = np.array(c("soil_lt")[:3], np.uint8)
            # 田埂
            self.rgb[y:y + 2, x:x + w] = np.array(c("dirt_lt")[:3], np.uint8)
            self.rgb[y + h - 2:y + h, x:x + w] = np.array(c("dirt_dk")[:3], np.uint8)
            self.rgb[y:y + h, x:x + 2] = np.array(c("dirt_lt")[:3], np.uint8)
            self.rgb[y:y + h, x + w - 2:x + w] = np.array(c("dirt_dk")[:3], np.uint8)

    # ---------- 阴影 ----------
    def _shade(self, m, strength=1):
        """在任意底面上压暗：草地压绿、泥地压褐，避免灰影发脏。"""
        dark = np.zeros_like(self.rgb)
        dark[self.kind == GRASS] = np.array(c("grass_dk")[:3], np.uint8)
        dark[self.kind == DIRT] = np.array(c("dirt_dk")[:3], np.uint8)
        dark[self.kind == SOIL] = np.array(c("soil_dk")[:3], np.uint8)
        dark[self.kind == ROAD] = np.array(c("dirt_dk")[:3], np.uint8)
        self.rgb[m] = dark[m]

    def shadow_ellipse(self, cx, cy, rx, ry):
        img = Image.new("L", (self.w, self.h), 0)
        ImageDraw.Draw(img).ellipse([cx - rx, cy - ry, cx + rx, cy + ry], fill=255)
        self._shade(np.array(img) > 0)

    def shadow_rect(self, x, y, w, h):
        m = np.zeros((self.h, self.w), bool)
        m[max(0, y):y + h, max(0, x):x + w] = True
        self._shade(m)

    # ---------- 边框树线 ----------
    def treeline(self):
        n = _noise(self.h, self.w, 71)
        ys = np.arange(self.h)[:, None]
        top = 26 + (n * 26).astype(np.int32)
        m = ys < top
        self.kind[m] = GRASS
        self.fill(m, "leaf_dk")
        self.fill(m & (n > 0.62), "leaf")
        self.fill(m & (n > 0.86), "leaf_lt")

    def bake(self):
        self.grass()
        self.treeline()
        self.yard()
        self.path()
        self.road()
        self.plots()
        self.flowers()
        # 接触阴影：先房子，再树，最后小物件
        hx, hy = L.HOUSE
        hw, hh = L.HOUSE_SIZE
        self.shadow_rect(hx - hw // 2 + 10, hy - 10, hw - 20, 16)
        self.shadow_ellipse(hx, hy - 2, hw // 2 - 6, 12)
        for (tx, ty, kind) in L.TREES:
            rx = 56 if kind == "big" else 38
            self.shadow_ellipse(tx + 18, ty - 6, rx, int(rx * 0.42))
        for (x0, x1) in L.FENCE_SEGMENTS:
            self.shadow_rect(x0, L.FENCE_Y - 4, x1 - x0, 8)
        for (name, x, y) in L.PROPS:
            self.shadow_ellipse(x + 2, y, 12 if name.startswith("chicken") else 9, 4)
        img = Image.fromarray(np.dstack([self.rgb, np.full((self.h, self.w), 255, np.uint8)]), "RGBA")
        return img