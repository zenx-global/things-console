import Foundation

/// 根据所选方法论，生成对应的计划模板任务清单。
/// 这是 App「选方法论 → 生成模板」的核心。
enum TemplateGenerator {

    static func tasks(for methodologyId: String) -> [TemplateTask] {
        switch methodologyId {
        case "danshari":     return danshariTemplate()
        case "konmari":      return konmariTemplate()
        case "minimalism":   return minimalismTemplate()
        case "flylady":      return flyladyTemplate()
        case "zenhabits":    return zenhabitsTemplate()
        case "dostadning":   return dostadningTemplate()
        case "gtd":          return gtdTemplate()
        case "5s":           return s5Template()
        default:             return []
        }
    }

    // MARK: 断舍离 —— 区域流动式，每个区域含「需要·合适·舒服」三问
    private static func danshariTemplate() -> [TemplateTask] {
        let areas = ["玄关", "客厅", "卧室 / 衣柜", "厨房", "卫生间", "书房 / 工作区", "储物间", "数字空间（延伸）"]
        let hint = "三问：①对现在的我是否必要？②是否合适？③留着是否让我舒服？"
        var t: [TemplateTask] = []
        for area in areas {
            t.append(.init(id: "ds-\(area)-c", group: area, title: "把「\(area)」所有物品集中摊开", hint: "获得全局视野，才能做出判断"))
            t.append(.init(id: "ds-\(area)-j", group: area, title: "用「需要·合适·舒服」逐一审视 \(area) 物品", hint: hint))
            t.append(.init(id: "ds-\(area)-k", group: area, title: "处理 \(area) 不需要的物品（丢弃 / 转送 / 待定箱）", hint: "犹豫的放待定箱，设 3 个月期限"))
        }
        t.append(.init(id: "ds-maintain-1", group: "维持", title: "按 7·5·1 法则控制收纳总量", hint: "看不见 7 成 / 看得见 5 成 / 展示 1 成"))
        t.append(.init(id: "ds-maintain-2", group: "维持", title: "建立「一进一出」习惯", hint: "每买一件新，丢弃一件同类旧"))
        return t
    }

    // MARK: KonMari —— 五类别任务流
    private static func konmariTemplate() -> [TemplateTask] {
        let categories: [(String, String)] = [
            ("衣服", "👕"),
            ("书籍", "📚"),
            ("纸张文件", "📄"),
            ("杂物（小物件）", "🧰"),
            ("情感纪念品", "💝"),
        ]
        let hint = "把每一件拿在手上：它是否让我怦然心动？心动则留，不心动则感谢后放手。"
        var t: [TemplateTask] = []
        t.append(.init(id: "km-prep", group: "准备", title: "想象整理完成后的理想生活", hint: "先在脑海中描绘理想生活的画面"))
        for (cat, _) in categories {
            t.append(.init(id: "km-\(cat)-1", group: cat, title: "把所有「\(cat)」集中到一起", hint: "按类别而非场所，全同类集中"))
            t.append(.init(id: "km-\(cat)-2", group: cat, title: "逐件「心动判断」决定「\(cat)」去留", hint: hint))
            t.append(.init(id: "km-\(cat)-3", group: cat, title: "「\(cat)」折叠竖立收纳，固定归属", hint: "折成可站立的小方块，像书本竖排"))
        }
        t.append(.init(id: "km-end", group: "收尾", title: "为每件留下的物品固定「家」", hint: "用完归位，维持心动空间"))
        return t
    }

    // MARK: Minimalism —— 30 天递增挑战
    private static func minimalismTemplate() -> [TemplateTask] {
        let hint90 = "90/90 法则：过去 90 天用过吗？未来 90 天会用吗？都没有→清除。"
        var t: [TemplateTask] = []
        for day in 1...30 {
            t.append(.init(id: "mn-d\(day)",
                           group: "第 \(week(of: day)) 周",
                           title: "Day \(day)：丢弃 / 捐赠 \(day) 件物品",
                           hint: day % 5 == 0 ? hint90 : "扔 / 捐 / 卖 / 回收都算"))
        }
        t.append(.init(id: "mn-sum", group: "总结", title: "30 天累计清除清单复盘", hint: "回顾清除的 465 件，感受空间与心境的变化"))
        return t
    }

    private static func week(of day: Int) -> Int {
        ((day - 1) / 7) + 1
    }

    // MARK: FlyLady —— Baby Steps + 分区
    private static func flyladyTemplate() -> [TemplateTask] {
        var t: [TemplateTask] = []
        // 起点
        t.append(.init(id: "fl-start", group: "起点", title: "把厨房水槽洗干净到发亮（Shiny Sink）", hint: "整个家的锚点与心理胜利"))
        // Baby Steps 精选
        let steps: [(String, String)] = [
            ("第 1 天", "起床后立刻穿衣打扮（含鞋子）"),
            ("第 2 天", "重建水槽闪亮状态"),
            ("第 3 天", "查看日历 / 待办"),
            ("第 4 天", "15 分钟定时整理（任选一区）"),
            ("第 5 天", "建立睡前惯例"),
            ("第 6 天", "建立晨间惯例"),
            ("第 7 天", "每周回顾 + 奖励自己"),
        ]
        for (d, act) in steps {
            t.append(.init(id: "fl-bs-\(d)", group: "Baby Steps", title: "\(d)：\(act)", hint: "进步而非完美，15 分钟就好"))
        }
        // 分区
        let zones = ["入口 / 餐厅 / 客厅", "厨房", "浴室", "主卧 + 主浴", "其余卧室 / 走廊"]
        for z in zones {
            t.append(.init(id: "fl-z-\(z)", group: "每周分区", title: "深清区：\(z)", hint: "15 分钟定时，本周聚焦此区"))
        }
        t.append(.init(id: "fl-bless", group: "每周祝福", title: "Home Blessing：1 小时快速清洁", hint: "吸尘/拖地/换床单/擦镜面，每项 10 分钟"))
        return t
    }

