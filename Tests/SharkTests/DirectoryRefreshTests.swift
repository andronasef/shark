import Foundation
import Testing
@testable import Shark

private actor DirectoryReads {
    private var pending: [Bool: CheckedContinuation<[FileItem], any Error>] = [:]
    func read(hidden: Bool) async throws -> [FileItem] {
        try await withCheckedThrowingContinuation { pending[hidden] = $0 }
    }
    func hasRead(hidden: Bool) -> Bool { pending[hidden] != nil }
    func finish(hidden: Bool, items: [FileItem]) { pending.removeValue(forKey: hidden)?.resume(returning: items) }
}

@MainActor
struct DirectoryRefreshTests {
    @Test(.timeLimit(.minutes(1))) func newestSameFolderRequestWins() async {
        let reads = DirectoryReads()
        let nav = NavigationState(initialURL: URL(fileURLWithPath: "/tmp"), readDirectory: { _, hidden in
            try await reads.read(hidden: hidden)
        })
        let first = Task { await nav.reloadCurrentDirectory() }
        while !(await reads.hasRead(hidden: false)) { await Task.yield() }
        nav.showHiddenFiles = true
        while !(await reads.hasRead(hidden: true)) { await Task.yield() }
        let latest = FileItem(url: URL(fileURLWithPath: "/tmp/.hidden"), name: ".hidden", isDirectory: false)
        await reads.finish(hidden: true, items: [latest])
        while nav.isLoading { await Task.yield() }
        await reads.finish(hidden: false, items: [])
        await first.value
        #expect(nav.items == [latest])
        #expect(!nav.isLoading)
    }
    @Test(.timeLimit(.minutes(1))) func canceledReloadDoesNotPublishAndClearsLoading() async {
        let reads = DirectoryReads()
        let nav = NavigationState(initialURL: URL(fileURLWithPath: "/tmp"), readDirectory: { _, hidden in
            try await reads.read(hidden: hidden)
        })
        let task = Task { await nav.reloadCurrentDirectory() }
        while !(await reads.hasRead(hidden: false)) { await Task.yield() }
        task.cancel()
        await reads.finish(hidden: false, items: [FileItem(url: URL(fileURLWithPath: "/tmp/old"), name: "old", isDirectory: false)])
        await task.value
        #expect(nav.items.isEmpty)
        #expect(!nav.isLoading)
    }

}
