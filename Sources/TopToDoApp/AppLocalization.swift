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

    var taskPoolTag: String {
        switch language {
        case .english:
            "Task Pool"
        case .simplifiedChinese:
            "任务池"
        case .traditionalChinese:
            "任務池"
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

    var taskPoolLimitTitle: String {
        switch language {
        case .english:
            "Task Pool is Full"
        case .simplifiedChinese:
            "任务池已满"
        case .traditionalChinese:
            "任務池已滿"
        }
    }

    var taskPoolLimitMessage: String {
        switch language {
        case .english:
            "Remove a task from Task Pool to make room."
        case .simplifiedChinese:
            "请先从任务池删除一个任务再继续。"
        case .traditionalChinese:
            "請先從任務池刪除一個任務再繼續。"
        }
    }

    var emptyTitleAlertTitle: String {
        switch language {
        case .english:
            "Title Required"
        case .simplifiedChinese:
            "需要标题"
        case .traditionalChinese:
            "需要標題"
        }
    }

    var emptyTitleAlertMessage: String {
        switch language {
        case .english:
            "A task can't be saved without a title. Add some text, or use the trash button to remove it."
        case .simplifiedChinese:
            "任务不能保存为空标题。请添加文字，或用删除按钮移除。"
        case .traditionalChinese:
            "任務不能保存為空標題。請添加文字，或用刪除按鈕移除。"
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

    var newTaskPoolTaskPlaceholder: String {
        switch language {
        case .english:
            "New task pool task"
        case .simplifiedChinese:
            "新增任务池任务"
        case .traditionalChinese:
            "新增任務池任務"
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

    var noTaskPoolTasksTitle: String {
        switch language {
        case .english:
            "No Task Pool tasks"
        case .simplifiedChinese:
            "暂无任务池任务"
        case .traditionalChinese:
            "暫無任務池任務"
        }
    }

    var noTaskPoolTasksDescription: String {
        switch language {
        case .english:
            "Create a task pool task above."
        case .simplifiedChinese:
            "在上方创建任务池任务。"
        case .traditionalChinese:
            "在上方建立任務池任務。"
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

    var moveToTaskPoolHelp: String {
        switch language {
        case .english:
            "Move to Task Pool"
        case .simplifiedChinese:
            "移至任务池"
        case .traditionalChinese:
            "移至任務池"
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

    var taskPoolFullHelp: String {
        switch language {
        case .english:
            "Task Pool is full"
        case .simplifiedChinese:
            "任务池已满"
        case .traditionalChinese:
            "任務池已滿"
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

    func taskPoolSummary(count: Int, limit: Int) -> String {
        switch language {
        case .english:
            "\(count)/\(limit) task pool tasks"
        case .simplifiedChinese:
            "\(count)/\(limit) 个任务池任务"
        case .traditionalChinese:
            "\(count)/\(limit) 個任務池任務"
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
