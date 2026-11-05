"""把用户提供的六张 PNG 拼成「主角家室内」一屏。

原则：**不重画素材**，只做裁切、缩放（面积平均）、限色、二值化 alpha，
再按下面的 LAYOUT 摆到 1280x800 的室内里。改坐标/尺寸后重跑即可。

    python -m tools.build_interior
"""

from __future__ import annotations

import json
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "assets" / "art" / "home_interior" / "source"
OUT = ROOT / "assets" / "art" / "home_interior"
PREV = ROOT / "previews" / "home_interior"

W, H = 1280, 800
WALL_H = 344          # 后墙（檐枋 + 窗 + 石脚）占的高度
FLOOR_TOP = WALL_H

# (贴图名, 尺寸, 底部中心 x, 底部中心 y, 碰撞footprint[dx0, dy0, w, h] 相对底部中心)
LAYOUT = [
    ("bed",   (72, 152), 204, 552, (-36, -112, 72, 112)),
    ("desk",  (156, 108), 596, 512, (-78, -28, 156, 28)),
    ("chest", (90, 70), 360, 664, (-45, -18, 90, 18)),
    ("stove", (180, 98), 1012, 566, (-90, -22, 180, 22)),
]
STEPS = ("steps", (330, 97), 640, 800)


def _crop_alpha(img: Image.Image) -> Image.Image:
    """按 alpha 通道裁边。

    注意：PIL 的 getbbox() 会把 alpha=0 但 RGB 非零的像素也算成内容，
    这几张源图透明区域里都有残留 RGB，所以必须只用 alpha 通道求 bbox。
    """
    a = img.convert("RGBA")
    box = a.getchannel("A").getbbox()
    return a.crop(box) if box else a


def shrink(img: Image.Image, size: tuple[int, int], colors: int = 40, opaque: bool = False,
           bg: tuple[int, int, int] = (58, 40, 26), inset: int = 0) -> Image.Image:
    """裁到不透明内容的边界 → 面积平均缩放 → 限色 → 二值 alpha。

    源图有三层边界要处理：alpha>0 的羽化光晕（几十像素宽）、半透明过渡、
    以及透明区域里残留的 RGB。先按 alpha>=128 二值化再求 bbox，才能裁到真正的轮廓；
    否则缩放后四周会留一圈背景色的脏边。
    """
    a = img.convert("RGBA")
    mask = a.getchannel("A").point(lambda v: 255 if v >= 128 else 0)
    box = mask.getbbox()
    if box:
        a = a.crop(box)
        mask = mask.crop(box)
    if inset > 0 and a.width > inset * 3 and a.height > inset * 3:
        a = a.crop((inset, inset, a.width - inset, a.height - inset))
        mask = mask.crop((inset, inset, mask.width - inset, mask.height - inset))
    small = a.resize(size, Image.BOX)
    if opaque:
        flat = Image.new("RGBA", small.size, bg + (255,))
        flat.alpha_composite(small)
        small = flat
    rgb = small.convert("RGB").quantize(colors=colors, method=Image.MEDIANCUT, dither=Image.NONE)
    out = rgb.convert("RGBA")
    if opaque:
        out.putalpha(255)
    else:
        alpha = mask.resize(size, Image.BOX).point(lambda v: 255 if v >= 128 else 0)
        alpha = alpha.filter(ImageFilter.MinFilter(3))
        out.putalpha(alpha)
    return out


