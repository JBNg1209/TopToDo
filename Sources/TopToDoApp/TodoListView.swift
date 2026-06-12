import TopToDoCore
import SwiftUI

private enum TodoTag: String, CaseIterable, Identifiable {
    case today
    case taskPool

    var id: String {
        rawValue
    }

    func title(using strings: AppStrings) -> String {
        switch self {
        case .today:
            strings.todayTag
        case .taskPool:
            strings.taskPoolTag
        }
    }
}

private enum ReminderListKind {
    case today
    case taskPool
}

private struct ReminderEditorState: Identifiable {
    let listKind: ReminderListKind
    let taskID: UUID
    let taskTitle: String
    let existingAlarmAt: Date?

    var id: UUID {
        taskID
    }
}

struct TodoListView: View {
    @EnvironmentObject private var store: TodoStore
    @EnvironmentObject private var alarmScheduler: AlarmScheduler
    @AppStorage("appLanguageCode") private var selectedLanguageCode = AppLanguage.english.rawValue
    @AppStorage("appFontSizeRawValue") private var fontSizeRawValue: String = FontSize.medium.rawValue
    @Environment(\.fontScale) private var fontScale
    @State private var selectedTag: TodoTag = .today
    @State private var newTaskPoolTitle = ""
    @State private var newTodayTitle = ""
    @State private var showTodayLimitAlert = false
    @State private var showTaskPoolLimitAlert = false
    @State private var showEmptyTitleAlert = false
    @State private var editingTodayId: UUID?
    @State private var editingTaskPoolId: UUID?
    @State private var reminderEditor: ReminderEditorState?

    private var language: AppLanguage {
        AppLanguage(rawValue: selectedLanguageCode) ?? .english
    }

    private var fontSize: FontSize {
        FontSize(rawValue: fontSizeRawValue) ?? .medium
    }

    private var metrics: AppMetrics {
        AppMetrics(scale: fontScale)
    }

    private var languageSelection: Binding<AppLanguage> {
        Binding(
            get: { language },
            set: { selectedLanguageCode = $0.rawValue }
        )
    }

    private var alarmAlertBinding: Binding<AlarmPresentation?> {
        Binding(
            get: { alarmScheduler.presentedAlarm },
            set: { newValue in
                if newValue == nil {
                    alarmScheduler.dismissPresentedAlarm()
                }
            }
        )
    }

    private var strings: AppStrings {
        AppStrings(language: language)
    }

