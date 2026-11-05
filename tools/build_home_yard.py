"""生成"主角家门口一屏"的全部素材。

    python -m tools.build_home_yard

产物（assets/art/home_yard/）：
    ground.png        1280x800 地面层
    house.png         700x440 主角家
    tree_big.png      250x300
    tree_small.png    168x210
    fence.png         96x78 可平铺栅栏段
    gate.png          150x118 院门
    crops_0..5.png    160x112 六种菜畦
    prop_*.png        井、陶罐、柴堆、晾架、鸡、桶、筐、凳、扫帚、草垛、石、箱、灌木、猫
    layout.json       场景摆放表 + 碰撞体
"""
import json
import os
import sys

from .pixel import house_art, props_art, yard_ground, yard_layout as L
from .pixel.scene_palette import check

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "art", "home_yard")


def save(cv_or_img, name):
    img = cv_or_img.img if hasattr(cv_or_img, "img") else cv_or_img
    path = os.path.join(OUT, name)
    img.save(path)
    bad = check(img)
    print("%-20s %4dx%-4d 调色板外=%d" % (name, img.width, img.height, bad))
    return bad


def build_layout():
    objs = [{"tex": "house", "x": L.HOUSE[0], "y": L.HOUSE[1]}]
    for (tx, ty, kind) in L.TREES:
        objs.append({"tex": "tree_%s" % kind, "x": tx, "y": ty})
    for (x0, x1) in L.FENCE_SEGMENTS:
        n = max(1, int(round((x1 - x0) / 96.0)))
        span = (x1 - x0) / float(n)
        for i in range(n):
            objs.append({"tex": "fence", "x": x0 + span * (i + 0.5), "y": L.FENCE_Y})
    objs.append({"tex": "gate", "x": (L.GATE[0] + L.GATE[1]) // 2, "y": L.FENCE_Y + 4})
    for i, (px, py) in enumerate(L.PLOTS):
        objs.append({"tex": "crops_%d" % (i % 6), "x": px + L.PLOT_W // 2, "y": py + L.PLOT_H - 6})
    for (name, x, y) in L.PROPS:
        objs.append({"tex": "prop_%s" % name, "x": x, "y": y})
    for o in objs:
        o["sort"] = o["y"]
    objs.sort(key=lambda o: o["sort"])
    return {
        "screen": [L.W, L.H],
        "ground": "ground",
        "objects": objs,
        "colliders": [list(c) for c in L.COLLIDERS],
    }


def main():
    os.makedirs(OUT, exist_ok=True)
    bad = 0
    ground = yard_ground.Ground()
    bad += save(ground.bake(), "ground.png")
    bad += save(house_art.draw(), "house.png")
    bad += save(props_art.tree("big"), "tree_big.png")
    bad += save(props_art.tree("small"), "tree_small.png")
    bad += save(props_art.fence_segment(), "fence.png")
    bad += save(props_art.gate(), "gate.png")
    for s in range(6):
        bad += save(props_art.crops(s), "crops_%d.png" % s)
    for name in props_art.PROP_NAMES:
        bad += save(props_art.prop(name), "prop_%s.png" % name)

    layout = build_layout()
    with open(os.path.join(OUT, "layout.json"), "w", encoding="utf-8") as f:
        json.dump(layout, f, ensure_ascii=False, indent=1)
    print("layout.json 物件数", len(layout["objects"]), "碰撞体", len(layout["colliders"]))
    print("调色板外总计", bad)

    if "--ascii" in sys.argv:
        print(house_art.draw().ascii())
    return 0 if bad == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
