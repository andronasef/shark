import XCTest
@testable import Shark

/// Regression tests for operations that used to lose or misplace user files.
@MainActor
final class DataSafetyTests: XCTestCase {
    var dir: URL!
    let fm = FileManager.default

    override func setUp() async throws {
        dir = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString).standardizedFileURL
        try fm.createDirectory(at: dir, withIntermediateDirectories: true)
        FileClipboardService.shared.clear()
        FileUndoService.shared.clear()
    }

    override func tearDown() async throws {
        try? fm.removeItem(at: dir)
        FileClipboardService.shared.clear()
        FileUndoService.shared.clear()
    }

    private func file(_ name: String, in folder: URL? = nil, _ text: String = "x") throws -> URL {
        let url = (folder ?? dir).appendingPathComponent(name)
        try text.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    private func folder(_ name: String) throws -> URL {
        let url = dir.appendingPathComponent(name)
        try fm.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    func testCutPasteIntoSameFolderKeepsFile() async throws {
        let report = try file("report.pdf")
        let nav = NavigationState(initialURL: dir)
        FileClipboardService.shared.cut([report])
        await nav.paste()
        XCTAssertTrue(fm.fileExists(atPath: report.path))
    }

    func testCutPasteNeverOverwritesExistingItem() async throws {
        let source = try folder("src")
        let target = try folder("dst")
        let moving = try file("a.txt", in: source, "new")
        let existing = try file("A.txt", in: target, "keep me")
        let nav = NavigationState(initialURL: target)
        FileClipboardService.shared.cut([moving])
        await nav.paste()
        XCTAssertEqual(try String(contentsOf: existing, encoding: .utf8), "keep me")
        XCTAssertTrue(fm.fileExists(atPath: moving.path), "Source must stay put when the paste is refused")
        XCTAssertNotNil(nav.operationError)
    }

    func testUndoOfCopyIntoSameFolderKeepsOriginal() async throws {
        let budget = try file("budget.xlsx", "original")
        let nav = NavigationState(initialURL: dir)
        FileClipboardService.shared.copy([budget])
        await nav.paste()
        let copy = dir.appendingPathComponent("budget copy 1.xlsx")
        XCTAssertTrue(fm.fileExists(atPath: copy.path))

        await nav.undo()
        XCTAssertEqual(try String(contentsOf: budget, encoding: .utf8), "original")
        XCTAssertFalse(fm.fileExists(atPath: copy.path))

        await nav.redo()
        XCTAssertTrue(fm.fileExists(atPath: copy.path), "Redo puts the copy back from the Trash")
    }

    func testCopyIntoItselfIsRefused() async throws {
        let parent = try folder("A")
        do {
            try await FileOperationsService.shared.copy(items: [parent], to: parent)
            XCTFail("Copying a folder into itself must throw")
        } catch {
            XCTAssertEqual(error as? FileOperationError, .intoItself("A"))
        }
        let contents = try fm.contentsOfDirectory(atPath: parent.path)
        XCTAssertTrue(contents.isEmpty)
    }

    func testMoveIntoDescendantIsRefused() async throws {
        let parent = try folder("A")
        let child = parent.appendingPathComponent("B")
        try fm.createDirectory(at: child, withIntermediateDirectories: true)
        do {
            try await FileOperationsService.shared.move(items: [parent], to: child)
            XCTFail("Moving a folder into its descendant must throw")
        } catch {
            XCTAssertEqual(error as? FileOperationError, .intoItself("A"))
        }
    }

    func testBatchRenameCollisionChangesNothing() async throws {
        let a = try file("a.txt")
        let b = try file("b.txt")
        _ = try file("x.txt")
        let rule = RenameRule(findText: "b", replaceText: "x")
        do {
            _ = try await FileOperationsService.shared.batchRename(items: [a, b], rule: rule)
            XCTFail("Renaming onto an existing file must throw")
        } catch {}
        XCTAssertTrue(fm.fileExists(atPath: a.path))
        XCTAssertTrue(fm.fileExists(atPath: b.path))
    }

    func testUndoOfBatchRenameSwap() async throws {
        // State after a batch rename that swapped the two names.
        let one = try file("one.txt", "was two")
        let two = try file("two.txt", "was one")
        FileUndoService.shared.record(.batchRename(pairs: [(source: one, destination: two), (source: two, destination: one)]))

        try await FileUndoService.shared.undo()
        XCTAssertEqual(try String(contentsOf: one, encoding: .utf8), "was one")
        XCTAssertEqual(try String(contentsOf: two, encoding: .utf8), "was two")

        try await FileUndoService.shared.redo()
        XCTAssertEqual(try String(contentsOf: one, encoding: .utf8), "was two")
    }

    func testBatchRenameRejectsSlash() async throws {
        let a = try file("a.txt")
        do {
            _ = try await FileOperationsService.shared.batchRename(items: [a], rule: RenameRule(findText: "a", replaceText: "x/y"))
            XCTFail("A name with / must throw")
        } catch {
            XCTAssertEqual(error as? FileOperationError, .invalidName("x/y.txt"))
        }
        XCTAssertTrue(fm.fileExists(atPath: a.path))
    }

    func testRenameRejectsPathEscapes() async throws {
        let a = try file("a.txt")
        for bad in ["../a.txt", "x:y", "..", ""] {
            do {
                _ = try await FileOperationsService.shared.rename(item: a, to: bad)
                XCTFail("\(bad) must be rejected")
            } catch {}
        }
        XCTAssertTrue(fm.fileExists(atPath: a.path))
    }

    func testCaseOnlyRename() async throws {
        let a = try file("readme.md")
        let renamed = try await FileOperationsService.shared.rename(item: a, to: "README.md")
        XCTAssertTrue(try fm.contentsOfDirectory(atPath: dir.path).contains("README.md"))
        XCTAssertEqual(renamed.lastPathComponent, "README.md")
    }

    func testTrashIsUndoable() async throws {
        let doomed = try file("doomed.txt", "precious")
        let nav = NavigationState(initialURL: dir)
        await nav.reloadCurrentDirectory()
        nav.selectedItemIDs = [nav.items[0].id]
        await nav.trashSelected()
        XCTAssertFalse(fm.fileExists(atPath: doomed.path))
        XCTAssertEqual(FileUndoService.shared.currentUndoDescription, "Trash")

        await nav.undo()
        XCTAssertEqual(try String(contentsOf: doomed, encoding: .utf8), "precious")
    }

    func testSelectAllAndTrashOnlyTouchVisibleItems() async throws {
        let draft = try file("draft.txt")
        let keep = try file("keep.txt")
        let nav = NavigationState(initialURL: dir)
        await nav.reloadCurrentDirectory()
        nav.selectedItemIDs = Set(nav.items.map(\.id))
        nav.filterText = "draft"
        XCTAssertEqual(nav.selectedItems.map(\.name), ["draft.txt"], "Filtering drops hidden items from the selection")

        nav.selectAll()
        await nav.trashSelected()
        XCTAssertFalse(fm.fileExists(atPath: draft.path))
        XCTAssertTrue(fm.fileExists(atPath: keep.path))
        await nav.undo()
    }

    func testShiftClickExtendsFromAnchor() {
        let names = ["a", "b", "c", "d"]
        let nav = NavigationState(initialURL: dir)
        nav.items = names.map { FileItem(url: dir.appendingPathComponent($0), name: $0, isDirectory: false) }
        let items = nav.filteredAndSortedItems
        nav.click(items[2], command: false, shift: false)
        nav.click(items[0], command: false, shift: true)
        XCTAssertEqual(nav.selectedItems.map(\.name), ["a", "b", "c"])
        nav.selectNextItem()
        XCTAssertEqual(nav.selectedItems.map(\.name), ["d"], "Arrow keys move from the anchor, not an arbitrary item")
    }

    func testShellQuotedRoundTripsHostileNames() throws {
        let hostile = "it's $(touch pwned) `id` \"q\"\nline"
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        process.arguments = ["-c", "printf %s " + hostile.shellQuoted]
        process.currentDirectoryURL = dir
        process.standardOutput = pipe
        try process.run()
        process.waitUntilExit()
        let output = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)
        XCTAssertEqual(output, hostile)
        XCTAssertFalse(fm.fileExists(atPath: dir.appendingPathComponent("pwned").path))
    }

    func testFailedBatchRenameUndoLeavesNamesIntactAndCanRetry() async throws {
        let renamed = try file("new.txt", "original")
        let old = try file("old.txt", "external")
        FileUndoService.shared.record(.batchRename(pairs: [(source: old, destination: renamed)]))
        do {
            try await FileUndoService.shared.undo()
            XCTFail("An occupied original name must refuse undo")
        } catch {}
        XCTAssertTrue(fm.fileExists(atPath: renamed.path))
        XCTAssertEqual(try String(contentsOf: old, encoding: .utf8), "external")
        XCTAssertFalse(try fm.contentsOfDirectory(atPath: dir.path).contains { $0.hasPrefix(".shark-rename-") })
        try fm.removeItem(at: old)
        try await FileUndoService.shared.undo()
        XCTAssertEqual(try String(contentsOf: old, encoding: .utf8), "original")
    }

}