    private var visibleTodayItems: [TodoItem] {
        store.todayItems.filter { !$0.title.todoTrimmed.isEmpty }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: metrics.spaciousSpacing) {
            header
            tagPicker
            sloganBanner

            Group {
                switch selectedTag {
                case .today:
                    todayView
                case .taskPool:
                    taskPoolView
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .padding(20)
        .background(Color(nsColor: .windowBackgroundColor))
        .sheet(item: $reminderEditor) { editor in
            ReminderEditorSheet(
                editor: editor,
                strings: strings,
                metrics: metrics,
                onCancel: { reminderEditor = nil },
                onSave: { alarmAt in
                    applyReminder(alarmAt, for: editor)
                    reminderEditor = nil
                }
            )
        }
        .alert(strings.todayLimitTitle, isPresented: $showTodayLimitAlert) {
            Button(strings.okButton, role: .cancel) {}
        } message: {
            Text(strings.todayLimitMessage)
        }
        .alert(strings.taskPoolLimitTitle, isPresented: $showTaskPoolLimitAlert) {
            Button(strings.okButton, role: .cancel) {}
        } message: {
            Text(strings.taskPoolLimitMessage)
        }
        .alert(strings.emptyTitleAlertTitle, isPresented: $showEmptyTitleAlert) {
            Button(strings.okButton, role: .cancel) {}
        } message: {
            Text(strings.emptyTitleAlertMessage)
        }
        .alert(item: alarmAlertBinding) { alarm in
            Alert(
                title: Text(strings.reminderAlertTitle),
                message: Text(strings.reminderAlertMessage(taskTitle: alarm.taskTitle)),
                dismissButton: .default(Text(strings.okButton)) {
                    alarmScheduler.dismissPresentedAlarm()
                }
            )
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: metrics.spaciousSpacing) {
            VStack(alignment: .leading, spacing: metrics.tinySpacing) {
                Text(selectedTag.title(using: strings))
                    .font(.system(size: 28, weight: .bold))
                Text(summary)
                    .font(.system(size: metrics.bodySize))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            fontSizeMenu

            Menu {
                Picker(selection: languageSelection) {
                    ForEach(AppLanguage.allCases) { language in
                        Text(language.displayName).tag(language)
                    }
                } label: {
                    Text(strings.languageLabel)
                }
                .pickerStyle(.inline)
            } label: {
                Image(systemName: "globe")
                    .imageScale(.large)
                    .frame(width: 28, height: 28)
                    .contentShape(Rectangle())
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()
            .help(strings.languageLabel)
        }
    }

    private var fontSizeMenu: some View {
        Menu {
            Picker(selection: $fontSizeRawValue) {
                ForEach(FontSize.allCases) { size in
                    Text(size.label(using: strings)).tag(size.rawValue)
                }
            } label: {
                Text(strings.fontSizeLabel)
            }
            .pickerStyle(.inline)
        } label: {
            Image(systemName: "textformat.size")
                .imageScale(.large)
                .frame(width: 28, height: 28)
                .contentShape(Rectangle())
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
        .help(strings.fontSizeLabel)
    }

    private var tagPicker: some View {
        NativeSegmentedPicker(
            selection: $selectedTag,
            labels: TodoTag.allCases.map { $0.title(using: strings) },
            width: 260
        )
    }

    private var sloganBanner: some View {
        HStack(spacing: metrics.standardSpacing) {
            Rectangle()
                .fill(Color.secondary.opacity(0.25))
                .frame(height: 1)
            Text(strings.slogan)
                .font(.system(size: metrics.captionSize))
                .italic()
                .tracking(2)
                .foregroundStyle(.tertiary)
                .layoutPriority(1)
            Rectangle()
                .fill(Color.secondary.opacity(0.25))
                .frame(height: 1)
        }
    }

    private var todayView: some View {
        VStack(alignment: .leading, spacing: metrics.comfortableSpacing) {
            HStack(spacing: metrics.compactSpacing) {
                TextField(strings.newTodayTaskPlaceholder, text: $newTodayTitle)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: metrics.bodySize))
                    .onSubmit(addTodayTask)

                Button(action: addTodayTask) {
                    Label(strings.newButton, systemImage: "plus")
                        .font(.system(size: metrics.bodySize))
                }
                .buttonStyle(.borderedProminent)
                .disabled(newTodayTitle.todoTrimmed.isEmpty)
            }

            if visibleTodayItems.isEmpty {
                ContentUnavailableView(strings.noTodayTasksTitle, systemImage: "tray", description: Text(strings.noTodayTasksDescription))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: metrics.standardSpacing) {
                        ForEach(Array(visibleTodayItems.enumerated()), id: \.element.id) { index, item in
                            TodayTaskRow(
                                displayIndex: index,
                                itemCount: visibleTodayItems.count,
                                item: item,
                                strings: strings,
                                metrics: metrics,
                                editingId: $editingTodayId,
                                canMoveToTaskPool: store.taskPoolItems.count < TodoStore.taskPoolLimit,
                                onComplete: {
                                    store.toggleTodayItemCompletion(id: item.id)
                                },
                                onMoveToTaskPool: {
                                    if store.taskPoolItems.count >= TodoStore.taskPoolLimit {
                                        showTaskPoolLimitAlert = true
                                    } else {
                                        store.moveTodayItemToTaskPool(id: item.id)
                                    }
                                },
                                onToggleHighlight: {
                                    store.toggleTodayHighlight(id: item.id)
                                },
                                onMoveToTop: {
                                    store.moveTodayItemToTop(id: item.id)
                                },
                                onMoveUp: {
                                    store.moveTodayItemUp(id: item.id)
                                },
                                onMoveDown: {
                                    store.moveTodayItemDown(id: item.id)
                                },
                                onEditReminder: {
                                    reminderEditor = ReminderEditorState(
                                        listKind: .today,
                                        taskID: item.id,
                                        taskTitle: item.title.todoTrimmed,
                                        existingAlarmAt: item.alarmAt
                                    )
                                },
                                onClearReminder: {
                                    store.clearTodayAlarm(id: item.id)
                                },
                                onDelete: {
                                    store.clearTodayItem(id: item.id)
                                },
                                onEmptyCommitAttempt: { showEmptyTitleAlert = true }
                            )
                        }
                    }
                }
            }
        }
    }

    private var taskPoolView: some View {
        VStack(alignment: .leading, spacing: metrics.comfortableSpacing) {
            HStack(spacing: metrics.compactSpacing) {
                TextField(strings.newTaskPoolTaskPlaceholder, text: $newTaskPoolTitle)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: metrics.bodySize))
                    .onSubmit(addTaskPoolTask)

                Button(action: addTaskPoolTask) {
                    Label(strings.newButton, systemImage: "plus")
                        .font(.system(size: metrics.bodySize))
                }
                .buttonStyle(.borderedProminent)
                .disabled(newTaskPoolTitle.todoTrimmed.isEmpty)
            }

            if store.taskPoolItems.isEmpty {
                ContentUnavailableView(strings.noTaskPoolTasksTitle, systemImage: "tray", description: Text(strings.noTaskPoolTasksDescription))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: metrics.compactSpacing) {
                        ForEach(Array(store.taskPoolItems.enumerated()), id: \.element.id) { index, item in
                            TaskPoolTaskRow(
                                displayIndex: index,
                                itemCount: store.taskPoolItems.count,
                                item: item,
                                strings: strings,
                                metrics: metrics,
                                editingId: $editingTaskPoolId,
                                canMoveToToday: store.todayItems.contains(where: { $0.title.todoTrimmed.isEmpty }),
                                onComplete: {
                                    store.toggleTaskPoolItemCompletion(id: item.id)
                                },
                                onMoveToToday: {
                                    if store.todayItems.allSatisfy({ !$0.title.todoTrimmed.isEmpty }) {
                                        showTodayLimitAlert = true
                                    } else {
                                        store.moveTaskPoolItemToToday(id: item.id)
                                    }
                                },
                                onToggleHighlight: {
                                    store.toggleTaskPoolHighlight(id: item.id)
                                },
                                onMoveToTop: {
                                    store.moveTaskPoolItemToTop(id: item.id)
                                },
                                onMoveUp: {
                                    store.moveTaskPoolItemUp(id: item.id)
                                },
                                onMoveDown: {
                                    store.moveTaskPoolItemDown(id: item.id)
                                },
                                onEditReminder: {
                                    reminderEditor = ReminderEditorState(
                                        listKind: .taskPool,
                                        taskID: item.id,
                                        taskTitle: item.title.todoTrimmed,
                                        existingAlarmAt: item.alarmAt
                                    )
                                },
                                onClearReminder: {
                                    store.clearTaskPoolAlarm(id: item.id)
                                },
                                onDelete: {
                                    store.removeTaskPoolItem(id: item.id)
                                },
                                onEmptyCommitAttempt: { showEmptyTitleAlert = true }
                            )
                        }
                    }
                }
            }
        }
    }

    private var summary: String {
        switch selectedTag {
        case .today:
            strings.todaySummary(open: store.todaySummary.open, completed: store.todaySummary.completed)
        case .taskPool:
            strings.taskPoolSummary(count: store.taskPoolItems.count, limit: TodoStore.taskPoolLimit)
        }
    }

    private func addTaskPoolTask() {
        guard !newTaskPoolTitle.todoTrimmed.isEmpty else {
            return
        }

        if store.taskPoolItems.count >= TodoStore.taskPoolLimit {
            showTaskPoolLimitAlert = true
            return
        }

        guard let newItem = store.addTaskPoolItem(title: newTaskPoolTitle) else {
            return
        }

        newTaskPoolTitle = ""
        editingTaskPoolId = newItem.id
    }

    private func addTodayTask() {
        guard !newTodayTitle.todoTrimmed.isEmpty else {
            return
        }

        if visibleTodayItems.count >= store.todayLimit {
            showTodayLimitAlert = true
            return
        }

        guard let emptyItem = store.todayItems.first(where: { $0.title.todoTrimmed.isEmpty }) else {
            return
        }

        store.updateTodayTitle(id: emptyItem.id, title: newTodayTitle)
        newTodayTitle = ""
        editingTodayId = emptyItem.id
    }

    private func applyReminder(_ alarmAt: Date, for editor: ReminderEditorState) {
        switch editor.listKind {
        case .today:
            store.setTodayAlarm(id: editor.taskID, alarmAt: alarmAt)
        case .taskPool:
            store.setTaskPoolAlarm(id: editor.taskID, alarmAt: alarmAt)
        }
    }
}

