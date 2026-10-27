import Foundation
import Testing
@testable import Shark

@MainActor
struct LargeDirectoryTests {
    @Test func repeatedSelectionReadsFollowReplacementMetadataAndOrder() {
        let nav = NavigationState()
        let a = URL(fileURLWithPath: "/tmp/summary/a")
        let b = URL(fileURLWithPath: "/tmp/summary/b")
        nav.items = [FileItem(url: a, name: "a", isDirectory: false, fileSize: 3),
                     FileItem(url: b, name: "b", isDirectory: false, fileSize: 7)]
        nav.selectedItemIDs = [a, b]
        #expect(nav.selectedTotalSize == 10)
        #expect(nav.selectedItems.map(\.name) == ["a", "b"])
        nav.items = [FileItem(url: a, name: "a", isDirectory: false, fileSize: 30),
                     FileItem(url: b, name: "b", isDirectory: false, fileSize: 70)]
        #expect(nav.selectedTotalSize == 100)
        nav.setSort(field: .name, ascending: false)
        #expect(nav.selectedItems.map(\.name) == ["b", "a"])
        nav.selectedItemIDs = [a]
        #expect(nav.selectedItems.map(\.name) == ["a"])
        #expect(nav.selectedTotalSize == 30)
    }

    @Test func selectionKeepsDisplayOrderAndDropsFilteredFiles() {
        let nav = NavigationState()
        nav.items = (0..<10_000).map { index in
            FileItem(url: URL(fileURLWithPath: "/tmp/large/file-\(index)"), name: "file-\(index)",
                     isDirectory: false, fileSize: Int64(index))
        }
        nav.selectedItemIDs = [nav.items[9].id, nav.items[99].id, nav.items[999].id]
        #expect(nav.selectedItems.map(\.name) == ["file-9", "file-99", "file-999"])
        #expect(nav.selectedTotalSize == 1107)
        nav.setSort(field: .size, ascending: false)
        #expect(nav.selectedItems.map(\.name) == ["file-999", "file-99", "file-9"])
        nav.filterText = "file-99"
        #expect(nav.selectedItems.map(\.name) == ["file-999", "file-99"])
        #expect(nav.selectedTotalSize == 1098)
        nav.filterText = ""
        #expect(nav.selectedItems.map(\.name) == ["file-999", "file-99"])
    }
}
