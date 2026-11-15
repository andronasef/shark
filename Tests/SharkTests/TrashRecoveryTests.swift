import XCTest
@testable import Shark

final class TrashRecoveryTests: XCTestCase {
    private var root: URL!
    override func setUpWithError() throws {
        root = FileManager.default.temporaryDirectory.appendingPathComponent("trash-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    }
    override func tearDown() { try? FileManager.default.removeItem(at: root) }

    private func make(_ path: String, _ text: String = "x") throws -> URL {
        let url = root.appendingPathComponent(path)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try text.write(to: url, atomically: true, encoding: .utf8)
        return url
    }
    private let stop: CollisionHandler = { _ in (.stop, false) }
    private let keepBoth: CollisionHandler = { _ in (.keepBoth, false) }

    func testRecordsSurviveRelaunchAndUnknownItemsHaveNone() throws {
        let file = root.appendingPathComponent("records.json")
        let trashed = try make("Trash/a.txt")
        TrashRecordStore(fileURL: file).add([(root.appendingPathComponent("docs/a.txt"), trashed)])
        let reopened = TrashRecordStore(fileURL: file)
        XCTAssertEqual(reopened.original(forTrashed: trashed)?.path, root.appendingPathComponent("docs/a.txt").path)
        XCTAssertNil(reopened.original(forTrashed: try make("Trash/unknown.txt")))
    }

    func testPruneDropsRecordsOfItemsThatLeftTheTrash() throws {
        let store = TrashRecordStore(fileURL: nil)
        let gone = root.appendingPathComponent("Trash/gone.txt")
        let kept = try make("Trash/kept.txt")
        store.add([(root.appendingPathComponent("o/gone.txt"), gone), (root.appendingPathComponent("o/kept.txt"), kept)])
        store.prune(trashFolder: root.appendingPathComponent("Trash"))
        XCTAssertEqual(store.count, 1)
        // An unreadable Trash must not wipe the records.
        store.prune(trashFolder: root.appendingPathComponent("Nope"))
        XCTAssertEqual(store.count, 1)
    }

    func testPutBackRestoresToTheOriginalPlace() async throws {
        let store = TrashRecordStore(fileURL: nil)
        let trashed = try make("Trash/a.txt", "data")
        try FileManager.default.createDirectory(at: root.appendingPathComponent("docs"), withIntermediateDirectories: true)
        store.add([(root.appendingPathComponent("docs/a.txt"), trashed)])
        let result = await FileOperationsService.shared.putBack(items: [trashed], store: store, resolve: stop)
        XCTAssertEqual(try String(contentsOf: root.appendingPathComponent("docs/a.txt")), "data")
        XCTAssertFalse(FileManager.default.fileExists(atPath: trashed.path))
        XCTAssertEqual(result.restored.count, 1)
        XCTAssertNil(store.original(forTrashed: trashed))
    }

    func testPutBackAsksOnClashAndKeepBothKeepsBoth() async throws {
        let store = TrashRecordStore(fileURL: nil)
        let trashed = try make("Trash/a.txt", "old")
        _ = try make("docs/a.txt", "new")
        store.add([(root.appendingPathComponent("docs/a.txt"), trashed)])
        _ = await FileOperationsService.shared.putBack(items: [trashed], store: store, resolve: keepBoth)
        XCTAssertEqual(try String(contentsOf: root.appendingPathComponent("docs/a.txt")), "new")
        XCTAssertEqual(try String(contentsOf: root.appendingPathComponent("docs/a 2.txt")), "old")
    }

    func testStoppedPutBackLeavesTheItemInTheTrashWithItsRecord() async throws {
        let store = TrashRecordStore(fileURL: nil)
        let trashed = try make("Trash/a.txt")
        _ = try make("docs/a.txt")
        store.add([(root.appendingPathComponent("docs/a.txt"), trashed)])
        let result = await FileOperationsService.shared.putBack(items: [trashed], store: store, resolve: stop)
        XCTAssertTrue(FileManager.default.fileExists(atPath: trashed.path))
        XCTAssertNotNil(store.original(forTrashed: trashed))
        XCTAssertTrue(result.restored.isEmpty)
    }

    func testMissingOriginalFolderAndUnrecordedItemsStayPutAndAreReported() async throws {
        let store = TrashRecordStore(fileURL: nil)
        let orphan = try make("Trash/orphan.txt")
        let unknown = try make("Trash/unknown.txt")
        store.add([(root.appendingPathComponent("deleted-folder/orphan.txt"), orphan)])
        let result = await FileOperationsService.shared.putBack(items: [orphan, unknown], store: store, resolve: stop)
        XCTAssertEqual(result.skipped.count, 2)
        XCTAssertTrue(FileManager.default.fileExists(atPath: orphan.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: unknown.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: root.appendingPathComponent("deleted-folder").path))
    }

    func testItemRenamedByTheTrashGetsItsOriginalNameBack() async throws {
        let store = TrashRecordStore(fileURL: nil)
        let trashed = try make("Trash/a 2.txt", "second")
        try FileManager.default.createDirectory(at: root.appendingPathComponent("docs"), withIntermediateDirectories: true)
        store.add([(root.appendingPathComponent("docs/a.txt"), trashed)])
        _ = await FileOperationsService.shared.putBack(items: [trashed], store: store, resolve: stop)
        XCTAssertEqual(try String(contentsOf: root.appendingPathComponent("docs/a.txt")), "second")
        let leftovers = try FileManager.default.contentsOfDirectory(atPath: root.appendingPathComponent("docs").path)
        XCTAssertEqual(leftovers, ["a.txt"])
    }

    func testSharkTrashCreatesARecordThatPutBackUses() async throws {
        let store = TrashRecordStore.shared
        let file = try make("docs/real.txt", "keep")
        let restorations = try await FileOperationsService.shared.trash(items: [file])
        defer { try? FileManager.default.removeItem(at: restorations[0].inTrash) }
        XCTAssertNotNil(store.original(forTrashed: restorations[0].inTrash))
        _ = await FileOperationsService.shared.putBack(items: [restorations[0].inTrash], resolve: stop)
        XCTAssertEqual(try String(contentsOf: file), "keep")
    }
}
