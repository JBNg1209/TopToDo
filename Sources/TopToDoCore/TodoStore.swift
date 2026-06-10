import Foundation

public final class TodoStore: ObservableObject {
    public static let baseTodayLimit = 5
    public static let taskPoolLimit = 30

    @Published public private(set) var todayItems: [TodoItem]
    @Published public private(set) var taskPoolItems: [TodoItem]

    private let persistenceURL: URL?
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let calendar: Calendar
    private let now: () -> Date
    private var todayKey: String

    public init(
        todayItems: [TodoItem]? = nil,
        taskPoolItems: [TodoItem] = [],
        persistenceURL: URL? = TodoStore.defaultPersistenceURL(),
        calendar: Calendar = .current,
        now: @escaping () -> Date = Date.init
    ) {
        self.persistenceURL = persistenceURL
        self.calendar = calendar
        self.now = now

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder

        let currentDayKey = Self.dayKey(for: now(), calendar: calendar)
        todayKey = currentDayKey

        if todayItems != nil || !taskPoolItems.isEmpty {
            self.todayItems = Self.normalizedTodayItems(todayItems ?? [], limit: Self.baseTodayLimit)
            self.taskPoolItems = Array(taskPoolItems.prefix(Self.taskPoolLimit))
            return
        }

        guard let persistenceURL, let savedState = Self.load(from: persistenceURL, decoder: decoder) else {
            self.todayItems = Self.emptyTodayItems(count: Self.baseTodayLimit)
            self.taskPoolItems = []
            return
        }

        self.taskPoolItems = Array(savedState.taskPoolItems.prefix(Self.taskPoolLimit))
        if savedState.todayKey == currentDayKey {
            self.todayItems = Self.normalizedTodayItems(savedState.todayItems, limit: Self.baseTodayLimit)
        } else {
            self.todayItems = Self.emptyTodayItems(count: Self.baseTodayLimit)
        }
    }

    public var todayLimit: Int {
        refreshForNewDayIfNeeded()
        return Self.baseTodayLimit
    }

    public var todaySummary: (open: Int, completed: Int) {
        let activeItems = todayItems.filter { !$0.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        let completed = activeItems.count(where: \.isCompleted)
        return (activeItems.count - completed, completed)
    }

    public var taskPoolSummary: (open: Int, completed: Int) {
        let completed = taskPoolItems.count(where: \.isCompleted)
        return (taskPoolItems.count - completed, completed)
    }

    public func refreshForNewDayIfNeeded() {
        // Today items are now persistent across days — no auto-reset at midnight.
    }

    public func updateTodayTitle(id: TodoItem.ID, title rawTitle: String) {
        refreshForNewDayIfNeeded()
        guard let index = todayItems.firstIndex(where: { $0.id == id }) else {
            return
        }

        todayItems[index].title = rawTitle
        if rawTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            todayItems[index].isCompleted = false
        }
        save()
    }

    public func completeTodayItem(id: TodoItem.ID) {
        toggleTodayItemCompletion(id: id)
    }

    public func toggleTodayItemCompletion(id: TodoItem.ID) {
        refreshForNewDayIfNeeded()
        guard let index = todayItems.firstIndex(where: { $0.id == id }),
              !todayItems[index].title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            return
        }

