import Foundation
import XCTest
@testable import TopToDoCore

final class TodoInvariantTests: XCTestCase {
    func testTodayIsNormalizedToFiveSlotsWhenLoadedWithTooManyItems() {
        let items = (0 ..< 7).map { TodoItem(title: "Task \($0)") }

        let store = TodoStore(todayItems: items, persistenceURL: nil)

        XCTAssertEqual(store.todayItems.count, TodoStore.baseTodayLimit)
        XCTAssertEqual(store.todayItems.map(\.title), ["Task 0", "Task 1", "Task 2", "Task 3", "Task 4"])
    }

    func testMovingTodayTaskToFullPoolLeavesBothListsUntouched() {
        let todayItem = TodoItem(title: "Today task")
        let poolItems = (0 ..< TodoStore.taskPoolLimit).map { TodoItem(title: "Pool \($0)") }
        let store = TodoStore(todayItems: [todayItem], taskPoolItems: poolItems, persistenceURL: nil)

        XCTAssertNil(store.moveTodayItemToTaskPool(id: todayItem.id))
        XCTAssertEqual(store.todayItems.first?.id, todayItem.id)
        XCTAssertEqual(store.taskPoolItems.count, TodoStore.taskPoolLimit)
    }

    func testMovingPoolTaskToTodayPreservesCompletionHighlightAndReminder() throws {
        let reminder = Date().addingTimeInterval(3_600)
        let item = TodoItem(title: "Pool task", isCompleted: true, isHighlighted: true, alarmAt: reminder)
        let store = TodoStore(todayItems: [], taskPoolItems: [item], persistenceURL: nil)

        let moved = try XCTUnwrap(store.moveTaskPoolItemToToday(id: item.id))

        XCTAssertEqual(moved.id, item.id)
        XCTAssertTrue(moved.isCompleted)
        XCTAssertTrue(moved.isHighlighted)
        XCTAssertEqual(moved.alarmAt, reminder)
        XCTAssertTrue(store.taskPoolItems.isEmpty)
    }

    func testBlankPoolTaskIsRejectedAndCannotBeCompleted() {
        let store = TodoStore(persistenceURL: nil)

        XCTAssertNil(store.addTaskPoolItem(title: " \n "))
        XCTAssertTrue(store.taskPoolItems.isEmpty)
    }

    func testCompletingPoolTaskClearsReminder() throws {
        let store = TodoStore(persistenceURL: nil)
        let item = try XCTUnwrap(store.addTaskPoolItem(title: "Task"))
        store.setTaskPoolAlarm(id: item.id, alarmAt: Date().addingTimeInterval(3_600))

        store.toggleTaskPoolItemCompletion(id: item.id)

        XCTAssertTrue(store.taskPoolItems[0].isCompleted)
        XCTAssertNil(store.taskPoolItems[0].alarmAt)
    }

    func testTaskPoolReorderingPreservesOtherItemsRelativeOrder() {
        let store = TodoStore(
            todayItems: [],
            taskPoolItems: [TodoItem(title: "A"), TodoItem(title: "B"), TodoItem(title: "C")],
            persistenceURL: nil
        )

        store.moveTaskPoolItemDown(id: store.taskPoolItems[0].id)
        store.moveTaskPoolItemToTop(id: store.taskPoolItems[2].id)

        XCTAssertEqual(store.taskPoolItems.map(\.title), ["C", "B", "A"])
    }

    func testConfiguredPersistencePathOverridesDefaultPath() {
        let configured = TodoStore.defaultPersistenceURL(environment: ["TOPTODO_PERSISTENCE_URL": " /tmp/toptodo-smoke.json "])

        XCTAssertEqual(configured?.path, "/tmp/toptodo-smoke.json")
    }

    func testBlankConfiguredPersistencePathFallsBackToApplicationSupport() {
        let configured = TodoStore.defaultPersistenceURL(environment: ["TOPTODO_PERSISTENCE_URL": "  "])

        XCTAssertEqual(configured?.lastPathComponent, "todos.json")
        XCTAssertEqual(configured?.deletingLastPathComponent().lastPathComponent, "TopToDo")
    }
}
