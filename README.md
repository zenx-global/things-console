# diu-diu-diu · 断舍离计划助手

> 一个 macOS 原生 App：沉淀断舍离方法论语料，套用一种方法论，自动生成你的断舍离计划模板。

---

## 这是什么

`diu-diu-diu` 由两部分组成：

### ① 方法论语料库（`docs/`）
用 Markdown 沉淀 8 种主流「整理 / 精简生活」方法论，作为 App 的方法论底座，也可独立阅读：

| # | 方法论 | 一句话定位 |
|---|---|---|
| 00 | [总览与对比](./docs/00-总览与方法论对比.md) | 8 种方法论一览、如何选择 |
| 01 | [断舍离](./docs/01-断舍离.md) ⭐ | 通过整理物品来整理内心 |
| 02 | [KonMari 怦然心动](./docs/02-KonMari-怦然心动.md) | 一次性彻底整理，心动法则 |
| 03 | [极简主义 Minimalism](./docs/03-极简主义-Minimalism.md) | 用更少的东西过更有意义的生活 |
| 04 | [FlyLady](./docs/04-FlyLady-飞来飞去夫人.md) | 用小步骤建立家务惯例 |
| 05 | [Zen Habits](./docs/05-Zen-Habits-禅习惯.md) | 少即是多，一次一个习惯 |
| 06 | [瑞典式死亡整理](./docs/06-瑞典式死亡整理-Döstädning.md) | 以终局视角温柔减负 |
| 07 | [GTD（信息维度）](./docs/07-GTD-信息维度整理.md) | 清空大脑，整理数字杂物 |
| 08 | [5S 现场管理法](./docs/08-5S现场管理法.md) | 标准化空间管理闭环 |

### ② SwiftUI Mac App（`app/`）
核心功能：**选择一种方法论 → 自动生成对应的可执行计划模板**。

- **方法论**：浏览学习 8 种方法论
- **我的计划**：新建计划，选方法论生成模板任务清单，可勾选 / 编辑 / 加备注
- **仪表盘**：所有计划总览与进度统计

数据用 SwiftData 本地持久化，无需后端、无需联网。

---

## 技术栈

- **平台**：macOS 14+
- **框架**：Swift + SwiftUI + SwiftData
- **依赖**：纯原生，无第三方库

---

## 构建

```bash
bash app/build.sh        # 产出 app/build/DiuDiuDiu.app
open app/build/DiuDiuDiu.app
```

> **构建方式说明**：本机当前只有 Command Line Tools（无完整 Xcode），因此用
> `swiftc` 直接编译 SwiftUI 源码并手工组装 `.app` bundle（见 `app/build.sh`）。
> 装了完整 Xcode 后，可改用 `.xcodeproj` + `xcodebuild` 构建。

---

## 项目结构

```
diu-diu-diu/
├── README.md
├── docs/                  # 方法论语料库（Markdown）
│   ├── 00-总览与方法论对比.md
│   ├── 01-断舍离.md
│   └── …（共 9 篇）
└── app/                   # SwiftUI Mac App
    ├── build.sh           # 构建脚本（swiftc 编译 + 打包 .app）
    └── DiuDiuDiu/
        ├── DiuDiuDiuApp.swift
        ├── Models/        # 数据模型
        ├── Data/          # 内置方法论数据（驱动模板生成）
        └── Views/         # UI
```

---

## License

MIT
