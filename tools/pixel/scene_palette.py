"""场景调色板：在人物调色板之外追加地面/建筑/植被色。

配色原则：
- 全部低饱和，冷绿阴影 + 暖褐受光，和主角身上的青蓝短褐、米白内衬同源；
- 每个材质只给 3-4 档（暗/基本/亮/高光），不做渐变，靠硬边分阶表现体积；
- 任何新颜色先登记在这里，绘制时只用名字。
"""
from .palette import PALETTE as HERO_PALETTE
from .palette import rgba

SCENE = {
    # 草地
    "grass_dk":   "2f4a39",
    "grass":      "3d5b42",
    "grass_lt":   "4e6d4a",
    "grass_hi":   "63855a",
    "grass_dry":  "7c8a4e",
    # 泥土 / 院子
    "dirt_dk":    "4b3928",
    "dirt":       "604a33",
    "dirt_lt":    "7a5f42",
    "dirt_hi":    "8f7350",
    # 耕地
    "soil_dk":    "3a2b1d",
    "soil":       "4d3a26",
    "soil_lt":    "61492f",
    # 石头
    "stone_dk":   "5c6157",
    "stone":      "7f8477",
    "stone_lt":   "9ba090",
    "stone_hi":   "b7bba8",
    # 木头
    "wood_dk":    "3d2f20",
    "wood":       "5a442c",
    "wood_lt":    "7b5d3a",
    "wood_hi":    "987650",
    # 稻草 / 茅草
    "straw_dk":   "8a6f3a",
    "straw":      "a88a4a",
    "straw_lt":   "c6a760",
    "straw_hi":   "dcc07a",
    # 青瓦
    "tile_dk":    "2f3d44",
    "tile":       "3e515a",
    "tile_lt":    "516974",
    "tile_hi":    "6a838d",
    # 夯土墙
    "wall_dk":    "7c6a51",
    "wall":       "9b8465",
    "wall_lt":    "b5a183",
    "wall_hi":    "cbb99b",
    # 白灰内墙
    "plaster_dk": "cfbf9c",
    "plaster":    "e8dcc0",
    "plaster_lt": "f2e8cf",
    # 树叶
    "leaf_dk":    "24402f",
    "leaf":       "31543c",
    "leaf_lt":    "44704b",
    "leaf_hi":    "5c8a5b",
    # 作物
    "sprout":     "6d9450",
    "crop":       "8fae55",
    "crop_lit":   "a9c268",
    # 水
    "water_dk":   "2f545d",
    "water":      "3f6d78",
    "water_lt":   "6fa2a8",
    # 布料点缀
    "cloth_red":  "a8443a",
    "cloth_red_lt": "c4645a",
}

PALETTE = dict(HERO_PALETTE)
PALETTE.update(SCENE)

_CACHE = {}


def c(name):
    """取色：只用本文件合并后的调色板，避免人物色表与场景色表分裂。"""
    hit = _CACHE.get(name)
    if hit is not None:
        return hit
    if name not in PALETTE:
        raise KeyError("未登记的颜色: %s" % name)
    h = PALETTE[name]
    if isinstance(h, tuple):
        _CACHE[name] = h
        return h
    v = tuple(int(h[i:i + 2], 16) for i in (0, 2, 4)) + (255,)
    _CACHE[name] = v
    return v


def check(img):
    """返回调色板外像素数量（必须为 0）。"""
    allowed = {c(n) for n in PALETTE}
    px = img.convert("RGBA").load()
    bad = 0
    for y in range(img.height):
        for x in range(img.width):
            p = px[x, y]
            if p[3] == 0:
                continue
            if p not in allowed:
                if p[3] < 255:
                    # 半透明一律视为违规：像素画不做 alpha 混合
                    bad += 1
                else:
                    bad += 1
    return bad


def hist(img):
    """统计用色，便于检查是否真的收敛在调色板内。"""
    px = img.convert("RGBA").load()
    seen = {}
    for y in range(img.height):
        for x in range(img.width):
            p = px[x, y]
            if p[3] == 0:
                continue
            seen[p] = seen.get(p, 0) + 1
    return seen


def rng(x, y, salt=0):
    """确定性伪随机：同一个坐标永远得到同一个值。"""
    n = (x * 374761393 + y * 668265263 + salt * 2147483647) & 0xFFFFFFFF
    n = (n ^ (n >> 13)) * 1274126177 & 0xFFFFFFFF
    return ((n ^ (n >> 16)) & 0xFFFF) / 65535.0