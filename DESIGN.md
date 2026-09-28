---
name: Things Console
description: 个人物品管理工作台 · 沉稳可靠的私人 CFO 资产终端（macOS 原生 SwiftUI）
colors:
  state-inuse: "systemBlue (adaptive)"
  state-idle: "systemOrange (adaptive)"
  state-retired: "systemGray (adaptive)"
  alert-expired: "systemRed (adaptive)"
  alert-soon: "systemOrange (adaptive)"
  alert-grace: "systemYellow (adaptive)"
  feedback-success: "systemGreen (adaptive)"
  interactive-accent: "accentColor (system tint, adaptive)"
  surface: "background (semantic)"
  surface-secondary: "controlBackgroundColor (semantic)"
  surface-bar: "bar material (semantic)"
  hairline: "quaternary (semantic)"
typography:
  display:
    textStyle: "largeTitle"
    fontWeight: "bold"
    purpose: "每页唯一的主标题（资产看板 / 物品台账 / 库存与到期…）"
  headline:
    textStyle: "title2"
    fontWeight: "bold"
    purpose: "详情面板物品名 / sheet 大标题"
  section:
    textStyle: "title3"
    fontWeight: "bold"
    purpose: "面板内部标题（快速录入、分类管理）"
  row-title:
    textStyle: "headline"
    fontWeight: "semibold"
    purpose: "列表行 / 卡片行主文本"
  field:
    textStyle: "subheadline"
    fontWeight: "regular"
    purpose: "字段值、行内次要标题"
  label:
    textStyle: "caption"
    fontWeight: "regular"
    purpose: "字段名、辅助说明、元信息"
  micro:
    textStyle: "caption2"
    fontWeight: "medium"
    purpose: "徽章文字、计数"
  numeric:
    fontFeature: "monospacedDigit"
    purpose: "一切金额 / 数量 / 天数 / 计数，强制等宽数字"
rounded:
  thumb: "6px"
  control: "10px"
  card: "12px"
spacing:
  xs: "8px"
  sm: "12px"
  md: "16px"
  lg: "22px"
  page: "24px"
components:
  stat-card:
    backgroundColor: "{colors.surface}"
    rounded: "{rounded.card}"
    padding: "{spacing.md}"
  status-badge:
    textColor: "{colors.state-inuse}"
    rounded: "999px (Capsule)"
  groupbox-section:
    backgroundColor: "{colors.surface}"
    padding: "{spacing.sm}"
  quick-add-bar:
    backgroundColor: "{colors.surface-bar}"
    padding: "{spacing.sm}"
---

# Design System: Things Console

## 1. Overview

**Creative North Star: "私人 CFO 的资产终端"**

这套视觉系统的唯一使命是让"管资产"这件事变快、变可信。数字是主角——金额、数量、天数永远用等宽数字呈现，其余元素全部让位。界面完全建立在 macOS 原生控件与语义色之上（NavigationSplitView / GroupBox / 系统材质），**不重造任何标准控件**：熟悉感即信任感。装饰近乎为零；动效只用于状态反馈，不做仪式感。

本系统明确拒绝（见 PRODUCT.md 反参考）：**手账可爱风**（贴纸、手绘边框、彩色便签感）、**SaaS 仪表盘味**（渐变 KPI 卡、发光效果）、**企业 ERP 感**（复杂表单、深层菜单）。分类 emoji 是功能性识别符号（固定语义、全站一致），不是装饰。

**Key Characteristics:**
- 左侧菜单 + 右侧功能区的固定工作台结构，每屏指向一个动作
- 全语义系统色，深色模式零适配成本
- 等宽数字 + 徽章词汇表（状态三色、到期三级）贯穿所有页面
- 扁平优先：hairline 描边 + 极浅投影，无重阴影
- 录入路径 Keyboard-first：回车即存、默认值记忆

## 2. Colors

调色板就是 macOS 系统语义色本身——**禁止出现任何硬编码色值**，深浅色模式、系统强调色自动适配。

### Primary
- **Interactive Accent（accentColor，系统强调色）**: 仅用于主操作按钮、当前选中、聚焦指示、进度条。遵循"一条强调色规则"：任何一屏占比 ≤10%。

