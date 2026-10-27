import Foundation
import Testing
@testable import Shark

private actor SizeReads {
    private var pending: [URL: CheckedContinuation<Int64?, Never>] = [:]
    func read(_ url: URL) async -> Int64? {
        await withCheckedContinuation { pending[url] = $0 }
    }
    func started(_ url: URL) -> Bool { pending[url] != nil }
    func finish(_ url: URL, size: Int64) { pending.removeValue(forKey: url)?.resume(returning: size) }
}

@MainActor
struct FolderSizeTests {
    @Test func independentCalculatorReceivesItsOwnResult() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        try Data([1, 2, 3]).write(to: root.appendingPathComponent("file"))
        let calculator = FolderSizeCalculator()
        calculator.requestSize(for: root)
        let deadline = ContinuousClock.now + .seconds(2)
        while calculator.isCalculating(url: root), ContinuousClock.now < deadline {
            await Task.yield()
        }
        #expect(!calculator.isCalculating(url: root))
        #expect(calculator.size(for: root) == 3)
    }

    @Test(.timeLimit(.minutes(1))) func resetRejectsOldResultsAndKeepsOccupiedSlotsBounded() async {
        let reads = SizeReads()
        let a = URL(fileURLWithPath: "/tmp/size-a")
        let b = URL(fileURLWithPath: "/tmp/size-b")
        let calculator = FolderSizeCalculator(concurrency: 1) { await reads.read($0) }
        calculator.requestSize(for: a)
        while !(await reads.started(a)) { await Task.yield() }
        calculator.clearCache()
        calculator.requestSize(for: b)
        #expect(await !reads.started(b))
        await reads.finish(a, size: 100)
        while !(await reads.started(b)) { await Task.yield() }
        #expect(calculator.size(for: a) == nil)
        await reads.finish(b, size: 7)
        while calculator.isCalculating(url: b) { await Task.yield() }
        #expect(calculator.size(for: b) == 7)
    }
}
