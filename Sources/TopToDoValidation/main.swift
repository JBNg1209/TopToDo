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

expect(store.moveTodayItemToTop(id: firstTodayID) != nil, "Today task should move to Backlog")
expect(store.topItems.map(\.title) == ["Buy milk"], "Moved task should be trimmed in Backlog")
expect(store.todayItems.first?.title.isEmpty == true, "Moved Today slot should be cleared")

let promotedID = store.addTopItem(title: "From backlog")!.id
expect(store.moveTopItemToToday(id: promotedID) != nil, "Top task should move to Today when a Today slot is open")
expect(store.topItems.map(\.title) == ["Buy milk"], "Backlog should drop the moved task")
expect(store.todayItems.first?.title == "From backlog", "Today should place the moved task in the first empty slot")
expect(store.todayItems[0].id != firstTodayID, "The moved task should be a fresh item, not reusing the cleared slot's id")

store.toggleTodayItemCompletion(id: store.todayItems[0].id)
let blockedID = store.addTopItem(title: "Cannot move")!.id
expect(store.moveTopItemToToday(id: blockedID) == nil, "Top task should not move to Today when Today is full")
expect(store.topItems.map(\.title) == ["Cannot move", "Buy milk"], "Backlog should be unchanged after a blocked move")
expect(store.todayItems.allSatisfy { !$0.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }, "Today should remain full")

store.removeTopItem(id: blockedID)

store.updateTopTitle(id: store.topItems[0].id, title: "  Buy oat milk  ")
expect(store.topItems[0].title == "  Buy oat milk  ", "Backlog editing should preserve active input")
store.completeTopItem(id: store.topItems[0].id)
store.completeTopItem(id: store.topItems[0].id)
expect(!store.topItems[0].isCompleted, "Completed Backlog task should toggle back to open")
store.removeTopItem(id: store.topItems[0].id)
expect(store.topItems.isEmpty, "Backlog task should delete")

for index in 0 ..< TodoStore.topLimit {
    expect(store.addTopItem(title: "Long term \(index)") != nil, "Backlog should accept up to 10 tasks")
}

expect(store.addTopItem(title: "Overflow") == nil, "Backlog should reject an 11th task")

let directory = FileManager.default.temporaryDirectory
    .appendingPathComponent(UUID().uuidString, isDirectory: true)
let file = directory.appendingPathComponent("todos.json")
defer { try? FileManager.default.removeItem(at: directory) }

let persistentStore = TodoStore(persistenceURL: file, calendar: calendar, now: { currentDate })
let persistentTodayID = persistentStore.todayItems[0].id
persistentStore.updateTodayTitle(id: persistentTodayID, title: "Expires tonight")
persistentStore.addTopItem(title: "Keep me")

let sameDayStore = TodoStore(persistenceURL: file, calendar: calendar, now: { currentDate })
expect(sameDayStore.todayItems[0].title == "Expires tonight", "Today tasks should reload on the same day")
expect(sameDayStore.topItems.map(\.title) == ["Keep me"], "Backlog tasks should persist")

currentDate = currentDate.addingTimeInterval(24 * 60 * 60)
let nextDayStore = TodoStore(persistenceURL: file, calendar: calendar, now: { currentDate })
expect(nextDayStore.todayItems.allSatisfy(\.title.isEmpty), "Today tasks should clear after midnight")
expect(nextDayStore.topItems.map(\.title) == ["Keep me"], "Backlog tasks should survive midnight")

print("TopToDo validation passed")
