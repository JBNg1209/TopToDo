import Foundation
import XCTest
@testable import TopToDoCore

final class TodoStoreTests: XCTestCase {
    func testTodayStartsWithFiveEmptySlots() {
        let store = TodoStore(persistenceURL: nil)

        XCTAssertEqual(store.todayItems.count, TodoStore.baseTodayLimit)
        XCTAssertTrue(store.todayItems.allSatisfy(\.title.isEmpty))
    }

    func testCompletingTodayTaskClearsReminder() {
        let store = TodoStore(persistenceURL: nil)
        let id = store.todayItems[0].id
        let reminder = Date().addingTimeInterval(3_600)

        store.updateTodayTitle(id: id, title: "Buy milk")
        store.setTodayAlarm(id: id, alarmAt: reminder)
        store.toggleTodayItemCompletion(id: id)

        XCTAssertTrue(store.todayItems[0].isCompleted)
        XCTAssertNil(store.todayItems[0].alarmAt)
    }

    func testMovingTaskToPoolTrimsTitleAndPreservesMetadata() throws {
        let store = TodoStore(persistenceURL: nil)
        let id = store.todayItems[0].id
        let reminder = Date().addingTimeInterval(3_600)

        store.updateTodayTitle(id: id, title: "  Buy milk  ")
        store.setTodayHighlight(id: id, highlight: .gray)
        store.setTodayAlarm(id: id, alarmAt: reminder)
        let updatedAt = store.todayItems[0].updatedAt

        let moved = try XCTUnwrap(store.moveTodayItemToTaskPool(id: id))

        XCTAssertEqual(moved.id, id)
        XCTAssertEqual(moved.title, "Buy milk")
        XCTAssertEqual(moved.highlight, .gray)
        XCTAssertEqual(moved.alarmAt, reminder)
        XCTAssertEqual(moved.updatedAt, updatedAt)
        XCTAssertFalse(store.todayItems.contains { $0.id == id })
    }

    func testTaskPoolRejectsMoreThanThirtyTasks() {
        let store = TodoStore(persistenceURL: nil)

        for index in 0 ..< TodoStore.taskPoolLimit {
            XCTAssertNotNil(store.addTaskPoolItem(title: "Task \(index)"))
        }

        XCTAssertNil(store.addTaskPoolItem(title: "One too many"))
        XCTAssertEqual(store.taskPoolItems.count, TodoStore.taskPoolLimit)
    }

    func testReorderingTodayKeepsEmptySlotsAtEnd() {
        let store = TodoStore(
            todayItems: [
                TodoItem(title: "One"),
                TodoItem(title: ""),
                TodoItem(title: "Two"),
            ],
            persistenceURL: nil
        )

        store.moveTodayItemToTop(id: store.todayItems[2].id)

        XCTAssertEqual(store.todayItems.map(\.title), ["Two", "One", "", "", ""])
    }

    func testOnlyTitleChangesRefreshUpdatedAt() throws {
        let originalDate = Date(timeIntervalSince1970: 1_000)
        let item = TodoItem(title: "Original", createdAt: originalDate)
        let store = TodoStore(todayItems: [item], persistenceURL: nil)

        store.setTodayHighlight(id: item.id, highlight: .blue)
        store.setTodayAlarm(id: item.id, alarmAt: Date(timeIntervalSince1970: 2_000))
        store.toggleTodayItemCompletion(id: item.id)
        XCTAssertEqual(store.todayItems[0].updatedAt, originalDate)

        store.toggleTodayItemCompletion(id: item.id)
        store.updateTodayTitle(id: item.id, title: "Edited")
        XCTAssertGreaterThan(store.todayItems[0].updatedAt, originalDate)
    }

    func testNewTaskUsesCreationTimeAsUpdatedAt() throws {
        let store = TodoStore(persistenceURL: nil)

        let item = try XCTUnwrap(store.addTaskPoolItem(title: "New task"))

        XCTAssertEqual(item.updatedAt, item.createdAt)
    }

    func testFillingTodaySlotResetsCreationAndUpdatedTimesTogether() {
        let oldDate = Date(timeIntervalSince1970: 1_000)
        let emptyItem = TodoItem(title: "", createdAt: oldDate)
        let store = TodoStore(todayItems: [emptyItem], persistenceURL: nil)

        store.updateTodayTitle(id: emptyItem.id, title: "New Today task")

        XCTAssertGreaterThan(store.todayItems[0].createdAt, oldDate)
        XCTAssertEqual(store.todayItems[0].updatedAt, store.todayItems[0].createdAt)
    }

    func testSearchMatchesTitleWithoutCaseSensitivity() {
        XCTAssertTrue(TodoSearch.matches(title: "Prepare Sales Report", query: "sales"))
        XCTAssertFalse(TodoSearch.matches(title: "Prepare Sales Report", query: "meeting"))
    }

    func testSearchTreatsBlankQueryAsShowingAllTasks() {
        XCTAssertTrue(TodoSearch.matches(title: "Any task", query: "  "))
    }
}
