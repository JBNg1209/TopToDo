import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case simplifiedChinese = "zh-Hans"
    case traditionalChinese = "zh-Hant"

    var id: String {
        rawValue
    }

    var displayName: String {
        switch self {
        case .english:
            "English"
        case .simplifiedChinese:
            "简体中文"
        case .traditionalChinese:
            "繁體中文"
        }
    }
}

struct AppStrings {
    let language: AppLanguage

    /// Brand slogan — kept identical across all supported languages on purpose.
    var slogan: String {
        "LESS IS MORE"
    }

    var todayTag: String {
        switch language {
        case .english:
            "Today Top5"
        case .simplifiedChinese:
            "今日 Top5"
        case .traditionalChinese:
            "今日 Top5"
        }
    }

    var backlogTag: String {
        switch language {
        case .english:
            "Backlog"
        case .simplifiedChinese:
            "长期清单"
        case .traditionalChinese:
            "長期清單"
        }
    }

    var languageLabel: String {
        switch language {
        case .english:
            "Language"
        case .simplifiedChinese:
            "语言"
        case .traditionalChinese:
            "語言"
        }
    }

    var fontSizeLabel: String {
        switch language {
        case .english:
            "Font Size"
        case .simplifiedChinese:
            "字体大小"
        case .traditionalChinese:
            "字體大小"
        }
    }

    var fontSizeSmall: String {
        switch language {
        case .english:
            "Small"
        case .simplifiedChinese:
            "小"
        case .traditionalChinese:
            "小"
        }
    }

    var fontSizeMedium: String {
        switch language {
        case .english:
            "Medium"
        case .simplifiedChinese:
            "中"
        case .traditionalChinese:
            "中"
        }
    }

    var fontSizeLarge: String {
        switch language {
        case .english:
            "Large"
        case .simplifiedChinese:
            "大"
        case .traditionalChinese:
            "大"
        }
    }

    var fontSizeExtraLarge: String {
        switch language {
        case .english:
            "Extra Large"
        case .simplifiedChinese:
            "特大"
        case .traditionalChinese:
            "特大"
        }
    }

    var okButton: String {
        switch language {
        case .english:
            "OK"
        case .simplifiedChinese:
            "好的"
        case .traditionalChinese:
            "好的"
        }
    }

    var todayLimitTitle: String {
        switch language {
        case .english:
            "Today is Full"
        case .simplifiedChinese:
            "今日已满"
        case .traditionalChinese:
            "今日已滿"
        }
    }

    var todayLimitMessage: String {
        switch language {
        case .english:
            "Complete or clear a task in Today Top5 to make room."
        case .simplifiedChinese:
            "请先完成或清空一个今日任务再继续。"
        case .traditionalChinese:
            "請先完成或清空一個今日任務再繼續。"
        }
    }

    var backlogLimitTitle: String {
        switch language {
        case .english:
            "Backlog is Full"
        case .simplifiedChinese:
            "长期清单已满"
        case .traditionalChinese:
            "長期清單已滿"
        }
    }

    var backlogLimitMessage: String {
        switch language {
        case .english:
            "Remove a task from Backlog to make room."
        case .simplifiedChinese:
            "请先删除一个长期任务再继续。"
        case .traditionalChinese:
            "請先刪除一個長期任務再繼續。"
        }
    }

    var newTodayTaskPlaceholder: String {
        switch language {
        case .english:
            "New today task"
        case .simplifiedChinese:
            "新增今日任务"
        case .traditionalChinese:
            "新增今日任務"
        }
    }

    var newBacklogTaskPlaceholder: String {
        switch language {
        case .english:
            "New long-term task"
        case .simplifiedChinese:
            "新增长期任务"
        case .traditionalChinese:
            "新增長期任務"
        }
    }

    var newButton: String {
        switch language {
        case .english:
            "New"
        case .simplifiedChinese:
            "新增"
        case .traditionalChinese:
            "新增"
        }
    }