private struct TodayTaskRow: View {
    let displayIndex: Int
    let itemCount: Int
    let item: TodoItem
    let strings: AppStrings
    let metrics: AppMetrics
    @Binding var editingId: UUID?
    @EnvironmentObject private var store: TodoStore
    @State private var title: String = ""
    @State private var isEditing: Bool = false
    let canMoveToTaskPool: Bool
    let onComplete: () -> Void
    let onMoveToTaskPool: () -> Void
    let onToggleHighlight: () -> Void
    let onMoveToTop: () -> Void
    let onMoveUp: () -> Void
    let onMoveDown: () -> Void
    let onEditReminder: () -> Void
    let onClearReminder: () -> Void
    let onDelete: () -> Void
    let onEmptyCommitAttempt: () -> Void

    var body: some View {
        HStack(spacing: metrics.compactSpacing) {
            completionButton

            EditableTaskTitle(
                placeholder: strings.todayTaskPlaceholder(index: displayIndex + 1),
                title: $title,
                isCompleted: item.isCompleted,
                isHighlighted: item.isHighlighted,
                metrics: metrics,
                isEditing: $isEditing,
                onCommit: commitEdit
            )

            reminderStatus

            visibleActions

            TaskMoreMenu(
                strings: strings,
                canMoveUp: displayIndex > 0,
                canMoveDown: displayIndex < itemCount - 1,
                hasAlarm: item.alarmAt != nil,
                onMoveUp: onMoveUp,
                onMoveDown: onMoveDown,
                onEditReminder: onEditReminder,
                onClearReminder: onClearReminder,
                onDelete: onDelete
            )
        }
        .frame(height: metrics.rowHeight)
        .onAppear {
            title = item.title
            if editingId == item.id {
                isEditing = true
            }
        }
        .onChange(of: item.title) { _, newValue in
            title = newValue
        }
        .onChange(of: isEditing) { _, newValue in
            if !newValue {
                if title.todoTrimmed.isEmpty {
                    isEditing = true
                    onEmptyCommitAttempt()
                    return
                }
                if editingId == item.id {
                    editingId = nil
                }
                commitEdit()
            }
        }
    }

