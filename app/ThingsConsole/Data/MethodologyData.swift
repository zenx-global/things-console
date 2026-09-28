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
        philosophy: "断舍离源自瑜伽「断行·舍行·离行」。不是单纯扔东西，而是通过筛选物品，以「我」为主角、以「当下」为时间轴，重新审视自己与物品的关系，最终整理的是内心。无法舍弃往往是因为判断标准偏离到了「物品」（还能用）或「他人」（别人送的），而非「我」。",
        principles: [
            .init(id: "ds-1", title: "断", detail: "断绝不需要的东西进入生活（源头把关：不买、不收）"),
            .init(id: "ds-2", title: "舍", detail: "舍弃多余的废物，清理身边堆积的无用之物"),
            .init(id: "ds-3", title: "离", detail: "脱离对物品的执念，让自己处于宽敞自在的空间"),
            .init(id: "ds-4", title: "自我轴 + 当下时间轴", detail: "以「我」为主语问「我现在需不需要」，时间轴永远在「当下」，不纠结过去、不担忧未来"),
            .init(id: "ds-5", title: "需要·合适·舒服", detail: "只保留当下真正需要、觉得合适、感到舒服的物品，舍弃不需要、不合适、不舒服的"),
            .init(id: "ds-6", title: "七·五·一法则", detail: "看不见的收纳留 7 成、看得见的留 5 成、展示型留 1 成，留白即余裕"),
            .init(id: "ds-7", title: "一进一出", detail: "每买一件新东西，就必须丢弃一件同类旧物，用替换代替增加，防止反弹"),
            .init(id: "ds-8", title: "三分法分类", detail: "大→中→小分类，把同类物品集中摊开后再收纳"),
            .init(id: "ds-9", title: "三种关系", detail: "我↔物品、我↔空间、我↔他人——断舍离可从物品延伸到人际、信息、时间、情绪"),
            .init(id: "ds-10", title: "警惕「可惜」陷阱", detail: "「太贵了」「以后可能用」「别人送的」都是判断标准偏离到物品/他人的信号，要拉回「我」"),
            .init(id: "ds-11", title: "待定箱缓冲", detail: "犹豫的物品放待定箱并设期限（如 3 个月），到期仍未用到就处理"),
        ],
        templateTitle: "区域流动式减物清单",
        sources: [
            "《断舍离》— 山下英子",
            "维基百科·断舍离",
            "中国新闻网·什么是真正的断舍离",
            "诚品·8 周断舍离心法",
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
        philosophy: "整理的本质九成靠精神、一成靠技巧。把每件物品拿在手上，只留下让你怦然心动的；不心动的物品感谢后放手。主张一次性彻底整理完成，之后用简单收纳维持，达成戏剧性的蜕变。",
        principles: [
            .init(id: "km-1", title: "心动法则 Spark Joy", detail: "唯一判断标准：把物品拿在手上，感受它是否还让你怦然心动"),
            .init(id: "km-2", title: "下定决心一次性整理", detail: "整理是特殊事件而非日常琐事，一次性彻底做完，才能形成质变"),
            .init(id: "km-3", title: "先丢弃，后收纳", detail: "全部丢弃完成后，才开始收纳；否则边收边塞会反复"),
            .init(id: "km-4", title: "按类别而非场所", detail: "把全屋同类物品全部集中到一起处理，而不是一个房间一个房间收"),
            .init(id: "km-5", title: "五类别顺序", detail: "衣服→书籍→纸张→杂物→纪念品，情感依恋由弱到强，纪念品放最后"),
            .init(id: "km-6", title: "竖立收纳", detail: "衣物折成可站立的小方块，像书本一样竖排放进抽屉，一眼看全"),
            .init(id: "km-7", title: "感谢仪式", detail: "对丢弃的物品说「谢谢你、再见」，感恩它完成使命，降低情绪阻力"),
            .init(id: "km-8", title: "给每件物品一个「家」", detail: "固定归属，用完归位，维持心动空间"),
        ],
        templateTitle: "五类别心动整理任务流",
        sources: [
            "《怦然心动的人生整理魔法》— 近藤麻理惠",
            "konmari.com 官方方法",
            "Penguin — Six Basic Rules of Tidying",
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
        philosophy: "极简是工具而非目的，目的是腾出时间、精力、金钱给重要的事（健康、关系、热情、成长、贡献）。只保留为生活增加价值的物品、关系、承诺。Love People, Use Things——爱人，用物，而不是反过来。",
        principles: [
            .init(id: "mn-1", title: "增加价值判断", detail: "核心问句：这能为我的生活增加价值吗？不确定的用 90/90 二次过滤"),
            .init(id: "mn-2", title: "30 天极简游戏", detail: "第 N 天丢 N 件，30 天累计清除 465 件（1+2+…+30=465），找伙伴一起更有动力"),
            .init(id: "mn-3", title: "Packing Party 打包派对", detail: "全部装箱，只取每天真正要用的，一段时间后剩下就是可丢的"),
            .init(id: "mn-4", title: "90/90 法则", detail: "过去 90 天用过、未来 90 天会用到的才保留，经验法则"),
            .init(id: "mn-5", title: "边界而非数字", detail: "不规定「只拥有 N 件」，而是为每类物品设定个人边界"),
            .init(id: "mn-6", title: "20·20·20 紧急情整理", detail: "20 分钟内、花 20 美元以内、跑 20 分钟就能解决的小混乱，立刻处理"),
            .init(id: "mn-7", title: "维度延伸", detail: "极简不止物品，还包括数字、关系、承诺、财务、情绪等维度"),
        ],
        templateTitle: "30 天极简游戏",
        sources: [
            "The Minimalists — theminimalists.com",
            "The Minimalists — 30-Day Minimalism Game",
            "Business Insider — 30-day minimalism challenge",
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
        philosophy: "混乱不是因为你懒，而是因为没人教你方法。用小步骤建立日常惯例，把失控的家拉回基本受控。Fly 也解读为 Finally Loving Yourself——先照顾好自己（穿衣打扮、穿鞋），再打理家。做得不完美的家务仍然祝福了家人。",
        principles: [
            .init(id: "fl-1", title: "闪亮水槽 Shiny Sink", detail: "第一步永远是把厨房水槽洗干净到发亮，它是整个家的锚点与心理胜利"),
            .init(id: "fl-2", title: "15 分钟法则", detail: "上定时器，只做 15 分钟就停；降低阻力，累积远比想象有效"),
            .init(id: "fl-3", title: "Baby Steps 31 步", detail: "31 天每天只加一个小习惯，如第 1 天起床立刻穿衣打扮+擦水槽"),
            .init(id: "fl-4", title: "每周 5 分区", detail: "把家分 5 区（入口客厅/厨房/浴室/主卧/其余），每周深清一区，月度循环"),
            .init(id: "fl-5", title: "Home Blessing", detail: "每周 1 小时快速完成吸尘、拖地、换床单等 7 项基础清洁，每项 10 分钟"),
            .init(id: "fl-6", title: "Control Journal", detail: "家庭管理活页夹：每日惯例/每周分区/餐计划/联系人/应急清单"),
            .init(id: "fl-7", title: "穿鞋原则", detail: "白天穿系带鞋而非拖鞋，是「我处于工作状态」的心理开关"),
            .init(id: "fl-8", title: "进步而非完美", detail: "不要因追求完美而不开始；做了不完美的家务仍然有意义"),
        ],
        templateTitle: "31 步 Baby Steps + 分区轮转",
        sources: [
            "flylady.net 官网",
            "FlyLady — Baby Steps",
            "FlyLady — Zones",
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
        philosophy: "少即是多（The Power of Less）。通过减少干扰、聚焦本质获得改变。一次只培养一个习惯，小而持续的改变胜过宏大计划。用简单、正念、可持续的小习惯创造积极的人生改变。",
        principles: [
            .init(id: "zh-1", title: "一次一个习惯", detail: "贪多必败，每月只攻一个核心习惯，专注才能固化"),
            .init(id: "zh-2", title: "清空桌面", detail: "彻底清空桌面只留必需品，物理整洁直接带来心理专注"),
            .init(id: "zh-3", title: "MIT 每日要事", detail: "每天先确定最重要的 1–3 件事（Most Important Tasks），优先完成"),
            .init(id: "zh-4", title: "信息节食", detail: "减少信息输入、批量处理收件箱，不被消息牵着走"),
            .init(id: "zh-5", title: "Zen To Done (ZTD)", detail: "轻量任务系统 10 习惯：收集/处理/计划/行动/简单清单/组织/回顾/简化/常规化/寻找热情"),
            .init(id: "zh-6", title: "习惯回路", detail: "触发→行动→奖励→重复，用正念设计好习惯的回路"),
            .init(id: "zh-7", title: "设定边界", detail: "为工作、信息、承诺设限，少即是多"),
        ],
        templateTitle: "单习惯 + 桌面清空清单",
        sources: [
            "zenhabits.net",
            "《少做一点不会死 The Power of Less》— Leo Babauta",
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
        philosophy: "在自己尚有能力时主动整理、把遗物提前妥善处理，不给亲人留负担。以终局视角重新看待物品，反而是温柔、释然的过程，而非悲伤。这不是普通打扫，而是重审价值观、与记忆告别、与死亡建立健康关系。",
        principles: [
            .init(id: "do-1", title: "大件优先", detail: "从家具、家电等大件、低情感依恋物品入手，最易见效"),
            .init(id: "do-2", title: "四分类处理", detail: "保留 / 捐赠 / 出售 / 丢弃——给每件物品归入其一"),
            .init(id: "do-3", title: "记忆物品传承", detail: "照片、信件、礼物——重点是情绪处理，把有故事的主动送给会珍惜的人"),
            .init(id: "do-4", title: "适度保留，不必极简", detail: "留下让自己愉悦的东西，目标不是空无一物，而是清爽且可控"),
            .init(id: "do-5", title: "与家人对话", detail: "把丢弃/赠送的决定讲给家人，减少身后纠纷，趁有能力时做"),
            .init(id: "do-6", title: "趁有能力时做", detail: "年龄不是限制，越早开始越轻松；这也是人生阶段性盘点"),
        ],
        templateTitle: "大件优先 + 四分类清单",
        sources: [
            "《死前断舍离 The Gentle Art of Swedish Death Cleaning》— Margareta Magnusson",
            "Wikipedia — Swedish death cleaning",
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
        philosophy: "压力不来自任务本身，而来自任务在大脑里的混沌堆积。把未完成的事移出大脑，放进可信赖的外部系统，达到「心智如水（mind like water）」的状态。本篇把 GTD 映射到数字杂物整理。",
        principles: [
            .init(id: "gtd-1", title: "1 收集 Capture", detail: "把散落的文件/截图/邮件/订阅集中到一个收集箱，不遗漏"),
            .init(id: "gtd-2", title: "2 厘清 Clarify", detail: "逐条判断：这是什么？保留/删除/归档/委派？可行动则定下一步"),
            .init(id: "gtd-3", title: "3 组织 Organize", detail: "建立项目/下一步行动/日历/等待/参考资料/将来也许清单与标签体系"),
            .init(id: "gtd-4", title: "4 回顾 Reflect", detail: "每周固定时间回顾，清理收件箱、桌面、下载夹，保持系统可信"),
            .init(id: "gtd-5", title: "5 执行 Engage", detail: "按情境/时间/精力/优先级选择最重要的事去做"),
            .init(id: "gtd-6", title: "2 分钟法则", detail: "能在 2 分钟内做完的，立刻做，不进系统，避免堆积"),
            .init(id: "gtd-7", title: "清空收集箱", detail: "收集箱是中转站不是存储箱，必须定期清空到零"),
        ],
        templateTitle: "数字杂物五步整理清单",
        sources: [
            "《搞定 GTD》— David Allen",
            "滴答清单帮助中心·用 GTD 清空大脑",
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
        philosophy: "源自丰田生产方式（TPS），五个 S 构成「减量→定位→清洁→标准化→素养」的完整管理闭环，移植到个人 / 家庭空间同样有效。强调持续规范化，最终落到「人」的素养养成。",
        principles: [
            .init(id: "5s-1", title: "1S 整理 Seiri", detail: "区分要与不要，把物品分为在用/暂不用/完全不用，果断舍弃不需要的"),
            .init(id: "5s-2", title: "2S 整顿 Seiton", detail: "三定：定类、定位、定量，目标 30 秒内能找到任何一件物品"),
            .init(id: "5s-3", title: "3S 清扫 Seiso", detail: "清除脏污；清扫即检查，发现潜在问题"),
            .init(id: "5s-4", title: "4S 清洁 Seiketsu", detail: "把前 3S 固化为可视化的规则/清单/制度，家庭会议达成共识"),
            .init(id: "5s-5", title: "5S 素养 Shitsuke", detail: "全员自律，让整理从形式变习惯，提升个人品格"),
            .init(id: "5s-6", title: "红牌作战 Red Tag", detail: "给「疑似不要」的物品贴红牌，集中暂存区，设期限，逾期即清"),
            .init(id: "5s-7", title: "目视化管理", detail: "标签、定位线、颜色编码、看板，让状态一目了然"),
            .init(id: "5s-8", title: "PDCA 循环", detail: "5S 不是一次性大扫除，而是计划-执行-检查-改进的持续循环"),
        ],
        templateTitle: "五步标准化整理模板",
        sources: [
            "丰田生产方式 / 5S 现场管理法",
            "Wikipedia — 5S (methodology)",
            "河北省市场监管局·把 5S 管理应用于家庭",
        ]
    )
}
