import XCTest
@testable import Shark

@MainActor
final class WorkspaceStateTests: XCTestCase {
    var workspace: WorkspaceState!
    let homeURL = FileManager.default.homeDirectoryForCurrentUser

    override func setUp() async throws {
        workspace = WorkspaceState(initialURL: homeURL)
    }

    func testInitialWorkspace() {
        XCTAssertEqual(workspace.tabs.count, 1)
        XCTAssertEqual(workspace.activeTabID, workspace.tabs[0].id)
        XCTAssertFalse(workspace.activeTab.isSplit)
        XCTAssertEqual(workspace.activeTab.activePane, .primary)
    }

    func testToggleSplitView() {
        workspace.toggleSplit()
        XCTAssertTrue(workspace.activeTab.isSplit)

        // Switching active pane
        workspace.toggleActivePane()
        XCTAssertEqual(workspace.activeTab.activePane, .secondary)

        workspace.toggleActivePane()
        XCTAssertEqual(workspace.activeTab.activePane, .primary)

        // Collapse split
        workspace.toggleSplit()
        XCTAssertFalse(workspace.activeTab.isSplit)
        XCTAssertEqual(workspace.activeTab.activePane, .primary)
    }

    func testTabManagement() {
        let firstTabID = workspace.activeTabID

        workspace.newTab()
        XCTAssertEqual(workspace.tabs.count, 2)
        XCTAssertNotEqual(workspace.activeTabID, firstTabID)

        workspace.previousTab()
        XCTAssertEqual(workspace.activeTabID, firstTabID)

        workspace.nextTab()
        XCTAssertNotEqual(workspace.activeTabID, firstTabID)

        // Close second tab
        let secondTabID = workspace.activeTabID
        workspace.closeTab(id: secondTabID)
        XCTAssertEqual(workspace.tabs.count, 1)
        XCTAssertEqual(workspace.activeTabID, firstTabID)
    }

    func testTabTitleUpdates() {
        let docs = homeURL.appendingPathComponent("Documents")
        let downloads = homeURL.appendingPathComponent("Downloads")

        workspace.activeNavigationState.navigateTo(docs)
        XCTAssertEqual(workspace.activeTab.title, "Documents")

        workspace.toggleSplit()
        workspace.activeTab.secondaryPane.navigateTo(downloads)
        XCTAssertEqual(workspace.activeTab.title, "Documents | Downloads")
    }

    func testTooltipFormatting() {
        let docs = homeURL.appendingPathComponent("Documents")
        workspace.activeNavigationState.navigateTo(docs)
        XCTAssertEqual(workspace.activeTab.tooltipText, docs.path)

        workspace.togglePin(id: workspace.activeTabID)
        XCTAssertEqual(workspace.activeTab.tooltipText, "Documents\n\(docs.path)")

        workspace.toggleLock(id: workspace.activeTabID)
        XCTAssertEqual(workspace.activeTab.tooltipText, "Documents\n\(docs.path)\nLocked")
    }

    func testPinAndUnpinInvariant() {
        workspace.newTab()
        workspace.newTab()
        workspace.newTab()
        // 4 tabs total: 0, 1, 2, 3
        let tab0 = workspace.tabs[0].id
                let tab2 = workspace.tabs[2].id

        workspace.togglePin(id: tab0)
        XCTAssertEqual(workspace.pinnedCount, 1)
        XCTAssertEqual(workspace.tabs[0].id, tab0)
        XCTAssertTrue(workspace.tabs[0].isPinned)

        // Pin tab2, should be placed at index 1 (end of pinned group)
        workspace.togglePin(id: tab2)
        XCTAssertEqual(workspace.pinnedCount, 2)
        XCTAssertEqual(workspace.tabs[1].id, tab2)
        XCTAssertTrue(workspace.tabs[1].isPinned)

        // Unpin tab0, should move to start of unpinned group (index 1)
        workspace.togglePin(id: tab0)
        XCTAssertEqual(workspace.pinnedCount, 1)
        XCTAssertFalse(workspace.tabs.first(where: { $0.id == tab0 })!.isPinned)
        XCTAssertTrue(workspace.tabs[0].isPinned)
        XCTAssertEqual(workspace.tabs[0].id, tab2)
    }

    func testMoveTabClampsToGroup() {
        workspace.newTab()
        workspace.newTab()
        workspace.newTab()

        let pTab = workspace.tabs[0].id
        workspace.togglePin(id: pTab) // index 0 is pinned, 1, 2, 3 unpinned

        let unpinnedTab = workspace.tabs[2].id
        // Attempt to move unpinned tab to index 0 (inside pinned group)
        workspace.moveTab(id: unpinnedTab, to: 0)
        // Should clamp to pinnedCount (1)
        XCTAssertEqual(workspace.tabs[1].id, unpinnedTab)

        // Attempt to move pinned tab beyond pinned group
        workspace.moveTab(id: pTab, to: 3)
        // Should clamp to pinned group range [0, 0]
        XCTAssertEqual(workspace.tabs[0].id, pTab)
    }

