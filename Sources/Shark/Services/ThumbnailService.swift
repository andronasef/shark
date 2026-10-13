import AppKit
import QuickLookThumbnailing

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

        do {
            let representation = try await QLThumbnailGenerator.shared.generateBestRepresentation(for: request)
            let image = representation.nsImage
            cache.setObject(image, forKey: key)
            return image
        } catch {
            let fallback = NSWorkspace.shared.icon(forFile: url.path)
            cache.setObject(fallback, forKey: key)
            return fallback
        }
    }
}