    private var completionButton: some View {
        Button(action: onComplete) {
            Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(item.isCompleted ? .green : .secondary)
        }
        .buttonStyle(.plain)
        .help(item.isCompleted ? strings.markAsOpenHelp : strings.completeTaskHelp)
    }

    private var visibleActions: some View {
        HStack(spacing: metrics.tinySpacing) {
            HoverHelpIconButton(
                helpText: canMoveToTaskPool ? strings.moveToTaskPoolHelp : strings.taskPoolFullHelp,
                isEnabled: canMoveToTaskPool,
                label: {
                    Image(systemName: "arrow.right")
                },
                action: {
                    onMoveToTaskPool()
                }
            )

            Button(action: onToggleHighlight) {
                Image(systemName: item.isHighlighted ? "flag.fill" : "flag")
                    .foregroundStyle(item.isHighlighted ? Color.red : Color.secondary)
            }
            .buttonStyle(.borderless)
            .help(item.isHighlighted ? strings.removeHighlightHelp : strings.highlightTaskHelp)

            Button(action: onMoveToTop) {
                Image(systemName: "arrow.up.to.line")
            }
            .buttonStyle(.borderless)
            .disabled(displayIndex == 0)
            .help(strings.pinTaskHelp)
        }
    }

    @ViewBuilder
    private var reminderStatus: some View {
        if let alarmAt = item.alarmAt {
            Image(systemName: "bell.fill")
                .font(.system(size: max(10, metrics.captionSize)))
                .foregroundStyle(.orange)
                .frame(width: 16)
                .padding(.trailing, metrics.standardSpacing)
                .help("\(strings.reminderSetHelp) · \(alarmAt.formatted(date: .abbreviated, time: .shortened))")
        }
    }

