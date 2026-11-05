# 协作说明 · 长庚·东沙旧事

三个 AI 各自在独立 worktree 里干活，共用同一个 Git 仓库与同一条基线。
`main` 是唯一的发布线，**只接收通过检查的改动**。

## 目录与角色

| 角色 | 分支 | 工作目录（工程同级） | 负责范围 |
|---|---|---|---|
| ChatGPT | `chatgpt/core` | `../changgeng-chatgpt` | 玩法与系统核心：时间/睡眠/周结算、农田、战斗、委托、商贸、合成、NPC 日程与好感、招募、存档结构 |
| DeepSeek | `deepseek/visual` | `../changgeng-deepseek` | 美术与表现：角色动画、场景绘制、UI 主题、像素材质与生成工具、预览图 |
| WorkBuddy | `workbuddy/integration` | `../changgeng-workbuddy` | 集成与工程：回归测试、碰撞/交互校验、Git 流程、打包发布、协作文档 |

## 文件归属（尽量避免同文件并发修改）

- **core 主责**：`main.gd` `life_cycle.gd` `farming.gd` `combat.gd` `commerce.gd`
  `commissions.gd` `commission_data.gd` `craft_catalog.gd` `craft_ui.gd` `cooking.gd`
  `equipment.gd` `gifting.gd` `recruitment.gd` `relationships.gd` `social_data.gd`
  `story_events.gd` `npc_life.gd` `frontier.gd` `weekly_chart.gd` `weekly_report.gd`
  `task_tracker.gd` `inventory_ui.gd` `inventory_profile.gd` `item_slot.gd`
  `bag_stacks.gd` `game_options.gd`
- **visual 主责**：`actor_visual.gd` `hero_anim_data.gd` `item_art.gd` `world_ground.gd`
  `world_layout.gd` `village_map.gd` `jade_theme.gd` `bronze_trim.gd`
  `assets/**` `previews/**` `tools/pixel/**` `tools/build_hero.py`
- **integration 主责**：`tests/**` `tools/package.ps1` `tools/run*.sh`
  `COLLABORATION.md` `.gitignore` `.gitattributes` `DEVELOPMENT-*.md` `README.md` `INSTALL.txt`
- `main.gd` 是交叉热点：visual 若需接入新绘制接口，先在 `workbuddy/integration` 里合，再由 core 统一改。

## 验收规则

1. 任何分支合入 `main` 前，必须在该分支工作目录内执行：

   ```bash
   bash tests/run_headless.sh
   ```

   判定：**32/32 通过**，且输出无 `SCRIPT ERROR` / `Assertion failed`。
2. 新增玩法的分支必须同时补一个 `tests/*.gd` 用例；只加代码不加用例的改动不合。
3. 改动 `world_layout.gd` 的坐标或碰撞数据，必须跑 `village_farm_v27.gd`、
   `gate_alignment_v251.gd`、`visual_geometry_v26.gd` 三个用例。
4. 涉及存档字段的改动，必须验证旧存档可读，并在 `DEVELOPMENT-vX.Y.md` 写明迁移规则。
5. 禁止 `git push --force`，禁止直接向 `main` 推提交；一律走分支合入。

## 本机运行须知

- 引擎二进制在 `.gitignore` 里，worktree 里用的是**目录联接**（junction）指回主工程的
  `engine/`，不需要各存一份。若联接失效，手动建一次即可。
- **本机安全策略禁止 Godot 进程写 AppData**，会直接段错误。运行前必须把用户目录
  指到工程内：`export APPDATA="$PWD\\_userdata"`（`tests/run_headless.sh` 已内置）。
- 图片目前用 `Image.load("res://...png")` 读原文件，能跑但**无法导出**（引擎会告警）。
  将来转导出流程前需改成 `Texture2D` 加载。

## 已知待办

- v0.28 角色图集行走帧：四个朝向第 2 帧与第 4 帧像素全同，只有 3 个独立姿势。
  根因在 `tools/pixel/hero.py` 的 `phase = [1,0,-1,0][index]`，建议第 4 帧对调手脚端点。
