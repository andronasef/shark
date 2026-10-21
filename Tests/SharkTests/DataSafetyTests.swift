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

}