    private func commitEdit() {
        if title != item.title {
            store.updateTodayTitle(id: item.id, title: title)
        }
    }
}

private struct TaskPoolTaskRow: View {
    let displayIndex: Int
    let itemCount: Int
    let item: TodoItem
    let strings: AppStrings
    let metrics: AppMetrics
    @Binding var editingId: UUID?
    @EnvironmentObject private var store: TodoStore
    @State private var title: String = ""
    @State private var isEditing: Bool = false
    let canMoveToToday: Bool
    let onComplete: () -> Void
    let onMoveToToday: () -> Void
    let onToggleHighlight: () -> Void
    let onMoveToTop: () -> Void
    let onMoveUp: () -> Void
    let onMoveDown: () -> Void
    let onEditReminder: () -> Void
    let onClearReminder: () -> Void
    let onDelete: () -> Void
    let onEmptyCommitAttempt: () -> Void

    var body: some View {
        HStack(spacing: metrics.compactSpacing) {
            completionButton

            EditableTaskTitle(
                placeholder: strings.taskPlaceholder,
                title: $title,
                isCompleted: item.isCompleted,
                isHighlighted: item.isHighlighted,
                metrics: metrics,
                isEditing: $isEditing,
                onCommit: commitEdit
            )

            reminderStatus

            visibleActions

            TaskMoreMenu(
                strings: strings,
                canMoveUp: displayIndex > 0,
                canMoveDown: displayIndex < itemCount - 1,
                hasAlarm: item.alarmAt != nil,
                onMoveUp: onMoveUp,
                onMoveDown: onMoveDown,
                onEditReminder: onEditReminder,
                onClearReminder: onClearReminder,
                onDelete: onDelete
            )
        }
        .frame(height: metrics.rowHeight)
        .onAppear {
            title = item.title
            if editingId == item.id {
                isEditing = true
            }
        }
        .onChange(of: item.title) { _, newValue in
            title = newValue
        }
        .onChange(of: isEditing) { _, newValue in
            if !newValue {
                if title.todoTrimmed.isEmpty {
                    isEditing = true
                    onEmptyCommitAttempt()
                    return
                }
                if editingId == item.id {
                    editingId = nil
                }
                commitEdit()
            }
        }
    }

    private var completionButton: some View {
        Button(action: onComplete) {
            Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(item.isCompleted ? .green : .secondary)
        }
        .buttonStyle(.plain)
        .help(item.isCompleted ? strings.markAsOpenHelp : strings.completeTaskHelp)
    }

