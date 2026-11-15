import Foundation

/// iCloud Drive actions through the public FileManager API.
public enum CloudService {
    public static func download(_ urls: [URL]) throws {
        for url in urls { try FileManager.default.startDownloadingUbiquitousItem(at: url) }
    }

    /// Removes the local copy but keeps the item in iCloud.
    public static func removeDownload(_ urls: [URL]) throws {
        for url in urls { try FileManager.default.evictUbiquitousItem(at: url) }
    }

    /// Polls until the item is on this Mac. Throws on an iCloud error or cancellation.
    public static func waitUntilDownloaded(_ url: URL, interval: Duration = .milliseconds(400)) async throws {
        while true {
            try Task.checkCancellation()
            switch CloudState.read(url).state {
            case .notCloud, .synced, .uploading: return
            case .error(let message): throw CloudError.failed(message)
            case .cloudOnly, .downloading: try await Task.sleep(for: interval)
            }
        }
    }
}

public enum CloudError: LocalizedError {
    case failed(String)
    public var errorDescription: String? {
        switch self { case .failed(let message): return message }
    }
}
