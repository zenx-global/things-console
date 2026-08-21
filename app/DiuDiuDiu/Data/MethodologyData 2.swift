import Foundation

/// 内置的 8 种方法论数据。与 docs/ 语料库一一对应。
enum MethodologyData {

    static let all: [Methodology] = [
        danshari, konmari, minimalism, flylady, zenhabits, dostadning, gtd, s5
    ]

    static func find(_ id: String) -> Methodology? {
        all.first { $0.id == id }
    }

    // MARK: 01 断舍离
    static let danshari = Methodology(
        id: "danshari",
        name: "断舍离",
        subtitle: "通过整理物品来整理内心",
        author: "山下英子",
        emoji: "🧘",
        criterion: "对「当下的我」是否必要 · 合适 · 舒服",
        audience: "想重新审视「自我与物品」关系的人",
        philosophy: "断舍离源自瑜伽「断行·舍行·离行」。不是单纯扔东西，而是通过筛选物品，以「我」为主角、以「当下」为时间轴，重新审视自己与物品的关系，最终整理的是内心。",
        principles: [
            .init(id: "ds-1", title: "断", detail: "断绝不需要的东西进入生活（源头把关：不买、不收）"),
            .init(id: "ds-2", title: "舍", detail: "舍弃多余的废物，清理身边堆积的无用之物"),
            .init(id: "ds-3", title: "离", detail: "脱离对物品的执念，让自己处于宽敞自在的空间"),
            .init(id: "ds-4", title: "自我轴 + 当下时间轴", detail: "以「我」为主语问「我现在需不需要」，时间轴永远在「当下」"),
            .init(id: "ds-5", title: "需要·合适·舒服", detail: "只保留当下真正需要、觉得合适、感到舒服的物品"),
            .init(id: "ds-6", title: "七·五·一法则", detail: "看不见的收纳留 7 成、看得见的留 5 成、展示型留 1 成，留白即余裕"),
            .init(id: "ds-7", title: "一进一出", detail: "每买一件新东西，就必须丢弃一件同类旧物，用替换代替增加"),
            .init(id: "ds-8", title: "三分法分类", detail: "大→中→小分类，把同类物品集中摊开后再收纳"),
        ],
        templateTitle: "区域流动式减物清单",
        sources: [
            "《断舍离》— 山下英子",
            "维基百科·断舍离",
        ]
    )

    // MARK: 02 KonMari
    static let konmari = Methodology(
        id: "konmari",
        name: "KonMari 怦然心动",
        subtitle: "一次性彻底整理，心动法则",
        author: "近藤麻理惠",
        emoji: "✨",
        criterion: "拿在手上，是否怦然心动（Spark Joy）",
        audience: "重视直觉、情感驱动，想要彻底蜕变的人",
        philosophy: "整理的本质九成靠精神、一成靠技巧。把每件物品拿在手上，只留下让你怦然心动的；不心动的物品感谢后放手。主张一次性彻底整理完成。",
        principles: [
            .init(id: "km-1", title: "心动法则", detail: "唯一判断标准：拿在手上是否还让你心动"),
            .init(id: "km-2", title: "先丢弃，后收纳", detail: "全部丢弃完成后再开始收纳"),
            .init(id: "km-3", title: "按类别而非场所", detail: "把同类物品全部集中到一起处理"),
            .init(id: "km-4", title: "竖立收纳", detail: "衣物折成可站立的小方块，像书本一样竖排放进抽屉"),
            .init(id: "km-5", title: "感谢仪式", detail: "对丢弃的物品说「谢谢你、再见」，降低情绪阻力"),
        ],
        templateTitle: "五类别心动整理任务流",
        sources: [
            "《怦然心动的人生整理魔法》— 近藤麻理惠",
            "konmari.com",
        ]
    )