### Secondary
- **State Trio（状态三色）**: 在用 `systemBlue` / 闲置 `systemOrange` / 已退役 `systemGray`。只出现在 StatusBadge 与状态选择器中，不作他用。

### Tertiary
- **Alert Ladder（到期三级）**: 过期 `systemRed`（≤7 天也用红）/ 临期 `systemOrange`（8–30 天）/ 宽限 `systemYellow`（>30 天的提醒）。质保临期用橙。成功反馈（保存成功）用 `systemGreen`，仅限即时反馈，不做持久装饰。

### Neutral
- **Surface（`background`）**: 卡片与面板底色。
- **Surface Secondary（`controlBackgroundColor`）**: 缩略图占位、输入类内嵌底。
- **Surface Bar（`.bar` 材质）**: 极速录入栏、页脚计数条等"贴边"区域。
- **Hairline（`.quaternary`）**: 全部描边与分隔，0.5pt。
- **Text（`.primary` / `.secondary` / `.tertiary`）**: 文本层级一律用系统语义色，保证默认对比度达标。

### Named Rules
**The Semantic-Only Rule.** 禁止在任何 View 中出现硬编码 `Color(red:…)` / `#hex`。一切颜色必须来自系统语义色或 PRODUCT.md 认可的状态词汇表。审计测试：全局搜索 `Color(red:` 与 `#`，命中即为违规。

**The One Voice Rule.** 强调色只为主操作服务；一屏内如果有两个以上蓝色按钮，一定有一个是错的。

**The Badge-With-Text Rule.** 任何状态/预警徽章必须带文字（如「剩 3 天」「已过期 2 天」），永不单靠颜色传达。

## 3. Typography

**Display Font:** SF Pro（系统字体，随 Dynamic Type 缩放）
**Body Font:** SF Pro（同族，Product register 下单字族即正确）
**Numeric Font:** SF Pro + `monospacedDigit()` 修饰

**Character:** 单字族、紧层级（SwiftUI text style 天然 1.125–1.2 级差）、重字重对比。数字永远是等宽的——这是台账类工具的 typography 底线。

### Hierarchy
- **Display（`.largeTitle.bold()`）**: 每页唯一主标题。每屏最多一个。
- **Headline（`.title2.bold()`）**: 详情面板物品名、sheet 标题。
- **Section（`.title3.bold()`）**: 独立面板（快速录入、分类管理）的头部标题。
- **Row Title（`.headline`）**: 列表行、卡片行主文本（物品名）。
- **Field（`.subheadline`）**: 字段值、行内次级文本。
- **Label（`.caption`）**: 字段名、辅助说明；`.tertiary` 用于可消失的元信息。
- **Micro（`.caption2.weight(.medium)`）**: 徽章文字、胶囊计数。
- **Numeric（`monospacedDigit()`）**: 金额、数量、天数、统计值——无一例外。

### Named Rules
**The Mono-Digits Rule.** 任何呈现在界面上的数字，若可能参与对比或变化，必须 `monospacedDigit()`。审计测试：看板 KPI、徽章天数、数量 Stepper 逐个检查。

## 4. Elevation

扁平优先，混合策略：以 hairline 描边（`.quaternary`，0.5pt）划分层级，卡片允许一层**环境级极浅投影**（`black 5% opacity, radius 3, y=1`）暗示可点击的卡片性。无深阴影、无玻璃拟态、无发光。列表行用交替底色（`.inset(alternatesRowBackgrounds: true)`）而非分隔阴影。

### Shadow Vocabulary
- **Card Lift**（`black.opacity(0.05), radius: 3, y: 1`）: 仅用于看板 KPI 卡与列表卡片行；配合 0.5pt hairline 描边同时出现。
- **Flat（无阴影）**: 徽章、GroupBox 内部元素、表单控件、工具栏。

### Named Rules
**The Flat-By-Default Rule.** 阴影是卡片属性，不是层级属性。若一个元素不需要暗示"可点/可拖"，它不配阴影。

## 5. Components

组件词汇表刻意精简：同一职责只有一种画法，跨页面零例外。

### Buttons
- **Shape:** 系统默认圆角（约 6px），`.borderedProminent` 为唯一主按钮样式
- **Primary:** 每屏最多一个（保存 / 添加 / 立即备份），使用系统强调色
- **Secondary / Borderless:** 行内小操作（重命名、显示、+/-）一律 `.borderless`，不与主按钮争夺视线
- **Destructive:** role: `.destructive`，系统红；出现在 confirmationDialog，永不裸奔（删除必须有确认）