    func testCloseTabHistoryAndCap20() {
        for i in 0..<25 {
            let dir = homeURL.appendingPathComponent("dir\(i)")
            workspace.newTab(url: dir)
        }

        // Close 23 tabs
        while workspace.tabs.count > 1 {
            workspace.closeTab(id: workspace.activeTabID)
        }

        // Closed history should be capped at 20
        XCTAssertEqual(workspace.closedTabs.count, 20)

        // Reopening closed tab
        let previousCount = workspace.tabs.count
        workspace.reopenClosedTab()
        XCTAssertEqual(workspace.tabs.count, previousCount + 1)
        XCTAssertEqual(workspace.closedTabs.count, 19)
    }

    func testClosingLastTabReplacesWithHomeTab() {
        XCTAssertEqual(workspace.tabs.count, 1)
        let lastID = workspace.activeTabID
        workspace.closeTab(id: lastID)

        XCTAssertEqual(workspace.tabs.count, 1)
        XCTAssertNotEqual(workspace.activeTabID, lastID)
        XCTAssertEqual(workspace.activeNavigationState.currentURL.path, homeURL.path)
    }

    func testDuplicateTab() {
        let docs = homeURL.appendingPathComponent("Documents")
        workspace.activeNavigationState.navigateTo(docs)
        workspace.setColor(.purple, for: workspace.activeTabID)
        workspace.toggleLock(id: workspace.activeTabID)

        let originalID = workspace.activeTabID
        workspace.duplicateTab(id: originalID)

        XCTAssertEqual(workspace.tabs.count, 2)
        let dup = workspace.activeTab
        XCTAssertNotEqual(dup.id, originalID)
        XCTAssertEqual(dup.primaryPane.currentURL.path, docs.path)
        XCTAssertEqual(dup.color, .purple)
        XCTAssertFalse(dup.isLocked, "Duplicated tab must not inherit locked state")
    }

    func testCloseOtherTabsAndCloseToRight() {
        let t0 = workspace.tabs[0].id
        workspace.togglePin(id: t0)

        workspace.newTab()
        let t1 = workspace.activeTabID

        workspace.newTab()
        let t2 = workspace.activeTabID
        workspace.toggleLock(id: t2)

        workspace.newTab()
        let t3 = workspace.activeTabID

        workspace.newTab()
        let t4 = workspace.activeTabID

        // Tabs: [t0(pinned), t1, t2(locked), t3, t4]
        // Close tabs to right of t1: should close t3 and t4, but preserve t2(locked) and t0(pinned)
        workspace.closeTabsToRight(id: t1)
        let idsAfterRight = workspace.tabs.map(\.id)
        XCTAssertTrue(idsAfterRight.contains(t0))
        XCTAssertTrue(idsAfterRight.contains(t1))
        XCTAssertTrue(idsAfterRight.contains(t2))
        XCTAssertFalse(idsAfterRight.contains(t3))
        XCTAssertFalse(idsAfterRight.contains(t4))

        // Close other tabs from t1: should preserve t0(pinned) and t2(locked)
        workspace.closeOtherTabs(id: t1)
        let idsAfterOther = workspace.tabs.map(\.id)
        XCTAssertTrue(idsAfterOther.contains(t0))
        XCTAssertTrue(idsAfterOther.contains(t1))
        XCTAssertTrue(idsAfterOther.contains(t2))
    }

    func testSelectTabByNumber() {
        for _ in 0..<10 {
            workspace.newTab()
        }
        XCTAssertEqual(workspace.tabs.count, 11)

        workspace.selectTab(number: 1)
        XCTAssertEqual(workspace.activeTabID, workspace.tabs[0].id)

        workspace.selectTab(number: 5)
        XCTAssertEqual(workspace.activeTabID, workspace.tabs[4].id)

        workspace.selectTab(number: 9)
        XCTAssertEqual(workspace.activeTabID, workspace.tabs.last!.id)
    }

    func testOpenFolderRouting() {
        let docs = homeURL.appendingPathComponent("Documents")
        let downloads = homeURL.appendingPathComponent("Downloads")

        // 1. Normal navigation: in place
        workspace.open(docs, from: workspace.activeNavigationState, newTab: false)
        XCTAssertEqual(workspace.tabs.count, 1)
        XCTAssertEqual(workspace.activeNavigationState.currentURL.path, docs.path)

        // 2. Command / middle click: background tab
        let originalID = workspace.activeTabID
        workspace.open(downloads, from: workspace.activeNavigationState, newTab: true)
        XCTAssertEqual(workspace.tabs.count, 2)
        XCTAssertEqual(workspace.activeTabID, originalID, "Must remain on active tab (background)")
        XCTAssertEqual(workspace.tabs.last!.primaryPane.currentURL.path, downloads.path)

        // 3. Locked tab: navigates in a foreground new tab
        workspace.toggleLock(id: workspace.activeTabID)
        let music = homeURL.appendingPathComponent("Music")
        workspace.open(music, from: workspace.activeNavigationState, newTab: false)
        XCTAssertEqual(workspace.tabs.count, 3)
        XCTAssertNotEqual(workspace.activeTabID, originalID, "Locked tab must route to new foreground tab")
        XCTAssertEqual(workspace.activeNavigationState.currentURL.path, music.path)
    }
}
