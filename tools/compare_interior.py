"""把室内样板改动前后的同机位截图拼成一张对比图。

用法：python -m tools.compare_interior
输入：previews/home_interior/preview-before.png（改动前）、preview.png（改动后）
输出：previews/home_interior/compare.png
"""
from __future__ import annotations

import pathlib

from PIL import Image, ImageDraw, ImageFont

ROOT = pathlib.Path(__file__).resolve().parent.parent
OUT_DIR = ROOT / "previews" / "home_interior"
FONT = ROOT / "assets" / "font.otf"
BAR = 44


def label(img: Image.Image, text: str) -> Image.Image:
    bar = Image.new("RGB", (img.width, BAR), (28, 20, 15))
    draw = ImageDraw.Draw(bar)
    font = ImageFont.truetype(str(FONT), 24)
    draw.text((20, BAR // 2 - 15), text, font=font, fill=(239, 227, 194))
    out = Image.new("RGB", (img.width, img.height + BAR), (28, 20, 15))
    out.paste(bar, (0, 0))
    out.paste(img, (0, BAR))
    return out


def main() -> None:
    before = Image.open(OUT_DIR / "preview-before.png").convert("RGB")
    after = Image.open(OUT_DIR / "preview.png").convert("RGB")
    top = label(before, "改动前：六张图拼装，没有侧墙与前矮墙，地面靠纵向拉伸凑高度")
    bottom = label(after, "改动后：完整房间结构 + 家具靠墙 + 木椅/遗书/油灯/圆桌")
    canvas = Image.new("RGB", (before.width, top.height + bottom.height), (18, 13, 9))
    canvas.paste(top, (0, 0))
    canvas.paste(bottom, (0, top.height))
    canvas.save(OUT_DIR / "compare.png")
    print("previews/home_interior/compare.png", canvas.size)


if __name__ == "__main__":
    main()
