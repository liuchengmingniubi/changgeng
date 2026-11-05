"""生成主角图集、手部锚点数据与预览图。

用法（在项目根目录）：
    python -m tools.build_hero
产物：
    assets/art/hero_walk_v28.png    4 行 × 4 帧 / 48×88
    assets/art/hero_attack_v28.png  4 行 × 6 帧 / 48×88
    assets/art/hero_idle_v28.png    4 行 × 2 帧 / 48×88
    hero_anim_data.gd               手部锚点（GDScript 常量）
    previews/hero-v28-sheet.png     4 倍放大 + 网格，供人眼看
"""
import os
import sys

from PIL import Image

from .pixel import hero
from .pixel.canvas import Canvas
from .pixel.palette import check_no_outside_colors, rgba

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ART = os.path.join(ROOT, "assets", "art")
PREVIEW = os.path.join(ROOT, "previews")

SHEETS = {
    "walk": (4, "hero_walk_v28.png"),
    "attack": (6, "hero_attack_v28.png"),
    "idle": (2, "hero_idle_v28.png"),
}


def build_sheet(kind, frames):
    cols, _name = SHEETS[kind]
    sheet = Image.new("RGBA", (hero.W * cols, hero.H * 4), (0, 0, 0, 0))
    hands = [[None] * cols for _ in range(4)]
    for d in range(4):
        for f in range(cols):
            cv, hand = hero.render(kind, d, f)
            sheet.alpha_composite(cv.img, (f * hero.W, d * hero.H))
            hands[d][f] = hand
    return sheet, hands


def main():
    os.makedirs(PREVIEW, exist_ok=True)
    all_hands = {}
    for kind, (cols, name) in SHEETS.items():
        sheet, hands = build_sheet(kind, cols)
        bad, sample = check_no_outside_colors(sheet)
        path = os.path.join(ART, name)
        sheet.save(path)
        all_hands[kind] = hands
        print(f"{name}: {sheet.width}x{sheet.height}  调色板外颜色 {bad} {sorted(sample)[:4]}")
        if bad:
            raise SystemExit("图集混入了调色板之外的颜色")

    # 预览：4 倍最近邻放大 + 2 像素网格
    for kind, (cols, name) in SHEETS.items():
        sheet = Image.open(os.path.join(ART, name))
        zoom = 4
        big = sheet.resize((sheet.width * zoom, sheet.height * zoom), Image.NEAREST)
        canvas = Canvas(big.width + 1, big.height + 1)
        canvas.img = big.convert("RGBA")
        from PIL import ImageDraw
        dr = ImageDraw.Draw(canvas.img)
        for c in range(cols + 1):
            x = min(c * hero.W * zoom, big.width - 1)
            dr.line([(x, 0), (x, big.height - 1)], fill=rgba("ink_soft"), width=1)
        for r in range(5):
            y = min(r * hero.H * zoom, big.height - 1)
            dr.line([(0, y), (big.width - 1, y)], fill=rgba("ink_soft"), width=1)
        canvas.img.save(os.path.join(PREVIEW, "hero-v28-" + kind + ".png"))

    write_anim_data(all_hands)
    dump_ascii()


def write_anim_data(hands):
    def rows(kind):
        out = []
        for d in range(4):
            out.append("[" + ", ".join("Vector2(%d,%d)" % h for h in hands[kind][d]) + "]")
        return ",\n\t".join(out)

    text = """extends RefCounted
# 由 tools/build_hero.py 生成，勿手改。坐标以每帧 48x88 画布左上角为原点。
const CELL := Vector2(48, 88)
const WALK_SHEET := "res://assets/art/hero_walk_v28.png"
const ATTACK_SHEET := "res://assets/art/hero_attack_v28.png"
const IDLE_SHEET := "res://assets/art/hero_idle_v28.png"
const WALK_FRAMES := 4
const ATTACK_FRAMES := 6
const IDLE_FRAMES := 2
# [朝向][帧] 朝向顺序：0 下 1 左 2 右 3 上
const WALK_HAND := [
\t%s
]
const ATTACK_HAND := [
\t%s
]
const IDLE_HAND := [
\t%s
]
""" % (rows("walk"), rows("attack"), rows("idle"))
    with open(os.path.join(ROOT, "hero_anim_data.gd"), "w", encoding="utf-8") as f:
        f.write(text)


def dump_ascii():
    for kind, d, f in [("idle", 0, 0), ("walk", 0, 0), ("walk", 2, 0), ("attack", 0, 3), ("attack", 2, 3)]:
        cv, _ = hero.render(kind, d, f)
        print("\n=== %s dir=%d frame=%d ===" % (kind, d, f))
        print(cv.ascii())


if __name__ == "__main__":
    sys.exit(main())