        todayItems[index].isCompleted.toggle()
        save()
    }

    public func clearTodayItem(id: TodoItem.ID) {
        refreshForNewDayIfNeeded()
        guard let index = todayItems.firstIndex(where: { $0.id == id }) else {
            return
        }

        todayItems[index] = Self.emptyTodayItem()
        save()
    }

    @discardableResult
    public func moveTodayItemToTaskPool(id: TodoItem.ID) -> TodoItem? {
        refreshForNewDayIfNeeded()
        guard taskPoolItems.count < Self.taskPoolLimit,
              let index = todayItems.firstIndex(where: { $0.id == id })
        else {
            return nil
        }

        let title = todayItems[index].title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else {
            return nil
        }

        let item = TodoItem(title: title)
        taskPoolItems.insert(item, at: 0)
        todayItems[index] = Self.emptyTodayItem()
        save()
        return item
    }

    @discardableResult
    public func moveTaskPoolItemToToday(id: TodoItem.ID) -> TodoItem? {
        refreshForNewDayIfNeeded()
        guard let poolIndex = taskPoolItems.firstIndex(where: { $0.id == id }) else {
            return nil
        }

        let title = taskPoolItems[poolIndex].title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty,
              let emptyIndex = todayItems.firstIndex(where: { $0.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })
        else {
            return nil
        }

        let item = TodoItem(title: title)
        todayItems[emptyIndex] = item
        taskPoolItems.remove(at: poolIndex)
        save()
        return item
    }

    @discardableResult
    public func addTaskPoolItem(title rawTitle: String) -> TodoItem? {
        guard taskPoolItems.count < Self.taskPoolLimit else {
            return nil
        }

        let title = rawTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else {
            return nil
        }

        let item = TodoItem(title: title)
        taskPoolItems.insert(item, at: 0)
        save()
        return item
    }

    public func updateTaskPoolTitle(id: TodoItem.ID, title rawTitle: String) {
        guard let index = taskPoolItems.firstIndex(where: { $0.id == id }) else {
            return
        }

        taskPoolItems[index].title = rawTitle
        save()
    }

    public func completeTaskPoolItem(id: TodoItem.ID) {
        toggleTaskPoolItemCompletion(id: id)
    }

    public func toggleTaskPoolItemCompletion(id: TodoItem.ID) {
        guard let index = taskPoolItems.firstIndex(where: { $0.id == id }),
              !taskPoolItems[index].title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            return
        }

        taskPoolItems[index].isCompleted.toggle()
        save()
    }

    public func removeTaskPoolItem(id: TodoItem.ID) {
        guard let index = taskPoolItems.firstIndex(where: { $0.id == id }) else {
            return
        }

        taskPoolItems.remove(at: index)
        save()
    }

    private func save() {
        guard let persistenceURL else {
            return
        }

        do {
            let directory = persistenceURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let state = TodoPersistenceState(
                todayKey: todayKey,
                todayItems: todayItems,
                taskPoolItems: taskPoolItems
            )
            let data = try encoder.encode(state)
            try data.write(to: persistenceURL, options: [.atomic])
        } catch {
            assertionFailure("Unable to save todos: \(error)")
        }
    }

    private static func load(from url: URL, decoder: JSONDecoder) -> TodoPersistenceState? {
        guard FileManager.default.fileExists(atPath: url.path) else {
            return nil
        }

        do {
            let data = try Data(contentsOf: url)
            if let state = try? decoder.decode(TodoPersistenceState.self, from: data) {
                return state
            }

            let legacyItems = try decoder.decode([TodoItem].self, from: data)
            return TodoPersistenceState(
                todayKey: "",
                todayItems: [],
                taskPoolItems: Array(legacyItems.prefix(Self.taskPoolLimit))
            )
        } catch {
            NSLog("TopToDo: Unable to load todos — starting fresh. \(error)")
            return nil
        }
    }

    private static func emptyTodayItems(count: Int) -> [TodoItem] {
        (0 ..< count).map { _ in emptyTodayItem() }
    }

    private static func emptyTodayItem() -> TodoItem {
        TodoItem(title: "")
    }

    private static func normalizedTodayItems(_ items: [TodoItem], limit: Int) -> [TodoItem] {
        let trimmedItems = Array(items.prefix(limit))
        let missingCount = max(0, limit - trimmedItems.count)
        return trimmedItems + emptyTodayItems(count: missingCount)
    }

    private static func dayKey(for date: Date, calendar: Calendar) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return [
            components.year ?? 0,
            components.month ?? 0,
            components.day ?? 0,
        ]
        .map(String.init)
        .joined(separator: "-")
    }

    public static func defaultPersistenceURL() -> URL? {
        guard let applicationSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return nil
        }

        let topToDoURL = applicationSupportURL
            .appendingPathComponent("TopToDo", isDirectory: true)
            .appendingPathComponent("todos.json")
        let legacyURL = applicationSupportURL
            .appendingPathComponent("iDo", isDirectory: true)
            .appendingPathComponent("todos.json")

        if !FileManager.default.fileExists(atPath: topToDoURL.path),
           FileManager.default.fileExists(atPath: legacyURL.path)
        {
            do {
                try FileManager.default.createDirectory(
                    at: topToDoURL.deletingLastPathComponent(),
                    withIntermediateDirectories: true
                )
                try FileManager.default.copyItem(at: legacyURL, to: topToDoURL)
            } catch {
                assertionFailure("Unable to migrate todos from iDo to TopToDo: \(error)")
            }
        }

        return topToDoURL
    }
}

private struct TodoPersistenceState: Codable {
    var todayKey: String
    var todayItems: [TodoItem]
    var taskPoolItems: [TodoItem]

    private enum CodingKeys: String, CodingKey {
        case todayKey
        case todayItems
        case taskPoolItems
        case topItems  // legacy key from pre-TaskPool renames
    }

    init(todayKey: String, todayItems: [TodoItem], taskPoolItems: [TodoItem]) {
        self.todayKey = todayKey
        self.todayItems = todayItems
        self.taskPoolItems = taskPoolItems
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.todayKey = try container.decode(String.self, forKey: .todayKey)
        self.todayItems = try container.decode([TodoItem].self, forKey: .todayItems)
        // Accept either the new "taskPoolItems" or the legacy "topItems" key so existing
        // user data migrates transparently across the rename.
        if let pool = try? container.decode([TodoItem].self, forKey: .taskPoolItems) {
            self.taskPoolItems = pool
        } else if let legacy = try? container.decode([TodoItem].self, forKey: .topItems) {
            self.taskPoolItems = legacy
        } else {
            self.taskPoolItems = []
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(todayKey, forKey: .todayKey)
        try container.encode(todayItems, forKey: .todayItems)
        try container.encode(taskPoolItems, forKey: .taskPoolItems)
    }
}
