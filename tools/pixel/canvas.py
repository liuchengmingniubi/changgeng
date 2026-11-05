"""硬边像素画布。

原则：
1. 所有坐标取整，绝不使用抗锯齿；
2. 只允许调色板内的颜色；
3. 形状画完统一做一次 1 像素描边，保证轮廓干净；
4. 光是"顶部/左侧亮、底部/右侧暗"的两档平涂，不做渐变。
"""
from PIL import Image, ImageDraw

from .palette import ascii_lookup
from .scene_palette import c as _color


def rgba(color):
    return _color(color) if isinstance(color, str) else color


class Canvas:
    def __init__(self, w, h):
        self.w, self.h = w, h
        self.img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        self.d = ImageDraw.Draw(self.img)

    # ---------- 基础绘制 ----------
    def px(self, x, y, color):
        x, y = int(round(x)), int(round(y))
        if 0 <= x < self.w and 0 <= y < self.h:
            self.img.putpixel((x, y), rgba(color) if isinstance(color, str) else color)

    def rect(self, x, y, w, h, color):
        x, y, w, h = int(round(x)), int(round(y)), int(round(w)), int(round(h))
        if w <= 0 or h <= 0:
            return
        if isinstance(color, tuple) and len(color) == 4 and color[3] == 0:
            self.d.rectangle([x, y, x + w - 1, y + h - 1], fill=None)
            for yy in range(y, y + h):
                for xx in range(x, x + w):
                    if 0 <= xx < self.w and 0 <= yy < self.h:
                        self.img.putpixel((xx, yy), (0, 0, 0, 0))
            return
        self.d.rectangle([x, y, x + w - 1, y + h - 1], fill=rgba(color))

    def line(self, x0, y0, x1, y1, color, width=1):
        self.d.line([int(round(x0)), int(round(y0)), int(round(x1)), int(round(y1))],
                    fill=rgba(color), width=int(width))

    def poly(self, points, color):
        self.d.polygon([(int(round(px)), int(round(py))) for px, py in points], fill=rgba(color))

    def ellipse(self, cx, cy, rx, ry, color):
        self.d.ellipse([int(cx - rx), int(cy - ry), int(cx + rx), int(cy + ry)], fill=rgba(color))

    # ---------- 上色辅助 ----------
    def box(self, x, y, w, h, base, lit=None, dark=None, lit_rows=1, lit_cols=1):
        """平涂 + 顶/左亮、底/右暗，形成最朴素的体积感。"""
        self.rect(x, y, w, h, base)
        if lit:
            if lit_rows:
                self.rect(x, y, w, lit_rows, lit)
            if lit_cols:
                self.rect(x, y, lit_cols, h, lit)
        if dark:
            self.rect(x, y + h - 1, w, 1, dark)
            self.rect(x + w - 1, y, 1, h, dark)

    def limb(self, a, b, width, color):
        """两段式肢体：粗细固定，端点取整，避免糊边。"""
        self.line(a[0], a[1], b[0], b[1], color, width)

    def carve(self, x, y, w, h):
        """挖成透明，用来削圆角。"""
        self.rect(x, y, w, h, (0, 0, 0, 0))

    def out(self, color="ink", only_empty=True):
        """1 像素外描边。"""
        src = self.img
        px = src.load()
        c = rgba(color)
        w, h = self.w, self.h
        marks = []
        for y in range(h):
            for x in range(w):
                if px[x, y][3] != 0:
                    continue
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < w and 0 <= ny < h and px[nx, ny][3] != 0:
                        marks.append((x, y))
                        break
        for x, y in marks:
            px[x, y] = c

    def paste(self, other, ox=0, oy=0, flip_x=False):
        img = other.img.transpose(Image.FLIP_LEFT_RIGHT) if flip_x else other.img
        self.img.alpha_composite(img, (int(ox), int(oy)))
        self.d = ImageDraw.Draw(self.img)

    def flipped(self):
        out = Canvas(self.w, self.h)
        out.img = self.img.transpose(Image.FLIP_LEFT_RIGHT)
        out.d = ImageDraw.Draw(out.img)
        return out

    # ---------- 检查 ----------
    def ascii(self):
        table = ascii_lookup()
        rows = []
        for y in range(self.h):
            row = "".join(table.get(self.img.getpixel((x, y)), "?") for x in range(self.w))
            rows.append(row.rstrip())
        return "\n".join(rows).rstrip()

    def used_rect(self):
        return self.img.getbbox()