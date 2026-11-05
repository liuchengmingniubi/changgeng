# 主角家门口一屏（美术样板）

独立的像素美术样板，用于确认「俯视角 + 房屋 + 院子 + 12 块农田 + 围栏 + 树木 + 连接村庄的道路」
的观感与比例。**不替换正式地图，不改玩法，`main.gd` 未改动**，只是一份可单独运行的预览。

## 怎么看

```
Play-Windows.bat 之外，直接跑这一屏：
engine\Godot_v4.3-stable_win64_console.exe --path . res://previews/home_yard_preview.tscn
```

截图（需要窗口模式，headless 没有 GPU 渲染不了）：

```
engine\Godot_v4.3-stable_win64_console.exe --path . res://previews/home_yard_preview.tscn -- --shot=res://previews/home_yard/preview.png
```

- `preview.png`：1280×800 整屏截图，场景里站着主角（待机帧，沿用 `hero_idle_v28.png`）。
- `preview-house-2x.png`：房屋与院子区域放大 2 倍，用来看细节。

## 文件

| 文件 | 说明 |
| --- | --- |
| `previews/home_yard_preview.tscn` / `.gd` | 预览场景：读 `layout.json` 依次画地面、物件（按 y 排序）、主角 |
| `assets/art/home_yard/ground.png` | 1280×800 地面层：草地、土院、小路、村道、12 块田的垄沟、树线、阴影 |
| `assets/art/home_yard/house.png` | 320×224 主角家：青瓦顶 + 瓦当 + 夯土墙木构 + 板门 + 两扇窗 + 石台基 + 挂饰 |
| `assets/art/home_yard/tree_big.png` / `tree_small.png` | 两档树冠，底部中心对齐 |
| `assets/art/home_yard/fence.png` / `gate.png` | 32×46 可平铺栅栏段、100×70 院门 |
| `assets/art/home_yard/crops_0..2.png` | 96×64 三档长势的作物层，铺在田垄上 |
| `assets/art/home_yard/props.png` + `props.json` | 128×128 图集（4×4，每格 32），含井、陶罐、水桶、柴堆、鸡、猫、草垛等 |
| `assets/art/home_yard/layout.json` | 摆放表：`objects[{tex,x,y,sort}]`，`x,y` 是底部中心，`sort` 是绘制顺序 |

## 素材规范

- 单色硬边像素，**所有颜色都在 `tools/pixel/scene_palette.py` 的调色板内**，
  生成时 `check()` 会统计调色板外像素与半透明像素，必须为 0。
- 地平线在同一处：物件底部中心落在自己的 y 上，站立物体（房、树、人）共用 1280×800 的一屏坐标。
- 显示比例 1:1，不做缩放，保证像素不糊。

## 重新生成

```
python -m tools.build_home_yard        # 全部素材 + layout.json
python -m tools.build_home_yard --ascii  # 附带打印房屋的 ASCII 草图
```

布局常量集中在 `tools/pixel/yard_layout.py`（房屋位置、12 块田的网格、栅栏与院门、道路、道具坐标），
改数值后重跑即可整体重排，不用动 Godot 侧。

## 还没做的

- 只做了静止一屏与待机姿态的主角；NPC、走动、四季光照没做。
- 房屋只有一栋形制，没有做多套变体。
- 素材尚未接入 `world_layout.gd` 的正式地图。