    private var visibleActions: some View {
        HStack(spacing: metrics.tinySpacing) {
            HoverHelpIconButton(
                helpText: canMoveToToday ? strings.moveToTodayHelp : strings.todayFullForMoveHelp,
                isEnabled: canMoveToToday,
                label: {
                    Image(systemName: "arrow.left")
                },
                action: {
                    onMoveToToday()
                }
            )

            Button(action: onToggleHighlight) {
                Image(systemName: item.isHighlighted ? "flag.fill" : "flag")
                    .foregroundStyle(item.isHighlighted ? Color.red : Color.secondary)
            }
            .buttonStyle(.borderless)
            .help(item.isHighlighted ? strings.removeHighlightHelp : strings.highlightTaskHelp)

            Button(action: onMoveToTop) {
                Image(systemName: "arrow.up.to.line")
            }
            .buttonStyle(.borderless)
            .disabled(displayIndex == 0)
            .help(strings.pinTaskHelp)
        }
    }

    @ViewBuilder
    private var reminderStatus: some View {
        if let alarmAt = item.alarmAt {
            Image(systemName: "bell.fill")
                .font(.system(size: max(10, metrics.captionSize)))
                .foregroundStyle(.orange)
                .frame(width: 16)
                .padding(.trailing, metrics.standardSpacing)
                .help("\(strings.reminderSetHelp) · \(alarmAt.formatted(date: .abbreviated, time: .shortened))")
        }
    }

    private func commitEdit() {
        if title != item.title {
            store.updateTaskPoolTitle(id: item.id, title: title)
        }
    }
}

private struct EditableTaskTitle: View {
    let placeholder: String
    @Binding var title: String
    let isCompleted: Bool
    let isHighlighted: Bool
    let metrics: AppMetrics
    @Binding var isEditing: Bool
    let onCommit: () -> Void

    @FocusState private var internalFocus: Bool

    private var titleColor: Color {
        if title.isEmpty {
            return .secondary
        }

        if isHighlighted {
            return isCompleted ? Color.red.opacity(0.7) : .red
        }

        return isCompleted ? .secondary : .primary
    }

    var body: some View {
        Group {
            if isEditing {
                TextField(placeholder, text: $title)
                    .focused($internalFocus)
                    .textFieldStyle(.plain)
                    .font(.system(size: metrics.bodySize))
                    .strikethrough(isCompleted)
                    .foregroundStyle(titleColor)
                    .onSubmit {
                        finishEditing()
                    }
                    .task {
                        try? await Task.sleep(for: .milliseconds(20))
                        if isEditing, !internalFocus {
                            internalFocus = true
                        }
                    }
            } else {
                Text(title.isEmpty ? placeholder : title)
                    .lineLimit(1)
                    .font(.system(size: metrics.bodySize))
                    .foregroundStyle(titleColor)
                    .strikethrough(isCompleted)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .layoutPriority(1)
                .contentShape(Rectangle())
                .onTapGesture {
                    isEditing = true
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: metrics.minEditHeight, alignment: .leading)
        .onChange(of: isEditing) { _, newValue in
            internalFocus = newValue
        }
        .onChange(of: internalFocus) { _, newValue in
            if !newValue, isEditing {
                isEditing = false
            }
        }
    }

    private func finishEditing() {
        onCommit()
        isEditing = false
    }
}

private struct TaskMoreMenu: View {
    let strings: AppStrings
    let canMoveUp: Bool
    let canMoveDown: Bool
    let hasAlarm: Bool
    let onMoveUp: () -> Void
    let onMoveDown: () -> Void
    let onEditReminder: () -> Void
    let onClearReminder: () -> Void
    let onDelete: () -> Void

    var body: some View {
        Menu {
            Button(strings.setReminderAction, action: onEditReminder)

            if hasAlarm {
                Button(strings.clearReminderAction, action: onClearReminder)
            }

            Divider()

            Button(strings.moveUpAction, action: onMoveUp)
                .disabled(!canMoveUp)
            Button(strings.moveDownAction, action: onMoveDown)
                .disabled(!canMoveDown)

            Divider()

            Button(strings.deleteTaskHelp, role: .destructive, action: onDelete)
        } label: {
            Image(systemName: "ellipsis.circle")
                .imageScale(.medium)
                .frame(width: 22, height: 22)
                .contentShape(Rectangle())
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
        .help(strings.moreActionsHelp)
    }
}

private struct HoverHelpIconButton<Label: View>: View {
    let helpText: String
    let isEnabled: Bool
    @ViewBuilder let label: () -> Label
    let action: () -> Void

    private let hitSize: CGFloat = 30

    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.primary.opacity(0.001))

            Button(action: action) {
                label()
            }
            .buttonStyle(.borderless)
            .disabled(!isEnabled)

            if !isEnabled {
                Color.clear
            }
        }
        .frame(width: hitSize, height: hitSize)
        .contentShape(Rectangle())
        .help(helpText)
    }
}

