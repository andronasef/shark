import XCTest
@testable import Shark

private final class Answers: @unchecked Sendable {
    private let lock = NSLock()
    private var queue: [(CollisionChoice, Bool)]
    private var seen: [CollisionPrompt] = []
    init(_ queue: [(CollisionChoice, Bool)]) { self.queue = queue }
    var prompts: [CollisionPrompt] { lock.withLock { seen } }
    private func next(_ prompt: CollisionPrompt) -> (CollisionChoice, Bool) {
        lock.withLock {
            seen.append(prompt)
            return queue.isEmpty ? (.stop, false) : queue.removeFirst()
        }
    }
    var handler: CollisionHandler { { prompt in
        let answer = self.next(prompt)
        return (answer.0, answer.1)
    } }
}

final class CollisionTransferTests: XCTestCase {
    var root: URL!
    var source: URL!
    var dest: URL!
    let fm = FileManager.default

    override func setUpWithError() throws {
        root = fm.temporaryDirectory.appendingPathComponent("shark_collision_\(UUID().uuidString)")
        source = root.appendingPathComponent("source")
        dest = root.appendingPathComponent("dest")
        try fm.createDirectory(at: source, withIntermediateDirectories: true)
        try fm.createDirectory(at: dest, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws { try? fm.removeItem(at: root) }

    @discardableResult
    private func write(_ text: String, _ name: String, in dir: URL) throws -> URL {
        let url = dir.appendingPathComponent(name)
        try fm.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try text.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    private func text(_ url: URL) -> String? { try? String(contentsOf: url, encoding: .utf8) }

    func testNoClashNeverAsksAndMoves() async throws {
        let a = try write("a", "a.txt", in: source)
        let answers = Answers([])
        let result = await FileOperationsService.shared.transfer(items: [a], to: dest, mode: .move, resolve: answers.handler)
        XCTAssertTrue(answers.prompts.isEmpty)
        XCTAssertNil(result.error)
        XCTAssertEqual(text(dest.appendingPathComponent("a.txt")), "a")
        XCTAssertFalse(fm.fileExists(atPath: a.path))
    }

    func testKeepBothNumbersAndKeepsExtension() async throws {
        let a = try write("new", "photo.jpg", in: source)
        try write("old", "photo.jpg", in: dest)
        try write("old2", "photo 2.jpg", in: dest)
        let result = await FileOperationsService.shared.transfer(items: [a], to: dest, mode: .copy, resolve: Answers([(.keepBoth, false)]).handler)
        XCTAssertNil(result.error)
        XCTAssertEqual(text(dest.appendingPathComponent("photo.jpg")), "old")
        XCTAssertEqual(text(dest.appendingPathComponent("photo 2.jpg")), "old2")
        XCTAssertEqual(text(dest.appendingPathComponent("photo 3.jpg")), "new")
        XCTAssertEqual(text(a), "new", "a copy leaves the source")
    }

    func testDuplicateNamingIsUnchanged() async throws {
        let a = try write("a", "doc.txt", in: dest)
        let created = try await FileOperationsService.shared.duplicate(items: [a])
        XCTAssertEqual(created.first?.lastPathComponent, "doc copy 1.txt")
    }

    func testReplaceTrashesTheOldItemAndUndoRestoresBoth() async throws {
        let a = try write("new", "a.txt", in: source)
        try write("old", "a.txt", in: dest)
        let result = await FileOperationsService.shared.transfer(items: [a], to: dest, mode: .move, resolve: Answers([(.replace, false)]).handler)
        XCTAssertNil(result.error)
        XCTAssertEqual(text(dest.appendingPathComponent("a.txt")), "new")

        let undo = await FileUndoService()
        await undo.record(try XCTUnwrap(result.undoAction(for: .move)))
        try await undo.undo()
        XCTAssertEqual(text(dest.appendingPathComponent("a.txt")), "old", "the replaced item comes back")
        XCTAssertEqual(text(a), "new", "the moved item returns to its folder")

        try await undo.redo()
        XCTAssertEqual(text(dest.appendingPathComponent("a.txt")), "new")
        XCTAssertFalse(fm.fileExists(atPath: a.path))
    }

    func testReplaceByCopyUndoRestoresTheOriginal() async throws {
        let a = try write("new", "a.txt", in: source)
        try write("old", "a.txt", in: dest)
        let result = await FileOperationsService.shared.transfer(items: [a], to: dest, mode: .copy, resolve: Answers([(.replace, false)]).handler)
        XCTAssertEqual(text(dest.appendingPathComponent("a.txt")), "new")
        let undo = await FileUndoService()
        await undo.record(try XCTUnwrap(result.undoAction(for: .copy)))
        try await undo.undo()
        XCTAssertEqual(text(dest.appendingPathComponent("a.txt")), "old")
        XCTAssertEqual(text(a), "new")
    }

    func testSkipLeavesBothAndContinues() async throws {
        let a = try write("a-new", "a.txt", in: source)
        let b = try write("b-new", "b.txt", in: source)
        try write("a-old", "a.txt", in: dest)
        let result = await FileOperationsService.shared.transfer(items: [a, b], to: dest, mode: .move, resolve: Answers([(.skip, false)]).handler)
        XCTAssertNil(result.error)
        XCTAssertEqual(text(dest.appendingPathComponent("a.txt")), "a-old")
        XCTAssertEqual(text(a), "a-new")
        XCTAssertEqual(text(dest.appendingPathComponent("b.txt")), "b-new")
    }

    func testStopKeepsCompletedWorkAndUndoableResult() async throws {
        let b = try write("b-new", "b.txt", in: source)
        let a = try write("a-new", "a.txt", in: source)
        let c = try write("c-new", "c.txt", in: source)
        try write("a-old", "a.txt", in: dest)
        let result = await FileOperationsService.shared.transfer(items: [b, a, c], to: dest, mode: .move, resolve: Answers([(.stop, false)]).handler)
        XCTAssertTrue(result.stopped)
        XCTAssertEqual(text(dest.appendingPathComponent("b.txt")), "b-new", "work finished before the conflict stays")
        XCTAssertEqual(text(a), "a-new")
        XCTAssertEqual(text(c), "c-new", "items after Stop are untouched")
        XCTAssertNotNil(result.undoAction(for: .move))
    }

    func testApplyToAllAsksOnce() async throws {
        let names = ["a.txt", "b.txt", "c.txt"]
        let items = try names.map { try write("new-\($0)", $0, in: source) }
        for n in names { try write("old-\(n)", n, in: dest) }
        let answers = Answers([(.keepBoth, true)])
        let result = await FileOperationsService.shared.transfer(items: items, to: dest, mode: .move, resolve: answers.handler)
        XCTAssertNil(result.error)
        XCTAssertEqual(answers.prompts.count, 1)
        for n in names {
            XCTAssertEqual(text(dest.appendingPathComponent(n)), "old-\(n)")
        }
        XCTAssertEqual(text(dest.appendingPathComponent("b 2.txt")), "new-b.txt")
    }

    func testTwoSourcesWithTheSameNameAreResolved() async throws {
        let other = root.appendingPathComponent("other")
        let first = try write("one", "same.txt", in: source)
        let second = try write("two", "same.txt", in: other)
        let result = await FileOperationsService.shared.transfer(items: [first, second], to: dest, mode: .copy, resolve: Answers([(.keepBoth, false)]).handler)
        XCTAssertNil(result.error)
        XCTAssertEqual(text(dest.appendingPathComponent("same.txt")), "one")
        XCTAssertEqual(text(dest.appendingPathComponent("same 2.txt")), "two")
    }

    func testMergeCombinesFoldersAndAsksAboutChildConflicts() async throws {
        let folder = source.appendingPathComponent("Project")
        try write("new-x", "x.txt", in: folder)
        try write("new-y", "sub/y.txt", in: folder)
        try write("only-new", "fresh.txt", in: folder)
        let target = dest.appendingPathComponent("Project")
        try write("old-x", "x.txt", in: target)
        try write("old-z", "z.txt", in: target)

        // Merge the folders; for the file clash inside, Replace.
        let answers = Answers([(.merge, false), (.replace, false)])
        let result = await FileOperationsService.shared.transfer(items: [folder], to: dest, mode: .move, resolve: answers.handler)
        XCTAssertNil(result.error)
        XCTAssertEqual(answers.prompts.count, 2)
        XCTAssertTrue(answers.prompts[0].canMerge)
        XCTAssertFalse(answers.prompts[1].canMerge)
        XCTAssertEqual(text(target.appendingPathComponent("x.txt")), "new-x")
        XCTAssertEqual(text(target.appendingPathComponent("z.txt")), "old-z", "files only in the destination stay")
        XCTAssertEqual(text(target.appendingPathComponent("sub/y.txt")), "new-y")
        XCTAssertEqual(text(target.appendingPathComponent("fresh.txt")), "only-new")
        XCTAssertFalse(fm.fileExists(atPath: folder.path), "the emptied source folder is trashed")

        let undo = await FileUndoService()
        await undo.record(try XCTUnwrap(result.undoAction(for: .move)))
        try await undo.undo()
        XCTAssertEqual(text(target.appendingPathComponent("x.txt")), "old-x")
        XCTAssertNil(text(target.appendingPathComponent("fresh.txt")))
        XCTAssertEqual(text(folder.appendingPathComponent("x.txt")), "new-x")
        XCTAssertEqual(text(folder.appendingPathComponent("sub/y.txt")), "new-y")
    }

    func testMergeApplyToAllCoversNestedFolders() async throws {
        let folder = source.appendingPathComponent("P")
        try write("n", "a/one.txt", in: folder)
        try write("n", "a/b/two.txt", in: folder)
        let target = dest.appendingPathComponent("P")
        try write("o", "a/b/keep.txt", in: target)
        let answers = Answers([(.merge, true)])
        let result = await FileOperationsService.shared.transfer(items: [folder], to: dest, mode: .copy, resolve: answers.handler)
        XCTAssertNil(result.error)
        XCTAssertEqual(answers.prompts.count, 1, "folders a and a/b merge without asking again")
        XCTAssertEqual(text(target.appendingPathComponent("a/b/keep.txt")), "o")
        XCTAssertEqual(text(target.appendingPathComponent("a/b/two.txt")), "n")
        XCTAssertEqual(text(folder.appendingPathComponent("a/one.txt")), "n", "a copy leaves the source")
    }

    func testFolderLinkIsNeverMergedInto() async throws {
        let outside = root.appendingPathComponent("outside")
        try write("untouched", "keep.txt", in: outside)
        try fm.createSymbolicLink(at: dest.appendingPathComponent("Docs"), withDestinationURL: outside)
        let folder = source.appendingPathComponent("Docs")
        try write("new", "fresh.txt", in: folder)
        let answers = Answers([(.keepBoth, false)])
        let result = await FileOperationsService.shared.transfer(items: [folder], to: dest, mode: .copy, resolve: answers.handler)
        XCTAssertNil(result.error)
        XCTAssertFalse(answers.prompts[0].canMerge, "a link to a folder is not a folder to merge into")
        XCTAssertNil(text(outside.appendingPathComponent("fresh.txt")), "nothing was written through the link")
        XCTAssertEqual(text(dest.appendingPathComponent("Docs 2/fresh.txt")), "new")
    }

    func testCopiedFolderLinkStaysALink() async throws {
        let outside = root.appendingPathComponent("outside")
        try write("x", "inside.txt", in: outside)
        let folder = source.appendingPathComponent("Box")
        try fm.createDirectory(at: folder, withIntermediateDirectories: true)
        try fm.createSymbolicLink(at: folder.appendingPathComponent("link"), withDestinationURL: outside)
        let target = dest.appendingPathComponent("Box")
        try fm.createDirectory(at: target, withIntermediateDirectories: true)
        let result = await FileOperationsService.shared.transfer(items: [folder], to: dest, mode: .copy, resolve: Answers([(.merge, false)]).handler)
        XCTAssertNil(result.error)
        let copiedLink = target.appendingPathComponent("link")
        XCTAssertEqual((try? fm.destinationOfSymbolicLink(atPath: copiedLink.path)), outside.path, "the link is copied as a link, not as its contents")
    }

    func testReplaceRefusesToTrashTheFolderHoldingTheSource() async throws {
        let inner = try write("inner", "Box/Box/file.txt", in: dest)
        let item = inner.deletingLastPathComponent()  // dest/Box/Box
        let result = await FileOperationsService.shared.transfer(items: [item], to: dest, mode: .move, resolve: Answers([(.replace, false)]).handler)
        XCTAssertNotNil(result.error)
        XCTAssertEqual(text(inner), "inner", "nothing was lost")
    }
}
