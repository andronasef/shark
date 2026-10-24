import Foundation
import Testing
@testable import Shark

struct FileContextActionsTests {
    @Test func contextUsesClickedItemOrWholeExistingSelection() {
        let a = FileItem(url: URL(fileURLWithPath: "/tmp/a"), name: "a", isDirectory: false)
        let b = FileItem(url: URL(fileURLWithPath: "/tmp/b"), name: "b", isDirectory: false)
        #expect(FileContextSelection.items(clicked: b, selected: [a.url], ordered: [a,b]) == [b])
        #expect(FileContextSelection.items(clicked: b, selected: [a.url,b.url], ordered: [a,b]) == [a,b])
    }

    @MainActor @Test func mixedTypesOnlyOfferSharedApplications() {
        let a = URL(fileURLWithPath: "/Applications/One.app")
        let b = URL(fileURLWithPath: "/Applications/Two.app")
        #expect(OpenWithService.commonApplications([[a,b],[b]]) == [b])
        #expect(OpenWithService.commonApplications([[a],[]]).isEmpty)
    }
}
