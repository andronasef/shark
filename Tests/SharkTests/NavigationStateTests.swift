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
    func testArrowKeyNavigation() async {
        let state = NavigationState()
        await state.reloadCurrentDirectory()

        XCTAssertTrue(state.selectedItemIDs.isEmpty)
        state.selectNextItem()
        if !state.filteredAndSortedItems.isEmpty {
            XCTAssertEqual(state.selectedItemIDs.count, 1)
            let firstID = state.selectedItemIDs.first
            XCTAssertEqual(firstID, state.filteredAndSortedItems.first?.id)

            state.selectNextItem()
            if state.filteredAndSortedItems.count > 1 {
                XCTAssertEqual(state.selectedItemIDs.first, state.filteredAndSortedItems[1].id)
            }

            state.selectPreviousItem()
            XCTAssertEqual(state.selectedItemIDs.first, firstID)
        }
    }
}
