"""把用户提供的 PNG 拼成「主角家室内」一屏。

原则：**不重画素材**，只做裁切、等比缩放、二值化 alpha、拼装。
素材保留原图细节（不做调色板量化），透明边缘用预乘 alpha 缩放 + 1px 腐蚀处理，避免黑边与光晕。

    python -m tools.build_interior

房间结构直接来自 `source/shell.png`：它本身就是「后墙 + 两侧立柱 + 前方矮墙 + 中央门洞 + 台阶」的完整外壳，
中间是镂空的。所以外壳按行切成两片：
  * `shell_back.png`：地面线以上（后墙 + 两侧立柱上半）→ 画在地面之后、物件之前；
  * `shell_front.png`：地面线以下（立柱下半 + 前方矮墙 + 台阶）→ 画在人物之后，人物走到门口会被矮墙压住小腿。
"""

from __future__ import annotations

import json
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "assets" / "art" / "home_interior" / "source"
OUT = ROOT / "assets" / "art" / "home_interior"
PREV = ROOT / "previews" / "home_interior"

W, H = 1280, 800
SCALE = 0.82                 # 房间外壳等比缩放（外壳 1442x972 → 1182x797）
SHELL_FRONT_ROW = 835        # 外壳里「前方矮墙上沿」那一行（源图坐标）

# 桌面小物件：跟着桌子一起画（sort 取桌子 y + 很小偏移），不参与碰撞、不挡人物
TABLETOP = [
    ("letter", (38, 28), 350, 430, 0.4),
    ("lamp",   (26, 24), 416, 426, 0.5),
]

# 可交互点：矩形是「人站进来就能按空格」的范围
INTERACT = [
    {"id": "letter", "rect": [300, 466, 180, 84], "prompt": "空格：阅读旧家书"},
]

# 家具：贴图, 尺寸（按源图宽高比换算）, 底部中心 x/y, 碰撞 footprint[dx0, dy0, w, h]
# 位置在地面线（FRAME_TOP≈381）与前矮墙上沿（≈685）之间，靠墙摆放、中间留出通路。
LAYOUT = [
    ("bed",   (72, 141), 164, 618, (-36, -104, 72, 104)),
    ("desk",  (156, 107), 388, 470, (-78, -30, 156, 30)),
    ("chair", (44, 79), 494, 496, (-18, -16, 36, 16)),
    ("chest", (90, 71), 255, 655, (-45, -20, 90, 20)),
    ("stove", (180, 99), 1058, 548, (-90, -22, 180, 22)),
    ("table", (104, 104), 862, 646, (-50, -34, 100, 34)),
]

START = (665, 668)


def _alpha_crop(img: Image.Image, inset: int = 0) -> Image.Image:
    """按 alpha>=128 裁到真实轮廓（getbbox 会把透明区残留的 RGB 也算成内容）。"""
    a = img.convert("RGBA")
    mask = a.getchannel("A").point(lambda v: 255 if v >= 128 else 0)
    box = mask.getbbox()
    if box:
        a = a.crop(box)
        mask = mask.crop(box)
    if inset:
        a = a.crop((inset, inset, a.width - inset, a.height - inset))
    return a


def _down(img: Image.Image, size: tuple[int, int], colors: int = 0) -> Image.Image:
    """等比缩到 size，保留原图细节。

    * 预乘 alpha 后再缩放：否则透明像素里的 RGB 会被 LANCZOS 混进边缘，缩出来一圈黑边；
    * 缩放后的 alpha 二值化 + 1px 腐蚀：去掉半透明羽化边，避免家具周围一圈光晕；
    * colors>0 时才做限色（家具有原图细节，默认不限）。
    """
    a = img.convert("RGBA")
    mask = a.getchannel("A").point(lambda v: 255 if v >= 128 else 0)
    box = mask.getbbox()
    if box:
        a = a.crop(box)
        mask = mask.crop(box)
    arr = np.array(a).astype(np.float32)
    arr[..., :3] *= arr[..., 3:4] / 255.0
    pm = Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8), "RGBA")
    small = np.array(pm.resize(size, Image.LANCZOS)).astype(np.float32)
    alp = small[..., 3:4] / 255.0
    rgb = np.where(alp > 0.004, small[..., :3] / np.maximum(alp, 1e-4), 0.0)
    out = Image.fromarray(np.dstack([np.clip(rgb, 0, 255), small[..., 3]]).astype(np.uint8), "RGBA")
    alpha = mask.resize(size, Image.LANCZOS).point(lambda v: 255 if v >= 110 else 0)
    alpha = alpha.filter(ImageFilter.MinFilter(3))
    out.putalpha(alpha)
    return out


