import Foundation
import Observation

@Observable
@MainActor
public final class FolderSizeCalculator {
    public static let shared = FolderSizeCalculator()

    private var cache: [URL: Int64] = [:]
    private var calculating: Set<URL> = []
    @ObservationIgnored private var requests: [URL: UUID] = [:]
    @ObservationIgnored private var running: [UUID: Task<Void, Never>] = [:]
    @ObservationIgnored private var queue: [URL] = []
    @ObservationIgnored private var queueIndex = 0
    private let concurrency: Int
    private let scan: @Sendable (URL) async -> Int64?

    public init() {
        concurrency = 2
        scan = { await Self.computeSize(of: $0) }
    }

    init(concurrency: Int, scan: @escaping @Sendable (URL) async -> Int64?) {
        self.concurrency = max(1, concurrency)
        self.scan = scan
    }

    isolated deinit {
        for task in running.values { task.cancel() }
    }

    public func size(for url: URL) -> Int64? {
        cache[url.standardizedFileURL]
    }

    public func isCalculating(url: URL) -> Bool {
        calculating.contains(url.standardizedFileURL)
    }

    public func requestSize(for url: URL) {
        let stdURL = url.standardizedFileURL
        // A repeat request recalculates: the folder may have changed since the cached size.
        if calculating.contains(stdURL) {
            return
        }

        calculating.insert(stdURL)
        requests[stdURL] = UUID()
        queue.append(stdURL)
        drain()
    }

    private func drain() {
        while running.count < concurrency, queueIndex < queue.count {
            let url = queue[queueIndex]
            queueIndex += 1
            guard let id = requests[url] else { continue }
            let scan = scan
            running[id] = Task { [weak self] in
                let size = await scan(url)
                self?.finish(url: url, id: id, size: Task.isCancelled ? nil : size)
            }
        }
        if queueIndex == queue.count { queue.removeAll(keepingCapacity: true); queueIndex = 0 }
    }

    private func finish(url: URL, id: UUID, size: Int64?) {
        running.removeValue(forKey: id)
        if requests[url] == id {
            requests.removeValue(forKey: url)
            calculating.remove(url)
            if let size { cache[url] = size }
        }
        drain()
    }

    public func clearCache() {
        for task in running.values { task.cancel() }
        requests.removeAll()
        queue.removeAll()
        queueIndex = 0
        cache.removeAll()
        calculating.removeAll()
        // Occupied slots are released only after their scans actually stop.
    }

    @concurrent private static func computeSize(of directoryURL: URL) async -> Int64? {
        scanSize(of: directoryURL)
    }

    private nonisolated static func scanSize(of directoryURL: URL) -> Int64? {
        guard !Task.isCancelled else { return nil }
        let fileManager = FileManager.default
        guard let enumerator = fileManager.enumerator(
            at: directoryURL,
            includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey, .isRegularFileKey],
            options: [.skipsPackageDescendants]
        ) else {
            return nil
        }

        var totalSize: Int64 = 0
        for case let fileURL as URL in enumerator {
            guard !Task.isCancelled else { return nil }
            do {
                let resourceValues = try fileURL.resourceValues(forKeys: [.fileSizeKey, .isRegularFileKey])
                if resourceValues.isRegularFile == true, let size = resourceValues.fileSize {
                    totalSize += Int64(size)
                }
            } catch {
                continue
            }
        }
        return totalSize
    }
}
