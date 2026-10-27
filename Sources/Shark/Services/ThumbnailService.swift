import AppKit
import QuickLookThumbnailing

struct ThumbnailKey: Hashable, Sendable {
    let url: URL
    let width: Int
    let height: Int
    let scale: Double
    let modified: Date?
    let bytes: Int?
    let resourceID: String?

    init(url: URL, size: CGSize, scale: CGFloat, modified: Date? = nil, bytes: Int? = nil, resourceID: String? = nil) {
        self.url = url
        let safeScale = scale.isFinite && scale > 0 ? scale : 1
        self.scale = Double(safeScale)
        func pixels(_ points: CGFloat) -> Int {
            guard points.isFinite else { return 128 }
            return Int(min(max((points * safeScale).rounded(.up), 1), 4096))
        }
        width = pixels(size.width)
        height = pixels(size.height)
        self.modified = modified; self.bytes = bytes; self.resourceID = resourceID
    }
}

/// CGImage is immutable; each decoded raster can safely cross actor boundaries.
struct ThumbnailRaster: @unchecked Sendable {
    let image: CGImage
    var byteCost: Int { image.bytesPerRow * image.height }
}

/// Coalesces consumers without giving any one consumer ownership of shared work.
actor ThumbnailScheduler {
    struct Statistics: Sendable {
        var requests = 0
        var cacheHits = 0
        var coalesced = 0
        var generated = 0
        var canceled = 0
        var peakActive = 0
        var active = 0
        var queued = 0
        var cachedBytes = 0
        var cachedEntries = 0
    }
    typealias Renderer = @Sendable (ThumbnailKey) async -> ThumbnailRaster?
    private struct Work {
        let id = UUID()
        var consumers: [UUID: CheckedContinuation<ThumbnailRaster?, Never>]
        var task: Task<Void, Never>?
    }
    private struct Entry { let raster: ThumbnailRaster; var access: UInt64 }
    private let renderer: Renderer
    private let concurrency: Int
    private let byteLimit: Int
    private let countLimit: Int
    private var work: [ThumbnailKey: Work] = [:]
    private var queue: [(key: ThumbnailKey, id: UUID)] = []
    private var queueIndex = 0
    private var queuedCount = 0
    private var cache: [ThumbnailKey: Entry] = [:]
    private var bytes = 0
    private var clock: UInt64 = 0
    private var active = 0
    private var stats = Statistics()

    init(concurrency: Int = 4, byteLimit: Int = 64 * 1024 * 1024, countLimit: Int = 500, renderer: @escaping Renderer) {
        self.concurrency = max(concurrency, 1); self.byteLimit = max(byteLimit, 0)
        self.countLimit = max(countLimit, 0); self.renderer = renderer
    }
    func key(url: URL, size: CGSize, scale: CGFloat) -> ThumbnailKey {
        // Actor isolation keeps filesystem metadata reads off the main actor.
        var resourceURL = url
        resourceURL.removeAllCachedResourceValues()
        let values = try? resourceURL.resourceValues(forKeys: [.contentModificationDateKey, .fileSizeKey, .fileResourceIdentifierKey])
        return ThumbnailKey(url: url, size: size, scale: scale, modified: values?.contentModificationDate,
            bytes: values?.fileSize, resourceID: values?.fileResourceIdentifier.map { String(describing: $0) })
    }
    func statistics() -> Statistics {
        var snapshot = stats
        snapshot.active = active; snapshot.queued = queuedCount
        snapshot.cachedBytes = bytes; snapshot.cachedEntries = cache.count
        return snapshot
    }
    func image(for key: ThumbnailKey) async -> ThumbnailRaster? {
        stats.requests += 1
        guard !Task.isCancelled else { return nil }
        clock &+= 1
        if var entry = cache[key] {
            stats.cacheHits += 1; entry.access = clock; cache[key] = entry
            return entry.raster
        }
        let id = UUID()
        var retryAfterCanceledWork = false
        let result = await withTaskCancellationHandler {
            await withCheckedContinuation { continuation in
                if work[key] != nil {
                    retryAfterCanceledWork = work[key]?.task?.isCancelled == true
                    stats.coalesced += 1
                    work[key]?.consumers[id] = continuation
                } else {
                    let job = Work(consumers: [id: continuation])
                    work[key] = job
                    queue.append((key, job.id))
                    queuedCount += 1
                }
                drain()
            }
        } onCancel: {
            Task { await self.cancel(key: key, consumer: id) }
        }
        if retryAfterCanceledWork, !Task.isCancelled { return await image(for: key) }
        return result
    }
    private func cancel(key: ThumbnailKey, consumer: UUID) {
        guard var job = work[key], let continuation = job.consumers.removeValue(forKey: consumer) else { return }
        stats.canceled += 1
        continuation.resume(returning: nil)
        if job.consumers.isEmpty {
            if let task = job.task {
                // Keep the occupied slot until cancellation finishes, avoiding overcommit.
                task.cancel()
                work[key] = job
            } else {
                work.removeValue(forKey: key)
                queuedCount -= 1
                drain()
            }
        } else { work[key] = job }
    }
    private func drain() {
        while active < concurrency, queueIndex < queue.count {
            let queued = queue[queueIndex]
            queueIndex += 1
            let key = queued.key
            guard work[key]?.id == queued.id else { continue }
            queuedCount -= 1
            active += 1; stats.generated += 1; stats.peakActive = max(stats.peakActive, active)
            let renderer = renderer
            work[key]?.task = Task {
                let result = await renderer(key)
                self.finish(key: key, result: Task.isCancelled ? nil : result)
            }
        }
        if queueIndex == queue.count {
            queue.removeAll(keepingCapacity: true)
            queueIndex = 0
        } else if queueIndex > 1024, queueIndex > queue.count / 2 {
            queue.removeFirst(queueIndex)
            queueIndex = 0
        }
    }
    private func finish(key: ThumbnailKey, result: ThumbnailRaster?) {
        guard let job = work.removeValue(forKey: key) else { return }
        active -= 1
        if let result, !job.consumers.isEmpty, result.byteCost <= byteLimit, countLimit > 0 {
            clock &+= 1
            if let old = cache.removeValue(forKey: key) { bytes -= old.raster.byteCost }
            cache[key] = Entry(raster: result, access: clock); bytes += result.byteCost
            while bytes > byteLimit || cache.count > countLimit {
                guard let oldest = cache.min(by: { $0.value.access < $1.value.access })?.key,
                      let removed = cache.removeValue(forKey: oldest) else { break }
                bytes -= removed.raster.byteCost
            }
        }
        for continuation in job.consumers.values { continuation.resume(returning: result) }
        drain()
    }
}