    // MARK: Zen Habits —— 单习惯 + 桌面清空
    private static func zenhabitsTemplate() -> [TemplateTask] {
        var t: [TemplateTask] = []
        t.append(.init(id: "zh-habit", group: "本月核心习惯", title: "选定本月唯一核心习惯并坚持 30 天", hint: "贪多必败，一次只攻一个"))
        t.append(.init(id: "zh-mit", group: "MIT 每日三件事", title: "每天写下最重要的 1–3 件事并优先完成", hint: "Most Important Tasks"))
        // 桌面清空
        let deskSteps = [
            "清空桌面，只留必需品（电脑、灯、水杯）",
            "为每件物品固定归属",
            "工作结束时让桌面保持清爽",
            "数字桌面同步清空（隐藏图标、整理文件）",
        ]
        for (i, s) in deskSteps.enumerated() {
            t.append(.init(id: "zh-desk-\(i)", group: "桌面清空", title: s, hint: "物理整洁带来心理专注"))
        }
        t.append(.init(id: "zh-info", group: "信息节食", title: "批量处理收件箱，减少信息输入", hint: "定时集中处理，而非随时响应"))
        return t
    }

    // MARK: Döstädning —— 大件优先 + 四分类
    private static func dostadningTemplate() -> [TemplateTask] {
        let bigItems = ["没人穿的衣物 / 鞋", "不用的家具 / 家电", "过期的囤货", "不再使用的运动器材"]
        var t: [TemplateTask] = []
        t.append(.init(id: "do-mindset", group: "心态", title: "以「如果明天我走了」的视角开启整理", hint: "温柔释然，而非悲伤"))
        for item in bigItems {
            t.append(.init(id: "do-big-\(item)", group: "大件优先", title: "处理：\(item)", hint: "大件、低情感依恋，最易入手"))
        }
        for cat in ["保留", "捐赠", "出售", "丢弃"] {
            t.append(.init(id: "do-sort-\(cat)", group: "四分类处理", title: "整理「\(cat)」清单", hint: "给每件物品归入四分类之一"))
        }
        t.append(.init(id: "do-memory", group: "记忆物品", title: "处理照片 / 信件 / 礼物（传承与告别）", hint: "把有故事的送给会珍惜的人"))
        t.append(.init(id: "do-family", group: "与家人对话", title: "把整理决定讲给家人", hint: "减少身后纠纷，趁有能力时做"))
        return t
    }

    // MARK: GTD —— 数字杂物五步
    private static func gtdTemplate() -> [TemplateTask] {
        let scenes = [
            ("收件箱", "邮件 / 私信 / 通知清零"),
            ("下载文件夹", "清理并归档或删除"),
            ("桌面", "整理并保持清爽"),
            ("手机 App", "删除 3 个月未用的 App"),
            ("订阅与信息源", "取关 / 退订无用信息源"),
            ("云盘 / 文件", "建立标签与文件夹体系"),
        ]
        let twoMin = "2 分钟法则：能在 2 分钟内处理完的，立刻做。"
        var t: [TemplateTask] = []
        t.append(.init(id: "gtd-capture", group: "1 收集", title: "把散落的数字杂物全部集中", hint: "文件 / 截图 / 邮件 / 订阅，不遗漏"))
        for (scene, act) in scenes {
            t.append(.init(id: "gtd-\(scene)", group: "2 厘清 & 3 组织", title: "\(scene)：\(act)", hint: "判断保留 / 删除 / 归档 / 委派"))
        }
        t.append(.init(id: "gtd-review", group: "4 回顾", title: "设定每周固定时间回顾清理", hint: "保持系统完整可信"))
        t.append(.init(id: "gtd-2min", group: "工具", title: "应用「2 分钟法则」", hint: twoMin))
        return t
    }

    // MARK: 5S —— 五步标准化
    private static func s5Template() -> [TemplateTask] {
        var t: [TemplateTask] = []
        t.append(.init(id: "5s-1-a", group: "1S 整理", title: "把物品分为「在用 / 暂不用 / 完全不用」", hint: "果断舍弃不需要的"))
        t.append(.init(id: "5s-1-b", group: "1S 整理", title: "红牌作战：给疑似不要的物品贴红牌", hint: "集中暂存区，逾期未用即清"))
        t.append(.init(id: "5s-2-a", group: "2S 整顿", title: "三定：每类物品定类 / 定位 / 定量", hint: "目标 30 秒内找到任何一件物品"))
        t.append(.init(id: "5s-2-b", group: "2S 整顿", title: "目视化：加标签、定位线、颜色编码", hint: "让状态一目了然"))
        t.append(.init(id: "5s-3", group: "3S 清扫", title: "定期打扫；清扫即检查", hint: "发现潜在问题"))
        t.append(.init(id: "5s-4", group: "4S 清洁", title: "把规则固化成清单 / 制度", hint: "家庭会议达成共识"))
        t.append(.init(id: "5s-5", group: "5S 素养", title: "每日自律复盘，让整理成为习惯", hint: "PDCA 循环持续改进"))
        return t
    }
}
