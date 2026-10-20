import AppKit
@preconcurrency import QuickLookThumbnailing

@MainActor
public final class ThumbnailService {
    public static let shared = ThumbnailService()

    private let cache = NSCache<NSURL, NSImage>()

    private init() {
        cache.countLimit = 500
    }

    public func thumbnail(for url: URL, size: CGSize = CGSize(width: 128, height: 128)) async -> NSImage {
        let key = url as NSURL
        if let cached = cache.object(forKey: key) {
            return cached
        }

        let scale = NSScreen.main?.backingScaleFactor ?? 2.0
        let request = QLThumbnailGenerator.Request(
            fileAt: url,
            size: size,
            scale: scale,
            representationTypes: .thumbnail
        )

        return await withCheckedContinuation { continuation in
            QLThumbnailGenerator.shared.generateBestRepresentation(for: request) { [weak self] representation, _ in
                let image = representation?.nsImage ?? NSWorkspace.shared.icon(forFile: url.path)
                Task { @MainActor [weak self] in
                    self?.cache.setObject(image, forKey: key)
                    continuation.resume(returning: image)
                }
            }
        }
    }
}
