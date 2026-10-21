import XCTest
@testable import Shark

final class SubfolderMenuTests: XCTestCase {
    private var root: URL!

    override func setUpWithError() throws {
        root = FileManager.default.temporaryDirectory.appendingPathComponent("subfolder-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: root)
    }

    @MainActor
    func testMenuCascadesSixLevelsDeepAndListsTheFileAtTheBottom() throws {
        var deepest = root!
        for level in 1...6 { deepest.appendPathComponent("level\(level)", isDirectory: true) }
        try FileManager.default.createDirectory(at: deepest, withIntermediateDirectories: true)
        try "x".write(to: deepest.appendingPathComponent("target.txt"), atomically: true, encoding: .utf8)

        let builder = SubfolderMenuBuilder { _, _ in }
        var menu = builder.buildMenu(for: root)
        for level in 1...6 {
            let item = try XCTUnwrap(menu.items.first { $0.title == "level\(level)" }, "level \(level)")
            let submenu = try XCTUnwrap(item.submenu)
            builder.menuNeedsUpdate(submenu) // AppKit calls this when the submenu opens
            menu = submenu
        }
        XCTAssertEqual(menu.items.map(\.title), ["target.txt"])
    }

    @MainActor
    func testClickOpensFoldersAndCommandOpensInANewTab() throws {
        var calls: [(URL, Bool)] = []
        let builder = SubfolderMenuBuilder { calls.append(($0, $1)) }
        builder.activate(root, modifiers: [])
        builder.activate(root, modifiers: .command)
        XCTAssertEqual(calls.map(\.1), [false, true])
    }

    @MainActor
    func testOptionClickCopiesInsteadOfOpening() throws {
        var navigated = false
        let builder = SubfolderMenuBuilder { _, _ in navigated = true }
        let file = root.appendingPathComponent("a.txt")
        try "x".write(to: file, atomically: true, encoding: .utf8)
        defer { FileClipboardService.shared.clear() }

        builder.activate(file, modifiers: .option)
        builder.activate(root, modifiers: .option)

        XCTAssertFalse(navigated)
        XCTAssertEqual(FileClipboardService.shared.getPasteableURLs()?.urls, [root.standardizedFileURL])
    }
}
