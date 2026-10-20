import XCTest
@testable import Shark

@MainActor
final class SecurityScopedBookmarkManagerTests: XCTestCase {
    private var tempDirectory: URL!
    private var storageURL: URL!
    private var manager: SecurityScopedBookmarkManager!

    override func setUp() async throws {
        try await super.setUp()
        tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        storageURL = tempDirectory.appendingPathComponent("test_bookmarks.json")
        manager = SecurityScopedBookmarkManager(storageURL: storageURL)
    }

    override func tearDown() async throws {
        if let temp = tempDirectory {
            try? FileManager.default.removeItem(at: temp)
        }
        try await super.tearDown()
    }

    func testSandboxDetectionDoesNotCrash() {
        let isSandboxed = manager.isSandboxed
        XCTAssertTrue(isSandboxed == true || isSandboxed == false)
    }

    func testIsAccessibleForExistingDirectory() {
        XCTAssertTrue(manager.isAccessible(url: tempDirectory))
        let nonExistent = tempDirectory.appendingPathComponent("non_existent_\(UUID().uuidString)")
        XCTAssertFalse(manager.isAccessible(url: nonExistent))
    }

    func testSaveAndResolveBookmark() throws {
        let testSubfolder = tempDirectory.appendingPathComponent("subfolder", isDirectory: true)
        try FileManager.default.createDirectory(at: testSubfolder, withIntermediateDirectories: true)

        let bookmarkData = try manager.saveBookmark(for: testSubfolder)
        XCTAssertFalse(bookmarkData.isEmpty)

        // Resolve bookmark
        let resolved = manager.resolveBookmark(data: bookmarkData)
        XCTAssertNotNil(resolved)
        XCTAssertEqual(resolved?.standardizedFileURL.path, testSubfolder.standardizedFileURL.path)
    }

    func testBookmarkPersistenceAcrossInstances() throws {
        let testSubfolder = tempDirectory.appendingPathComponent("persistent_folder", isDirectory: true)
        try FileManager.default.createDirectory(at: testSubfolder, withIntermediateDirectories: true)

        try manager.saveBookmark(for: testSubfolder)

        // Create new instance pointing to same storageURL
        let secondManager = SecurityScopedBookmarkManager(storageURL: storageURL)
        XCTAssertTrue(secondManager.ensureAccess(to: testSubfolder))
    }

    func testAccessLifecycleTracking() {
        let testURL = tempDirectory!
        XCTAssertTrue(manager.startAccessing(url: testURL))
        XCTAssertTrue(manager.startAccessing(url: testURL))
        manager.stopAccessing(url: testURL)
        manager.stopAccessing(url: testURL)
    }

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
