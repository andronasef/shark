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
}
