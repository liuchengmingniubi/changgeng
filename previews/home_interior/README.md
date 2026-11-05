# 主角家室内（六张图拼装版）

用你给的六张 PNG（灶台、书桌、木床、石板地面、木箱、空屋外壳）拼出来的室内样板：
**素材一像素没重画**，只做了裁切、缩放、限色和拼装。
**不替换正式地图、不改玩法、`main.gd` 一行未动**，可以单独打开跑。

## 怎么看

```
engine\Godot_v4.3-stable_win64_console.exe --path . res://previews/home_interior_preview.tscn
```

操作：**WASD / 方向键**走动，**空格**挥剑。入口在下方中央的踏步处。

- 走到**桌子前面会被挡住**（碰撞），走不到桌子里面去。
- 从床的上方往下走会被床挡住，这时**床会盖住人物的腿**——按脚底 y 排序，人退到家具后面就被压住。
- 左右两侧墙壁、画面上下边缘都有碰撞，不会走出屋子。

截图与录像（必须窗口模式，headless 没有 GPU）：

```
engine\Godot_v4.3-stable_win64_console.exe --path . res://previews/home_interior_preview.tscn -- --shot=res://previews/home_interior/preview.png
engine\Godot_v4.3-stable_win64_console.exe --path . res://previews/home_interior_preview.tscn -- --demo=D:\tmp\frames --frames=230
```

- `preview.png`：1280×800 实机截图，主角站在门口踏步上。
- `preview-python.png`：不启 Godot 的纯 PIL 合图，改完素材后快速自查用。
- `walk-demo.gif` / `walk-demo.mp4`：进屋 → 顶到桌前停住 → 绕到左边 → 贴墙走 → 下移被床挡住，
  中间挥一次剑；30fps / 230 帧 ≈ 7.6 秒。

## 文件

| 文件 | 说明 |
| --- | --- |
| `previews/home_interior_preview.tscn` / `.gd` | 预览场景：读 `layout.json`，处理移动、碰撞、按 y 排序遮挡、截图与录像 |
| `assets/art/home_interior/wall.png` | 1280×344 后墙：从外壳图上段裁出来，含檐枋、格窗、夯土墙、石脚 |
| `assets/art/home_interior/ground.png` | 1280×800 地面：石板铺满下半屏 + 墙脚投影 + 家具接触影 + 窗光 + 四角压暗 |
| `assets/art/home_interior/bed.png` | 72×152 |
| `assets/art/home_interior/desk.png` | 156×108 |
| `assets/art/home_interior/chest.png` | 90×70 |
| `assets/art/home_interior/stove.png` | 180×98 |
| `assets/art/home_interior/steps.png` | 330×97 门口踏步（连两侧石座） |
| `assets/art/home_interior/layout.json` | 摆放表：`objects[{tex,x,y,sort}]` + `colliders[[x,y,w,h]]`，`x,y` 是底部中心 |
| `assets/art/home_interior/source/` | 六张原始 PNG（带 `.gdignore`，Godot 不导入），重新生成时用 |

## 素材规范

- **透明背景**：处理时先按 `alpha ≥ 128` 二值化求边界再裁切，用同一张遮罩做缩放后的 alpha，
  最后 `MinFilter(3)` 腐蚀 1 像素去掉羽化毛边。原图透明区残留的 RGB 不会被带进来。
  （直接用 `Image.getbbox()` 会把透明区里的 RGB 也算成内容，裁不干净——这一版踩过。）
- 每张图量化到 40 色（后墙/地面 56 色），`dither=NONE`，避免噪点。
- 1:1 显示不缩放；站立物件一律**底部中心对齐**，`sort` 取脚底 y。
- **遮挡**：`sort` 小的先画；人物绘制时按自己的脚底 y 插进这个序列。
- **阴影**：家具的接触影烘进 `ground.png`，人物阴影由宿主 `draw_ellipse_shadow()` 实时画。
  不要用 `draw_set_transform(..., Vector2(1, 0.4))` 压扁圆——圆心也会被乘进去，阴影会飞到画面上方。

## 比例

主角 88 像素高。床长 152、桌高 108、灶台高 98、木箱高 70——
床比人长、灶台到腰、箱子到膝盖，六张图缩到同一尺度后再摆，人物走进去不会显得过大或过小。

## 重新生成

```
python -m tools.build_interior          # 全部素材 + layout.json + PIL 合图
```

摆放常量集中在 `tools/build_interior.py` 的 `LAYOUT`（尺寸、底部中心坐标、碰撞 footprint），
改数值后重跑即可整体重排，Godot 侧不用动。

## 还没做到的

- 房间里只有四件家具，中场偏空；按「只用这六张图」的约束，没有补新素材。
- 地面是同一张石板平铺后纵向压缩，近处没有做更大的透视变化。
- 没有门窗开合、没有可交互物件，没接任务系统（按你的要求这一版不动）。
- 尚未接入 `main.gd` 的进屋流程，仍是独立预览场景。
