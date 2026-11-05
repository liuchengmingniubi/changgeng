"""地面层：黄土坡地 + 踩实的院子 + 踏石小路 + 村道 + 阴影与细节。

做法：
1. 先用 numpy 生成"材质图"与"明暗图"，明暗是连续量；
2. 阴影不是 alpha 叠加，而是把明暗档位往下压，于是阴影永远是同族更暗的色，
   不会出现半透明像素；
3. 最后用 4x4 有序抖动把档位之间的台阶揉开，模拟参考图那种柔和的过渡；
4. 细节（踏石、碎石、草簇、裂纹、秸秆）用 PIL 画在色块之上。
"""
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

from . import yard_layout as L
from .canvas import Canvas
from .scene_palette import RAMPS, T, rng

GRASS, YARD, LOESS, ROAD, SOIL = 0, 1, 2, 3, 4
MAT_NAME = {GRASS: "grass", YARD: "yard", LOESS: "loess", ROAD: "road", SOIL: "soil"}
MAX_LV = max(len(RAMPS[n]) for n in MAT_NAME.values())

BAYER4 = np.array([[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]], np.float32) / 16.0


def _noise(h, w, cell, seed):
    small = np.random.default_rng(seed).random((max(2, h // cell), max(2, w // cell))).astype(np.float32)
    im = Image.fromarray((small * 255).astype(np.uint8)).resize((w, h), Image.BICUBIC)
    a = np.asarray(im, np.float32) / 255.0
    lo, hi = float(a.min()), float(a.max())
    return (a - lo) / max(1e-5, hi - lo)


def _poly_mask(points, blur=10):
    m = Image.new("L", (L.W, L.H), 0)
    ImageDraw.Draw(m).polygon(points, fill=255)
    return np.asarray(m.filter(ImageFilter.GaussianBlur(blur)), np.float32) / 255.0


def _shape_mask(w, h, draw_fn, blur):
    m = Image.new("L", (w, h), 0)
    draw_fn(ImageDraw.Draw(m))
    return np.asarray(m.filter(ImageFilter.GaussianBlur(blur)), np.float32) / 255.0


class Ground:
    def __init__(self):
        self.w, self.h = L.W, L.H
        self.mat = np.full((self.h, self.w), LOESS, np.int8)
        self.lv = np.full((self.h, self.w), 2.0, np.float32)
        self.shadow = np.zeros((self.h, self.w), np.float32)
        self._regions()
        self._light()
        self._bake()

    # ---------------- 材质区域 ----------------
    def _regions(self):
        h, w = self.h, self.w
        yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)

        # 院子：多边形 + 毛边
        yard = _poly_mask(L.YARD, 14)
        yard_noise = _noise(h, w, 26, 11)
        yard_m = np.clip((yard - 0.42) * 3.0 + (yard_noise - 0.5) * 1.4, 0, 1)
        self.mat = np.where(yard_m > 0.5, YARD, self.mat).astype(np.int8)
        self.yard_m = yard_m

        # 村道：底部横带，上缘毛糙
        road_top = L.ROAD_Y[0] + (yard_noise - 0.5) * 26
        road_m = np.clip((yy - road_top) / 10.0, 0, 1)
        self.mat = np.where(road_m > 0.5, ROAD, self.mat).astype(np.int8)
        self.road_m = road_m

        # 草：大块噪声成滩，院子里几乎不长
        g = _noise(h, w, 70, 3) * 0.62 + _noise(h, w, 18, 4) * 0.38
        g_thr = 0.795 + (yy / h) * 0.05
        grass_m = np.clip((g - g_thr) * 13.0, 0, 1) * (1.0 - np.clip(yard_m * 1.45, 0, 1))
        self.mat = np.where(grass_m > 0.5, GRASS, self.mat).astype(np.int8)
        self.grass_m = grass_m

        # 踩出来的土：门口、院门内侧、水井边，颜色更浅更实
        worn = np.zeros((h, w), np.float32)
        for (cx, cy, rx, ry) in ((400, 500, 150, 54), (600, 660, 120, 44), (210, 570, 90, 40)):
            m = _shape_mask(w, h, lambda d, cx=cx, cy=cy, rx=rx, ry=ry:
                             d.ellipse([cx - rx, cy - ry, cx + rx, cy + ry], fill=255), 18)
            worn = np.maximum(worn, m)
        worn = np.clip(worn * 1.2 + (yard_noise - 0.5) * 0.5, 0, 1)
        self.mat = np.where(worn > 0.55, YARD, self.mat).astype(np.int8)
        self.yard_m = np.maximum(self.yard_m, worn)

    # ---------------- 明暗 ----------------
    def _light(self):
        h, w = self.h, self.w
        base = _noise(h, w, 120, 21) * 1.1 + _noise(h, w, 34, 22) * 0.55
        self.lv = self.lv + (base - 0.78) * 0.9

        yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
        sh = np.zeros((h, w), np.float32)

        def blob(cx, cy, rx, ry, strength, blur=16, dx=0, dy=0):
            nonlocal sh
            m = _shape_mask(w, h, lambda d: d.ellipse(
                [cx - rx + dx, cy - ry + dy, cx + rx + dx, cy + ry + dy], fill=255), blur)
            sh = np.maximum(sh, m * strength)

        # 房屋：从墙脚往右下拖一大片，房檐下再压一圈
        hx, hy = L.HOUSE
        blob(hx + 170, hy + 40, 460, 96, 0.92, 30, dx=80, dy=24)
        blob(hx + 120, hy - 150, 380, 70, 0.34, 24, dx=60, dy=140)

        # 院墙脚：院子的边缘压一道暗，院子才“围”得起来
        sh = np.maximum(sh, np.clip(self.yard_m * (1.0 - self.yard_m) * 5.2, 0, 1) * 0.42)

        # 树
        for (tx, ty, kind) in L.TREES:
            r = 96 if kind == "big" else 62
            blob(tx + 26, ty - 6, r, r * 0.42, 0.55, 22, dx=34, dy=26)

        # 菜畦：每块南侧一条软影
        for (px, py) in L.PLOTS:
            blob(px + L.PLOT_W / 2 + 10, py + L.PLOT_H + 6, L.PLOT_W * 0.62, 16, 0.5, 14)

        # 栅栏：一条窄影
        for (x0, x1) in L.FENCE_SEGMENTS:
            blob((x0 + x1) / 2 + 6, L.FENCE_Y + 12, (x1 - x0) / 2, 14, 0.55, 8)

        # 水井与杂物
        for (name, x, y) in L.PROPS:
            r = 30 if name in ("well", "hay") else 14
            blob(x + 4, y + 2, r, r * 0.45, 0.45, 10)

        self.shadow = np.clip(sh, 0, 1)
        self.lv = self.lv + self.shadow * 2.4

    # ---------------- 上色 ----------------
    def _bake(self):
        h, w = self.h, self.w
        yy, xx = np.mgrid[0:h, 0:w]
        dith = (BAYER4[yy % 4, xx % 4] - 0.5) * 1.05

        # 让草地/黄土的交界带一点草根色
        lv = self.lv + dith
        lut = np.zeros((len(MAT_NAME), MAX_LV, 3), np.uint8)
        for mi, name in MAT_NAME.items():
            ramp = RAMPS[name]
            for i in range(MAX_LV):
                lut[mi, i] = T(name, min(i, len(ramp) - 1))[:3]

        idx = np.clip(np.rint(lv), 0, MAX_LV - 1).astype(np.int16)
        # 草比黄土再提亮半档，免得绿块发闷
        idx = np.where(self.mat == GRASS, np.clip(idx - 1, 0, MAX_LV - 1), idx).astype(np.int16)
        # 院土是踩实的干土，比坡地再亮一点
        idx = np.where(self.mat == YARD, np.clip(idx - 1, 0, MAX_LV - 1), idx).astype(np.int16)
        rgb = lut[self.mat.astype(np.int16), idx]
        self.img = Image.fromarray(rgb, "RGB").convert("RGBA")
        self.cv = Canvas(w, h)
        self.cv.img = self.img
        self.cv.d = ImageDraw.Draw(self.img)
        self._details()

    # ---------------- 细节 ----------------
    def _details(self):
        cv = self.cv
        self._flagstones(cv)
        self._speckles(cv)
        self._cracks(cv)
        self._tufts(cv, 210, 31)
        self._tufts(cv, 90, 32, dry=True)
        self._edge_tufts(cv)
        self._pebbles(cv, 130)
        self._flowers(cv, 26)
        cv.img = cv.img.convert("RGBA")

    def _flagstones(self, cv):
        """沿小路铺不规则的踏石。"""
        pts = L.PATH
        total = 0.0
        segs = []
        for i in range(len(pts) - 1):
            ax, ay = pts[i]
            bx, by = pts[i + 1]
            d = ((bx - ax) ** 2 + (by - ay) ** 2) ** 0.5
            segs.append((ax, ay, bx, by, d))
            total += d
        step = 46.0
        dist = 0.0
        t = 0.0
        i = 0
        n = 0
        while t <= total:
            while i < len(segs) - 1 and t > dist + segs[i][4]:
                dist += segs[i][4]
                i += 1
            ax, ay, bx, by, d = segs[i]
            u = (t - dist) / max(1e-3, d)
            cx = ax + (bx - ax) * u + (rng(n, 7, 1) - 0.5) * 26
            cy = ay + (by - ay) * u + (rng(n, 8, 2) - 0.5) * 12
            self._stone(cv, cx, cy, 21 + rng(n, 9, 3) * 9, 12 + rng(n, 10, 4) * 6, n)
            n += 1
            t += step + rng(n, 11, 5) * 14

    def _stone(self, cv, cx, cy, rx, ry, seed):
        pts = []
        k = 9
        for i in range(k):
            a = 6.28318 * i / k
            j = 0.78 + rng(int(cx) + i, int(cy), seed) * 0.32
            pts.append((cx + np.cos(a) * rx * j, cy + np.sin(a) * ry * j))
        cv.poly([(px, py + 3) for (px, py) in pts], T("stone", 4))
        cv.poly(pts, T("stone", 2))
        top = [(cx + (px - cx) * 0.74, cy - 2 + (py - cy) * 0.62) for (px, py) in pts]
        cv.poly(top, T("stone", 1))
        cv.poly([(cx + (px - cx) * 0.42, cy - 3 + (py - cy) * 0.36) for (px, py) in pts], T("stone", 0))

    def _speckles(self, cv):
        """黄土上的碎土粒、草屑。"""
        for y in range(0, self.h, 3):
            for x in range(0, self.w, 3):
                if rng(x, y, 12) > 0.955:
                    lv = int(self.lv[y, x])
                    cv.px(x, y, T("loess", lv + 2))

    def _cracks(self, cv):
        for i in range(120):
            x = rng(i, 1, 21) * self.w
            y = rng(i, 2, 22) * self.h
            if y < 430:
                continue
            ln = 3 + rng(i, 3, 23) * 6
            cv.line(x, y, x + ln, y + rng(i, 4, 24) * 3, T("loess", 5))

    def _tufts(self, cv, clusters, seed, dry=False):
        for c in range(clusters):
            x = rng(c, 1, seed) * self.w
            y = 120 + rng(c, 2, seed) * (self.h - 150)
            if self.yard_m[int(y), int(x)] > 0.6 and rng(c, 3, seed) > 0.25:
                continue
            n = 3 + int(rng(c, 4, seed) * 5)
            base = "grass"
            for i in range(n):
                bx = x + (rng(c, 10 + i, seed) - 0.5) * 14
                hgt = 5 + rng(c, 20 + i, seed) * 9
                lean = (rng(c, 30 + i, seed) - 0.5) * 5
                lv = 1 + int(rng(c, 40 + i, seed) * 2)
                cv.line(bx, y, bx + lean, y - hgt, T(base, lv))
                cv.px(bx, y + 1, T("loess", 4))

    def _edge_tufts(self, cv):
        """栅栏脚下、墙根、院边这些地方草最密，参考图也是这么长的。"""
        spots = []
        for x in range(30, self.w, 17):
            spots.append((x + rng(x, 1, 61) * 12, L.FENCE_Y - 2 + rng(x, 2, 62) * 10))
        for x in range(60, 780, 23):
            spots.append((x + rng(x, 3, 63) * 14, 452 + rng(x, 4, 64) * 12))
        for x in range(0, self.w, 41):
            spots.append((x + rng(x, 5, 65) * 20, self.h - 12 - rng(x, 6, 66) * 16))
        for (x, y) in spots:
            n = 4 + int(rng(int(x), int(y), 67) * 5)
            for i in range(n):
                bx = x + (rng(int(x), i, 68) - 0.5) * 16
                hgt = 6 + rng(int(x), i, 69) * 11
                lean = (rng(int(x), i, 70) - 0.5) * 6
                cv.line(bx, y, bx + lean, y - hgt, T("grass", 1 + (i % 2)))
            cv.px(x, y + 1, T("loess", 4))

    def _pebbles(self, cv, n):
        for i in range(n):
            x = rng(i, 1, 41) * self.w
            y = 120 + rng(i, 2, 42) * (self.h - 130)
            r = 2 + rng(i, 3, 43) * 3
            cv.ellipse(x, y + 1, r, r * 0.7, T("stone", 4))
            cv.ellipse(x, y, r, r * 0.7, T("stone", 2))
            cv.px(x - r * 0.4, y - r * 0.4, T("stone", 1))

    def _flowers(self, cv, n):
        for i in range(n):
            x = rng(i, 1, 51) * self.w
            y = 140 + rng(i, 2, 52) * (self.h - 170)
            if self.yard_m[int(y), int(x)] > 0.6:
                continue
            cv.px(x, y, T("red", 0))
            cv.px(x + 1, y, T("red", 1))
            cv.px(x, y + 1, T("grass", 3))

    def image(self):
        return self.cv.img.convert("RGB").convert("RGBA")

    def bake(self):
        return self.image()
