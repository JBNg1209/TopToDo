import TopToDoCore
import SwiftUI

private enum TodoTag: String, CaseIterable, Identifiable {
    case today
    case top

    var id: String {
        rawValue
    }

    func title(using strings: AppStrings) -> String {
        switch self {
        case .today:
            strings.todayTag
        case .top:
            strings.backlogTag
        }
    }
}

struct TodoListView: View {
    @EnvironmentObject private var store: TodoStore
    @AppStorage("appLanguageCode") private var selectedLanguageCode = AppLanguage.english.rawValue
    @AppStorage("appFontSizeRawValue") private var fontSizeRawValue: String = FontSize.medium.rawValue
    @Environment(\.fontScale) private var fontScale
    @State private var selectedTag: TodoTag = .today
    @State private var newTopTitle = ""
    @State private var newTodayTitle = ""
    @State private var showTodayLimitAlert = false
    @State private var showLongTermLimitAlert = false

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
                case .top:
                    topView
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .padding(20)
        .background(Color(nsColor: .windowBackgroundColor))
        .onAppear {
            store.refreshForNewDayIfNeeded()
        }
        .alert(strings.todayLimitTitle, isPresented: $showTodayLimitAlert) {
            Button(strings.okButton, role: .cancel) {}
        } message: {
            Text(strings.todayLimitMessage)
        }
        .alert(strings.backlogLimitTitle, isPresented: $showLongTermLimitAlert) {
            Button(strings.okButton, role: .cancel) {}
        } message: {
            Text(strings.backlogLimitMessage)
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

            HStack(alignment: .firstTextBaseline, spacing: metrics.tagPickerSpacing) {
                Image(systemName: "clock.arrow.circlepath")
                    .imageScale(.small)
                Text(strings.todayResetNote)
            }
            .font(.system(size: metrics.captionSize))
            .foregroundStyle(.secondary)

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
                                    canMoveToTop: store.topItems.count < TodoStore.topLimit,
                                    onComplete: {
                                        store.toggleTodayItemCompletion(id: item.id)
                                    },
                                    onMoveToTop: {
                                        if store.topItems.count >= TodoStore.topLimit {
                                            showLongTermLimitAlert = true
                                        } else {
                                            store.moveTodayItemToTop(id: item.id)
                                        }
                                    },
                                    onDelete: {
                                        store.clearTodayItem(id: item.id)
                                    }
                                )
                            }
                        }
                    }
                }
            }
        }
    }

    private var topView: some View {
        VStack(alignment: .leading, spacing: metrics.comfortableSpacing) {
            HStack(spacing: metrics.compactSpacing) {
                TextField(strings.newBacklogTaskPlaceholder, text: $newTopTitle)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: metrics.bodySize))
                    .onSubmit(addTopTask)

                Button(action: addTopTask) {
                    Label(strings.newButton, systemImage: "plus")
                        .font(.system(size: metrics.bodySize))
                }
                .buttonStyle(.borderedProminent)
                .disabled(newTopTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            if store.topItems.isEmpty {
                ContentUnavailableView(strings.noBacklogTasksTitle, systemImage: "tray", description: Text(strings.noBacklogTasksDescription))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: metrics.compactSpacing) {
                        ForEach(store.topItems) { item in
                            TopTaskRow(
                                item: item,
                                strings: strings,
                                metrics: metrics,
                                canMoveToToday: store.todayItems.contains(where: { $0.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }),
                                onComplete: {
                                    store.toggleTopItemCompletion(id: item.id)
                                },
                                onMoveToToday: {
                                    if store.todayItems.allSatisfy({ !$0.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) {
                                        showTodayLimitAlert = true
                                    } else {
                                        store.moveTopItemToToday(id: item.id)
                                    }
                                },
                                onDelete: {
                                    store.removeTopItem(id: item.id)
                                }
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
        case .top:
            strings.backlogSummary(count: store.topItems.count, limit: TodoStore.topLimit)
        }
    }

    private func addTopTask() {
        let trimmedTitle = newTopTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            return
        }

        if store.topItems.count >= TodoStore.topLimit {
            showLongTermLimitAlert = true
            return
        }

        commitTopTask()
    }

    private func commitTopTask() {
        guard store.addTopItem(title: newTopTitle) != nil else {
            return
        }

        newTopTitle = ""
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
    }
}

private struct TodayTaskRow: View {
    let index: Int
    let item: TodoItem
    let strings: AppStrings
    let metrics: AppMetrics
    @EnvironmentObject private var store: TodoStore
    @State private var title: String = ""
    @FocusState private var isEditing: Bool
    let canMoveToTop: Bool
    let onComplete: () -> Void
    let onMoveToTop: () -> Void
    let onDelete: () -> Void

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

            Button(action: onMoveToTop) {
                Image(systemName: "arrow.up.right.square")
            }
            .buttonStyle(.borderless)
            .disabled(isEmpty)
            .help(canMoveToTop ? strings.moveToBacklogHelp : strings.backlogFullHelp)

            Button(role: .destructive, action: onDelete) {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
            .help(strings.deleteTaskHelp)
        }
        .frame(height: metrics.rowHeight)
        .onAppear {
            title = item.title
        }
        .onChange(of: item.title) { _, newValue in
            title = newValue
        }
        .onChange(of: isEditing) { _, newValue in
            if !newValue {
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
    @EnvironmentObject private var store: TodoStore
    @State private var title: String = ""
    @FocusState private var isEditing: Bool
    let canMoveToToday: Bool
    let onComplete: () -> Void
    let onMoveToToday: () -> Void
    let onDelete: () -> Void

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
                Image(systemName: "arrow.down.to.line")
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
        }
        .onChange(of: item.title) { _, newValue in
            title = newValue
        }
        .onChange(of: isEditing) { _, newValue in
            if !newValue {
                commitEdit()
            }
        }
    }

    private func commitEdit() {
        if title != item.title {
            store.updateTopTitle(id: item.id, title: title)
        }
    }
}

private struct EditableTaskTitle: View {
    let placeholder: String
    @Binding var title: String
    let isCompleted: Bool
    @FocusState.Binding var isEditing: Bool
    let metrics: AppMetrics
    let onCommit: () -> Void

    var body: some View {
        ZStack(alignment: .leading) {
            if isEditing {
                TextField(placeholder, text: $title)
                    .textFieldStyle(.plain)
                    .focused($isEditing)
                    .font(.system(size: metrics.bodySize))
                    .strikethrough(isCompleted)
                    .foregroundStyle(isCompleted ? .secondary : .primary)
                    .onSubmit {
                        finishEditing()
                    }
            } else {
                Button(action: beginEditing) {
                    Text(title.isEmpty ? placeholder : title)
                        .lineLimit(1)
                        .font(.system(size: metrics.bodySize))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundStyle(title.isEmpty || isCompleted ? .secondary : .primary)
                        .strikethrough(isCompleted)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, minHeight: metrics.minEditHeight, alignment: .leading)
    }

    private func beginEditing() {
        isEditing = true
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