/// Quick Look may complete concurrently with cancellation; resolve its continuation exactly once.
private final class ThumbnailRequest: @unchecked Sendable {
    let request: QLThumbnailGenerator.Request
    private let lock = NSLock()
    private var continuation: CheckedContinuation<ThumbnailRaster?, Never>?
    private var canceled = false
    init(key: ThumbnailKey) {
        request = QLThumbnailGenerator.Request(fileAt: key.url,
            size: CGSize(width: CGFloat(key.width) / key.scale, height: CGFloat(key.height) / key.scale),
            scale: key.scale, representationTypes: .thumbnail)
    }
    func run() async -> ThumbnailRaster? {
        await withTaskCancellationHandler {
            await withCheckedContinuation { continuation in
                lock.lock()
                if canceled { lock.unlock(); continuation.resume(returning: nil); return }
                self.continuation = continuation
                QLThumbnailGenerator.shared.generateBestRepresentation(for: request) { [self] representation, _ in
                    resolve(representation.map { ThumbnailRaster(image: $0.cgImage) })
                }
                lock.unlock()
            }
        } onCancel: { self.cancel() }
    }
    private func resolve(_ result: ThumbnailRaster?) {
        lock.lock(); let pending = continuation; continuation = nil; lock.unlock()
        pending?.resume(returning: result)
    }
    private func cancel() {
        lock.lock(); canceled = true; lock.unlock()
        QLThumbnailGenerator.shared.cancel(request)
        resolve(nil)
    }
}

@MainActor
public final class ThumbnailService {
    public static let shared = ThumbnailService()
    private let scheduler = ThumbnailScheduler { key in await ThumbnailRequest(key: key).run() }
    private init() {}

    nonisolated static func requestDimension(_ points: CGFloat) -> CGFloat {
        guard points.isFinite else { return 128 }
        return min(4096, max(32, (points / 32).rounded(.up) * 32))
    }

    func statistics() async -> ThumbnailScheduler.Statistics { await scheduler.statistics() }

    public func thumbnail(for url: URL, size: CGSize = CGSize(width: 128, height: 128), scale: CGFloat? = nil) async -> NSImage {
        let displayScale = max(scale ?? NSScreen.main?.backingScaleFactor ?? 2, 1)
        let key = await scheduler.key(url: url, size: size, scale: displayScale)
        if let raster = await scheduler.image(for: key), !Task.isCancelled {
            // Natural point dimensions preserve the generated thumbnail's aspect ratio.
            return NSImage(cgImage: raster.image, size: CGSize(width: CGFloat(raster.image.width) / displayScale, height: CGFloat(raster.image.height) / displayScale))
        }
        // Failures remain retryable; a temporary permission/decode error never poisons the cache.
        return NSImage(systemSymbolName: "doc", accessibilityDescription: nil) ?? NSImage(size: size)
    }
}
