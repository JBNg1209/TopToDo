import Foundation
import XCTest
@testable import TopToDoCore

final class TodoPersistenceTests: XCTestCase {
    func testSavedStatePersistsMetadataAndDoesNotWriteDateResetMetadata() throws {
        let file = try makePersistenceURL()
        defer { try? FileManager.default.removeItem(at: file.deletingLastPathComponent()) }
        let store = TodoStore(persistenceURL: file)
        let id = store.todayItems[0].id
        let reminder = Date().addingTimeInterval(5_400)

        store.updateTodayTitle(id: id, title: "Keep tomorrow")
        store.setTodayHighlight(id: id, highlight: .blue)
        store.setTodayAlarm(id: id, alarmAt: reminder)

        let savedJSON = try String(contentsOf: file, encoding: .utf8)
        XCTAssertFalse(savedJSON.contains("todayKey"))
        XCTAssertTrue(savedJSON.contains("highlight"))
        XCTAssertFalse(savedJSON.contains("isHighlighted"))
        XCTAssertTrue(savedJSON.contains("updatedAt"))
        XCTAssertTrue(savedJSON.contains("alarmAt"))

        let reloaded = TodoStore(persistenceURL: file)
        let item = try XCTUnwrap(reloaded.todayItems.first)
        XCTAssertEqual(item.title, "Keep tomorrow")
        XCTAssertEqual(item.highlight, .blue)
        XCTAssertEqual(item.alarmAt, reminder)
    }

    func testLegacyItemsReceiveDefaultsForNewFields() throws {
        let file = try makePersistenceURL()
        defer { try? FileManager.default.removeItem(at: file.deletingLastPathComponent()) }
        let legacyJSON = """
        {
          "todayItems": [{
            "id": "\(UUID())",
            "title": "Legacy today",
            "isCompleted": false,
            "createdAt": "2026-06-12T08:00:00Z"
          }],
          "topItems": [{
            "id": "\(UUID())",
            "title": "Legacy pool",
            "isCompleted": true,
            "createdAt": "2026-06-12T09:00:00Z"
          }]
        }
        """
        try legacyJSON.write(to: file, atomically: true, encoding: .utf8)

        let store = TodoStore(persistenceURL: file)

        XCTAssertEqual(store.todayItems[0].title, "Legacy today")
        XCTAssertFalse(store.todayItems[0].isHighlighted)
        XCTAssertEqual(store.todayItems[0].updatedAt, store.todayItems[0].createdAt)
        XCTAssertNil(store.todayItems[0].alarmAt)
        XCTAssertEqual(store.taskPoolItems[0].title, "Legacy pool")
    }

    func testLegacyBooleanHighlightMapsToRed() throws {
        let file = try makePersistenceURL()
        defer { try? FileManager.default.removeItem(at: file.deletingLastPathComponent()) }
        let createdAt = "2026-06-12T08:00:00Z"
        let legacyJSON = """
        {
          "todayItems": [{
            "id": "\(UUID())",
            "title": "Legacy highlighted task",
            "isCompleted": false,
            "isHighlighted": true,
            "createdAt": "\(createdAt)"
          }],
          "taskPoolItems": []
        }
        """
        try legacyJSON.write(to: file, atomically: true, encoding: .utf8)

        let item = TodoStore(persistenceURL: file).todayItems[0]

        XCTAssertEqual(item.highlight, .red)
        XCTAssertEqual(item.updatedAt, item.createdAt)
    }

    func testLegacyArrayFormatLoadsIntoTaskPool() throws {
        let file = try makePersistenceURL()
        defer { try? FileManager.default.removeItem(at: file.deletingLastPathComponent()) }
        let legacyJSON = """
        [{
          "id": "\(UUID())",
          "title": "Legacy array item",
          "isCompleted": false,
          "createdAt": "2026-06-12T08:00:00Z"
        }]
        """
        try legacyJSON.write(to: file, atomically: true, encoding: .utf8)

        let store = TodoStore(persistenceURL: file)

        XCTAssertTrue(store.todayItems.allSatisfy(\.title.isEmpty))
        XCTAssertEqual(store.taskPoolItems.map(\.title), ["Legacy array item"])
    }

    private func makePersistenceURL() throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent("todos.json")
    }
}