    // MARK: 03 Minimalism
    static let minimalism = Methodology(
        id: "minimalism",
        name: "极简主义 Minimalism",
        subtitle: "用更少的东西过更有意义的生活",
        author: "The Minimalists",
        emoji: "⚪️",
        criterion: "是否为生活「增加价值」",
        audience: "喜欢游戏化、需要同伴监督的年轻人 / 转折期的人",
        philosophy: "极简是工具而非目的。只保留为生活增加价值的物品、关系、承诺，腾出时间精力给重要的事。",
        principles: [
            .init(id: "mn-1", title: "增加价值", detail: "判断语：这能为我的生活增加价值吗？"),
            .init(id: "mn-2", title: "30 天极简游戏", detail: "第 N 天丢 N 件，30 天累计清除 465 件"),
            .init(id: "mn-3", title: "Packing Party", detail: "全部装箱，只取每天要用的，剩下即丢弃"),
            .init(id: "mn-4", title: "90/90 法则", detail: "过去 90 天用过、未来 90 天会用到的才保留"),
        ],
        templateTitle: "30 天极简游戏",
        sources: [
            "The Minimalists — theminimalists.com",
        ]
    )

    // MARK: 04 FlyLady
    static let flylady = Methodology(
        id: "flylady",
        name: "FlyLady",
        subtitle: "用小步骤建立家务惯例",
        author: "Marla Cilley",
        emoji: "🧹",
        criterion: "进步而非完美（Progress, not perfection）",
        audience: "被家务长期压垮、时间碎片化的家庭 / 妈妈",
        philosophy: "混乱不是因为你懒，而是因为没人教你方法。用小步骤建立日常惯例，把失控的家拉回基本受控。",
        principles: [
            .init(id: "fl-1", title: "闪亮水槽", detail: "第一步永远是把厨房水槽洗干净到发亮，作为整个家的锚点"),
            .init(id: "fl-2", title: "15 分钟法则", detail: "上定时器，只做 15 分钟就停；累积远比想象有效"),
            .init(id: "fl-3", title: "Baby Steps", detail: "31 天每天只加一个小习惯"),
            .init(id: "fl-4", title: "每周分区", detail: "把家分 5 区，每周深清一区"),
            .init(id: "fl-5", title: "Home Blessing", detail: "每周 1 小时快速完成吸尘、拖地、换床单等基础清洁"),
        ],
        templateTitle: "31 步 Baby Steps + 分区轮转",
        sources: [
            "flylady.net",
        ]
    )

    // MARK: 05 Zen Habits
    static let zenhabits = Methodology(
        id: "zenhabits",
        name: "Zen Habits 禅习惯",
        subtitle: "少即是多，一次只培养一个习惯",
        author: "Leo Babauta",
        emoji: "🍃",
        criterion: "是否减少干扰、服务当下要事",
        audience: "桌面 / 数字信息混乱的知识工作者",
        philosophy: "少即是多。通过减少干扰、聚焦本质获得改变。一次只培养一个习惯，小而持续的改变胜过宏大计划。",
        principles: [
            .init(id: "zh-1", title: "一次一个习惯", detail: "贪多必败，每月只攻一个核心习惯"),
            .init(id: "zh-2", title: "清空桌面", detail: "彻底清空桌面只留必需品，物理整洁带来心理专注"),
            .init(id: "zh-3", title: "MIT", detail: "每天先确定最重要的 1–3 件事，优先完成"),
            .init(id: "zh-4", title: "信息节食", detail: "减少信息输入、批量处理收件箱"),
        ],
        templateTitle: "单习惯 + 桌面清空清单",
        sources: [
            "zenhabits.net",
        ]
    )

