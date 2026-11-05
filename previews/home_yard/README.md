# 主角家门口一屏（参考图重做版）

按参考图重做的独立像素样板：暖橙黄土院子、青瓦夯土大屋、木栅栏与院门、水井、菜畦、
杂物，以及**可在场景里走动、会被物件正确遮挡、有碰撞的主角**。
**不替换正式地图、不改玩法、`main.gd` 一行未动**，是一份可以单独打开跑的预览工程。

## 怎么看

直接开窗跑这一屏：

```
engine\Godot_v4.3-stable_win64_console.exe --path . res://previews/home_yard_preview.tscn
```

操作：**WASD / 方向键**走动，**空格**挥剑。人物走到栅栏北侧，栅栏会压住他的小腿；
撞到房屋、菜畦、水井、树干会被挡住。

截图（必须窗口模式，headless 没有 GPU）：

```
engine\Godot_v4.3-stable_win64_console.exe --path . res://previews/home_yard_preview.tscn -- --shot=res://previews/home_yard/preview.png
```

- `preview.png`：1280×800 实机截图（主角站在院子里）。
- `preview-house-2x.png`：房屋区域 2 倍放大，用来看瓦面、墙面、门窗口的细节。
- `preview-python.png`：不启 Godot 的纯 PIL 合图，只用于生成素材后快速自查构图。
- `walk-demo.gif` / `walk-demo.mp4`：行走 + 挥剑演示（30fps，60 帧 ≈ 2 秒），
  走位是脚本录的固定路线：右 → 右上 → 上 → 左 → 左下。

## 文件

| 文件 | 说明 |
| --- | --- |
| `previews/home_yard_preview.tscn` / `.gd` | 预览场景：读 `layout.json`，处理移动、碰撞、按 y 排序遮挡、截图与录像 |
| `assets/art/home_yard/ground.png` | 1280×800 地面：黄土、稀疏草滩、踩实院土、踏石小路、村道、6 块菜畦垄沟、树线、接触阴影 |
| `assets/art/home_yard/house.png` | 700×440 主角家：青瓦坡顶 + 瓦当 + 檐板 + 夯土墙 + 木构门窗 + 石台基 + 挂饰 |
| `assets/art/home_yard/tree_big.png` / `tree_small.png` | 250×300 / 168×210 两档树，冠层按椭球法线逐像素分六档 |
| `assets/art/home_yard/fence.png` / `gate.png` | 96×66 可平铺栅栏段、150×100 对开院门 |
| `assets/art/home_yard/crops_0..5.png` | 160×112 六种菜畦（苗、叶菜、葱、玉米、瓜架、空畦） |
| `assets/art/home_yard/prop_*.png` | 16 件独立道具（井、陶罐、柴堆、晾架、鸡、水桶、篮、凳、扫帚、草垛、石、箱、灌木、猫…），每件一张图 |
| `assets/art/home_yard/layout.json` | 摆放表：`objects[{tex,x,y,sort}]` + `colliders[[x,y,w,h]]`，`x,y` 是底部中心 |

## 素材规范

- 单色硬边像素，**所有颜色都在 `tools/pixel/scene_palette.py` 的材质梯里**（每种材质 3–7 档），
  生成时 `check()` 统计调色板外像素与半透明像素，必须为 0。
- 1:1 显示不缩放；站立物件一律**底部中心对齐**，`sort` 取脚底 y。
- **遮挡**：`sort` 小的先画，人物由场景在绘制时按自己的脚底 y 插进这个序列。
- **阴影**：大树、房屋、菜畦、栅栏的投影烘进 `ground.png`；小物件只留一圈接触影；
  人物阴影由宿主 `draw_ellipse_shadow()` 实时画。注意**不要用 `draw_set_transform` 缩放坐标系来压扁圆**——
  那样会把圆心也一起乘上缩放，阴影会飞到画面上方（这一版踩过）。

## 重新生成

```
python -m tools.build_home_yard          # 全部素材 + layout.json
python -m tools.scene_preview            # 不开 Godot 的快速合图
```

布局常量集中在 `tools/pixel/yard_layout.py`（房屋、菜畦网格、栅栏院门、道路、树木、道具、碰撞体），
改数值后重跑即可整体重排，Godot 侧不用动。

## 与参考图相比还没做到的

- 屋顶还是直坡，没有参考图那种明显的翘角与举折；墙面偏平，缺少真实的抹灰、雨痕层次。
- 菜畦的作物密度、树的枝叶穿插都比参考图简化。
- 只有这一栋房屋形制，没有做多套变体；地形的起伏、远处村落没做。
- 素材尚未接入 `world_layout.gd` 的正式地图（样板阶段刻意不动正式场景）。