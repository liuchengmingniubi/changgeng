"""固定调色板：全部美术只允许使用这里的颜色。

颜色取自已上线 UI 的青玉/铜金体系，保证人物、场景、界面同源。
任何新素材都要先在这里登记，再在绘制里引用名字，禁止随手写十六进制。
"""

PALETTE = {
    # 轮廓 / 阴影
    "ink":         "1b2b26",
    "ink_soft":    "2f443c",
    "shadow":      "232c30",
    # 皮肤
    "skin":        "d8b18a",
    "skin_lit":    "e8c8a2",
    "skin_dark":   "b4876a",
    # 头发
    "hair":        "262c2d",
    "hair_lit":    "3d4646",
    "hair_warm":   "4a3c31",
    # 上衣（青蓝短褐）
    "tunic":       "416f78",
    "tunic_lit":   "5b9296",
    "tunic_dark":  "2d535f",
    # 领口 / 内衬
    "cream":       "efe3c2",
    "cream_dark":  "cfc09b",
    # 腰带
    "sash":        "7d5a3a",
    "sash_lit":    "a87c4c",
    "sash_dark":   "5b3f28",
    # 裤子 / 靴
    "pants":       "39413e",
    "pants_lit":   "4d5852",
    "pants_dark":  "2b322f",
    "boot":        "4a3527",
    "boot_lit":    "6b4d36",
    "boot_dark":   "33241a",
    # 金属 / 玉
    "steel":       "cbdcd4",
    "steel_dark":  "8fa5a0",
    "jade":        "567263",
    "gold":        "bda36a",
    "gold_lit":    "d4bd88",
    "gold_dark":   "8a7345",
}

# ASCII 预览用：越靠前的字越"亮"，仅用于人工检查轮廓
ASCII_KEYS = [
    (".", None),
    ("#", "ink"),
    ("~", "ink_soft"),
    ("h", "hair"),
    ("H", "hair_lit"),
    ("s", "skin"),
    ("S", "skin_lit"),
    ("d", "skin_dark"),
    ("t", "tunic"),
    ("T", "tunic_lit"),
    ("u", "tunic_dark"),
    ("c", "cream"),
    ("C", "cream_dark"),
    ("b", "sash"),
    ("B", "sash_lit"),
    ("x", "sash_dark"),
    ("p", "pants"),
    ("P", "pants_lit"),
    ("q", "pants_dark"),
    ("o", "boot"),
    ("O", "boot_lit"),
    ("Q", "boot_dark"),
    ("m", "steel"),
    ("M", "steel_dark"),
    ("j", "jade"),
    ("g", "gold"),
    ("y", "gold_lit"),
    ("G", "gold_dark"),
    ("w", "shadow"),
]


def rgba(name):
    h = PALETTE[name]
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), 255)


def ascii_lookup():
    table = {}
    for ch, name in ASCII_KEYS:
        if name is None:
            table[(0, 0, 0, 0)] = ch
        else:
            table[rgba(name)] = ch
    return table


def check_no_outside_colors(img):
    """返回调色板之外的颜色数量；必须为 0，否则说明混入了渐变/抗锯齿。"""
    allowed = {rgba(n) for n in PALETTE}
    allowed.add((0, 0, 0, 0))
    bad = 0
    seen = set()
    for count, color in img.getcolors(maxcolors=1 << 24) or []:
        if color not in allowed:
            bad += count
            if len(seen) < 8:
                seen.add(color)
    return bad, seen