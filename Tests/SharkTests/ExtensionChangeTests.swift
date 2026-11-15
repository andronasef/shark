import XCTest
@testable import Shark

final class ExtensionChangeTests: XCTestCase {
    private func check(_ old: String, _ new: String, folder: Bool = false) -> ExtensionChange? {
        ExtensionChange.check(oldName: old, newName: new, isFolder: folder)
    }

    func testStemRenameKeepingTheExtensionIsNotAChange() {
        XCTAssertNil(check("report.txt", "summary.txt"))
        XCTAssertNil(check("photo.JPG", "photo.jpg"))   // case only
    }

    func testRemovingOrChangingTheExtensionIsReported() {
        let removed = check("report.txt", "report")
        XCTAssertEqual(removed?.isRemoval, true)
        XCTAssertEqual(removed?.keepingName, "report.txt")
        let changed = check("report.txt", "report.md")
        XCTAssertEqual(changed?.newExtension, "md")
        XCTAssertEqual(changed?.keepingName, "report.md.txt")
    }

    func testFoldersDotfilesAndAddedExtensionsAreLeftAlone() {
        XCTAssertNil(check("Project v1.2", "Project v2", folder: true))
        XCTAssertNil(check(".gitignore", ".gitattributes"))
        XCTAssertNil(check("README", "README.md"))
        XCTAssertNil(check("README", "Notes"))
    }

    func testOnlyTheLastExtensionCounts() {
        XCTAssertNil(check("archive.tar.gz", "backup.tar.gz"))
        XCTAssertEqual(check("archive.tar.gz", "archive.tar")?.oldExtension, "gz")
    }
}