private struct ReminderEditorSheet: View {
    let editor: ReminderEditorState
    let strings: AppStrings
    let metrics: AppMetrics
    let onCancel: () -> Void
    let onSave: (Date) -> Void

    @State private var selectedYear: Int
    @State private var selectedMonth: Int
    @State private var selectedDay: Int
    @State private var selectedHour: Int
    @State private var selectedMinute: Int

    private let calendar: Calendar

    init(
        editor: ReminderEditorState,
        strings: AppStrings,
        metrics: AppMetrics,
        onCancel: @escaping () -> Void,
        onSave: @escaping (Date) -> Void
    ) {
        self.editor = editor
        self.strings = strings
        self.metrics = metrics
        self.onCancel = onCancel
        self.onSave = onSave
        let calendar = Calendar.current
        self.calendar = calendar
        let initialDate = Self.normalizedReminderDate(
            from: editor.existingAlarmAt ?? Date().addingTimeInterval(60 * 60),
            calendar: calendar
        )
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: initialDate)
        _selectedYear = State(initialValue: components.year ?? 2026)
        _selectedMonth = State(initialValue: components.month ?? 1)
        _selectedDay = State(initialValue: components.day ?? 1)
        _selectedHour = State(initialValue: components.hour ?? 0)
        _selectedMinute = State(initialValue: components.minute ?? 0)
    }

    private var yearRange: [Int] {
        let currentYear = calendar.component(.year, from: Date())
        return Array(currentYear ... (currentYear + 5))
    }

    private var dayRange: [Int] {
        let dayCount = calendar.range(
            of: .day,
            in: .month,
            for: calendar.date(from: DateComponents(year: selectedYear, month: selectedMonth, day: 1)) ?? Date()
        )?.count ?? 31
        return Array(1 ... dayCount)
    }

    private var minuteOptions: [Int] {
        Array(stride(from: 0, through: 55, by: 5))
    }

    private var composedDate: Date? {
        calendar.date(
            from: DateComponents(
                year: selectedYear,
                month: selectedMonth,
                day: min(selectedDay, dayRange.count),
                hour: selectedHour,
                minute: selectedMinute
            )
        )
    }

    private var canSave: Bool {
        guard let composedDate else {
            return false
        }

        return composedDate > Date()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: metrics.spaciousSpacing) {
            Text(strings.reminderEditorTitle)
                .font(.system(size: 20, weight: .semibold))

            Text(editor.taskTitle)
                .font(.system(size: metrics.bodySize))
                .foregroundStyle(.secondary)
                .lineLimit(2)

            Text(strings.reminderDateLabel)
                .font(.system(size: metrics.bodySize, weight: .medium))

            HStack(spacing: metrics.compactSpacing) {
                reminderPicker(title: strings.reminderYearLabel, selection: $selectedYear, options: yearRange) { year in
                    "\(year)"
                }
                reminderPicker(title: strings.reminderMonthLabel, selection: $selectedMonth, options: Array(1 ... 12)) { month in
                    "\(month)"
                }
                reminderPicker(title: strings.reminderDayLabel, selection: $selectedDay, options: dayRange) { day in
                    "\(day)"
                }
            }

            HStack(spacing: metrics.compactSpacing) {
                reminderPicker(title: strings.reminderHourLabel, selection: $selectedHour, options: Array(0 ... 23)) { hour in
                    String(format: "%02d", hour)
                }
                reminderPicker(title: strings.reminderMinuteLabel, selection: $selectedMinute, options: minuteOptions) { minute in
                    String(format: "%02d", minute)
                }
                Spacer(minLength: 0)
            }

            if !canSave {
                Text(strings.reminderMustBeFutureMessage)
                    .font(.system(size: metrics.captionSize))
                    .foregroundStyle(.secondary)
            }

            HStack {
                Spacer()

                Button(strings.cancelButton, action: onCancel)
                    .keyboardShortcut(.cancelAction)

                Button(strings.saveButton) {
                    if let composedDate {
                        onSave(composedDate)
                    }
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(!canSave)
            }
        }
        .padding(20)
        .frame(width: 420)
        .onChange(of: selectedYear) { _, _ in
            clampDayIfNeeded()
        }
        .onChange(of: selectedMonth) { _, _ in
            clampDayIfNeeded()
        }
    }

    @ViewBuilder
    private func reminderPicker<Value: Hashable>(
        title: String,
        selection: Binding<Value>,
        options: [Value],
        label: @escaping (Value) -> String
    ) -> some View {
        VStack(alignment: .leading, spacing: metrics.tinySpacing) {
            Text(title)
                .font(.system(size: metrics.captionSize))
                .foregroundStyle(.secondary)

            Picker(title, selection: selection) {
                ForEach(options, id: \.self) { value in
                    Text(label(value)).tag(value)
                }
            }
            .labelsHidden()
            .frame(minWidth: 72)
        }
    }

    private func clampDayIfNeeded() {
        let maxDay = dayRange.count
        if selectedDay > maxDay {
            selectedDay = maxDay
        }
    }

    private static func normalizedReminderDate(from date: Date, calendar: Calendar) -> Date {
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let roundedMinute = ((components.minute ?? 0) + 2) / 5 * 5
        let adjustedDate = calendar.date(
            from: DateComponents(
                year: components.year,
                month: components.month,
                day: components.day,
                hour: components.hour,
                minute: roundedMinute == 60 ? 0 : roundedMinute
            )
        ) ?? date

        if roundedMinute == 60 {
            return calendar.date(byAdding: .hour, value: 1, to: adjustedDate) ?? adjustedDate
        }

        return adjustedDate
    }
}

