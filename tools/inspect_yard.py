"""把预览图降采样成 ASCII，供无法看图的模型自查构图。

    python -m tools.inspect_yard [路径] [列数]

每个字符代表该格子里出现最多的颜色类别：
    .  透明/天空   g 草地   d 土院   s 农田   r 道路   T 屋顶   W 木(墙/栅栏)
    L 树叶         k 描边/暗部   o 其它(道具/人物)
"""
import sys
from collections import Counter

from PIL import Image

sys.path.insert(0, ".")
from tools.pixel.scene_palette import PALETTE  # noqa: E402

CLASSES = [
    ("grass_dk", "g"), ("grass", "g"), ("grass_lt", "g"), ("grass_hi", "g"), ("grass_dry", "g"),
    ("dirt_dk", "d"), ("dirt", "d"), ("dirt_lt", "d"), ("dirt_hi", "d"),
    ("soil_dk", "s"), ("soil", "s"), ("soil_lt", "s"),
    ("tile_dk", "T"), ("tile", "T"), ("tile_lt", "T"), ("tile_hi", "T"),
    ("wood_dk", "W"), ("wood", "W"), ("wood_lt", "W"), ("wood_hi", "W"),
    ("wall_dk", "W"), ("wall", "W"), ("wall_lt", "W"), ("wall_hi", "W"),
    ("plaster_dk", "W"), ("plaster", "W"), ("plaster_lt", "W"),
    ("leaf_dk", "L"), ("leaf", "L"), ("leaf_lt", "L"), ("leaf_hi", "L"),
    ("ink", "k"), ("ink_soft", "k"), ("shadow", "k"),
]


def classify(rgb):
    for name, ch in CLASSES:
        h = PALETTE[name]
        v = tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))
        if v == rgb:
            return ch
    return "o"


def main():
    path = sys.argv[1] if len(sys.argv) > 1 else "previews/home_yard/preview.png"
    cols = int(sys.argv[2]) if len(sys.argv) > 2 else 96
    img = Image.open(path).convert("RGBA")
    w, h = img.size
    cw = max(1, w // cols)
    rows = max(1, h // cw // 2)
    ch = max(1, h // rows)
    px = img.load()
    print("%s  %dx%d  -> %dx%d 格, 每格 %dx%d px" % (path, w, h, cols, rows, cw, ch))
    for ry in range(rows):
        line = []
        for rx in range(cols):
            cnt = Counter()
            for y in range(ry * ch, min(h, (ry + 1) * ch), max(1, ch // 4)):
                for x in range(rx * cw, min(w, (rx + 1) * cw), max(1, cw // 4)):
                    r, g, b, a = px[x, y]
                    if a == 0:
                        cnt["."] += 1
                    elif a < 255:
                        cnt["o"] += 1
                    else:
                        cnt[classify((r, g, b))] += 1
            if not cnt:
                line.append(" ")
                continue
            line.append(cnt.most_common(1)[0][0])
        print("".join(line))
    # 分区统计
    print()
    for label, box in [("左院", (0, 400, 640, 800)), ("右农田", (640, 80, 1280, 500)),
                       ("房屋", (170, 290, 490, 520)), ("道路", (0, 700, 1280, 800))]:
        sub = img.crop(box)
        cnt = Counter()
        for r, g, b, a in sub.getdata():
            cnt["." if a == 0 else classify((r, g, b))] += 1
        total = sum(cnt.values())
        top = ", ".join("%s%.0f%%" % (k, 100.0 * v / total) for k, v in cnt.most_common(5))
        print("%-6s %s" % (label, top))


if __name__ == "__main__":
    main()