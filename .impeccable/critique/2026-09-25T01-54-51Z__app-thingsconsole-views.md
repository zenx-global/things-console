---
target: 物品管理工作台视图 (app/ThingsConsole/Views)
total_score: 26
p0_count: 1
p1_count: 3
timestamp: 2026-09-25T01-54-51Z
slug: app-thingsconsole-views
---
# Things Console · UX 设计评审（app/ThingsConsole/Views）

Method: dual-agent (A: 设计评审子代理 · B: 确定性检测子代理) · 浏览器跳过（原生 App 无 HTML 入口，屏幕锁定）

## 设计健康分：26/40（Acceptable）

| # | 启发式 | 分 | 关键问题 |
|---|--------|----|---------|
| 1 | 系统状态可见性 | 3 | 写盘失败 try? 静默（ItemStore.swift:56-59） |
| 2 | 贴合真实世界 | 3 | CFO 词汇准确 |
| 3 | 用户控制与自由 | 2 | 无 Undo；表单 Esc 蒸发全部输入 |
| 4 | 一致性与标准 | 3 | 文件夹恢复无确认 vs 历史恢复有；.purple/.indigo 越界 |
| 5 | 错误预防 | 3 | canSave 门控、数量钳制、预设删除禁用 |
| 6 | 识别而非回忆 | 3 | 过滤器常驻、空值「—」 |
| 7 | 灵活与效率 | 3 | 回车连录成立；缺 ⌘N/⌘F |
| 8 | 美学与极简 | 3 | 看板一屏 6 语义色为密度峰值 |
| 9 | 错误恢复 | 1 | 损坏→静默空态→GC 删照片；失败提示无出路 |
| 10 | 帮助与文档 | 2 | tooltip 不全，无帮助入口 |

## 反模式判定

非 AI slop：零装饰动效、零硬编码色、不重造控件。KPI 4 连卡为 hero-metric 骨架的克制版残留。检测器（web 规则集）0 命中；grep：硬编码色 0、monospacedDigit 14、accessibilityLabel 0、borderedProminent 逐屏 1、无确认破坏性操作 4 条。A/B 独立命中同一批问题。

## 优先问题

- **[P0] 数据损坏级联灾难**：load() 解码失败静默为空（ItemStore.swift:51-53）→ collectGarbage 物理删除全部照片（:39-41）。修法：区分「不存在」与「解码失败」、解码成功才 GC、replaceAll 前自动快照。
- **[P1] 4 条破坏性路径无确认**：文件夹恢复全量替换（DataBackupView.swift:252-278）、删计划（PlanListView.swift:73-76）、删任务（PlanDetailView.swift:200,110）、清备注（PlanDetailView.swift:231-233）。修法：确认对话框 + 轻量 Undo。
- **[P1] 看板预警不可行动**：预警行无点击（DashboardView.swift:143-157）、「还有 N 项」死胡同（:135）。修法：行接详情 sheet、N 项跳库存页。
- **[P1] 可达性**：accessibilityLabel 0；勾选按钮读 SF Symbol 名（PlanDetailView.swift:138-142,198-206）；onTapGesture 卡片键盘不可达（PlanListView.swift:71 等）；进度四色无文字等价（PlanListView.swift:112-119）。
- **[P2] 效率与规模**：无 ⌘N/⌘F；PhotoThumbView 无缓存（PhotoThumbView.swift:30-34）；listBackups 全量解码（BackupService.swift:99）；超长名称挤出操作按钮（ItemLedgerView.swift:415）。

## Persona 红旗

- Alex：录入入口未全局化（三跳）；无 ⌘N；看板预警不可点。
- Sam：勾选读「circle.fill」；onTapGesture 卡片键盘不可达；进度四色无文字。
- Riley：坏字节→空台账→照片销毁；Esc 蒸发表单；200 字名称挤出按钮；缺 Photos/ 备份恢复后占位图无提示。
- 收拾房间单手录入者：极速栏只收名称，录完资产表全 0 元；删上一件要四步。

## 次要观察

计数口径不一（看板不含退役 vs 页脚含）；.purple/.indigo 越界；「完成」按钮两种画法；categoryBreakdown 104pt 截断+金额压缩；CategoryPicker 哨兵可冲突；listBackups 解码只为数数；快速录入无价格位。

## 启发性问题

1. 录入入口是否应全局化（⌘N / 看板快条）？
2. 「建议先备份」文案能否变成系统自动快照？
3. 看板预警终点是「被看见」还是「被处置」？
