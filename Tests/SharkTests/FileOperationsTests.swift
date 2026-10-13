import XCTest
@testable import Shark

final class FileOperationsTests: XCTestCase {
    var tempDirectory: URL!

    override func setUp() async throws {
        let temp = FileManager.default.temporaryDirectory
        tempDirectory = temp.appendingPathComponent("shark_fileops_test_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    override func tearDown() async throws {
        try? FileManager.default.removeItem(at: tempDirectory)
    }

    func testCreateFolderAndCollision() async throws {
        let folder1 = try await FileOperationsService.shared.createFolder(named: "NewFolder", at: tempDirectory)
        XCTAssertTrue(FileManager.default.fileExists(atPath: folder1.path))
        XCTAssertEqual(folder1.lastPathComponent, "NewFolder")

        // Duplicate name should auto-increment
        let folder2 = try await FileOperationsService.shared.createFolder(named: "NewFolder", at: tempDirectory)
        XCTAssertTrue(FileManager.default.fileExists(atPath: folder2.path))
        XCTAssertEqual(folder2.lastPathComponent, "NewFolder 1")
    }

    func testCreateFileAndDuplicate() async throws {
        let file = try await FileOperationsService.shared.createFile(named: "document.txt", at: tempDirectory, content: "Hello World".data(using: .utf8))
        XCTAssertTrue(FileManager.default.fileExists(atPath: file.path))

        try await FileOperationsService.shared.duplicate(items: [file])

        let duplicatePath = tempDirectory.appendingPathComponent("document copy 1.txt").path
        XCTAssertTrue(FileManager.default.fileExists(atPath: duplicatePath))
    }

    func testBatchRename() async throws {
        let fileA = try await FileOperationsService.shared.createFile(named: "photo_sample_a.jpg", at: tempDirectory)
        let fileB = try await FileOperationsService.shared.createFile(named: "photo_sample_b.jpg", at: tempDirectory)

        let rule = RenameRule(
            findText: "sample",
            replaceText: "final",
            prefix: "vacation_",
            useNumbering: true,
            startingNumber: 1,
            paddingDigits: 2
        )

        let renamed = try await FileOperationsService.shared.batchRename(items: [fileA, fileB], rule: rule)
        XCTAssertEqual(renamed.count, 2)
        XCTAssertEqual(renamed[0].lastPathComponent, "vacation_photo_final_a_01.jpg")
        XCTAssertEqual(renamed[1].lastPathComponent, "vacation_photo_final_b_02.jpg")

        XCTAssertTrue(FileManager.default.fileExists(atPath: renamed[0].path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: renamed[1].path))
    }

    func testRenameRuleUnit() {
        let rule = RenameRule(
            findText: "draft",
            replaceText: "v1",
            prefix: "DOC_",
            suffix: "_approved",
            useNumbering: false
        )

        let result = rule.apply(to: "draft_spec.pdf", index: 0)
        XCTAssertEqual(result, "DOC_v1_spec_approved.pdf")
    }
}
