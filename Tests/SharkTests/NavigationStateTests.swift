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

    func testShiftArrow1DDetailsSelection() {
        let state = NavigationState()
        let items = (0..<8).map { i in
            FileItem(url: URL(fileURLWithPath: "/test/item\(i)"), name: "item\(i)", isDirectory: false)
        }
        state.items = items
        state.viewMode = .details // 1D list view

        // Select item 2 as starting anchor
        state.click(items[2], command: false, shift: false)
        XCTAssertEqual(state.selectedItemIDs, [items[2].id])
        XCTAssertEqual(state.selectionLeadID, items[2].url)

        // Shift + Next (Right/Down in 1D): range 2...3
        state.selectNextItem(extendingSelection: true)
        XCTAssertEqual(state.selectedItemIDs, [items[2].id, items[3].id])
        XCTAssertEqual(state.selectionLeadID, items[3].url)

        // Shift + Next again: range 2...4
        state.selectNextItem(extendingSelection: true)
        XCTAssertEqual(state.selectedItemIDs, [items[2].id, items[3].id, items[4].id])
        XCTAssertEqual(state.selectionLeadID, items[4].url)

        // Shift + Previous: contracts back to range 2...3
        state.selectPreviousItem(extendingSelection: true)
        XCTAssertEqual(state.selectedItemIDs, [items[2].id, items[3].id])
        XCTAssertEqual(state.selectionLeadID, items[3].url)

        // Shift + Previous again: contracts back to range 2...2 (just item 2)
        state.selectPreviousItem(extendingSelection: true)
        XCTAssertEqual(state.selectedItemIDs, [items[2].id])
        XCTAssertEqual(state.selectionLeadID, items[2].url)

        // Shift + Previous across anchor: range 1...2
        state.selectPreviousItem(extendingSelection: true)
        XCTAssertEqual(state.selectedItemIDs, [items[1].id, items[2].id])
        XCTAssertEqual(state.selectionLeadID, items[1].url)
    }

    private func gridState(count: Int, columns: Int) -> (NavigationState, [FileItem]) {
        let state = NavigationState()
        let items = (0..<count).map { i in
            FileItem(url: URL(fileURLWithPath: "/test/item\(i)"), name: "item\(i)", isDirectory: false)
        }
        state.items = items
        state.viewMode = .grid
        state.gridColumnCount = columns
        return (state, items)
    }

    private func ids(_ items: [FileItem], _ range: ClosedRange<Int>) -> Set<URL> {
        Set(items[range].map(\.id))
    }

    /// Windows Explorer selects a run in reading order, never a rectangle, even in icon view.
    func testShiftArrowInGridSelectsRunInReadingOrder() {
        let (state, items) = gridState(count: 12, columns: 4)
        state.click(items[1], command: false, shift: false)

        state.selectBelowItem(extendingSelection: true)
        XCTAssertEqual(state.selectionLeadID, items[5].id)
        XCTAssertEqual(state.selectedItemIDs, ids(items, 1...5))

        state.selectNextItem(extendingSelection: true)
        XCTAssertEqual(state.selectedItemIDs, ids(items, 1...6))

        state.selectAboveItem(extendingSelection: true)
        XCTAssertEqual(state.selectionLeadID, items[2].id)
        XCTAssertEqual(state.selectedItemIDs, ids(items, 1...2))

        state.selectPreviousItem(extendingSelection: true)
        state.selectPreviousItem(extendingSelection: true)
        XCTAssertEqual(state.selectionLeadID, items[0].id)
        XCTAssertEqual(state.selectedItemIDs, ids(items, 0...1))
    }

    func testShiftDownOnShortLastRowStopsAtLastItem() {
        let (state, items) = gridState(count: 23, columns: 5)
        state.click(items[12], command: false, shift: false)

        state.selectBelowItem(extendingSelection: true)
        XCTAssertEqual(state.selectedItemIDs, ids(items, 12...17))
        XCTAssertEqual(state.scrollToURL, items[17].id)

        state.selectBelowItem(extendingSelection: true)
        XCTAssertEqual(state.selectionLeadID, items[22].id)
        XCTAssertEqual(state.selectedItemIDs, ids(items, 12...22))

        state.selectBelowItem(extendingSelection: true)
        XCTAssertEqual(state.selectedItemIDs, ids(items, 12...22))
    }

    func testShiftClickInGridSelectsRunAndKeepsAnchor() {
        let (state, items) = gridState(count: 12, columns: 4)
        state.click(items[2], command: false, shift: false)

        state.click(items[9], command: false, shift: true)
        XCTAssertEqual(state.selectedItemIDs, ids(items, 2...9))

        // A second Shift-click re-pivots on the same anchor rather than growing the old range.
        state.click(items[0], command: false, shift: true)
        XCTAssertEqual(state.selectedItemIDs, ids(items, 0...2))
    }

    func testCommandShiftClickAddsRunToSelection() {
        let (state, items) = gridState(count: 12, columns: 4)
        state.click(items[0], command: false, shift: false)
        state.click(items[8], command: true, shift: false)

        state.click(items[10], command: true, shift: true)
        XCTAssertEqual(state.selectedItemIDs, ids(items, 0...0).union(ids(items, 8...10)))
    }

    func testPlainArrowAfterShiftRangeMovesFromLead() {
        let (state, items) = gridState(count: 12, columns: 4)
        state.click(items[1], command: false, shift: false)
        state.selectNextItem(extendingSelection: true)
        state.selectNextItem(extendingSelection: true)

        state.selectNextItem()
        XCTAssertEqual(state.selectedItemIDs, [items[4].id])
    }
}
