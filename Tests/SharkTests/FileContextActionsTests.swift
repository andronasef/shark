import Foundation
import Testing
@testable import Shark

struct FileContextActionsTests {
    @MainActor @Test func contextUsesClickedItemOrWholeExistingSelection() {
        let a = FileItem(url: URL(fileURLWithPath: "/tmp/a"), name: "a", isDirectory: false)
        let b = FileItem(url: URL(fileURLWithPath: "/tmp/b"), name: "b", isDirectory: false)
        let navigation = NavigationState()
        navigation.items = [a, b]
        navigation.selectedItemIDs = [a.url]
        #expect(navigation.contextItems(for: b) == [b])
        navigation.selectedItemIDs = [a.url, b.url]
        #expect(navigation.contextItems(for: b) == [a, b])
    }

    @MainActor @Test func mixedTypesOnlyOfferSharedApplications() {
        let a = URL(fileURLWithPath: "/Applications/One.app")
        let b = URL(fileURLWithPath: "/Applications/Two.app")
        #expect(OpenWithService.commonApplications([[a,b],[b]]) == [b])
        #expect(OpenWithService.commonApplications([[a],[]]).isEmpty)
    }

    @MainActor @Test func openWithRequiresOnlyFiles() {
        let file = FileItem(url: URL(fileURLWithPath: "/tmp/a.txt"), name: "a.txt", isDirectory: false)
        let folder = FileItem(url: URL(fileURLWithPath: "/tmp/f"), name: "f", isDirectory: true)
        #expect(OpenWithService.canOpenWith([file]))
        #expect(!OpenWithService.canOpenWith([file, folder]), "a mixed selection must not offer to open folders in an app")
        #expect(!OpenWithService.canOpenWith([]))
        #expect(OpenWithService.applications(for: [file, folder]).isEmpty)
    }

    @Test func contentTypeComesFromTheNameNotTheDisk() {
        #expect(OpenWithService.contentTypeKey(for: URL(fileURLWithPath: "/missing/photo.JPG")) == "public.jpeg")
        #expect(OpenWithService.contentTypeKey(for: URL(fileURLWithPath: "/missing/noext")) == "public.data")
    }
}
