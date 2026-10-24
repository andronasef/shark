import Foundation

public final class DiskSpaceService: Sendable {
    public static let shared = DiskSpaceService()

    public init() {}

    public struct SpaceInfo: Sendable {
        public let availableBytes: Int64
        public let totalBytes: Int64

        public var formattedAvailable: String {
            ByteCountFormatter.string(fromByteCount: availableBytes, countStyle: .file)
        }

        public var formattedTotal: String {
            ByteCountFormatter.string(fromByteCount: totalBytes, countStyle: .file)
        }

        public var summary: String {
            L10n.format("%@ available", formattedAvailable)
        }
    }

    public func getDiskSpace(for url: URL) -> SpaceInfo? {
        do {
            let values = try url.resourceValues(forKeys: [
                .volumeAvailableCapacityKey,
                .volumeAvailableCapacityForImportantUsageKey,
                .volumeTotalCapacityKey
            ])

            let available = values.volumeAvailableCapacityForImportantUsage ?? Int64(values.volumeAvailableCapacity ?? 0)
            let total = Int64(values.volumeTotalCapacity ?? 0)

            guard available > 0 else { return nil }
            return SpaceInfo(availableBytes: available, totalBytes: total)
        } catch {
            return nil
        }
    }
}
