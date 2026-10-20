import AppKit
import QuickLookThumbnailing

@MainActor
public final class ThumbnailService {
    public static let shared = ThumbnailService()

    private let cache = NSCache<NSURL, NSImage>()

    private init() {
        cache.countLimit = 500
    }

    private nonisolated func fetchCGImage(for url: URL, size: CGSize, scale: CGFloat) async -> CGImage? {
        let request = QLThumbnailGenerator.Request(
            fileAt: url,
            size: size,
            scale: scale,
            representationTypes: .thumbnail
        )
        return await withCheckedContinuation { continuation in
            QLThumbnailGenerator.shared.generateBestRepresentation(for: request) { rep, _ in
                continuation.resume(returning: rep?.cgImage)
            }
        }
    }

    public func thumbnail(for url: URL, size: CGSize = CGSize(width: 128, height: 128)) async -> NSImage {
        let key = url as NSURL
        if let cached = cache.object(forKey: key) {
            return cached
        }

        let scale = NSScreen.main?.backingScaleFactor ?? 2.0
        if let cgImage = await fetchCGImage(for: url, size: size, scale: scale) {
            let image = NSImage(cgImage: cgImage, size: size)
            cache.setObject(image, forKey: key)
            return image
        } else {
            let fallback = NSWorkspace.shared.icon(forFile: url.path)
            cache.setObject(fallback, forKey: key)
            return fallback
        }
    }
}
