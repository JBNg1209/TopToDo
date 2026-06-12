import Foundation
import TopToDoCore

func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else {
        fputs("Validation failed: \(message)\n", stderr)
        exit(1)
    }
}

func expectDate(_ actual: Date?, isCloseTo expected: Date, _ message: String) {
    guard let actual else {
        fputs("Validation failed: \(message)\n", stderr)
        exit(1)
    }

    expect(abs(actual.timeIntervalSince(expected)) < 1, message)
}

let store = TodoStore(persistenceURL: nil)

expect(store.todayItems.count == TodoStore.baseTodayLimit, "Today should start with 5 slots")
expect(store.todayItems.allSatisfy(\.title.isEmpty), "Today slots should start blank")

let firstTodayID = store.todayItems[0].id
store.updateTodayTitle(id: firstTodayID, title: "  Buy milk  ")
expect(store.todayItems[0].title == "  Buy milk  ", "Today editing should preserve active input")

store.setTodayAlarm(id: firstTodayID, alarmAt: Date().addingTimeInterval(3600))
store.completeTodayItem(id: firstTodayID)
expect(store.todayItems[0].isCompleted, "Today task should complete")
expect(store.todayItems[0].alarmAt == nil, "Completing a Today task should clear its reminder")
store.completeTodayItem(id: firstTodayID)
expect(!store.todayItems[0].isCompleted, "Completed Today task should toggle back to open")

store.toggleTodayHighlight(id: firstTodayID)
expect(store.todayItems[0].isHighlighted, "Today highlight should toggle on")

for index in 1 ..< TodoStore.baseTodayLimit {
    let id = store.todayItems[index].id
    store.updateTodayTitle(id: id, title: "Task \(index + 1)")
}

store.moveTodayItemDown(id: firstTodayID)
expect(store.todayItems.filter { !$0.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.map(\.title).prefix(2) == ["Task 2", "  Buy milk  "], "Today move-down should reorder visible tasks")
store.moveTodayItemToTop(id: firstTodayID)
expect(store.todayItems.first?.title == "  Buy milk  ", "Today move-to-top should place the task first")

expect(store.moveTodayItemToTaskPool(id: firstTodayID) != nil, "Today task should move to Task Pool")
expect(store.taskPoolItems.first?.title == "Buy milk", "Moved task should be trimmed in Task Pool")
expect(store.taskPoolItems.first?.isHighlighted == true, "Moved task should preserve highlight")
expect(store.todayItems.contains(where: { $0.id == firstTodayID }) == false, "Moved Today task should leave its original slot")

let promotedID = store.addTaskPoolItem(title: "From task pool")!.id
store.toggleTaskPoolHighlight(id: promotedID)
let promotedAlarm = Date().addingTimeInterval(7200)
store.setTaskPoolAlarm(id: promotedID, alarmAt: promotedAlarm)
expect(store.moveTaskPoolItemToToday(id: promotedID) != nil, "Task Pool task should move to Today when a Today slot is open")
expect(store.todayItems.contains { $0.id == promotedID && $0.isHighlighted }, "Moved task should preserve highlight when moving to Today")
expectDate(store.todayItems.first(where: { $0.id == promotedID })?.alarmAt, isCloseTo: promotedAlarm, "Moved task should preserve reminder when moving to Today")

let blockedID = store.addTaskPoolItem(title: "Cannot move")!.id
expect(store.moveTaskPoolItemToToday(id: blockedID) == nil, "Task Pool task should not move to Today when Today is full")
store.removeTaskPoolItem(id: blockedID)

let poolA = UUID()
let poolB = UUID()
let poolC = UUID()
let orderedPoolStore = TodoStore(
    todayItems: [],
    taskPoolItems: [
        TodoItem(id: poolA, title: "A"),
        TodoItem(id: poolB, title: "B"),
        TodoItem(id: poolC, title: "C"),
    ],
    persistenceURL: nil
)
orderedPoolStore.moveTaskPoolItemDown(id: poolA)
expect(orderedPoolStore.taskPoolItems.map(\.title) == ["B", "A", "C"], "Task Pool move-down should swap adjacent tasks")
orderedPoolStore.moveTaskPoolItemToTop(id: poolC)
expect(orderedPoolStore.taskPoolItems.map(\.title) == ["C", "B", "A"], "Task Pool move-to-top should place the task first")

let gappedTodayStore = TodoStore(
    todayItems: [
        TodoItem(title: "One"),
        TodoItem(title: ""),
        TodoItem(title: "Two"),
    ],
    persistenceURL: nil
)
let twoID = gappedTodayStore.todayItems[2].id
gappedTodayStore.moveTodayItemToTop(id: twoID)
expect(gappedTodayStore.todayItems.map(\.title) == ["Two", "One", "", "", ""], "Today reordering should keep empty slots at the end")

let directory = FileManager.default.temporaryDirectory
    .appendingPathComponent(UUID().uuidString, isDirectory: true)
let file = directory.appendingPathComponent("todos.json")
defer { try? FileManager.default.removeItem(at: directory) }

let persistentStore = TodoStore(persistenceURL: file)
let persistentTodayID = persistentStore.todayItems[0].id
let persistentAlarm = Date().addingTimeInterval(5400)
persistentStore.updateTodayTitle(id: persistentTodayID, title: "Keep tomorrow")
persistentStore.toggleTodayHighlight(id: persistentTodayID)
persistentStore.setTodayAlarm(id: persistentTodayID, alarmAt: persistentAlarm)
let longTermID = persistentStore.addTaskPoolItem(title: "Keep me")!.id
persistentStore.toggleTaskPoolHighlight(id: longTermID)

let savedJSON = (try? String(contentsOf: file, encoding: .utf8)) ?? ""
expect(!savedJSON.contains("todayKey"), "Saved state should not include date-based Today reset metadata")
expect(savedJSON.contains("isHighlighted"), "Saved state should include highlight metadata")
expect(savedJSON.contains("alarmAt"), "Saved state should include reminder metadata")

let reloadedStore = TodoStore(persistenceURL: file)
expect(reloadedStore.todayItems[0].title == "Keep tomorrow", "Today tasks should persist across launches")
expect(reloadedStore.todayItems[0].isHighlighted, "Today highlight should persist across launches")
expectDate(reloadedStore.todayItems[0].alarmAt, isCloseTo: persistentAlarm, "Today reminder should persist across launches")
expect(reloadedStore.taskPoolItems.first?.isHighlighted == true, "Task Pool highlight should persist across launches")

let legacyJSON = """
{
  "todayItems": [
    {
      "id": "\(UUID())",
      "title": "Legacy today",
      "isCompleted": false,
      "createdAt": "2026-06-12T08:00:00Z"
    }
  ],
  "taskPoolItems": [
    {
      "id": "\(UUID())",
      "title": "Legacy pool",
      "isCompleted": true,
      "createdAt": "2026-06-12T09:00:00Z"
    }
  ]
}
"""
try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
try legacyJSON.write(to: file, atomically: true, encoding: .utf8)

let legacyStore = TodoStore(persistenceURL: file)
expect(legacyStore.todayItems[0].title == "Legacy today", "Legacy Today item should decode")
expect(legacyStore.todayItems[0].isHighlighted == false, "Legacy Today item should default highlight to false")
expect(legacyStore.todayItems[0].alarmAt == nil, "Legacy Today item should default reminder to nil")
expect(legacyStore.taskPoolItems[0].title == "Legacy pool", "Legacy Task Pool item should decode")

print("TopToDo validation passed")
