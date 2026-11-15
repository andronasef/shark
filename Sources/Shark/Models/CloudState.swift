import Foundation

/// Where an iCloud Drive item stands, from the public URL resource values. There is no percentage
/// here on purpose: macOS exposes no public progress value for a download, so none is shown.
public enum CloudState: Sendable, Hashable {
    case notCloud
    /// In iCloud and on this Mac, nothing to report.
    case synced
    /// In iCloud only; opening it needs a download.
    case cloudOnly
    case downloading
    case uploading
    case error(String)

    public var isCloudItem: Bool { self != .notCloud }

    /// The one state worth a badge. Synced and non-cloud items get none.
    public var needsBadge: Bool {
        switch self {
        case .notCloud, .synced: return false
        default: return true
        }
    }

    public static func make(isUbiquitous: Bool, status: URLUbiquitousItemDownloadingStatus?,
                            isDownloading: Bool, isUploading: Bool, errorMessage: String?) -> CloudState {
        guard isUbiquitous else { return .notCloud }
        if let errorMessage { return .error(errorMessage) }
        if isDownloading { return .downloading }
        if isUploading { return .uploading }
        if status == .notDownloaded { return .cloudOnly }
        return .synced
    }

    static let resourceKeys: Set<URLResourceKey> = [
        .isUbiquitousItemKey, .ubiquitousItemDownloadingStatusKey, .ubiquitousItemIsDownloadingKey,
        .ubiquitousItemIsUploadingKey, .ubiquitousItemIsSharedKey,
        .ubiquitousItemDownloadingErrorKey, .ubiquitousItemUploadingErrorKey
    ]

    /// Reads the state of one item. Costs one extra lookup only for items that are in iCloud.
    public static func read(_ url: URL) -> (state: CloudState, isShared: Bool) {
        guard let flag = try? url.resourceValues(forKeys: [.isUbiquitousItemKey]), flag.isUbiquitousItem == true,
              let v = try? url.resourceValues(forKeys: resourceKeys) else { return (.notCloud, false) }
        let error = v.ubiquitousItemDownloadingError ?? v.ubiquitousItemUploadingError
        let state = make(isUbiquitous: true, status: v.ubiquitousItemDownloadingStatus,
                         isDownloading: v.ubiquitousItemIsDownloading ?? false,
                         isUploading: v.ubiquitousItemIsUploading ?? false,
                         errorMessage: error?.localizedDescription)
        return (state, v.ubiquitousItemIsShared ?? false)
    }
}
