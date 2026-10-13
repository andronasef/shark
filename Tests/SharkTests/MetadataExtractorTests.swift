import XCTest
import CryptoKit
@testable import Shark

final class MetadataExtractorTests: XCTestCase {
    var tempFileURL: URL!
    var tempDirURL: URL!
    let testContent = "Hello Shark Metadata\n"

    override func setUp() async throws {
        let tempDir = FileManager.default.temporaryDirectory
        tempFileURL = tempDir.appendingPathComponent("shark_metadata_test_\(UUID().uuidString).txt")
        try testContent.write(to: tempFileURL, atomically: true, encoding: .utf8)

        tempDirURL = tempDir.appendingPathComponent("shark_test_folder_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDirURL, withIntermediateDirectories: true)
    }

    override func tearDown() async throws {
        try? FileManager.default.removeItem(at: tempFileURL)
        try? FileManager.default.removeItem(at: tempDirURL)
    }

    func testExtractFileMetadata() async throws {
        let metadata = await MetadataExtractor.shared.extractMetadata(for: tempFileURL)
        XCTAssertNotNil(metadata)
        guard let meta = metadata else { return }

        XCTAssertEqual(meta.name, tempFileURL.lastPathComponent)
        XCTAssertFalse(meta.isDirectory)
        XCTAssertEqual(meta.fileSize, Int64(testContent.utf8.count))
        XCTAssertFalse(meta.ownerName.isEmpty)
        XCTAssertFalse(meta.groupName.isEmpty)
        XCTAssertFalse(meta.octalPermissions.isEmpty)
        XCTAssertTrue(meta.symbolicPermissions.hasPrefix("-"), "Regular file permissions must start with '-'")
    }

    func testExtractDirectoryMetadata() async throws {
        let metadata = await MetadataExtractor.shared.extractMetadata(for: tempDirURL)
        XCTAssertNotNil(metadata)
        guard let meta = metadata else { return }

        XCTAssertTrue(meta.isDirectory)
        XCTAssertTrue(meta.symbolicPermissions.hasPrefix("d"), "Directory permissions must start with 'd'")
    }

    func testComputeSHA256() async throws {
        let calculatedHash = await MetadataExtractor.shared.computeSHA256(for: tempFileURL)
        XCTAssertNotNil(calculatedHash)

        let expectedData = testContent.data(using: .utf8)!
        let expectedDigest = SHA256.hash(data: expectedData)
        let expectedHashString = expectedDigest.map { String(format: "%02x", $0) }.joined()

        XCTAssertEqual(calculatedHash, expectedHashString)
    }
}
