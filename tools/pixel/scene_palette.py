"""场景调色板：从参考图取样的暖黄土 + 青瓦 + 夯土墙 配色。

设计：
- 每种材质给一条 4-7 档的明暗梯（ramp），索引 0 最亮、越往后越暗；
- 绘制时只用 `T(材质, 档位)` 取色，档位由光照/阴影图决定，因此阴影是
  "换成更暗的同族色"而不是 alpha 混合，画面依然干净、可数色；
- 描边用暖黑（ink），不是纯黑，跟参考图的棕线一致；
- 所有档案登记进 PALETTE，`check()` 统计调色板外像素，必须为 0。
"""
from .palette import PALETTE as HERO_PALETTE
from .palette import rgba

RAMPS = {
    # 黄土：村子里的主要地表，偏橙、亮度高
    "loess": ["fbc98e", "f4b87c", "e9a86b", "d9975b", "c0814b", "9c6538", "78502c"],
    # 踩实的院土：比黄土更粉、更灰一点
    "yard":  ["f3bc84", "e8ac74", "d99c66", "c58a58", "a97046", "8a5936"],
    # 草：暖橄榄绿
    "grass": ["b9bb68", "a0a355", "868c47", "6c7539", "545d2d", "3f4823"],
    # 耕地
    "soil":  ["9c6a40", "825734", "684426", "4f331d", "3a2414"],
    # 村道
    "road":  ["eab173", "dd9f62", "c98b51", "ae7443", "8d5c34", "6d4728"],
    # 石头
    "stone": ["e6d3b6", "d3bd9c", "b9a381", "9d8767", "7e6a4f", "60503a"],
    # 青瓦
    "tile":  ["b7c0bd", "98a3a3", "7b878a", "5f6b70", "48535a", "333c43", "232a30"],
    # 夯土墙
    "wall":  ["f6c489", "eab073", "d99a5e", "c0814b", "a0653a", "7d4c2b"],
    # 木构
    "wood":  ["a87a50", "8a5f3c", "6e472b", "54331e", "3d2414", "2a1809"],
    # 树叶
    "leaf":  ["b3b661", "979c4d", "7c833c", "636b30", "4c5426", "38401c", "272e13"],
    # 树皮（参考图里的树皮偏浅、像桦木）
    "bark":  ["ded0b4", "c4b294", "a48d6b", "827052", "5e4c34", "3f3122"],
    # 作物：青菜
    "crop":  ["cfe07a", "b3cf5c", "97b048", "7b9239", "61732c"],
    # 作物：黄熟的穗
    "crop_y": ["f2dc6a", "dcc24f", "c0a43c", "9c8230", "7a6326"],
    # 白灰墙 / 窗纸
    "plaster": ["fbe5c0", "f0d5ab", "dfc294", "c4a375", "a4835a"],
    # 草秸 / 草垛
    "straw": ["f4d98a", "e2c06a", "c9a24e", "a87f3a", "856029", "63451c"],
    # 布料
    "red":   ["d4786a", "b9534a", "963b36"],
    "blue":  ["9fc4c6", "7fa8ad", "5f878e"],
    "water": ["86b3b4", "5f929a", "3f6d78"],
    # 描边
    "ink":   ["2b1d12", "3d2c1c"],
}

PALETTE = dict(HERO_PALETTE)
for _mat, _ramp in RAMPS.items():
    for _i, _h in enumerate(_ramp):
        PALETTE["%s_%d" % (_mat, _i)] = _h

_CACHE = {}


def _hex(v):
    return tuple(int(v[i:i + 2], 16) for i in (0, 2, 4)) + (255,)


def T(mat, level=2):
    """取色：mat 是 RAMPS 的键，level 是明暗档位（0 最亮），超界自动夹住。"""
    ramp = RAMPS[mat]
    i = int(round(level))
    i = 0 if i < 0 else (len(ramp) - 1 if i >= len(ramp) else i)
    key = (mat, i)
    hit = _CACHE.get(key)
    if hit is None:
        hit = _hex(ramp[i])
        _CACHE[key] = hit
    return hit


def ramp_len(mat):
    return len(RAMPS[mat])


def c(name):
    """按名字取色（兼容旧代码）。"""
    hit = _CACHE.get(name)
    if hit is not None:
        return hit
    if name not in PALETTE:
        raise KeyError("未登记的颜色: %s" % name)
    h = PALETTE[name]
    v = h if isinstance(h, tuple) else _hex(h)
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
                bad += 1
    return bad


def hist(img):
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
