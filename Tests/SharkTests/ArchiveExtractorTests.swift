import XCTest
@testable import Shark

final class ArchiveExtractorTests: XCTestCase {
    var root: URL!
    let fm = FileManager.default
    let keepAll: CollisionHandler = { _ in (.keepBoth, false) }

    override func setUpWithError() throws {
        root = fm.temporaryDirectory.appendingPathComponent("shark_extract_\(UUID().uuidString)")
        try fm.createDirectory(at: root, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws { try? fm.removeItem(at: root) }

    @discardableResult
    private func tool(_ path: String, _ args: [String], in dir: URL? = nil) throws -> Int32 {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = args
        process.currentDirectoryURL = dir
        try process.run()
        process.waitUntilExit()
        return process.terminationStatus
    }

    private func write(_ text: String, _ relative: String, in dir: URL) throws {
        let url = dir.appendingPathComponent(relative)
        try fm.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try text.write(to: url, atomically: true, encoding: .utf8)
    }

    private func text(_ relative: String) -> String? { try? String(contentsOf: root.appendingPathComponent(relative), encoding: .utf8) }

    /// Builds an archive from `files` (relative to a scratch folder) with the given tool and arguments.
    private func makeZip(named name: String, files: [String: String]) throws -> URL {
        let scratch = root.appendingPathComponent("scratch_\(UUID().uuidString)")
        for (path, body) in files { try write(body, path, in: scratch) }
        let archive = root.appendingPathComponent(name)
        XCTAssertEqual(try tool("/usr/bin/zip", ["-qr", archive.path] + files.keys.map { String($0.split(separator: "/")[0]) }.sorted().reduce(into: [String]()) { if !$0.contains($1) { $0.append($1) } }, in: scratch), 0)
        try fm.removeItem(at: scratch)
        return archive
    }

    private func stagingLeftovers() -> [String] {
        ((try? fm.contentsOfDirectory(atPath: root.path)) ?? []).filter { $0.hasPrefix(".shark-extract-") }
    }

    func testSingleFileLandsBesideTheArchive() async throws {
        let archive = try makeZip(named: "one.zip", files: ["note.txt": "hello"])
        let result = try await ArchiveExtractor.extract(archive, resolve: keepAll)
        XCTAssertNil(result.error)
        XCTAssertEqual(text("note.txt"), "hello")
        XCTAssertTrue(stagingLeftovers().isEmpty)
    }

    func testSeveralTopLevelItemsGoIntoAFolderNamedAfterTheArchive() async throws {
        let archive = try makeZip(named: "bundle.zip", files: ["a.txt": "A", "b.txt": "B"])
        _ = try await ArchiveExtractor.extract(archive, resolve: keepAll)
        XCTAssertEqual(text("bundle/a.txt"), "A")
        XCTAssertEqual(text("bundle/b.txt"), "B")
        XCTAssertNil(text("a.txt"), "loose files are not scattered next to the archive")
    }

    func testASingleTopLevelFolderIsNotNestedAgain() async throws {
        let archive = try makeZip(named: "wrapper.zip", files: ["Project/readme.md": "R", "Project/src/main.c": "M"])
        _ = try await ArchiveExtractor.extract(archive, resolve: keepAll)
        XCTAssertEqual(text("Project/readme.md"), "R")
        XCTAssertEqual(text("Project/src/main.c"), "M")
        XCTAssertNil(text("wrapper/Project/readme.md"))
    }

    func testMacOSZipLeftoversAreIgnored() async throws {
        // A zip made the way Finder makes it: ditto writes real __MACOSX/._ metadata entries.
        let scratch = root.appendingPathComponent("macsrc")
        try write("A", "Doc/a.txt", in: scratch)
        XCTAssertEqual(try tool("/usr/bin/xattr", ["-w", "com.apple.test", "x", scratch.appendingPathComponent("Doc/a.txt").path]), 0)
        let archive = root.appendingPathComponent("mac.zip")
        XCTAssertEqual(try tool("/usr/bin/ditto", ["-c", "-k", "--sequesterRsrc", "--keepParent", scratch.appendingPathComponent("Doc").path, archive.path]), 0)
        _ = try await ArchiveExtractor.extract(archive, resolve: keepAll)
        XCTAssertEqual(text("Doc/a.txt"), "A")
        XCTAssertFalse(fm.fileExists(atPath: root.appendingPathComponent("__MACOSX").path))
        XCTAssertFalse(fm.fileExists(atPath: root.appendingPathComponent("mac").path), "the leftover does not count as a second item")
    }

    func testUnusableMetadataEntryDoesNotFailTheExtraction() async throws {
        let archive = try makeZip(named: "junk.zip", files: ["Doc/a.txt": "A", "__MACOSX/Doc/._a.txt": "not appledouble"])
        _ = try await ArchiveExtractor.extract(archive, resolve: keepAll)
        XCTAssertEqual(text("Doc/a.txt"), "A")
    }

    func testTarballNameStripsBothExtensions() async throws {
        XCTAssertEqual(ArchiveExtractor.baseName(of: URL(fileURLWithPath: "/x/photos.tar.gz")), "photos")
        XCTAssertEqual(ArchiveExtractor.baseName(of: URL(fileURLWithPath: "/x/photos.zip")), "photos")
        XCTAssertEqual(ArchiveExtractor.baseName(of: URL(fileURLWithPath: "/x/v1.2.tgz")), "v1.2")
        let scratch = root.appendingPathComponent("src")
        try write("1", "a.txt", in: scratch); try write("2", "b.txt", in: scratch)
        let archive = root.appendingPathComponent("pair.tar.gz")
        XCTAssertEqual(try tool("/usr/bin/bsdtar", ["-czf", archive.path, "a.txt", "b.txt"], in: scratch), 0)
        _ = try await ArchiveExtractor.extract(archive, resolve: keepAll)
        XCTAssertEqual(text("pair/a.txt"), "1")
    }

    func testNameClashUsesTheSharedChoicesAndUndoRemovesTheExtractedItem() async throws {
        try write("existing", "note.txt", in: root)
        let archive = try makeZip(named: "one.zip", files: ["note.txt": "from archive"])
        let result = try await ArchiveExtractor.extract(archive, resolve: keepAll)
        XCTAssertEqual(text("note.txt"), "existing")
        XCTAssertEqual(text("note 2.txt"), "from archive")

        let undo = await FileUndoService()
        await undo.record(try XCTUnwrap(result.undoAction(for: .move)))
        try await undo.undo()
        XCTAssertNil(text("note 2.txt"), "undo removes only what was extracted")
        XCTAssertEqual(text("note.txt"), "existing")
    }

    func testReplaceKeepsTheOldItemInTheTrashAndStagingIsGone() async throws {
        try write("old", "note.txt", in: root)
        let archive = try makeZip(named: "one.zip", files: ["note.txt": "new"])
        let result = try await ArchiveExtractor.extract(archive) { _ in (.replace, false) }
        XCTAssertEqual(text("note.txt"), "new")
        XCTAssertTrue(stagingLeftovers().isEmpty)
        let undo = await FileUndoService()
        await undo.record(try XCTUnwrap(result.undoAction(for: .move)))
        try await undo.undo()
        XCTAssertEqual(text("note.txt"), "old", "undo brings the replaced item back")
    }

    private func craftedTar(_ python: String, named name: String) throws -> URL {
        let archive = root.appendingPathComponent(name)
        let script = "import tarfile, io\nt = tarfile.open(r'\(archive.path)', 'w')\n\(python)\nt.close()\n"
        let status = try tool("/usr/bin/env", ["python3", "-c", script])
        try XCTSkipIf(status != 0, "python3 is not available to craft the archive")
        return archive
    }

    func testTraversalAndAbsolutePathsAreRefusedBeforeAnythingIsWritten() async throws {
        let inner = root.appendingPathComponent("inner")
        try fm.createDirectory(at: inner, withIntermediateDirectories: true)
        let archive = try craftedTar("""
        for name in ['../evil.txt', '/tmp/shark-abs-evil.txt']:
            info = tarfile.TarInfo(name); data = b'x'; info.size = len(data); t.addfile(info, io.BytesIO(data))
        """, named: "evil.tar")
        let moved = inner.appendingPathComponent("evil.tar")
        try fm.moveItem(at: archive, to: moved)
        do {
            _ = try await ArchiveExtractor.extract(moved, resolve: keepAll)
            XCTFail("an unsafe archive must be refused")
        } catch let error as ArchiveError {
            XCTAssertEqual(error, .unsafePath("evil.tar"))
        }
        XCTAssertFalse(fm.fileExists(atPath: root.appendingPathComponent("evil.txt").path))
        XCTAssertFalse(fm.fileExists(atPath: "/tmp/shark-abs-evil.txt"))
        XCTAssertTrue(((try? fm.contentsOfDirectory(atPath: inner.path)) ?? []).allSatisfy { !$0.hasPrefix(".shark-extract-") })
    }

    func testWritingThroughAnArchivedLinkNeverEscapes() async throws {
        let inner = root.appendingPathComponent("inner")
        let outside = root.appendingPathComponent("outside")
        try fm.createDirectory(at: inner, withIntermediateDirectories: true)
        try fm.createDirectory(at: outside, withIntermediateDirectories: true)
        let archive = try craftedTar("""
        link = tarfile.TarInfo('link'); link.type = tarfile.SYMTYPE; link.linkname = '\(outside.path)'; t.addfile(link)
        info = tarfile.TarInfo('link/evil.txt'); data = b'x'; info.size = len(data); t.addfile(info, io.BytesIO(data))
        """, named: "link.tar")
        let moved = inner.appendingPathComponent("link.tar")
        try fm.moveItem(at: archive, to: moved)
        _ = try? await ArchiveExtractor.extract(moved, resolve: keepAll)
        XCTAssertFalse(fm.fileExists(atPath: outside.appendingPathComponent("evil.txt").path), "nothing is written through a link")
        XCTAssertTrue(((try? fm.contentsOfDirectory(atPath: inner.path)) ?? []).allSatisfy { !$0.hasPrefix(".shark-extract-") })
    }

    func testUnreadableFileOffersArchiveUtilityAndLeavesNothingBehind() async throws {
        let fake = root.appendingPathComponent("broken.zip")
        try Data("this is not an archive".utf8).write(to: fake)
        do {
            _ = try await ArchiveExtractor.extract(fake, resolve: keepAll)
            XCTFail("a non-archive must not extract")
        } catch let error as ArchiveError {
            XCTAssertTrue(error.offersArchiveUtility)
        }
        XCTAssertTrue(stagingLeftovers().isEmpty)
        XCTAssertTrue(fm.fileExists(atPath: fake.path), "the original is untouched")
    }

    func testStuffItIsHandedToArchiveUtility() async throws {
        let sit = root.appendingPathComponent("old.sit")
        try Data("x".utf8).write(to: sit)
        do { _ = try await ArchiveExtractor.extract(sit, resolve: keepAll); XCTFail() }
        catch let error as ArchiveError { XCTAssertTrue(error.offersArchiveUtility) }
        XCTAssertTrue(ArchiveExtractor.isArchive(sit))
    }

    func testEmptyArchiveIsReported() async throws {
        let archive = root.appendingPathComponent("empty.tar")
        XCTAssertEqual(try tool("/usr/bin/bsdtar", ["-cf", archive.path, "--files-from", "/dev/null"]), 0)
        do { _ = try await ArchiveExtractor.extract(archive, resolve: keepAll); XCTFail() }
        catch let error as ArchiveError { XCTAssertEqual(error, .empty("empty.tar")) }
    }
}
