# DEVELOPMENT v0.28-visual — 按参考图重做的家园样板（分支 `deepseek/visual`）

> 这份说明只覆盖视觉工作（美术素材 + 预览场景 + 生成管线），不含玩法改动。
> 正式地图 `world_layout.gd`、`main.gd` 与全部玩法代码**一行未改**。

## 这一版做了什么

按参考图重做「主角家门口」这一屏：暖橙黄土院子、青灰筒瓦夯土大屋、木栅栏与院门、水井、
六块菜畦、树木与杂物，人物可以在里面走动，有碰撞，并按脚底 y 正确遮挡。

同时把美术生成管线从「一套人物调色板 + 场景色叠加」重构成**材质梯**：每种材质 3–7 档明暗，
所有素材都从同一套颜色派生，保证不同物件放在一起时明度关系一致。

## 主要内容

### 1. 主角逐帧精灵（v28）

- 3 张图集，单格 48×88，行序 = 朝向 下/左/右/上：
  `assets/art/hero_walk_v28.png`（4 帧）、`hero_attack_v28.png`（6 帧）、`hero_idle_v28.png`（4 帧）。
- 数据文件 `hero_anim_data.gd` 由 `tools/build_hero.py` 生成（手部锚点、刀光角度、帧数），**不要手改**。
- `actor_visual.gd` 已改为按帧取图，删除了原来的程序 IK 手臂；挥剑时的刀光轨迹用手部锚点连成折线。
- 重新生成：`python -m tools.build_hero`；预览：`python -m tools.preview_hero`。

### 2. 家园样板场景

- 预览场景：`previews/home_yard_preview.tscn` / `.gd`。WASD 或方向键移动，空格挥剑。
  碰撞体与摆放表都在 `assets/art/home_yard/layout.json` 里，场景不写死坐标。
- 素材全部在 `assets/art/home_yard/`，1:1 显示不缩放：`ground.png` 1280×800、`house.png` 700×440、
  两档树、栅栏与院门、六种菜畦、16 件独立道具（每件一张 PNG）。
- 截图：`previews/home_yard/preview.png`（实机 1280×800）、`preview-house-2x.png`（房屋 2 倍）；
  行走演示：`walk-demo.gif` / `walk-demo.mp4`（30fps，60 帧）。
- 说明文档：`previews/home_yard/README.md`（怎么看、文件表、素材规范、遮挡与阴影约定、未做到项）。

### 3. 生成器

| 文件 | 作用 |
| --- | --- |
| `tools/pixel/scene_palette.py` | 材质梯 `RAMPS` + `T(mat, level)`；`check()` 统计调色板外与半透明像素 |
| `tools/pixel/canvas.py` | 硬边像素画布（矩形/线/多边形/椭圆/挖洞/外描边/水平翻转/ASCII 预览） |
| `tools/pixel/yard_layout.py` | 一屏的布局常量：房屋、菜畦网格、栅栏院门、道路、树、道具、碰撞体 |
| `tools/pixel/yard_ground.py` | 地面：噪声地形、草滩、踩实院土、踏石小路、村道、菜畦垄沟、树线、接触阴影 |
| `tools/pixel/house_art.py` | 房屋：筒瓦坡顶、瓦当、檐板、夯土墙、木构门窗、石台基、挂饰 |
| `tools/pixel/props_art.py` | 树、栅栏、院门、菜畦、16 件道具 |
| `tools/build_home_yard.py` | 出全部素材 + `layout.json`（`--ascii` 可打印房屋草图） |
| `tools/scene_preview.py` | 不开 Godot，用 PIL 直接合成一屏，生成素材后快速自查 |
| `tools/inspect_yard.py` | 把截图按材质降采样成 ASCII 并统计用色占比，无图形界面时用来自查构图 |

```
python -m tools.build_home_yard
python -m tools.scene_preview
```

### 4. 文档

- 本文件；`previews/home_yard/README.md`；`README.md` 末尾新增「美术样品」小节。

## 验证

- 素材：全部 PNG 调色板外像素 0、无半透明像素。
- 运行：工作树 `changgeng-deepseek`（分支 `deepseek/visual`）内 headless 启动无脚本错误；
  预览场景窗口模式截图 `err=0 size=(1280, 800)`。
- 回归：32 个 `tests/*.gd` 全部 **PASS=32 FAIL=0**。
- 遮挡：人物按脚底 y 插入物件序列；站在栅栏北侧（y=620）时栅栏（y=706 底边）压住小腿。
- 阴影：房屋/树/菜畦/栅栏的投影已烘进 `ground.png`，素材内只保留小物件接触影，避免双层硬边褐盘。

## 已知不足 / 后续

- 屋顶仍是直坡，缺少参考图的翘角与举折；墙面偏平，抹灰与雨痕层次不足；菜畦密度与枝叶穿插比参考图简化。
- 只有一栋房屋形制，没有多套变体；地形起伏与远景村落未做。
- 样板尚未接入正式地图，`world_layout.gd` 的矢量场景仍在用。
- `tests/visual_geometry_v26.gd` 依赖 `actor_visual.frames` 每行 4 帧，改帧数前要先改测试。

## 与他人协作的注意

- `main.gd` 是交叉热点，visual 分支不要直接改；本次未改。
- `tests/**`、`COLLABORATION.md` 由 integration 主责；本次未改。
- 含中文的 `.gd`/`.md` 不要用 PowerShell `Get-Content | Set-Content` 改（会按 ANSI 读成乱码），
  用编辑器或 write/edit 工具。