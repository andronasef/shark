import XCTest
@testable import Shark

final class CloudStateTests: XCTestCase {
    private func state(ubiq: Bool = true, status: URLUbiquitousItemDownloadingStatus? = .current,
                       down: Bool = false, up: Bool = false, error: String? = nil) -> CloudState {
        CloudState.make(isUbiquitous: ubiq, status: status, isDownloading: down, isUploading: up, errorMessage: error)
    }

    func testPlainFilesAndSyncedFilesShowNoBadge() {
        XCTAssertEqual(state(ubiq: false), .notCloud)
        XCTAssertEqual(state(), .synced)
        XCTAssertFalse(state().needsBadge)
        XCTAssertFalse(CloudState.notCloud.needsBadge)
    }

    func testCloudOnlyDownloadingUploadingAndErrorAreDistinct() {
        XCTAssertEqual(state(status: .notDownloaded), .cloudOnly)
        XCTAssertEqual(state(status: .notDownloaded, down: true), .downloading)
        XCTAssertEqual(state(up: true), .uploading)
        XCTAssertEqual(state(status: .notDownloaded, error: "offline"), .error("offline"))
        for s in [CloudState.cloudOnly, .downloading, .uploading, .error("x")] { XCTAssertTrue(s.needsBadge) }
    }

    func testRealLocalFileIsNotACloudItem() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("cloud-\(UUID().uuidString).txt")
        try "x".write(to: url, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: url) }
        XCTAssertEqual(CloudState.read(url).state, .notCloud)
        XCTAssertFalse(CloudState.read(url).isShared)
    }

    func testWaitReturnsImmediatelyForALocalFile() async throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("cloud-\(UUID().uuidString).txt")
        try "x".write(to: url, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: url) }
        try await CloudService.waitUntilDownloaded(url)
    }
}