private struct NativeSegmentedPicker: NSViewRepresentable {
    @Binding var selection: TodoTag
    let labels: [String]
    let width: CGFloat

    func makeNSView(context: Context) -> NSSegmentedControl {
        let control = NSSegmentedControl(labels: labels, trackingMode: .selectOne, target: context.coordinator, action: #selector(Coordinator.valueChanged(_:)))
        control.segmentStyle = .rounded
        control.segmentDistribution = .fillEqually
        control.frame = NSRect(x: 0, y: 0, width: width, height: 25)
        return control
    }

    func updateNSView(_ nsView: NSSegmentedControl, context: Context) {
        for index in labels.indices where index < nsView.segmentCount {
            nsView.setLabel(labels[index], forSegment: index)
        }

        if let index = TodoTag.allCases.firstIndex(of: selection) {
            nsView.selectedSegment = index
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, @unchecked Sendable {
        var parent: NativeSegmentedPicker

        init(_ parent: NativeSegmentedPicker) {
            self.parent = parent
        }

        @objc func valueChanged(_ sender: NSSegmentedControl) {
            DispatchQueue.main.async {
                if sender.selectedSegment >= 0, sender.selectedSegment < TodoTag.allCases.count {
                    self.parent.selection = TodoTag.allCases[sender.selectedSegment]
                }
            }
        }
    }
}

private extension String {
    var todoTrimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
