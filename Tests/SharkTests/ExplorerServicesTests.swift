import XCTest
@testable import Shark

@MainActor
final class ExplorerServicesTests: XCTestCase {
    var tempDirectory: URL!
    var clipboard: FileClipboardService!
    var undoService: FileUndoService!

    override func setUp() async throws {
        tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        clipboard = FileClipboardService()
        undoService = FileUndoService()
    }

    override func tearDown() async throws {
        try? FileManager.default.removeItem(at: tempDirectory)
        clipboard.clear()
        undoService.clear()
        FileClipboardService.shared.clear()
        FileUndoService.shared.clear()
    }

    func testClipboardCutAndCopy() {
        let file1 = tempDirectory.appendingPathComponent("file1.txt")
        let file2 = tempDirectory.appendingPathComponent("file2.txt")
        try? "test".write(to: file1, atomically: true, encoding: .utf8)
        try? "test".write(to: file2, atomically: true, encoding: .utf8)

        clipboard.cut([file1])
        XCTAssertEqual(clipboard.mode, .cut)
        XCTAssertTrue(clipboard.isCut(file1))
        XCTAssertFalse(clipboard.isCut(file2))
        XCTAssertTrue(clipboard.hasItemsToPaste)

        clipboard.copy([file2])
        XCTAssertEqual(clipboard.mode, .copy)
        XCTAssertFalse(clipboard.isCut(file1))
        XCTAssertFalse(clipboard.isCut(file2))

        clipboard.clear()
        XCTAssertFalse(clipboard.hasItemsToPaste)
        XCTAssertEqual(clipboard.items.count, 0)
    }

    func testUndoRedoMove() async throws {
        let sourceDir = tempDirectory.appendingPathComponent("source")
        let destDir = tempDirectory.appendingPathComponent("dest")
        try FileManager.default.createDirectory(at: sourceDir, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: destDir, withIntermediateDirectories: true)

        let file = sourceDir.appendingPathComponent("hello.txt")
        try "content".write(to: file, atomically: true, encoding: .utf8)

        let targetFile = destDir.appendingPathComponent("hello.txt")
        try FileManager.default.moveItem(at: file, to: targetFile)

        undoService.record(.move(pairs: [(source: file, destination: targetFile)]))
        XCTAssertTrue(undoService.canUndo)
        XCTAssertFalse(undoService.canRedo)
        XCTAssertEqual(undoService.currentUndoDescription, "Move")

        // Perform Undo -> Moves back to source
        try await undoService.undo()
        XCTAssertTrue(FileManager.default.fileExists(atPath: file.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: targetFile.path))
        XCTAssertFalse(undoService.canUndo)
        XCTAssertTrue(undoService.canRedo)

        // Perform Redo -> Moves back to destination
        try await undoService.redo()
        XCTAssertFalse(FileManager.default.fileExists(atPath: file.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: targetFile.path))
        XCTAssertTrue(undoService.canUndo)
        XCTAssertFalse(undoService.canRedo)
    }

    func testUndoRedoRename() async throws {
        let original = tempDirectory.appendingPathComponent("old.txt")
        let renamed = tempDirectory.appendingPathComponent("new.txt")
        try "rename me".write(to: original, atomically: true, encoding: .utf8)
        try FileManager.default.moveItem(at: original, to: renamed)

        undoService.record(.rename(original: original, current: renamed))

        // Undo
        try await undoService.undo()
        XCTAssertTrue(FileManager.default.fileExists(atPath: original.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: renamed.path))

        // Redo
        try await undoService.redo()
        XCTAssertFalse(FileManager.default.fileExists(atPath: original.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: renamed.path))
    }

    func testDiskSpaceQuery() {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let spaceInfo = DiskSpaceService.shared.getDiskSpace(for: home)
        XCTAssertNotNil(spaceInfo)
        XCTAssertGreaterThan(spaceInfo?.availableBytes ?? 0, 0)
        XCTAssertTrue(spaceInfo?.summary.contains("available") == true)
    }

    func testNavigationStateExplorerOperations() async throws {
        let fileA = tempDirectory.appendingPathComponent("alpha.txt")
        let fileB = tempDirectory.appendingPathComponent("beta.txt")
        try "alpha contents".write(to: fileA, atomically: true, encoding: .utf8)
        try "beta longer contents".write(to: fileB, atomically: true, encoding: .utf8)

        let nav = NavigationState(initialURL: tempDirectory)
        await nav.reloadCurrentDirectory()

        XCTAssertEqual(nav.items.count, 2)

        // Selection & Total Size
        nav.selectedItemIDs = Set(nav.items.map(\.url))
        XCTAssertEqual(nav.selectedItems.count, 2)
        XCTAssertGreaterThan(nav.selectedTotalSize, 0)

        // Rename alpha.txt to gamma.txt
        let itemA = nav.items.first { $0.name == "alpha.txt" }!
        await nav.commitRename(url: itemA.url, newName: "gamma.txt")
        let gammaURL = tempDirectory.standardizedFileURL.appendingPathComponent("gamma.txt")
        XCTAssertTrue(FileManager.default.fileExists(atPath: gammaURL.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: itemA.url.path))

        // Undo Rename
        await nav.undo()
        XCTAssertTrue(FileManager.default.fileExists(atPath: itemA.url.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: gammaURL.path))

        // Redo Rename
        await nav.redo()
        XCTAssertTrue(FileManager.default.fileExists(atPath: gammaURL.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: itemA.url.path))
    }
}
