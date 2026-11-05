"""用 Python 把 home_yard 的素材按 layout.json 合成一张预览图。

    python -m tools.scene_preview [输出路径] [人物x] [人物y]

它和 Godot 预览场景读同一份 layout.json，用来在没有 GPU 的场合快速看构图；
Godot 版才是最终交付（那里有真实移动、碰撞与遮挡）。
"""
import json
import os
import sys

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ART = os.path.join(ROOT, "assets", "art", "home_yard")
HERO = os.path.join(ROOT, "assets", "art", "hero_idle_v28.png")
CELL = (48, 88)


def main():
    out = sys.argv[1] if len(sys.argv) > 1 else os.path.join(ROOT, "previews", "home_yard", "preview-python.png")
    hx = float(sys.argv[2]) if len(sys.argv) > 2 else 520.0
    hy = float(sys.argv[3]) if len(sys.argv) > 3 else 620.0

    with open(os.path.join(ART, "layout.json"), encoding="utf-8") as f:
        layout = json.load(f)

    ground = Image.open(os.path.join(ART, "ground.png")).convert("RGBA")
    canvas = ground.copy()
    cache = {}

    hero = Image.open(HERO).convert("RGBA").crop((0, 0, CELL[0], CELL[1]))
    hero_y = hy

    def blob(name):
        if name not in cache:
            cache[name] = Image.open(os.path.join(ART, name + ".png")).convert("RGBA")
        return cache[name]

    def put(name, x, y):
        img = blob(name)
        canvas.alpha_composite(img, (int(round(x - img.width / 2)), int(round(y - img.height))))

    for o in layout["objects"]:
        if float(o["sort"]) > hero_y:
            break
        put(o["tex"], o["x"], o["y"])

    # 人物脚下阴影
    sh = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    from PIL import ImageDraw
    ImageDraw.Draw(sh).ellipse([hx - 13, hy - 6, hx + 13, hy + 4], fill=(60, 40, 26, 90))
    canvas.alpha_composite(sh)
    canvas.alpha_composite(hero, (int(round(hx - 24)), int(round(hy - 87))))

    drawn = False
    for o in layout["objects"]:
        if not drawn and float(o["sort"]) > hero_y:
            drawn = True
        if drawn:
            put(o["tex"], o["x"], o["y"])

    os.makedirs(os.path.dirname(out), exist_ok=True)
    canvas.convert("RGB").save(out)
    print("saved", out, canvas.size)
    return 0


if __name__ == "__main__":
    sys.exit(main())
