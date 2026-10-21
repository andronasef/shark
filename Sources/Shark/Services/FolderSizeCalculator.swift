import Foundation
import Observation

@Observable
@MainActor
public final class FolderSizeCalculator {
    public static let shared = FolderSizeCalculator()

    private var cache: [URL: Int64] = [:]
    private var calculating: Set<URL> = []

    public init() {}

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
        Task.detached(priority: .utility) {
            let total = Self.computeSize(of: stdURL)
            await MainActor.run {
                FolderSizeCalculator.shared.finishCalculating(url: stdURL, size: total)
            }
        }
    }

    private func finishCalculating(url: URL, size: Int64?) {
        calculating.remove(url)
        if let size {
            cache[url] = size
        }
    }

    public func clearCache() {
        cache.removeAll()
        calculating.removeAll()
    }

    private nonisolated static func computeSize(of directoryURL: URL) -> Int64? {
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
