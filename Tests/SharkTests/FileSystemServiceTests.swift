import XCTest
@testable import Shark

final class FileSystemServiceTests: XCTestCase {
    var service: FileSystemService!

    override func setUp() async throws {
        service = FileSystemService()
    }

    func testStandardPlaces() async {
        let places = await service.standardPlaces()
        XCTAssertFalse(places.isEmpty, "Standard places should include Home, Desktop, etc.")
        XCTAssertTrue(places.contains { $0.name == "Home" })
    }

    func testMountedVolumes() async {
        let volumes = await service.mountedVolumes()
        XCTAssertFalse(volumes.isEmpty, "Should find at least one mounted volume")
    }

    func testResolvePathTilde() async {
        let homeResolved = await service.resolvePath("~")
        XCTAssertNotNil(homeResolved)
        XCTAssertEqual(homeResolved?.path, FileManager.default.homeDirectoryForCurrentUser.path)
    }

    func testResolveNonExistentPath() async {
        let invalid = await service.resolvePath("/this/path/should/definitely/not/exist/\(UUID().uuidString)")
        XCTAssertNil(invalid)
    }

    func testDirectoryContentsEnumeration() async throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        // Create sample files
        let testFile = tempDir.appendingPathComponent("test1.txt")
        try "Shark file manager".write(to: testFile, atomically: true, encoding: .utf8)

        let testSubDir = tempDir.appendingPathComponent("Subfolder")
        try FileManager.default.createDirectory(at: testSubDir, withIntermediateDirectories: true)

        let items = try await service.contentsOfDirectory(at: tempDir, showHidden: false)
        XCTAssertEqual(items.count, 2)
        XCTAssertTrue(items.contains { $0.name == "test1.txt" && !$0.isDirectory })
        XCTAssertTrue(items.contains { $0.name == "Subfolder" && $0.isDirectory })
    }
}
