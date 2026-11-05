"""生成"主角家门口一屏"的全部素材。

    python -m tools.build_home_yard

产物（assets/art/home_yard/）：
    ground.png        1280x800 地面层（含阴影、村道、农田、树线）
    house.png         320x224 主角家
    tree_big.png      156x176
    tree_small.png    112x128
    fence.png         32x46 可平铺栅栏段
    gate.png          100x70 院门
    crops_0..2.png    96x64 三档作物
    props.png         128x128 小道具图集（4x4，每格 32）
    props.json        道具名 -> 图集序号
    layout.json       场景摆放表，Godot 预览场景直接读
"""
import json
import os
import sys

from PIL import Image

from .pixel import house_art, props_art, yard_ground, yard_layout as L
from .pixel.scene_palette import check

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "art", "home_yard")


def save(cv_or_img, name):
    img = cv_or_img.img if hasattr(cv_or_img, "img") else cv_or_img
    path = os.path.join(OUT, name)
    img.save(path)
    bad = check(img)
    print("%-18s %4dx%-4d 调色板外=%d" % (name, img.width, img.height, bad))
    return bad


def build_props_atlas():
    names = props_art.PROP_NAMES
    sheet = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
    index = {}
    for i, name in enumerate(names):
        cx, cy = (i % 4) * 32, (i // 4) * 32
        sheet.alpha_composite(props_art.prop(name).img, (cx, cy))
        index[name] = i
    return sheet, index


def build_layout(prop_index):
    objs = []
    objs.append({"tex": "house", "x": L.HOUSE[0], "y": L.HOUSE[1]})
    for (tx, ty, kind) in L.TREES:
        objs.append({"tex": "tree_%s" % kind, "x": tx, "y": ty})
    for (x0, x1) in L.FENCE_SEGMENTS:
        n = max(1, (x1 - x0) // 32)
        for i in range(n):
            objs.append({"tex": "fence", "x": x0 + i * 32 + 16, "y": L.FENCE_Y})
    objs.append({"tex": "gate", "x": (L.GATE[0] + L.GATE[1]) // 2, "y": L.FENCE_Y + 2})
    for i, (px, py) in enumerate(L.PLOTS):
        objs.append({"tex": "crops_%d" % (i % 3), "x": px + L.PLOT_W // 2, "y": py + L.PLOT_H - 4})
    for (name, x, y) in L.PROPS:
        objs.append({"tex": "prop:%s" % name, "x": x, "y": y})
    for o in objs:
        o["sort"] = o["y"]
    objs.sort(key=lambda o: o["sort"])
    return {"screen": [L.W, L.H], "ground": "ground", "objects": objs}


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
    for s in range(3):
        bad += save(props_art.crops(s), "crops_%d.png" % s)
    atlas, index = build_props_atlas()
    bad += save(atlas, "props.png")

    with open(os.path.join(OUT, "props.json"), "w", encoding="utf-8") as f:
        json.dump(index, f, ensure_ascii=False, indent=1)
    with open(os.path.join(OUT, "layout.json"), "w", encoding="utf-8") as f:
        json.dump(build_layout(index), f, ensure_ascii=False, indent=1)
    print("layout.json 物件数", len(build_layout(index)["objects"]))
    print("调色板外总计", bad)

    # 生成器自检：把房子缩略成 ASCII，肉眼确认大体结构
    if "--ascii" in sys.argv:
        print(house_art.draw().ascii())
    return 0 if bad == 0 else 1


if __name__ == "__main__":
    sys.exit(main())