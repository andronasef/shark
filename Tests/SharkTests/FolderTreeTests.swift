import XCTest
@testable import Shark

final class FolderTreeTests: XCTestCase {
    private var root: URL!

    override func setUpWithError() throws {
        root = FileManager.default.temporaryDirectory.appendingPathComponent("tree-\(UUID().uuidString)", isDirectory: true)
        let fm = FileManager.default
        for path in ["b", "a/inner", "a10", "a2", ".hidden", "Pkg.app/Contents"] {
            try fm.createDirectory(at: root.appendingPathComponent(path), withIntermediateDirectories: true)
        }
        try Data().write(to: root.appendingPathComponent("file.txt"))
        try fm.createSymbolicLink(at: root.appendingPathComponent("link"), withDestinationURL: root.appendingPathComponent("b"))
        try fm.createSymbolicLink(at: root.appendingPathComponent("filelink"), withDestinationURL: root.appendingPathComponent("file.txt"))
    }

    override func tearDownWithError() throws { try? FileManager.default.removeItem(at: root) }

    func testChildFoldersListsOnlyFoldersInFinderOrder() {
        let names = FolderTree.childFolders(of: root, showHidden: false).map(\.lastPathComponent)
        XCTAssertEqual(names, ["a", "a2", "a10", "b", "link"], "files, packages, hidden folders and file symlinks are excluded; numbers sort naturally")
    }

    func testHiddenFoldersAppearWhenRequested() {
        XCTAssertTrue(FolderTree.childFolders(of: root, showHidden: true).map(\.lastPathComponent).contains(".hidden"))
    }

    func testUnreadableFolderHasNoChildren() {
        XCTAssertEqual(FolderTree.childFolders(of: root.appendingPathComponent("missing"), showHidden: false), [])
    }

    func testAncestorsListRootDownToParent() {
        let target = URL(fileURLWithPath: "/Users/andrew/Downloads/x")
        XCTAssertEqual(FolderTree.ancestors(of: target, below: URL(fileURLWithPath: "/")).map(\.path),
                       ["/", "/Users", "/Users/andrew", "/Users/andrew/Downloads"])
        XCTAssertEqual(FolderTree.ancestors(of: target, below: URL(fileURLWithPath: "/Users/andrew")).map(\.path),
                       ["/Users/andrew", "/Users/andrew/Downloads"])
        XCTAssertEqual(FolderTree.ancestors(of: URL(fileURLWithPath: "/Users"), below: URL(fileURLWithPath: "/Users")), [])
        XCTAssertEqual(FolderTree.ancestors(of: URL(fileURLWithPath: "/opt"), below: URL(fileURLWithPath: "/Users")), [])
    }

    func testDeepestRootWinsAndSiblingPrefixesDoNotMatch() {
        let roots = [URL(fileURLWithPath: "/"), URL(fileURLWithPath: "/Users/andrew"), URL(fileURLWithPath: "/Volumes/Flash")]
        XCTAssertEqual(FolderTree.root(containing: URL(fileURLWithPath: "/Users/andrew/Documents"), among: roots)?.path, "/Users/andrew")
        XCTAssertEqual(FolderTree.root(containing: URL(fileURLWithPath: "/Users/andrew2/x"), among: roots)?.path, "/")
        XCTAssertEqual(FolderTree.root(containing: URL(fileURLWithPath: "/Volumes/Flash/x"), among: roots)?.path, "/Volumes/Flash")
    }

    @MainActor func testExpandLoadsChildrenRevealsAndPersists() async throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "tree-\(UUID().uuidString)"))
        let model = FolderTreeModel(defaults: defaults)
        let top = [FolderTreeRoot(url: root, name: "Root", icon: "house")]
        XCTAssertEqual(model.rows(for: top).map(\.name), ["Root"])
        XCTAssertTrue(model.rows(for: top)[0].canExpand, "unknown children show an arrow")

        await model.expand(root, showHidden: false)
        XCTAssertEqual(model.rows(for: top).map(\.name), ["Root", "a", "a2", "a10", "b", "link"])
        XCTAssertEqual(model.rows(for: top).map(\.depth), [0, 1, 1, 1, 1, 1])

        await model.reveal(root.appendingPathComponent("a/inner"), roots: [root], showHidden: false)
        XCTAssertEqual(model.rows(for: top).map(\.name), ["Root", "a", "inner", "a2", "a10", "b", "link"])
        XCTAssertFalse(model.rows(for: top).first { $0.name == "a2" }!.isExpanded)

        await model.load(root.appendingPathComponent("a2"), showHidden: false)
        XCTAssertFalse(model.rows(for: top).first { $0.name == "a2" }!.canExpand, "a folder with no subfolders loses its arrow")

        model.collapse(root)
        XCTAssertEqual(model.rows(for: top).map(\.name), ["Root"])
        XCTAssertFalse(FolderTreeModel(defaults: defaults).isExpanded(root), "collapse is persisted")
        XCTAssertTrue(FolderTreeModel(defaults: defaults).isExpanded(root.appendingPathComponent("a")))
    }

    func testSidebarStylePreferenceFallsBackToPlaces() {
        XCTAssertEqual(SidebarStyle.preference("tree"), .tree)
        XCTAssertEqual(SidebarStyle.preference("bogus"), .places)
        XCTAssertEqual(SidebarStyle.preference(nil), .places)
    }
}
