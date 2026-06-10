import Foundation
import TopToDoCore

func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else {
        fputs("Validation failed: \(message)\n", stderr)
        exit(1)
    }
}

var currentDate = Date(timeIntervalSince1970: 1_786_000_000)
let calendar = Calendar(identifier: .gregorian)
let store = TodoStore(persistenceURL: nil, calendar: calendar, now: { currentDate })

expect(store.todayItems.count == TodoStore.baseTodayLimit, "Today should start with 5 slots")
expect(store.todayItems.allSatisfy(\.title.isEmpty), "Today slots should start blank")

let firstTodayID = store.todayItems[0].id
store.updateTodayTitle(id: firstTodayID, title: "  Buy milk  ")
expect(store.todayItems[0].title == "  Buy milk  ", "Today editing should preserve active input")

store.completeTodayItem(id: firstTodayID)
expect(store.todayItems[0].isCompleted, "Today task should complete")
store.completeTodayItem(id: firstTodayID)
expect(!store.todayItems[0].isCompleted, "Completed Today task should toggle back to open")
store.toggleTodayItemCompletion(id: firstTodayID)
expect(store.todayItems[0].isCompleted, "Open Today task should toggle back to completed")

for index in 1 ..< TodoStore.baseTodayLimit {
    let id = store.todayItems[index].id
    store.updateTodayTitle(id: id, title: "Task \(index + 1)")
    store.completeTodayItem(id: id)
}

expect(store.todayItems.count == TodoStore.baseTodayLimit, "Completing all 5 Today tasks should NOT unlock extra slots")
expect(store.todayItems.allSatisfy { $0.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || $0.isCompleted }, "All filled Today slots should be completed")
expect(store.todayLimit == TodoStore.baseTodayLimit, "Today limit should remain 5 even when all slots are completed")

expect(store.moveTodayItemToTaskPool(id: firstTodayID) != nil, "Today task should move to Task Pool")
expect(store.taskPoolItems.map(\.title) == ["Buy milk"], "Moved task should be trimmed in Task Pool")
expect(store.todayItems.first?.title.isEmpty == true, "Moved Today slot should be cleared")

let promotedID = store.addTaskPoolItem(title: "From task pool")!.id
expect(store.moveTaskPoolItemToToday(id: promotedID) != nil, "Task Pool task should move to Today when a Today slot is open")
expect(store.taskPoolItems.map(\.title) == ["Buy milk"], "Task Pool should drop the moved task")
expect(store.todayItems.first?.title == "From task pool", "Today should place the moved task in the first empty slot")
expect(store.todayItems[0].id != firstTodayID, "The moved task should be a fresh item, not reusing the cleared slot's id")

store.toggleTodayItemCompletion(id: store.todayItems[0].id)
let blockedID = store.addTaskPoolItem(title: "Cannot move")!.id
expect(store.moveTaskPoolItemToToday(id: blockedID) == nil, "Task Pool task should not move to Today when Today is full")
expect(store.taskPoolItems.map(\.title) == ["Cannot move", "Buy milk"], "Task Pool should be unchanged after a blocked move")
expect(store.todayItems.allSatisfy { !$0.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }, "Today should remain full")

store.removeTaskPoolItem(id: blockedID)

store.updateTaskPoolTitle(id: store.taskPoolItems[0].id, title: "  Buy oat milk  ")
expect(store.taskPoolItems[0].title == "  Buy oat milk  ", "Task Pool editing should preserve active input")
store.completeTaskPoolItem(id: store.taskPoolItems[0].id)
store.completeTaskPoolItem(id: store.taskPoolItems[0].id)
expect(!store.taskPoolItems[0].isCompleted, "Completed Task Pool task should toggle back to open")
store.removeTaskPoolItem(id: store.taskPoolItems[0].id)
expect(store.taskPoolItems.isEmpty, "Task Pool task should delete")

for index in 0 ..< TodoStore.taskPoolLimit {
    expect(store.addTaskPoolItem(title: "Long term \(index)") != nil, "Task Pool should accept up to \(TodoStore.taskPoolLimit) tasks")
}

expect(store.addTaskPoolItem(title: "Overflow") == nil, "Task Pool should reject a \(TodoStore.taskPoolLimit + 1)th task")

let directory = FileManager.default.temporaryDirectory
    .appendingPathComponent(UUID().uuidString, isDirectory: true)
let file = directory.appendingPathComponent("todos.json")
defer { try? FileManager.default.removeItem(at: directory) }

let persistentStore = TodoStore(persistenceURL: file, calendar: calendar, now: { currentDate })
let persistentTodayID = persistentStore.todayItems[0].id
persistentStore.updateTodayTitle(id: persistentTodayID, title: "Expires tonight")
persistentStore.addTaskPoolItem(title: "Keep me")

let sameDayStore = TodoStore(persistenceURL: file, calendar: calendar, now: { currentDate })
expect(sameDayStore.todayItems[0].title == "Expires tonight", "Today tasks should reload on the same day")
expect(sameDayStore.taskPoolItems.map(\.title) == ["Keep me"], "Task Pool tasks should persist")

currentDate = currentDate.addingTimeInterval(24 * 60 * 60)
let nextDayStore = TodoStore(persistenceURL: file, calendar: calendar, now: { currentDate })
expect(nextDayStore.todayItems.allSatisfy(\.title.isEmpty), "Today tasks should clear after midnight")
expect(nextDayStore.taskPoolItems.map(\.title) == ["Keep me"], "Task Pool tasks should survive midnight")

print("TopToDo validation passed")
