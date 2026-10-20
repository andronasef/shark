import XCTest
@testable import Shark

@MainActor
final class NavigationStateTests: XCTestCase {
    var state: NavigationState!
    let homeURL = FileManager.default.homeDirectoryForCurrentUser

    override func setUp() async throws {
        state = NavigationState(initialURL: homeURL)
    }

    func testInitialState() {
        XCTAssertEqual(state.currentURL.path, homeURL.standardizedFileURL.path)
        XCTAssertFalse(state.canGoBack)
        XCTAssertFalse(state.canGoForward)
    }

    func testNavigationHistory() {
        let docs = homeURL.appendingPathComponent("Documents")
        let downloads = homeURL.appendingPathComponent("Downloads")

        state.navigateTo(docs)
        XCTAssertTrue(state.canGoBack)
        XCTAssertFalse(state.canGoForward)
        XCTAssertEqual(state.currentURL.path, docs.standardizedFileURL.path)

        state.navigateTo(downloads)
        XCTAssertEqual(state.backStack.count, 2)

        state.goBack()
        XCTAssertEqual(state.currentURL.path, docs.standardizedFileURL.path)
        XCTAssertTrue(state.canGoForward)

        state.goForward()
        XCTAssertEqual(state.currentURL.path, downloads.standardizedFileURL.path)
    }

    func testGoUp() {
        let docs = homeURL.appendingPathComponent("Documents")
        state.navigateTo(docs)

        state.goUp()
        XCTAssertEqual(state.currentURL.path, homeURL.standardizedFileURL.path)
    }

    func testFiltering() {
        let item1 = FileItem(url: URL(fileURLWithPath: "/test/fileA.swift"), name: "fileA.swift", isDirectory: false)
        let item2 = FileItem(url: URL(fileURLWithPath: "/test/fileB.txt"), name: "fileB.txt", isDirectory: false)
        let item3 = FileItem(url: URL(fileURLWithPath: "/test/FolderC"), name: "FolderC", isDirectory: true)

        state.items = [item1, item2, item3]
        XCTAssertEqual(state.filteredAndSortedItems.count, 3)

        state.filterText = "swift"
        XCTAssertEqual(state.filteredAndSortedItems.count, 1)
        XCTAssertEqual(state.filteredAndSortedItems.first?.name, "fileA.swift")

        state.filterText = "Folder"
        XCTAssertEqual(state.filteredAndSortedItems.count, 1)
        XCTAssertEqual(state.filteredAndSortedItems.first?.name, "FolderC")
    }
    func testArrowKeyNavigation() {
        let state = NavigationState()
        let items = (0..<8).map { i in
            FileItem(url: URL(fileURLWithPath: "/test/item\(i)"), name: "item\(i)", isDirectory: false)
        }
        state.items = items
        state.gridColumnCount = 4

        XCTAssertTrue(state.selectedItemIDs.isEmpty)
        state.selectNextItem()
        XCTAssertEqual(state.selectedItemIDs.first, items[0].id)

        // Right arrow moves to item 1
        state.selectNextItem()
        XCTAssertEqual(state.selectedItemIDs.first, items[1].id)

        // Down arrow moves 1 row down (col count 4: index 1 + 4 = 5)
        state.selectBelowItem()
        XCTAssertEqual(state.selectedItemIDs.first, items[5].id)

        // Up arrow moves 1 row up (index 5 - 4 = 1)
        state.selectAboveItem()
        XCTAssertEqual(state.selectedItemIDs.first, items[1].id)

        // Left arrow moves to item 0
        state.selectPreviousItem()
        XCTAssertEqual(state.selectedItemIDs.first, items[0].id)

        // Moving up from top row stays at item 0 (does not loop or crash)
        state.selectAboveItem()
        XCTAssertEqual(state.selectedItemIDs.first, items[0].id)
    }
}