    // MARK: 06 Döstädning
    static let dostadning = Methodology(
        id: "dostadning",
        name: "瑞典式死亡整理 Döstädning",
        subtitle: "以终局视角温柔减负",
        author: "Margareta Magnusson",
        emoji: "🕊️",
        criterion: "「如果明天我走了，它还有意义吗」",
        audience: "中老年、或想以终局视角盘点人生的人",
        philosophy: "在自己尚有能力时主动整理、把遗物提前妥善处理，不给亲人留负担。以终局视角重新看待物品，是温柔释然的过程。",
        principles: [
            .init(id: "do-1", title: "大件优先", detail: "从家具等大件、低情感依恋物品入手"),
            .init(id: "do-2", title: "四分类处理", detail: "保留 / 捐赠 / 出售 / 丢弃"),
            .init(id: "do-3", title: "记忆物品传承", detail: "照片、信件、礼物——把有故事的送给会珍惜的人"),
            .init(id: "do-4", title: "适度保留", detail: "留下让自己愉悦的东西，不必极简，清爽且可控即可"),
            .init(id: "do-5", title: "与家人对话", detail: "把决定讲给家人，减少身后纠纷"),
        ],
        templateTitle: "大件优先 + 四分类清单",
        sources: [
            "《死前断舍离》— Margareta Magnusson",
        ]
    )

    // MARK: 07 GTD
    static let gtd = Methodology(
        id: "gtd",
        name: "GTD（信息维度）",
        subtitle: "清空大脑，整理数字杂物",
        author: "David Allen",
        emoji: "📥",
        criterion: "是什么 / 可行动吗 / 下一步是什么",
        audience: "信息过载、收件箱 / 下载夹 / 桌面长期爆炸的人",
        philosophy: "压力不来自任务本身，而来自任务在大脑里的混沌堆积。把未完成的事移出大脑，达到「心智如水」的状态。这里映射到数字杂物整理。",
        principles: [
            .init(id: "gtd-1", title: "收集", detail: "把散落的文件 / 截图 / 邮件 / 订阅集中"),
            .init(id: "gtd-2", title: "厘清", detail: "逐条判断：保留 / 删除 / 归档 / 委派"),
            .init(id: "gtd-3", title: "组织", detail: "建立文件夹 / 标签体系"),
            .init(id: "gtd-4", title: "回顾", detail: "定期清理收件箱、桌面、下载文件夹"),
            .init(id: "gtd-5", title: "2 分钟法则", detail: "能在 2 分钟内做完的，立刻做，不进系统"),
        ],
        templateTitle: "数字杂物五步整理清单",
        sources: [
            "《搞定 GTD》— David Allen",
        ]
    )

    // MARK: 08 5S
    static let s5 = Methodology(
        id: "5s",
        name: "5S 现场管理法",
        subtitle: "从减量到维持的标准化空间管理闭环",
        author: "丰田生产方式",
        emoji: "📐",
        criterion: "要与不要 + 三定（定位 / 定类 / 定量）",
        audience: "工程思维、想给空间标准化、家庭 / 团队协作的人",
        philosophy: "源自丰田生产方式，五个 S 构成「减量→定位→清洁→标准化→素养」的完整管理闭环，移植到个人 / 家庭空间同样有效。",
        principles: [
            .init(id: "5s-1", title: "1S 整理 Seiri", detail: "区分要与不要，果断舍弃不需要的"),
            .init(id: "5s-2", title: "2S 整顿 Seiton", detail: "三定：定类、定位、定量，30 秒内能找到任何一件物品"),
            .init(id: "5s-3", title: "3S 清扫 Seiso", detail: "清除脏污；清扫即检查，发现潜在问题"),
            .init(id: "5s-4", title: "4S 清洁 Seiketsu", detail: "把前 3S 固化为可视化的规则 / 清单"),
            .init(id: "5s-5", title: "5S 素养 Shitsuke", detail: "全员自律，让整理从形式变习惯"),
            .init(id: "5s-6", title: "红牌作战", detail: "给「疑似不要」的物品贴红牌，集中暂存，逾期即清"),
        ],
        templateTitle: "五步标准化整理模板",
        sources: [
            "丰田生产方式 / 5S 现场管理法",
        ]
    )
}
