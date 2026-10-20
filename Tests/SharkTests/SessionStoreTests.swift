import XCTest
@testable import Shark

@MainActor
final class SessionStoreTests: XCTestCase {
    var tempFileURL: URL!

    override func setUp() async throws {
        tempFileURL = FileManager.default.temporaryDirectory.appending(path: "shark_test_session_\(UUID().uuidString).json")
    }

    override func tearDown() async throws {
        try? FileManager.default.removeItem(at: tempFileURL)
    }

    func testSessionRoundTrip() throws {
        let store = SessionStore(fileURL: tempFileURL)
        let homeURL = FileManager.default.homeDirectoryForCurrentUser
        let docs = homeURL.appendingPathComponent("Documents")
        let downloads = homeURL.appendingPathComponent("Downloads")

        let ws = WorkspaceState(initialURL: docs)
        ws.activeNavigationState.viewMode = .details
        ws.activeNavigationState.sortField = .size
        ws.setColor(.purple, for: ws.activeTabID)
        ws.togglePin(id: ws.activeTabID)

        // Add second tab (split)
        ws.newTab(url: downloads)
        ws.toggleSplit()
        ws.setColor(.blue, for: ws.activeTabID)

        // Add a closed tab to history
        ws.newTab()
        ws.closeTab(id: ws.activeTabID)

        // Save
        store.saveNow(ws)
        XCTAssertTrue(FileManager.default.fileExists(atPath: tempFileURL.path))

        // Restore
        let restoredStore = SessionStore(fileURL: tempFileURL)
        guard let restoredWS = restoredStore.restore() else {
            XCTFail("Failed to restore workspace")
            return
        }

        XCTAssertEqual(restoredWS.tabs.count, 2)
        XCTAssertEqual(restoredWS.pinnedCount, 1)
        XCTAssertTrue(restoredWS.tabs[0].isPinned)
        XCTAssertEqual(restoredWS.tabs[0].color, .purple)
        XCTAssertEqual(restoredWS.tabs[0].primaryPane.viewMode, .details)
        XCTAssertEqual(restoredWS.tabs[0].primaryPane.sortField, .size)

        XCTAssertFalse(restoredWS.tabs[1].isPinned)
        XCTAssertTrue(restoredWS.tabs[1].isSplit)
        XCTAssertEqual(restoredWS.tabs[1].color, .blue)

        XCTAssertEqual(restoredWS.closedTabs.count, 1)
    }

    func testCorruptFileRestoreReturnsNil() throws {
        let badData = "INVALID JSON { [[[".data(using: .utf8)!
        try badData.write(to: tempFileURL)

        let store = SessionStore(fileURL: tempFileURL)
        let restored = store.restore()
        XCTAssertNil(restored)
    }

    func testMissingPathFallbackToAncestor() throws {
        let missingURL = URL(fileURLWithPath: "/tmp/shark_missing_test_dir_\(UUID().uuidString)/sub/deep")
        let pane = PaneSnapshot(
            url: missingURL,
            viewMode: "details",
            sortField: "name",
            sortAscending: true,
            showHidden: false,
            iconSize: 80.0
        )
        let tab = TabSnapshot(
            id: UUID(),
            isPinned: false,
            isLocked: false,
            color: nil,
            isSplit: false,
            activePane: .primary,
            primary: pane,
            secondary: pane
        )
        let snap = WorkspaceSnapshot(tabs: [tab], activeTabID: tab.id)

        let data = try JSONEncoder().encode(snap)
        try data.write(to: tempFileURL)

        let store = SessionStore(fileURL: tempFileURL)
        guard let restored = store.restore() else {
            XCTFail("Failed to restore workspace with missing path")
            return
        }

        XCTAssertEqual(restored.tabs.count, 1)
        let restoredURL = restored.activeNavigationState.currentURL
        XCTAssertTrue(FileManager.default.fileExists(atPath: restoredURL.path))
        XCTAssertTrue(restoredURL.path.hasPrefix("/tmp") || restoredURL.path == FileManager.default.homeDirectoryForCurrentUser.path)
    }

    func testAutosaveDebounce() async throws {
        let store = SessionStore(fileURL: tempFileURL)
        let ws = WorkspaceState()
        store.startAutosave(ws)

        XCTAssertFalse(FileManager.default.fileExists(atPath: tempFileURL.path))

        // Mutate workspace
        ws.newTab()

        // Wait 800ms for 500ms debounce
        try await Task.sleep(for: .milliseconds(800))

        XCTAssertTrue(FileManager.default.fileExists(atPath: tempFileURL.path))
    }
}
