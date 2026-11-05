"""生成给美术评审用的预览：按动作分张的放大对照表 + 循环 GIF。

用法（项目根目录）：
    python -m tools.preview_hero
产物都在 previews/：
    hero-v28-idle-sheet.png / -walk-sheet.png / -attack-sheet.png   4 方向 × 各帧，4 倍
    hero-v28-{walk,attack,idle}.gif                                  4 方向并排的循环动画
"""
import os
import sys

from PIL import Image, ImageDraw, ImageFont

from .pixel import hero
from .pixel.palette import rgba

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "previews")
DIR_NAME = {0: "down / front", 1: "left", 2: "right", 3: "up / back"}
ZOOM = 4
PAD = 8
LABEL = 96
COUNTS = {"idle": 4, "walk": 4, "attack": 6}


def frame(kind, d, f):
    cv, _ = hero.render(kind, d, f)
    return cv.img


def sheet(kind):
    n = COUNTS[kind]
    cw, ch = hero.W * ZOOM, hero.H * ZOOM
    width = LABEL + n * (cw + PAD) + PAD
    height = 30 + 4 * (ch + 18 + PAD)
    img = Image.new("RGBA", (width, height), rgba("ink"))
    dr = ImageDraw.Draw(img)
    font = ImageFont.load_default()
    dr.text((LABEL, 8), "%s  (%d frames, 48x88 px each, x%d)" % (kind.upper(), n, ZOOM),
            font=font, fill=(239, 227, 194, 255))
    for d in range(4):
        y = 30 + d * (ch + 18 + PAD)
        dr.text((6, y + ch // 2 - 6), DIR_NAME[d], font=font, fill=(168, 178, 150, 255))
        for f in range(n):
            x = LABEL + f * (cw + PAD)
            img.alpha_composite(frame(kind, d, f).resize((cw, ch), Image.NEAREST), (x, y))
            dr.rectangle([x, y, x + cw - 1, y + ch - 1], outline=(47, 68, 60, 255))
            dr.text((x + 4, y + ch - 14), str(f), font=font, fill=(140, 154, 130, 255))
    path = os.path.join(OUT, "hero-v28-%s-sheet.png" % kind)
    img.save(path)
    print("wrote", path, img.size)


def gif(kind, fps):
    n = COUNTS[kind]
    images = []
    for f in range(n):
        strip = Image.new("RGBA", (hero.W * 4 * ZOOM, hero.H * ZOOM), (27, 43, 38, 255))
        for d in range(4):
            big = frame(kind, d, f).resize((hero.W * ZOOM, hero.H * ZOOM), Image.NEAREST)
            strip.alpha_composite(big, (d * hero.W * ZOOM, 0))
        images.append(strip.convert("P", palette=Image.ADAPTIVE, colors=64))
    path = os.path.join(OUT, "hero-v28-%s.gif" % kind)
    images[0].save(path, save_all=True, append_images=images[1:],
                   duration=int(1000 / fps), loop=0, disposal=2)
    print("wrote", path, len(images), "frames")


def main():
    os.makedirs(OUT, exist_ok=True)
    for kind in ("idle", "walk", "attack"):
        sheet(kind)
    gif("walk", 8)
    gif("attack", 12)
    gif("idle", 4)


if __name__ == "__main__":
    sys.exit(main())