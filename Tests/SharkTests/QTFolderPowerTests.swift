import XCTest
@testable import Shark

@MainActor
final class QTFolderPowerTests: XCTestCase {
    var tempDirectory: URL!

    override func setUp() async throws {
        tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent("shark_qt_test_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    override func tearDown() async throws {
        try? FileManager.default.removeItem(at: tempDirectory)
    }

    func testRecentFoldersService() {
        let storageURL = tempDirectory.appendingPathComponent("recent_test.json")
        let service = RecentFoldersService(storageURL: storageURL)

        let folder1 = tempDirectory.appendingPathComponent("FolderA")
        let folder2 = tempDirectory.appendingPathComponent("FolderB")
        try? FileManager.default.createDirectory(at: folder1, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: folder2, withIntermediateDirectories: true)

        service.recordVisit(to: folder1)
        service.recordVisit(to: folder2)
        service.recordVisit(to: folder2) // folder2 visited twice -> frequent

        XCTAssertEqual(service.recentFolders.count, 2)
        XCTAssertEqual(service.recentFolders.first?.standardizedFileURL, folder2.standardizedFileURL)

        XCTAssertEqual(service.frequentFolders.count, 1)
        XCTAssertEqual(service.frequentFolders.first?.standardizedFileURL, folder2.standardizedFileURL)

        // Reload from disk
        let reloaded = RecentFoldersService(storageURL: storageURL)
        XCTAssertEqual(reloaded.recentFolders.count, 2)
        XCTAssertEqual(reloaded.frequentFolders.count, 1)

        // Remove
        service.remove(url: folder1)
        XCTAssertEqual(service.recentFolders.count, 1)
    }

    func testTabGroupService() {
        let storageURL = tempDirectory.appendingPathComponent("groups_test.json")
        let service = TabGroupService(storageURL: storageURL)

        let dir1 = tempDirectory.appendingPathComponent("Dir1")
        let dir2 = tempDirectory.appendingPathComponent("Dir2")
        try? FileManager.default.createDirectory(at: dir1, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: dir2, withIntermediateDirectories: true)

        let tab1 = WorkspaceTab(initialURL: dir1, isPinned: true, color: .blue)
        let tab2 = WorkspaceTab(initialURL: dir2, isSplit: true, color: .green)

        let group = service.saveGroup(name: "Coding Setup", tabs: [tab1, tab2])
        XCTAssertEqual(service.groups.count, 1)
        XCTAssertEqual(group.name, "Coding Setup")
        XCTAssertEqual(group.tabs.count, 2)
        XCTAssertTrue(group.tabs[0].isPinned)
        XCTAssertEqual(group.tabs[0].color, .blue)
        XCTAssertTrue(group.tabs[1].isSplit)

        // Restore into new workspace
        let ws = WorkspaceState()
        service.restore(group: group, into: ws)
        XCTAssertEqual(ws.tabs.count, 2)
        XCTAssertEqual(ws.tabs[0].primaryPane.currentURL.standardizedFileURL, dir1.standardizedFileURL)
        XCTAssertEqual(ws.tabs[0].color, .blue)
        XCTAssertTrue(ws.tabs[0].isPinned)

        // Rename & Delete
        service.renameGroup(id: group.id, newName: "Renamed Setup")
        XCTAssertEqual(service.groups.first?.name, "Renamed Setup")

        service.deleteGroup(id: group.id)
        XCTAssertEqual(service.groups.count, 0)
    }

    func testSubfolderMenuBuilder() async {
        let subA = tempDirectory.appendingPathComponent("SubDirA")
        let subB = tempDirectory.appendingPathComponent("SubDirB")
        let file1 = tempDirectory.appendingPathComponent("z_file.txt")
        let file2 = tempDirectory.appendingPathComponent("a_file.txt")

        try? FileManager.default.createDirectory(at: subA, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: subB, withIntermediateDirectories: true)
        try? "content".write(to: file1, atomically: true, encoding: .utf8)
        try? "content".write(to: file2, atomically: true, encoding: .utf8)

        let builder = SubfolderMenuBuilder { _, _ in }

        let menu = builder.buildMenu(for: tempDirectory)
        await builder.loadContents(of: menu)
        XCTAssertEqual(menu.items.count, 4)

        // Directories appear first
        XCTAssertEqual(menu.items[0].title, "SubDirA")
        XCTAssertNotNil(menu.items[0].submenu)
        XCTAssertEqual(menu.items[1].title, "SubDirB")
        XCTAssertNotNil(menu.items[1].submenu)

        // Files appear second, sorted alphabetically
        XCTAssertEqual(menu.items[2].title, "a_file.txt")
        XCTAssertNil(menu.items[2].submenu)
        XCTAssertEqual(menu.items[3].title, "z_file.txt")
        XCTAssertNil(menu.items[3].submenu)
    }

    func testHoverPreviewServiceTextSnippet() async throws {
        let codeFile = tempDirectory.appendingPathComponent("script.py")
        let sampleCode = """
        def main():
            print("Hello Shark QTTabBar")
            for i in range(10):
                print(i)

        if __name__ == "__main__":
            main()
        """
        try sampleCode.write(to: codeFile, atomically: true, encoding: .utf8)

        let preview = await HoverPreviewService.shared.fetchPreview(for: codeFile)
        switch preview {
        case .text(let lines, let totalLines, _, _, _):
            XCTAssertGreaterThanOrEqual(lines.count, 5)
            XCTAssertTrue(lines[0].contains("def main"))
            XCTAssertEqual(totalLines, sampleCode.components(separatedBy: .newlines).count)
        default:
            XCTFail("Expected text preview for .py file")
        }
    }
}