def _shadow(ground: Image.Image, cx: int, bottom: int, rx: int, ry: int, alpha: int = 90) -> None:
    layer = Image.new("RGBA", (rx * 2 + 10, ry * 2 + 10), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    d.ellipse([4, 4, rx * 2 + 5, ry * 2 + 5], fill=(28, 16, 8, alpha))
    layer = layer.filter(ImageFilter.GaussianBlur(3))
    ground.alpha_composite(layer, (cx - rx - 5, bottom - ry - 5))


def build() -> dict:
    OUT.mkdir(parents=True, exist_ok=True)
    PREV.mkdir(parents=True, exist_ok=True)

    shell = _crop_alpha(Image.open(SRC / "shell.png"))
    floor_src = _crop_alpha(Image.open(SRC / "floor.png"))

    # 后墙：取墙 + 檐枋 + 石脚这一横条，铺满 1280 宽
    wall_box = shell.crop((6, 6, shell.width - 6, 465))
    wall = wall_box.resize((W, WALL_H), Image.LANCZOS)
    wall = wall.convert("RGB").quantize(colors=56, method=Image.MEDIANCUT, dither=Image.NONE).convert("RGBA")
    wall_alpha = wall_box.resize((W, WALL_H), Image.LANCZOS).getchannel("A").point(lambda v: 255 if v >= 128 else 0)
    wall.putalpha(wall_alpha)
    wall.save(OUT / "wall.png")

    # 地面：整块石砖铺满下半屏，纵向压缩当作俯视透视；压暗一点，室内不该和院子一样亮
    ground = Image.new("RGBA", (W, H), (52, 34, 22, 255))
    floor_img = shrink(floor_src, (W, H - FLOOR_TOP), colors=56, opaque=True, bg=(52, 34, 22))
    shade = Image.new("RGBA", floor_img.size, (54, 30, 14, 56))
    floor_img = Image.alpha_composite(floor_img, shade)
    ground.alpha_composite(floor_img, (0, FLOOR_TOP))

    # 墙脚投影
    foot = Image.new("RGBA", (W, 46), (0, 0, 0, 0))
    fd = ImageDraw.Draw(foot)
    for i in range(46):
        fd.rectangle([0, i, W, i], fill=(24, 14, 6, int(110 * (1 - i / 46.0) ** 1.6)))
    ground.alpha_composite(foot, (0, FLOOR_TOP))

    # 家具接触阴影（画在地面上，物件贴上去就不飘）
    for tex, size, x, y, foot_ in LAYOUT:
        _shadow(ground, x, y - 6, int(size[0] * 0.48), 13, 120)
    _shadow(ground, 640, 796, 140, 14, 90)

    # 四角压暗，把视线收到屋子中间
    vign = Image.new("L", (W, H), 0)
    vd = ImageDraw.Draw(vign)
    for i in range(340):
        v = int(150 * (1 - i / 340.0) ** 2.6)
        vd.rectangle([i, i, W - i, H - i], outline=v, width=2)
    vign = vign.filter(ImageFilter.GaussianBlur(90))
    dark = Image.new("RGBA", (W, H), (16, 9, 4, 255))
    dark.putalpha(vign)
    ground.alpha_composite(dark)

    # 窗光落在地上的暖光斑
    glow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    for cx in (356, 962):
        gd.ellipse([cx - 190, 352, cx + 190, 596], fill=(255, 214, 150, 34))
    glow = glow.filter(ImageFilter.GaussianBlur(46))
    ground.alpha_composite(glow)

    ground.alpha_composite(wall, (0, 0))
    ground.convert("RGB").save(OUT / "ground.png")

    # 入口台阶：从外壳底部中间取踏步 + 两侧石座
    steps = shrink(shell.crop((545, 878, 975, 1006)), STEPS[1], colors=34)
    steps.save(OUT / "steps.png")

    sprites = {}
    for tex, size, x, y, _ in LAYOUT:
        img = shrink(Image.open(SRC / f"{tex}.png"), size, colors=40)
        img.save(OUT / f"{tex}.png")
        sprites[tex] = img

    objects = [{"tex": t, "x": x, "y": y, "sort": y} for t, _, x, y, _ in LAYOUT]
    objects.append({"tex": "steps", "x": STEPS[2], "y": STEPS[3], "sort": STEPS[3] - 1})
    objects.sort(key=lambda o: o["sort"])

    colliders = [[0, 0, W, FLOOR_TOP + 8], [0, 0, 10, H], [W - 10, 0, 10, H], [0, H - 8, W, 8]]
    for _, _, x, y, f in LAYOUT:
        colliders.append([x + f[0], y + f[1], f[2], f[3]])
    colliders += [[452, 726, 84, 74], [744, 726, 84, 74]]   # 台阶两侧石座

    layout = {"screen": [W, H], "floor_top": FLOOR_TOP, "objects": objects, "colliders": colliders}
    (OUT / "layout.json").write_text(json.dumps(layout, ensure_ascii=False, indent=1), encoding="utf-8")

    # 不开 Godot 的快速合图
    prev = Image.new("RGBA", (W, H), (0, 0, 0, 255))
    prev.alpha_composite(Image.open(OUT / "ground.png").convert("RGBA"))
    for o in objects:
        img = sprites.get(o["tex"]) or Image.open(OUT / f"{o['tex']}.png").convert("RGBA")
        prev.alpha_composite(img, (o["x"] - img.width // 2, o["y"] - img.height))
    hero = Image.open(ROOT / "assets" / "art" / "hero_idle_v28.png").convert("RGBA").crop((0, 0, 48, 88))
    hero = hero.crop(hero.getbbox())
    prev.alpha_composite(hero, (430 - hero.width // 2, 690 - hero.height))
    prev.convert("RGB").save(PREV / "preview-python.png")
    return layout


if __name__ == "__main__":
    lay = build()
    print("objects", len(lay["objects"]), "colliders", len(lay["colliders"]))
