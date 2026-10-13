import XCTest
@testable import Shark

@MainActor
final class SortingFilteringTests: XCTestCase {
    var state: NavigationState!

    override func setUp() async throws {
        state = NavigationState(initialURL: FileManager.default.temporaryDirectory)
    }

    func testSortFoldersBeforeFiles() {
        let fileA = FileItem(url: URL(fileURLWithPath: "/tmp/a_file.txt"), name: "a_file.txt", isDirectory: false)
        let folderZ = FileItem(url: URL(fileURLWithPath: "/tmp/z_folder"), name: "z_folder", isDirectory: true)

        state.items = [fileA, folderZ]
        state.sortField = .name
        state.sortAscending = true

        let sorted = state.filteredAndSortedItems
        XCTAssertEqual(sorted.count, 2)
        XCTAssertTrue(sorted[0].isDirectory, "Directories should always precede regular files")
        XCTAssertEqual(sorted[0].name, "z_folder")
        XCTAssertEqual(sorted[1].name, "a_file.txt")
    }

    func testSortBySize() {
        let smallFile = FileItem(url: URL(fileURLWithPath: "/tmp/small.txt"), name: "small.txt", isDirectory: false, fileSize: 100)
        let largeFile = FileItem(url: URL(fileURLWithPath: "/tmp/large.txt"), name: "large.txt", isDirectory: false, fileSize: 5000)

        state.items = [largeFile, smallFile]
        state.sortField = .size
        state.sortAscending = true

        var sorted = state.filteredAndSortedItems
        XCTAssertEqual(sorted[0].name, "small.txt")
        XCTAssertEqual(sorted[1].name, "large.txt")

        state.sortAscending = false
        sorted = state.filteredAndSortedItems
        XCTAssertEqual(sorted[0].name, "large.txt")
        XCTAssertEqual(sorted[1].name, "small.txt")
    }

    func testSortByDate() {
        let olderDate = Date(timeIntervalSince1970: 1000)
        let newerDate = Date(timeIntervalSince1970: 5000)

        let oldFile = FileItem(url: URL(fileURLWithPath: "/tmp/old.txt"), name: "old.txt", isDirectory: false, dateModified: olderDate)
        let newFile = FileItem(url: URL(fileURLWithPath: "/tmp/new.txt"), name: "new.txt", isDirectory: false, dateModified: newerDate)

        state.items = [newFile, oldFile]
        state.sortField = .dateModified
        state.sortAscending = true

        var sorted = state.filteredAndSortedItems
        XCTAssertEqual(sorted[0].name, "old.txt")
        XCTAssertEqual(sorted[1].name, "new.txt")

        state.sortAscending = false
        sorted = state.filteredAndSortedItems
        XCTAssertEqual(sorted[0].name, "new.txt")
        XCTAssertEqual(sorted[1].name, "old.txt")
    }

    func testFilteringCaseInsensitive() {
        let item1 = FileItem(url: URL(fileURLWithPath: "/tmp/ReadMe.md"), name: "ReadMe.md", isDirectory: false)
        let item2 = FileItem(url: URL(fileURLWithPath: "/tmp/main.swift"), name: "main.swift", isDirectory: false)
        let item3 = FileItem(url: URL(fileURLWithPath: "/tmp/Config.json"), name: "Config.json", isDirectory: false)

        state.items = [item1, item2, item3]

        state.filterText = "readme"
        XCTAssertEqual(state.filteredAndSortedItems.count, 1)
        XCTAssertEqual(state.filteredAndSortedItems.first?.name, "ReadMe.md")

        state.filterText = ".SWIFT"
        XCTAssertEqual(state.filteredAndSortedItems.count, 1)
        XCTAssertEqual(state.filteredAndSortedItems.first?.name, "main.swift")

        state.filterText = "nonexistent"
        XCTAssertEqual(state.filteredAndSortedItems.count, 0)
    }
}