### Badges（签名组件）
- **StatusBadge:** Capsule，底色 = 状态色 14% opacity，文字 = 状态色，`.caption2.weight(.medium)`，文字 = 状态名
- **ExpiryBadge:** 同构，三级颜色按天数切换，文字永远带具体数字（「剩 3 天」「今天到期」「已过期 2 天」）
- **State:** 纯展示，无 hover 态

### Cards / Containers
- **Corner Style:** 卡片 12px（stat-card、计划卡），缩略图 6px，内嵌编辑行 10px
- **Background:** `.background` 语义底
- **Shadow Strategy:** 见 Elevation——Card Lift 仅限 KPI 卡与卡片行
- **Border:** 0.5pt `.quaternary` hairline，与阴影成对出现
- **Internal Padding:** 卡片 16px；GroupBox 内容 6–12px；页面级 padding 24px；分区间距 22px

### Inputs / Fields
- **Style:** 系统原生 TextField（`.roundedBorder` 在工具栏，Form 内用系统默认），永不自定义边框
- **Focus:** 系统焦点环；极速录入场景用 `@FocusState` 自动聚焦名称框
- **Error:** 表单校验错误用 `.caption` + `systemRed` 文本，紧贴字段下方；同时禁用保存按钮
- **Date Fields:** 可清除日期统一 `ClearableDateField` 模式（未设置 → 「未设置」按钮；已设置 → DatePicker + 清除 ×）

### Navigation
- **Style:** NavigationSplitView 两栏；侧边栏两个 Section（工作台 / 整理行动），`.sidebar` 样式，系统选中态
- **Detail:** 工具栏 `.unified`；主操作（新增 / 快速录入）居右 primaryAction 位

### Quick-Add Bar（签名组件）
台账底部的极速录入栏：`.bar` 材质、12px padding、bolt 图标 + plain TextField，回车提交。它是"快是有设计感的"原则的实体化——永远可见、永远可用、永远不弹层。

### Forms
- 统一 `Form` + `.formStyle(.grouped)`，Section 标题即分组名
- 新建与编辑共用同一表单（`ItemFormView(item:)` 区分），保存按钮文案随模式变化
- 必填缺失或校验失败 → 保存按钮 disabled，错误就地显示

## 6. Do's and Don'ts

### Do:
- **Do** 只用系统语义色：`systemBlue/Orange/Gray/Red/Yellow/Green` + `.primary/.secondary/.tertiary` 文本层级 + `.quaternary` 描边。
- **Do** 一切数字 `monospacedDigit()`，金额经 `MoneyFormat.yuan` 统一格式化。
- **Do** 每屏恰好一个 `.borderedProminent` 主按钮；行内小操作用 `.borderless`。
- **Do** 徽章永远带文字；删除永远走 confirmationDialog；空态永远给一条出路（录入按钮 / 清除过滤）。
- **Do** 复用既有组件词汇：StatusBadge、ExpiryBadge、PhotoThumbView、ClearableDateField、CategoryPicker——新页面先找现成的，再造新的。

### Don't:
- **Don't** 手账可爱风：贴纸、手绘边框、彩色便签感、无语义的 emoji 装饰（PRODUCT.md 反参考，原词引用）。
- **Don't** SaaS 仪表盘味：渐变 KPI 大数字卡、发光效果、装饰性图表、hero-metric 模板（大数字+小标签+渐变强调）。
- **Don't** 企业 ERP 感：为完备而完备的字段、深层嵌套菜单、超过一屏的表单。
- **Don't** 硬编码色值（`Color(red:…)` / `#hex`）——Semantic-Only Rule，审计可搜。
- **Don't** 重造原生控件：自定义开关、自绘滚动条、非标准模态；系统有的就用系统的。
- **Don't** 装饰性动效：无状态含义的动画、页面加载编排、弹跳曲线。动效只传达状态变化，150–250ms，跟随系统减弱动态设置。
- **Don't** 侧边彩条：任何卡片 / 列表行 / 提示条上 >1px 的 `border-left` 彩色强调条，出现即重写（用背景 tint 或前置图标替代）。
