import XCTest
@testable import Shark

final class SecurityScopedBookmarkManagerTests: XCTestCase {
    private var tempDirectory: URL!
    private var storageURL: URL!

    override func setUpWithError() throws {
        tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        storageURL = tempDirectory.appendingPathComponent("test_bookmarks.json")
    }

    override func tearDownWithError() throws {
        if let temp = tempDirectory {
            try? FileManager.default.removeItem(at: temp)
        }
    }

    @MainActor
    private func makeManager() -> SecurityScopedBookmarkManager {
        SecurityScopedBookmarkManager(storageURL: storageURL)
    }

    @MainActor
    func testSandboxDetectionDoesNotCrash() {
        let manager = makeManager()
        let isSandboxed = manager.isSandboxed
        XCTAssertTrue(isSandboxed == true || isSandboxed == false)
    }

    @MainActor
    func testIsAccessibleForExistingDirectory() {
        let manager = makeManager()
        XCTAssertTrue(manager.isAccessible(url: tempDirectory))
        let nonExistent = tempDirectory.appendingPathComponent("non_existent_\(UUID().uuidString)")
        XCTAssertFalse(manager.isAccessible(url: nonExistent))
    }

    @MainActor
    func testSaveAndResolveBookmark() throws {
        let testSubfolder = tempDirectory.appendingPathComponent("subfolder", isDirectory: true)
        try FileManager.default.createDirectory(at: testSubfolder, withIntermediateDirectories: true)

        let manager = makeManager()
        let bookmarkData = try manager.saveBookmark(for: testSubfolder)
        XCTAssertFalse(bookmarkData.isEmpty)

        // Resolve bookmark
        let resolved = manager.resolveBookmark(data: bookmarkData)
        XCTAssertNotNil(resolved)
        XCTAssertEqual(resolved?.standardizedFileURL.path, testSubfolder.standardizedFileURL.path)
    }

    @MainActor
    func testBookmarkPersistenceAcrossInstances() throws {
        let testSubfolder = tempDirectory.appendingPathComponent("persistent_folder", isDirectory: true)
        try FileManager.default.createDirectory(at: testSubfolder, withIntermediateDirectories: true)

        let manager = makeManager()
        try manager.saveBookmark(for: testSubfolder)

        // Create new instance pointing to same storageURL
        let secondManager = SecurityScopedBookmarkManager(storageURL: storageURL)
        XCTAssertTrue(secondManager.ensureAccess(to: testSubfolder))
    }

    @MainActor
    func testAccessLifecycleTracking() {
        let manager = makeManager()
        let testURL = tempDirectory!
        XCTAssertTrue(manager.startAccessing(url: testURL))
        XCTAssertTrue(manager.startAccessing(url: testURL))
        manager.stopAccessing(url: testURL)
        manager.stopAccessing(url: testURL)
    }

    @MainActor
    func testPaneSnapshotWithBookmarkData() throws {
        let dummyData = "test-security-scoped-bookmark-data".data(using: .utf8)
        let pane = PaneSnapshot(
            url: tempDirectory,
            viewMode: "grid",
            sortField: "name",
            sortAscending: true,
            showHidden: false,
            iconSize: 80.0,
            bookmarkData: dummyData
        )

        let encoded = try JSONEncoder().encode(pane)
        let decoded = try JSONDecoder().decode(PaneSnapshot.self, from: encoded)

        XCTAssertEqual(decoded.url, pane.url)
        XCTAssertEqual(decoded.bookmarkData, dummyData)
    }
}
