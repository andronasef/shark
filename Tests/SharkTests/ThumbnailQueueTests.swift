import AppKit
import Testing
@testable import Shark

private actor ThumbnailGate {
    private var pending: [URL: CheckedContinuation<ThumbnailRaster?, Never>] = [:]
    func render(_ key: ThumbnailKey) async -> ThumbnailRaster? {
        await withCheckedContinuation { pending[key.url] = $0 }
    }
    func started(_ key: ThumbnailKey) -> Bool { pending[key.url] != nil }
    func finish(_ key: ThumbnailKey, with raster: ThumbnailRaster) {
        pending.removeValue(forKey: key.url)?.resume(returning: raster)
    }
}

struct ThumbnailQueueTests {
    @Test(.timeLimit(.minutes(1))) func canceledQueuedKeyCanBeRequestedAgain() async throws {
        let context = try #require(CGContext(data: nil, width: 8, height: 8, bitsPerComponent: 8, bytesPerRow: 32,
            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
        let raster = ThumbnailRaster(image: try #require(context.makeImage()))
        let gate = ThumbnailGate()
        let scheduler = ThumbnailScheduler(concurrency: 1) { await gate.render($0) }
        let active = ThumbnailKey(url: URL(fileURLWithPath: "/tmp/active.png"), size: CGSize(width: 8, height: 8), scale: 1)
        let queued = ThumbnailKey(url: URL(fileURLWithPath: "/tmp/queued.png"), size: CGSize(width: 8, height: 8), scale: 1)
        let first = Task { await scheduler.image(for: active) }
        while !(await gate.started(active)) { await Task.yield() }
        let canceled = Task { await scheduler.image(for: queued) }
        while await scheduler.statistics().queued < 1 { await Task.yield() }
        canceled.cancel()
        #expect(await canceled.value == nil)
        let replacement = Task { await scheduler.image(for: queued) }
        while await scheduler.statistics().requests < 3 { await Task.yield() }
        await gate.finish(active, with: raster)
        _ = await first.value
        while !(await gate.started(queued)) { await Task.yield() }
        await gate.finish(queued, with: raster)
        #expect(await replacement.value != nil)
        let statistics = await scheduler.statistics()
        #expect(statistics.generated == 2)
        #expect(statistics.queued == 0)
        #expect(statistics.peakActive == 1)
    }
}
