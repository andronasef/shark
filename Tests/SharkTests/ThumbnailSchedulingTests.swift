import XCTest
import AppKit
@testable import Shark

final class ThumbnailSchedulingTests: XCTestCase {
    private func key(_ name: String, size: CGFloat = 16, scale: CGFloat = 2, date: Date? = nil) -> ThumbnailKey {
        ThumbnailKey(url: URL(fileURLWithPath: "/tmp/\(name).png"), size: CGSize(width: size, height: size), scale: scale, modified: date)
    }
    private static func raster() -> ThumbnailRaster {
        let space = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: nil, width: 16, height: 16, bitsPerComponent: 8, bytesPerRow: 64,
            space: space, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        return ThumbnailRaster(image: context.makeImage()!)
    }
    func testSizeScaleAndRevisionNeverAlias() {
        XCTAssertNotEqual(key("same"), key("same", size: 32))
        XCTAssertNotEqual(key("same"), key("same", scale: 1))
        XCTAssertNotEqual(key("same"), key("same", date: Date(timeIntervalSince1970: 1)))
    }
    func testFileRevisionIsReadAgainOffMainActor() async throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: url) }
        let scheduler = ThumbnailScheduler { _ in nil }
        try Data([1]).write(to: url)
        let first = await scheduler.key(url: url, size: CGSize(width: 16, height: 16), scale: 2)
        try Data([1, 2, 3]).write(to: url)
        let second = await scheduler.key(url: url, size: CGSize(width: 16, height: 16), scale: 2)
        XCTAssertNotEqual(first, second)
    }

    func testConcurrentConsumersCoalesceAndCache() async {
        let scheduler = ThumbnailScheduler { _ in
            try? await Task.sleep(for: .milliseconds(30))
            return Self.raster()
        }
        let key = key("shared")
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<20 { group.addTask { _ = await scheduler.image(for: key) } }
        }
        _ = await scheduler.image(for: key)
        let stats = await scheduler.statistics()
        XCTAssertEqual(stats.generated, 1)
        XCTAssertEqual(stats.coalesced, 19)
        XCTAssertEqual(stats.cacheHits, 1)
    }
    func testConcurrencyAndDecodedByteBudget() async {
        let scheduler = ThumbnailScheduler(concurrency: 2, byteLimit: 2048, countLimit: 100) { _ in
            try? await Task.sleep(for: .milliseconds(10))
            return Self.raster()
        }
        let keys = (0..<16).map { key("\($0)") }
        await withTaskGroup(of: Void.self) { group in
            for key in keys { group.addTask { _ = await scheduler.image(for: key) } }
        }
        let stats = await scheduler.statistics()
        XCTAssertEqual(stats.peakActive, 2)
        XCTAssertLessThanOrEqual(stats.cachedBytes, 2048)
        XCTAssertEqual(stats.cachedEntries, 2)
        XCTAssertEqual(stats.active, 0)
        XCTAssertEqual(stats.queued, 0)
    }
    func testCancelingOneConsumerDoesNotCancelAnother() async {
        let scheduler = ThumbnailScheduler { _ in
            try? await Task.sleep(for: .milliseconds(60))
            return Self.raster()
        }
        let key = key("cancel")
        let first = Task { await scheduler.image(for: key) }
        let second = Task { await scheduler.image(for: key) }
        // Observe registration rather than guessing when the child tasks have started.
        while await scheduler.statistics().requests < 2 { await Task.yield() }
        first.cancel()
        let canceled = await first.value
        let kept = await second.value
        XCTAssertNil(canceled)
        XCTAssertNotNil(kept)
        let stats = await scheduler.statistics()
        XCTAssertEqual(stats.generated, 1)
    }
    func testFailuresAreRetryable() async {
        let scheduler = ThumbnailScheduler { _ in nil }
        let key = key("failure")
        _ = await scheduler.image(for: key)
        _ = await scheduler.image(for: key)
        let stats = await scheduler.statistics()
        XCTAssertEqual(stats.generated, 2)
        XCTAssertEqual(stats.cachedEntries, 0)
    }
    func testCanceledQueuedConsumerDoesNotGenerate() async {
        let scheduler = ThumbnailScheduler(concurrency: 1) { _ in
            try? await Task.sleep(for: .milliseconds(60))
            return Self.raster()
        }
        let firstKey = key("active")
        let waitingKey = key("waiting")
        let first = Task { await scheduler.image(for: firstKey) }
        while await scheduler.statistics().active < 1 { await Task.yield() }
        let queued = Task { await scheduler.image(for: waitingKey) }
        while await scheduler.statistics().queued < 1 { await Task.yield() }
        queued.cancel()
        _ = await queued.value
        _ = await first.value
        let stats = await scheduler.statistics()
        XCTAssertEqual(stats.generated, 1)
        XCTAssertEqual(stats.queued, 0)
    }
}
