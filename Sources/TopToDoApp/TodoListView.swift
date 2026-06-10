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

struct TodoListView: View {
    @EnvironmentObject private var store: TodoStore
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

    private var strings: AppStrings {
        AppStrings(language: language)
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
    }

    private var header: some View {
        HStack(alignment: .top, spacing: metrics.spaciousSpacing) {
            VStack(alignment: .leading, spacing: metrics.tinySpacing) {
                // Title stays at a fixed 28pt regardless of font size preference.
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
                .disabled(newTodayTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            if store.todayItems.filter({ !$0.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }).isEmpty {
                ContentUnavailableView(strings.noTodayTasksTitle, systemImage: "tray", description: Text(strings.noTodayTasksDescription))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: metrics.standardSpacing) {
                        ForEach(Array(store.todayItems.enumerated()), id: \.element.id) { index, item in
                            if !item.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                TodayTaskRow(
                                    index: index,
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
                .disabled(newTaskPoolTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            if store.taskPoolItems.isEmpty {
                ContentUnavailableView(strings.noTaskPoolTasksTitle, systemImage: "tray", description: Text(strings.noTaskPoolTasksDescription))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: metrics.compactSpacing) {
                        ForEach(store.taskPoolItems) { item in
                            TopTaskRow(
                                item: item,
                                strings: strings,
                                metrics: metrics,
                                editingId: $editingTaskPoolId,
                                canMoveToToday: store.todayItems.contains(where: { $0.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }),
                                onComplete: {
                                    store.toggleTaskPoolItemCompletion(id: item.id)
                                },
                                onMoveToToday: {
                                    if store.todayItems.allSatisfy({ !$0.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) {
                                        showTodayLimitAlert = true
                                    } else {
                                        store.moveTaskPoolItemToToday(id: item.id)
                                    }
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
        let trimmedTitle = newTaskPoolTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            return
        }

        if store.taskPoolItems.count >= TodoStore.taskPoolLimit {
            showTaskPoolLimitAlert = true
            return
        }

        commitTaskPoolTask()
    }

    private func commitTaskPoolTask() {
        guard let newItem = store.addTaskPoolItem(title: newTaskPoolTitle) else {
            return
        }

        newTaskPoolTitle = ""
        // Drop the new task straight into edit mode so the user can keep typing.
        editingTaskPoolId = newItem.id
    }

    private func addTodayTask() {
        let trimmedTitle = newTodayTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            return
        }

        let nonEmptyCount = store.todayItems.filter { !$0.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count
        if nonEmptyCount >= store.todayLimit {
            showTodayLimitAlert = true
            return
        }

        commitTodayTask()
    }

    private func commitTodayTask() {
        guard let emptyItem = store.todayItems.first(where: { $0.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) else {
            return
        }
        store.updateTodayTitle(id: emptyItem.id, title: newTodayTitle)
        newTodayTitle = ""
        // Drop the new task straight into edit mode so the user can keep typing.
        editingTodayId = emptyItem.id
    }
}

private struct TodayTaskRow: View {
    let index: Int
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
    let onDelete: () -> Void
    let onEmptyCommitAttempt: () -> Void

    private var isEmpty: Bool {
        title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        HStack(spacing: metrics.compactSpacing) {
            Button(action: onComplete) {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(item.isCompleted ? .green : .secondary)
            }
            .buttonStyle(.plain)
            .help(item.isCompleted ? strings.markAsOpenHelp : strings.completeTaskHelp)

            EditableTaskTitle(
                placeholder: strings.todayTaskPlaceholder(index: index + 1),
                title: $title,
                isCompleted: item.isCompleted,
                isEditing: $isEditing,
                metrics: metrics,
                onCommit: commitEdit
            )

            Button(action: onMoveToTaskPool) {
                // "Send to the list on the right" — simple right arrow.
                Image(systemName: "arrow.right")
            }
            .buttonStyle(.borderless)
            .disabled(isEmpty)
            .help(canMoveToTaskPool ? strings.moveToTaskPoolHelp : strings.taskPoolFullHelp)

            Button(role: .destructive, action: onDelete) {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
            .help(strings.deleteTaskHelp)
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
                if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    // Reject: keep the user in edit mode and surface an alert.
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

    private func commitEdit() {
        if title != item.title {
            store.updateTodayTitle(id: item.id, title: title)
        }
    }
}

private struct TopTaskRow: View {
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
    let onDelete: () -> Void
    let onEmptyCommitAttempt: () -> Void

    var body: some View {
        HStack(spacing: metrics.compactSpacing) {
            Button(action: onComplete) {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(item.isCompleted ? .green : .secondary)
            }
            .buttonStyle(.plain)
            .help(item.isCompleted ? strings.markAsOpenHelp : strings.completeTaskHelp)

            EditableTaskTitle(
                placeholder: strings.taskPlaceholder,
                title: $title,
                isCompleted: item.isCompleted,
                isEditing: $isEditing,
                metrics: metrics,
                onCommit: commitEdit
            )

            Button(action: onMoveToToday) {
                // "Send to the list on the left" — mirrors the right arrow on Today rows.
                Image(systemName: "arrow.left")
            }
            .buttonStyle(.borderless)
            .help(canMoveToToday ? strings.moveToTodayHelp : strings.todayFullForMoveHelp)

            Button(role: .destructive, action: onDelete) {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
            .help(strings.deleteTaskHelp)
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
                if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    // Reject: keep the user in edit mode and surface an alert.
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
    @Binding var isEditing: Bool
    let metrics: AppMetrics
    let onCommit: () -> Void

    // Local focus state. The parent only knows about `isEditing: Bool`; the child owns
    // the actual focus binding so it can be re-asserted on demand without going through
    // the parent's state.
    @FocusState private var internalFocus: Bool

    var body: some View {
        Group {
            if isEditing {
                TextField(placeholder, text: $title)
                    .focused($internalFocus)
                    .textFieldStyle(.plain)
                    .font(.system(size: metrics.bodySize))
                    .strikethrough(isCompleted)
                    .foregroundStyle(isCompleted ? .secondary : .primary)
                    .onSubmit {
                        finishEditing()
                    }
                    // Focus is set in the same render pass as the TextField being
                    // introduced. Give SwiftUI a frame to install the first responder,
                    // then re-assert if the binding didn't catch.
                    .task {
                        try? await Task.sleep(for: .milliseconds(20))
                        if isEditing, !internalFocus {
                            internalFocus = true
                        }
                    }
            } else {
                // Display mode is a plain Text, not a disabled TextField. The Text is
                // always hit-testable; the tap gesture reliably fires regardless of
                // any disabled-control quirks upstream.
                Text(title.isEmpty ? placeholder : title)
                    .lineLimit(1)
                    .font(.system(size: metrics.bodySize))
                    .foregroundStyle(title.isEmpty || isCompleted ? .secondary : .primary)
                    .strikethrough(isCompleted)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        isEditing = true
                    }
            }
        }
        .frame(maxWidth: .infinity, minHeight: metrics.minEditHeight, alignment: .leading)
        // Parent toggled edit mode (e.g. new task auto-edits) → take focus.
        .onChange(of: isEditing) { _, newValue in
            internalFocus = newValue
        }
        // User clicked away while editing → propagate focus loss back to the parent so
        // it can commit and clear the editing id.
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
