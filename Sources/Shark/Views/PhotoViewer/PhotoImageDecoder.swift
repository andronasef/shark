import AppKit
import ImageIO
import UniformTypeIdentifiers

/// Serial decoding bounds simultaneous raster allocation. Only the current frame is retained by a viewer.
actor PhotoImageDecoder {
    static let shared = PhotoImageDecoder()

    /// CGImage is immutable; no mutable ImageIO source escapes the decoder actor.
    struct Result: @unchecked Sendable {
        let image: CGImage?
        let pixels: CGSize
        let frameCount: Int
        let duration: Double
        let metadata: String
        let error: String?
        let detailLimited: Bool
    }

    nonisolated static func fitsRasterBudget(width: Int, height: Int) -> Bool {
        guard width > 0, height > 0 else { return false }
        return width <= (16 * 1024 * 1024) / height
    }

    func decode(url: URL, maxPixel: Int, frame: Int = 0, actualSize: Bool = false) -> Result {
        func failure(_ message: String) -> Result {
            Result(image: nil, pixels: .zero, frameCount: 0, duration: 0.1, metadata: "", error: message, detailLimited: false)
        }
        guard !Task.isCancelled else { return failure(L10n.text("Photo loading was canceled.")) }
        guard FileManager.default.isReadableFile(atPath: url.path) else {
            return failure(L10n.text("This photo is missing or cannot be read. You can continue to the next photo."))
        }
        guard let source = CGImageSourceCreateWithURL(url as CFURL, [kCGImageSourceShouldCache: false] as CFDictionary) else {
            return failure(L10n.text("This file is damaged or its image format is unsupported."))
        }
        let count = CGImageSourceGetCount(source)
        guard count > 0 else { return failure(L10n.text("This image contains no readable frames.")) }
        let index = min(frame, count - 1)
        let props = CGImageSourceCopyPropertiesAtIndex(source, index, nil) as? [CFString: Any] ?? [:]
        let width = props[kCGImagePropertyPixelWidth] as? Int ?? 0
        let height = props[kCGImagePropertyPixelHeight] as? Int ?? 0
        let orientation = props[kCGImagePropertyOrientation] as? Int ?? 1
        let pixels = orientation >= 5 ? CGSize(width: height, height: width) : CGSize(width: width, height: height)
        // Permit full resolution only within the same 64 MiB decoded-raster budget.
        let fullResolutionFits = Self.fitsRasterBudget(width: width, height: height)
        let requestedEdge = actualSize && fullResolutionFits ? max(width, height) : min(max(maxPixel, 1), 4096)
        guard let image = ImageDownsampler.image(from: source, at: index, maxPixel: requestedEdge) else {
            return failure(L10n.text("This photo could not be decoded. You can continue to the next photo."))
        }
        let gif = props[kCGImagePropertyGIFDictionary] as? [CFString: Any] ?? [:]
        let delay = gif[kCGImagePropertyGIFUnclampedDelayTime] as? Double ?? gif[kCGImagePropertyGIFDelayTime] as? Double ?? 0.1
        let type = CGImageSourceGetType(source).flatMap { UTType($0 as String)?.localizedDescription } ?? L10n.text("Image")
        let bytes = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
        var metadata = "\(Int(pixels.width)) × \(Int(pixels.height)) · \(type) · \(ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file))"
        let exif = props[kCGImagePropertyExifDictionary] as? [CFString: Any] ?? [:]
        let tiff = props[kCGImagePropertyTIFFDictionary] as? [CFString: Any] ?? [:]
        let details = [tiff[kCGImagePropertyTIFFModel] as? String, exif[kCGImagePropertyExifDateTimeOriginal] as? String].compactMap { $0 }
        if !details.isEmpty { metadata += " · " + details.joined(separator: " · ") }
        let animated = CGImageSourceGetType(source).map { UTType($0 as String)?.conforms(to: .gif) == true } ?? false
        return Result(image: image, pixels: pixels, frameCount: animated ? count : 1, duration: max(delay, 0.02), metadata: metadata, error: nil, detailLimited: actualSize && !fullResolutionFits)
    }
}

/// Bounded, orientation-correct decode shared by the photo viewer and hover previews.
enum ImageDownsampler {
    nonisolated static func image(from source: CGImageSource, at index: Int = 0, maxPixel: Int) -> CGImage? {
        CGImageSourceCreateThumbnailAtIndex(source, index, [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixel,
            kCGImageSourceShouldCacheImmediately: true
        ] as CFDictionary)
    }
}