    var todayResetNote: String {
        switch language {
        case .english:
            "Tasks on this page reset after midnight when you reopen or use the app. Move important unfinished tasks to Backlog."
        case .simplifiedChinese:
            "本页任务会在午夜后于下次打开或操作时自动清空。重要的未完成任务可移至长期清单。"
        case .traditionalChinese:
            "本頁任務會在午夜後於下次開啟或操作時自動清空。重要的未完成任務可移至長期清單。"
        }
    }

    var noTodayTasksTitle: String {
        switch language {
        case .english:
            "No Today tasks"
        case .simplifiedChinese:
            "暂无今日任务"
        case .traditionalChinese:
            "暫無今日任務"
        }
    }

    var noTodayTasksDescription: String {
        switch language {
        case .english:
            "Create a today task above."
        case .simplifiedChinese:
            "在上方创建今日任务。"
        case .traditionalChinese:
            "在上方建立今日任務。"
        }
    }

    var noBacklogTasksTitle: String {
        switch language {
        case .english:
            "No Backlog tasks"
        case .simplifiedChinese:
            "暂无长期任务"
        case .traditionalChinese:
            "暫無長期任務"
        }
    }

    var noBacklogTasksDescription: String {
        switch language {
        case .english:
            "Create a long-term task above."
        case .simplifiedChinese:
            "在上方创建长期任务。"
        case .traditionalChinese:
            "在上方建立長期任務。"
        }
    }

    var taskPlaceholder: String {
        switch language {
        case .english:
            "Task"
        case .simplifiedChinese:
            "任务"
        case .traditionalChinese:
            "任務"
        }
    }

    var markAsOpenHelp: String {
        switch language {
        case .english:
            "Mark as open"
        case .simplifiedChinese:
            "标记为未完成"
        case .traditionalChinese:
            "標記為未完成"
        }
    }

    var completeTaskHelp: String {
        switch language {
        case .english:
            "Complete task"
        case .simplifiedChinese:
            "完成任务"
        case .traditionalChinese:
            "完成任務"
        }
    }

    var deleteTaskHelp: String {
        switch language {
        case .english:
            "Delete task"
        case .simplifiedChinese:
            "删除任务"
        case .traditionalChinese:
            "刪除任務"
        }
    }

    var moveToBacklogHelp: String {
        switch language {
        case .english:
            "Move to Backlog"
        case .simplifiedChinese:
            "移至长期清单"
        case .traditionalChinese:
            "移至長期清單"
        }
    }

    var moveToTodayHelp: String {
        switch language {
        case .english:
            "Move to Today"
        case .simplifiedChinese:
            "移至今日"
        case .traditionalChinese:
            "移至今日"
        }
    }

    var todayFullForMoveHelp: String {
        switch language {
        case .english:
            "Today is full"
        case .simplifiedChinese:
            "今日已满"
        case .traditionalChinese:
            "今日已滿"
        }
    }

    var backlogFullHelp: String {
        switch language {
        case .english:
            "Backlog is full"
        case .simplifiedChinese:
            "长期清单已满"
        case .traditionalChinese:
            "長期清單已滿"
        }
    }

    func todaySummary(open: Int, completed: Int) -> String {
        switch language {
        case .english:
            "\(open) open, \(completed) completed today"
        case .simplifiedChinese:
            "\(open) 个未完成，\(completed) 个今日已完成"
        case .traditionalChinese:
            "\(open) 個未完成，\(completed) 個今日已完成"
        }
    }

    func backlogSummary(count: Int, limit: Int) -> String {
        switch language {
        case .english:
            "\(count)/\(limit) backlog tasks"
        case .simplifiedChinese:
            "\(count)/\(limit) 个长期任务"
        case .traditionalChinese:
            "\(count)/\(limit) 個長期任務"
        }
    }

    func todayTaskPlaceholder(index: Int) -> String {
        switch language {
        case .english:
            "Task \(index)"
        case .simplifiedChinese:
            "任务 \(index)"
        case .traditionalChinese:
            "任務 \(index)"
        }
    }
}
