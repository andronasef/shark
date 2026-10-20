import XCTest
@testable import Shark

@MainActor
final class MillerColumnsTests: XCTestCase {
    var tempDirectory: URL!
    var subfolder: URL!
    var file1: URL!
    var file2: URL!

    override func setUp() async throws {
        tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)

        subfolder = tempDirectory.appendingPathComponent("SubDir")
        try FileManager.default.createDirectory(at: subfolder, withIntermediateDirectories: true)

        file1 = tempDirectory.appendingPathComponent("Note1.txt")
        try "Content 1".write(to: file1, atomically: true, encoding: .utf8)

        file2 = subfolder.appendingPathComponent("DeepNote.txt")
        try "Content 2".write(to: file2, atomically: true, encoding: .utf8)
    }

    override func tearDown() async throws {
        try? FileManager.default.removeItem(at: tempDirectory)
    }

    func testResetLoadsRootColumn() async throws {
        let coordinator = MillerColumnsCoordinator()
        coordinator.reset(rootDirectory: tempDirectory)

        XCTAssertEqual(coordinator.columns.count, 1)
        XCTAssertEqual(coordinator.columns[0].directoryURL, tempDirectory)

        // Wait for async load
        try await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertFalse(coordinator.columns[0].isLoading)
        XCTAssertEqual(coordinator.columns[0].items.count, 2) // subfolder + file1
    }

    func testSelectSubfolderExpandsColumn() async throws {
        let coordinator = MillerColumnsCoordinator()
        coordinator.reset(rootDirectory: tempDirectory)
        try await Task.sleep(nanoseconds: 100_000_000)

        guard let dirItem = coordinator.columns[0].items.first(where: { $0.isDirectory }) else {
            XCTFail("Missing directory item")
            return
        }

        coordinator.selectItem(dirItem, inColumn: 0)

        XCTAssertEqual(coordinator.columns.count, 2)
        XCTAssertEqual(coordinator.columns[0].selectedURL, dirItem.url)
        XCTAssertEqual(coordinator.columns[1].directoryURL, dirItem.url)
        XCTAssertNil(coordinator.previewItem)

        // Wait for column 1 to load
        try await Task.sleep(nanoseconds: 100_000_000)
        XCTAssertFalse(coordinator.columns[1].isLoading)
        XCTAssertEqual(coordinator.columns[1].items.count, 1) // DeepNote.txt
    }

    func testSelectFileShowsPreview() async throws {
        let coordinator = MillerColumnsCoordinator()
        coordinator.reset(rootDirectory: tempDirectory)
        try await Task.sleep(nanoseconds: 100_000_000)

        guard let fileItem = coordinator.columns[0].items.first(where: { !$0.isDirectory }) else {
            XCTFail("Missing file item")
            return
        }

        coordinator.selectItem(fileItem, inColumn: 0)

        XCTAssertEqual(coordinator.columns.count, 1)
        XCTAssertEqual(coordinator.columns[0].selectedURL, fileItem.url)
        XCTAssertEqual(coordinator.previewItem?.url, fileItem.url)
    }

    func testMoveSelectionAndLeftRightNavigation() async throws {
        let coordinator = MillerColumnsCoordinator()
        coordinator.reset(rootDirectory: tempDirectory)
        try await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertNil(coordinator.columns[0].selectedURL)

        // Move down to first item
        coordinator.moveSelection(by: 1)
        XCTAssertNotNil(coordinator.columns[0].selectedURL)

        // Move down to second item
        coordinator.moveSelection(by: 1)
        XCTAssertNotNil(coordinator.columns[0].selectedURL)

        // Left / Right navigation bounds checking
        coordinator.navigateLeft()
        XCTAssertEqual(coordinator.activeColumnIndex, 0) // Already at 0

        coordinator.navigateRight()
        // If no column 1 yet, remains 0
        XCTAssertTrue(coordinator.activeColumnIndex <= 1)
    }
}
