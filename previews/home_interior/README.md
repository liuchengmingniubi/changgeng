# 主角家室内（完整房间版）

用你给的十张 PNG（空屋外壳、石板地面、木床、书桌、木椅、木箱、灶台连备餐台、圆餐桌、遗书、油灯）拼出来的室内样板：
**素材一像素没重画**，只做了裁切、等比缩放、去毛边和拼装。
**不替换正式地图、不改玩法、`main.gd` 一行未动**，可以单独打开跑。

## 怎么看

```
engine\Godot_v4.3-stable_win64_console.exe --path . res://previews/home_interior_preview.tscn
```

操作：**WASD / 方向键**走动，**空格**挥剑。走到书桌前，屏幕提示「空格：阅读旧家书」，按空格打开遗书，再按空格合上。

- **入口**在下方中央的门洞，踏步连着门口；门洞左右是矮墙，人物走不出去。
- **碰墙会停**：贴住后墙/侧墙/家具时位移停止，走路动画也跟着停，不会原地踏步。
- **遮挡**按脚底 y 排序：人被家具挡住时家具压在人身上（站在书桌后方只剩头部露出，走到灶台/床后面同理）。
- **碰撞**按家具实际落地范围设，桌子、床、箱子、灶台、木椅、圆桌都进不去；中央通路始终留空。
- 书桌上的遗书、油灯跟着桌面一起排序，不单独挡人。

截图与录像（必须窗口模式，headless 没有 GPU）：

```
engine\Godot_v4.3-stable_win64_console.exe --path . res://previews/home_interior_preview.tscn -- --shot=res://previews/home_interior/preview.png
engine\Godot_v4.3-stable_win64_console.exe --path . res://previews/home_interior_preview.tscn -- --demo=D:\tmp\frames --frames=380
```

## 这一版改了什么

1. **恢复完整房间**：外壳整张按 0.82 缩到 1182×795 放在画面中央，切上下两片——`shell_back.png` 画在人后面（后墙、檐枋、两侧立柱），`shell_front.png` 画在人前面（前矮墙、门洞、台阶），人走到门口会被矮墙压住小腿。
2. **地面只从镂空处透出**：用外壳 alpha 做遮罩，房间与门洞以外保持暗底，墙脚不再出现黑断层（墙脚投影改成 34 行由 64 递减的暖色渐变）。
3. **取消纵向拉伸**：地面按等宽等比缩放到 1182，再裁一条；石板尺寸全屏一致，近处不再放大。
4. **家具靠墙**：床靠左墙、书桌靠后墙、灶台靠右墙、箱子在床尾；木椅在书桌右侧、圆桌在灶台前，中央留 R 形通路。
5. **新素材接入**：木椅 44×79、圆桌 104×104、遗书 38×28、油灯 26×24，都按原图宽高比换算（先定宽，高=宽×原高/原宽），原图透明留白去掉。
6. **透明边缘**：缩放前先预乘 alpha、缩完再反预乘（LANCZOS），alpha 阈值 110 二值化后 `MinFilter(3)` 腐蚀 1 像素。不再做调色板量化，保留原图层次。
7. **遗书阅读交互**：`layout.json` 的 `interact` 给出阅读范围与提示文字，正文沿用 `main.gd` 里「父母的遗书 · 剧情草稿」原文。

## 文件

| 文件 | 说明 |
| --- | --- |
| `previews/home_interior_preview.tscn` / `.gd` | 预览场景：读 `layout.json`，处理移动、碰撞、按 y 排序遮挡、阅读面板、截图与录像 |
| `assets/art/home_interior/shell_back.png` / `shell_front.png` | 外壳上下两片（1182×795 与 1182×448），前者在人后面、后者在人前面 |
| `assets/art/home_interior/ground.png` | 1280×800 地面：石板 + 墙脚投影 + 家具接触影 + 窗光 + 四角压暗 |
| `assets/art/home_interior/bed.png` | 72×141 |
| `assets/art/home_interior/desk.png` | 156×107 |
| `assets/art/home_interior/chair.png` | 44×79 |
| `assets/art/home_interior/chest.png` | 90×71 |
| `assets/art/home_interior/stove.png` | 180×99（灶台连备餐台，整张图） |
| `assets/art/home_interior/table.png` | 104×104 圆餐桌 |
| `assets/art/home_interior/letter.png` | 38×28 遗书（桌面件） |
| `assets/art/home_interior/lamp.png` | 26×24 油灯（桌面件） |
| `assets/art/home_interior/layout.json` | 摆放表：`room` / `frame` / `objects[{tex,x,y,sort}]` / `colliders` / `interact`，`x,y` 是底部中心 |
| `assets/art/home_interior/source/` | 十张原始 PNG（带 `.gdignore`，Godot 不导入），重新生成时用 |

截图与录像：

| 文件 | 说明 |
| --- | --- |
| `preview.png` | 1280×800 实机截图，主角站在门口 |
| `compare.png` | 同机位前后对比（上：改动前 / 下：改动后） |
| `preview-before.png` | 改动前的实机截图，留着做对比 |
| `preview-python.png` | 不启 Godot 的纯 PIL 合图，改完素材后快速自查 |
| `walk-demo.gif` / `walk-demo.mp4` | 进门 → 顶住书桌 → 读遗书 → 绕到桌后（遮挡）→ 横穿 → 顶住圆桌 → 走向灶台 |

## 素材规范

- **透明背景**：先按 `alpha ≥ 128` 二值化求边界再裁切（`Image.getbbox()` 会把透明区残留 RGB 也算成内容，裁不干净），用同一张遮罩做缩放后的 alpha，最后腐蚀 1 像素去羽化边。
- **预乘 alpha**：缩放前后预乘/反预乘，否则透明像素的 RGB 会渗进边缘变成黑边或光晕。
- 1:1 显示不缩放；站立物件一律**底部中心对齐**，`sort` 取脚底 y；桌面小件用 `sort = 桌面 y + 0.4/0.5` 保证压在桌面上。
- **遮挡**：`sort` 小的先画；人物按自己的脚底 y 插进这个序列，`shell_front` 固定画在最后。
- **阴影**：家具接触影烘进 `ground.png`，人物阴影由宿主 `draw_ellipse_shadow()` 实时画。
  不要用 `draw_set_transform(..., Vector2(1, 0.4))` 压扁圆——圆心也会被乘进去，阴影会飞到画面上方。

## 比例

主角 88 像素高（旧主角，仅作测试，没有为适配家具做任何拉伸）。
床长 141、书桌高 107、灶台高 99、圆桌 104、木椅 79、箱子 71——
床比人长、灶台到腰、箱子到膝盖，十张图缩到同一尺度后再摆，人走进去不会显得过大或过小。

## 重新生成

```
python -m tools.build_interior        # 全部素材 + layout.json + PIL 合图
python -m tools.compare_interior      # 前后对比图
```

摆放常量集中在 `tools/build_interior.py` 的 `LAYOUT`（尺寸、底部中心坐标、碰撞 footprint）与
`INTERACT`（交互范围），改数值后重跑即可整体重排，Godot 侧不用动。

## 还没做到的

- 没有门窗开合、没有床/箱子的使用交互，没接任务系统（按要求这一版不动）。
- 遗书只有阅读面板，尚未写回剧情状态。
- 尚未接入 `main.gd` 的进屋流程，仍是独立预览场景。
- 旧主角是临时测试素材，正式人物动画还在 `deepseek/visual` 的另一条线上。