def _shadow(ground: Image.Image, cx: int, bottom: int, rx: int, ry: int, alpha: int = 120) -> None:
    layer = Image.new("RGBA", (rx * 2 + 12, ry * 2 + 12), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    d.ellipse([6, 6, rx * 2 + 5, ry * 2 + 5], fill=(26, 14, 7, alpha))
    layer = layer.filter(ImageFilter.GaussianBlur(3))
    ground.alpha_composite(layer, (cx - rx - 6, bottom - ry - 6))


def _hollow(shell: Image.Image) -> tuple[int, int, int, int]:
    """外壳中间那块镂空（地面区）在源图里的上下左右边界。

    不能只看中轴一列：中轴上方可能是透明留白、下方可能穿过台阶，
    所以按行统计「中间 60% 宽度里有多透明」，取最长的一段连续开启行。
    """
    a = np.array(shell)[:, :, 3]
    hgt, wid = a.shape
    band = a[:, int(wid * 0.2):int(wid * 0.8)] < 24
    frac = band.mean(axis=1)
    open_rows = frac > 0.92
    best_len, best_start, cur_start = 0, 0, None
    for y in range(hgt):
        if open_rows[y]:
            if cur_start is None:
                cur_start = y
        elif cur_start is not None:
            if y - cur_start > best_len:
                best_len, best_start = y - cur_start, cur_start
            cur_start = None
    if cur_start is not None and hgt - cur_start > best_len:
        best_len, best_start = hgt - cur_start, cur_start
    y0, y1 = best_start, best_start + best_len - 1
    cy = (y0 + y1) // 2
    row = a[cy, :] < 24
    cx = wid // 2
    if not row[cx]:
        cx = int(np.argmax(row))          # 中轴被挡住时退化成第一个透明点
    x0 = cx
    while x0 > 0 and row[x0 - 1]:
        x0 -= 1
    x1 = cx
    while x1 < wid - 1 and row[x1 + 1]:
        x1 += 1
    return x0, x1, y0, y1


def build() -> dict:
    OUT.mkdir(parents=True, exist_ok=True)
    PREV.mkdir(parents=True, exist_ok=True)

    shell = _alpha_crop(Image.open(SRC / "shell.png"))
    left, right, hole_top, hole_bottom = _hollow(shell)
    sw, sh = round(shell.width * SCALE), round(shell.height * SCALE)
    offx = (W - sw) // 2
    back_h = round(hole_top * SCALE)
    front_y = round(hole_top * SCALE)
    front_h = sh - back_h
    front_top = round(SHELL_FRONT_ROW * SCALE)
    room_x0 = offx + round(left * SCALE) + 4
    room_x1 = offx + round(right * SCALE) - 4

    # 外壳切两片：地面线以上 / 以下
    back = shell.crop((0, 0, shell.width, hole_top)).resize((sw, back_h), Image.LANCZOS)
    front = shell.crop((0, hole_top, shell.width, shell.height)).resize((sw, front_h), Image.LANCZOS)
    back.save(OUT / "shell_back.png")
    front.save(OUT / "shell_front.png")

    # 地面：等比缩放到房间宽度（不拉伸），再从中裁一条铺满屏幕下半
    floor_raw = _alpha_crop(Image.open(SRC / "floor.png"), inset=14)
    target_w = sw + 60
    fs = target_w / float(floor_raw.width)
    floor_full = floor_raw.resize((target_w, round(floor_raw.height * fs)), Image.LANCZOS)
    strip_h = H - front_y
    top = max(0, (floor_full.height - strip_h) // 2)
    floor_cut = floor_full.crop((0, top, target_w, top + strip_h))
    floor_cut = floor_cut.crop(((target_w - sw) // 2, 0, (target_w - sw) // 2 + sw, strip_h))

    ground = Image.new("RGBA", (W, H), (20, 13, 8, 255))
    shade = Image.new("RGBA", floor_cut.size, (52, 30, 15, 58))
    floor_img = Image.alpha_composite(floor_cut, shade)

    # 地面只从外壳的镂空处透出来：镂空 = 房间 + 门洞，其余（墙外）保持暗底
    scaled_shell = shell.resize((sw, sh), Image.LANCZOS)
    hole_mask = scaled_shell.getchannel("A").point(lambda v: 255 if v < 24 else 0)
    mask_full = Image.new("L", (W, H), 0)
    mask_full.paste(hole_mask, (offx, 0))
    keep = Image.new("L", (W, H), 0)
    keep.paste(mask_full.crop((0, front_y, W, 768)), (0, front_y))
    floor_img.putalpha(keep.crop((offx, front_y, offx + sw, front_y + strip_h)))
    ground.alpha_composite(floor_img, (offx, front_y))

    # 墙脚投影：后墙、左右立柱落在石板上的一圈暗部（消掉墙脚黑断层）
    foot = Image.new("RGBA", (sw, 34), (0, 0, 0, 0))
    fd = ImageDraw.Draw(foot)
    for i in range(34):
        fd.rectangle([0, i, sw, i], fill=(26, 15, 7, int(64 * (1 - i / 34.0) ** 1.8)))
    ground.alpha_composite(foot, (offx, front_y))
    side = Image.new("RGBA", (30, H - front_y), (0, 0, 0, 0))
    sd = ImageDraw.Draw(side)
    for i in range(30):
        sd.rectangle([i, 0, i, H], fill=(26, 15, 7, int(54 * (1 - i / 30.0) ** 1.6)))
    ground.alpha_composite(side, (room_x0, front_y))
    ground.alpha_composite(side.transpose(Image.FLIP_LEFT_RIGHT), (room_x1 - 30, front_y))

    # 家具接触阴影
    for tex, size, x, y, f in LAYOUT:
        _shadow(ground, x, y - 5, int(size[0] * 0.46), 12, 120)

    # 四角压暗
    vign = Image.new("L", (W, H), 0)
    vd = ImageDraw.Draw(vign)
    for i in range(320):
        v = int(150 * (1 - i / 320.0) ** 2.8)
        vd.rectangle([i, i, W - i, H - i], outline=v, width=2)
    vign = vign.filter(ImageFilter.GaussianBlur(90))
    dark = Image.new("RGBA", (W, H), (18, 10, 5, 255))
    dark.putalpha(vign)
    ground.alpha_composite(dark)

    # 窗光落在地上
    glow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    for sx in (385, 1080):
        cx = offx + round(sx * SCALE)
        gd.ellipse([cx - 175, front_y, cx + 175, front_y + 232], fill=(255, 214, 150, 30))
    glow = glow.filter(ImageFilter.GaussianBlur(46))
    ground.alpha_composite(glow)

    ground.convert("RGB").save(OUT / "ground.png")

    sprites = {}
    for tex, size, x, y, _ in LAYOUT:
        img = _down(Image.open(SRC / f"{tex}.png"), size)
        img.save(OUT / f"{tex}.png")
        sprites[tex] = img
    for tex, size, x, y, _ in TABLETOP:
        img = _down(Image.open(SRC / f"{tex}.png"), size)
        img.save(OUT / f"{tex}.png")
        sprites[tex] = img

    desk_y = next(y for t, _, _, y, _ in LAYOUT if t == "desk")
    objects = [{"tex": t, "x": x, "y": y, "sort": y} for t, _, x, y, _ in LAYOUT]
    objects += [{"tex": t, "x": x, "y": y, "sort": desk_y + bias} for t, _, x, y, bias in TABLETOP]
    objects.sort(key=lambda o: o["sort"])

    colliders = [
        [0, 0, W, front_y + 6],              # 后墙
        [0, 0, room_x0, H],                  # 左墙
        [room_x1, 0, W - room_x1, H],        # 右墙
        [0, front_top - 6, W, H - front_top + 6],   # 前方矮墙（门洞也好走不出去）
    ]
    for _, _, x, y, f in LAYOUT:
        colliders.append([x + f[0], y + f[1], f[2], f[3]])

    layout = {
        "screen": [W, H],
        "room": {"x0": room_x0, "x1": room_x1, "top": front_y, "front": front_top},
        "frame": {"back": {"tex": "shell_back", "x": offx, "y": 0},
                  "front": {"tex": "shell_front", "x": offx, "y": front_y}},
        "start": list(START),
        "objects": objects,
        "colliders": colliders,
        "interact": INTERACT,
    }
    (OUT / "layout.json").write_text(json.dumps(layout, ensure_ascii=False, indent=1), encoding="utf-8")

    # 不开 Godot 的快速合图
    prev = Image.new("RGBA", (W, H), (0, 0, 0, 255))
    prev.alpha_composite(Image.open(OUT / "ground.png").convert("RGBA"))
    prev.alpha_composite(back, (offx, 0))
    for o in objects:
        img = sprites.get(o["tex"]) or Image.open(OUT / f"{o['tex']}.png").convert("RGBA")
        prev.alpha_composite(img, (o["x"] - img.width // 2, o["y"] - img.height))
    hero = Image.open(ROOT / "assets" / "art" / "hero_idle_v28.png").convert("RGBA").crop((0, 0, 48, 88))
    hero = hero.crop(hero.getbbox())
    prev.alpha_composite(hero, (START[0] - hero.width // 2, START[1] - hero.height))
    prev.alpha_composite(front, (offx, front_y))
    prev.convert("RGB").save(PREV / "preview-python.png")

    print("room x %d..%d  floor %d..%d  shell %dx%d@%d" % (room_x0, room_x1, front_y, front_top, sw, sh, offx))
    return layout


if __name__ == "__main__":
    lay = build()
    print("objects", len(lay["objects"]), "colliders", len(lay["colliders"]))
