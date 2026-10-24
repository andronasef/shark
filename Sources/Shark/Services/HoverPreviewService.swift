import AVFoundation
import AppKit
import Foundation
import ImageIO
import QuickLookThumbnailing
import UniformTypeIdentifiers

public enum HoverPreviewData: @unchecked Sendable {
    /// `dimensions` is `.zero` when the pixel size is unknown (e.g. a document thumbnail).
    case image(NSImage, dimensions: CGSize, fileSizeFormatted: String)
    case text(lines: [String], totalLines: Int, encoding: String, fileSizeFormatted: String, truncated: Bool)
    case media(url: URL, isVideo: Bool, fileSizeFormatted: String)
    case unsupported
}

@MainActor
public final class HoverPreviewService {
    public static let shared = HoverPreviewService()

    nonisolated static let textReadLimit = 32 * 1024
    nonisolated static let previewLineLimit = 40

    private enum Kind: Sendable { case image, text, media(isVideo: Bool), quickLook }

    nonisolated static let imagePixelLimit = 1024
    nonisolated static let animatedByteLimit = 16 * 1024 * 1024
    nonisolated static let cacheByteLimit = 32 * 1024 * 1024
    private struct Entry { let data: HoverPreviewData; let cost: Int }
    private var cache: [String: Entry] = [:]
    private var cacheOrder: [String] = []
    private(set) var cachedByteCount = 0
    private var generation = 0
    private let textExtensions: Set<String> = [
        "txt", "md", "markdown", "swift", "py", "js", "jsx", "ts", "tsx", "json", "jsonc", "toml",
        "html", "htm", "css", "scss", "xml", "plist", "yaml", "yml", "sh", "zsh", "bash", "fish",
        "c", "cpp", "cc", "h", "hpp", "m", "mm", "rs", "go", "rb", "java", "kt", "php", "lua", "sql",
        "csv", "tsv", "log", "conf", "cfg", "ini", "env", "gitignore", "rtfd", "tex", "diff", "patch"
    ]
    private let textFileNames: Set<String> = [
        "makefile", "dockerfile", "readme", "license", "changelog", "podfile", "gemfile", "package.resolved"
    ]
    /// Documents Quick Look can thumbnail but we cannot render ourselves.
    private let quickLookExtensions: Set<String> = [
        "pdf", "rtf", "doc", "docx", "xls", "xlsx", "ppt", "pptx", "pages", "numbers", "key", "epub"
    ]

    private init() {}

    public func supportsPreview(for url: URL) -> Bool {
        kind(of: url) != nil
    }

    private func kind(of url: URL) -> Kind? {
        let ext = url.pathExtension.lowercased()
        if textExtensions.contains(ext) || textFileNames.contains(url.lastPathComponent.lowercased()) { return .text }
        if quickLookExtensions.contains(ext) { return .quickLook }
        guard let type = UTType(filenameExtension: ext) else { return nil }
        if type.conforms(to: .image) { return .image }
        if type.conforms(to: .movie) || type.conforms(to: .video) { return .media(isVideo: true) }
        if type.conforms(to: .audio) { return .media(isVideo: false) }
        if type.conforms(to: .sourceCode) || type.conforms(to: .plainText) { return .text }
        return nil
    }

    public func fetchPreview(for url: URL) async -> HoverPreviewData {
        let standardized = url.standardizedFileURL
        let kind = kind(of: standardized)
        let generation = self.generation
        // Detached work owns every disk read and decode, including revision metadata.
        let work = Task.detached(priority: .userInitiated) {
            let revision = Self.revision(of: standardized)
            return revision
        }
        let revision = await withTaskCancellationHandler { await work.value } onCancel: { work.cancel() }
        guard !Task.isCancelled else { return .unsupported }
        let key = "\(standardized.path)|\(revision)"
        if let cached = cache[key] { return cached.data }
        let loader = Task.detached(priority: .userInitiated) {
            let result: HoverPreviewData
            switch kind {
            case .image: result = Self.generateImagePreview(for: standardized)
            case .text: result = Self.generateTextPreview(for: standardized)
            case .media(let isVideo): result = await Self.generateMediaPreview(for: standardized, isVideo: isVideo)
            case .quickLook: result = await Self.generateThumbnail(for: standardized)
            case nil: result = .unsupported
            }
            guard !Task.isCancelled, Self.revision(of: standardized) == revision else { return HoverPreviewData.unsupported }
            return result
        }
        let result = await withTaskCancellationHandler { await loader.value } onCancel: { loader.cancel() }
        guard !Task.isCancelled, generation == self.generation else { return .unsupported }
        // Failed/cancelled reads remain retryable.
        if case .unsupported = result { return result }
        let cost = Self.cost(of: result)
        while !cacheOrder.isEmpty && (cachedByteCount + cost > Self.cacheByteLimit || cache.count >= 24) {
            let oldest = cacheOrder.removeFirst()
            cachedByteCount -= cache.removeValue(forKey: oldest)?.cost ?? 0
        }
        if cost <= Self.cacheByteLimit {
            if let old = cache.removeValue(forKey: key) {
                cachedByteCount -= old.cost
                cacheOrder.removeAll { $0 == key }
            }
            cache[key] = Entry(data: result, cost: cost)
            cacheOrder.append(key)
            cachedByteCount += cost
        }
        return result
    }

    nonisolated private static func revision(of url: URL) -> String {
        let values = try? url.resourceValues(forKeys: [.contentModificationDateKey, .fileSizeKey, .fileResourceIdentifierKey])
        return "\(values?.contentModificationDate?.timeIntervalSinceReferenceDate ?? 0)|\(values?.fileSize ?? 0)|\(String(describing: values?.fileResourceIdentifier))"
    }

    nonisolated private static func formatFileSize(for url: URL) -> String {
        let size = (try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
        return ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)
    }

    nonisolated private static func generateImagePreview(for url: URL) -> HoverPreviewData {
        guard !Task.isCancelled,
              let source = CGImageSourceCreateWithURL(url as CFURL, [kCGImageSourceShouldCache: false] as CFDictionary),
              let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let width = props[kCGImagePropertyPixelWidth] as? Int,
              let height = props[kCGImagePropertyPixelHeight] as? Int else { return .unsupported }
        let count = CGImageSourceGetCount(source)
        let dimensions = CGSize(width: width, height: height)
        // Preserve small animations, but bound their complete decoded frame footprint.
        // Larger animations show a bounded first-frame thumbnail instead.
        let frameBytes = Double(width) * Double(height) * 16 * Double(count)
        if count > 1, frameBytes <= Double(animatedByteLimit),
           ((try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? Int.max) <= animatedByteLimit,
           let image = NSImage(contentsOf: url), !Task.isCancelled {
            return .image(image, dimensions: dimensions, fileSizeFormatted: formatFileSize(for: url))
        }
        guard !Task.isCancelled, let thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: imagePixelLimit,
            kCGImageSourceShouldCacheImmediately: true
        ] as CFDictionary), !Task.isCancelled else { return .unsupported }
        return .image(NSImage(cgImage: thumbnail, size: .zero), dimensions: dimensions,
                      fileSizeFormatted: formatFileSize(for: url))
    }

    nonisolated private static func generateMediaPreview(for url: URL, isVideo: Bool) async -> HoverPreviewData {
        guard !Task.isCancelled, (try? await AVURLAsset(url: url).load(.isPlayable)) == true,
              !Task.isCancelled else { return .unsupported }
        return .media(url: url, isVideo: isVideo, fileSizeFormatted: formatFileSize(for: url))
    }

    nonisolated private static func generateThumbnail(for url: URL) async -> HoverPreviewData {
        guard !Task.isCancelled else { return .unsupported }
        let sizeStr = formatFileSize(for: url)
        // Request is only handed to QLThumbnailGenerator, which is documented thread-safe.
        nonisolated(unsafe) let request = QLThumbnailGenerator.Request(fileAt: url, size: CGSize(width: 320, height: 240),
                                                                      scale: 2, representationTypes: .thumbnail)
        return await withTaskCancellationHandler {
            await withCheckedContinuation { continuation in
                QLThumbnailGenerator.shared.generateBestRepresentation(for: request) { rep, _ in
                    if let rep {
                        continuation.resume(returning: .image(rep.nsImage, dimensions: .zero, fileSizeFormatted: sizeStr))
                    } else { continuation.resume(returning: .unsupported) }
                }
            }
        } onCancel: { QLThumbnailGenerator.shared.cancel(request) }
    }

    nonisolated private static func generateTextPreview(for url: URL) -> HoverPreviewData {
        guard !Task.isCancelled, let handle = try? FileHandle(forReadingFrom: url) else { return .unsupported }
        defer { try? handle.close() }
        let data = handle.readData(ofLength: textReadLimit)
        guard !Task.isCancelled, let (text, encoding) = decode(data) else { return .unsupported }
        let allLines = text.components(separatedBy: .newlines)
        return .text(lines: Array(allLines.prefix(previewLineLimit)), totalLines: allLines.count,
                     encoding: encoding, fileSizeFormatted: formatFileSize(for: url), truncated: data.count == textReadLimit)
    }

    nonisolated static func pixelSize(of image: NSImage) -> CGSize {
        guard let cg = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return image.representations.first.map { CGSize(width: $0.pixelsWide, height: $0.pixelsHigh) } ?? .zero
        }
        return CGSize(width: cg.width, height: cg.height)
    }

    nonisolated private static func cost(of data: HoverPreviewData) -> Int {
        switch data {
        case .image(let image, _, _):
            // NSBitmapImageRep animation can retain all frames, including frames not yet decoded.
            // Snapshot reps report Retina-scaled pixels, so measure CGImage-backed images directly.
            return image.representations.reduce(0) { total, rep in
                if let bitmap = rep as? NSBitmapImageRep {
                    let frames = bitmap.value(forProperty: .frameCount) as? Int ?? 1
                    return total + bitmap.pixelsWide * bitmap.pixelsHigh * 16 * max(1, frames)
                }
                let size = pixelSize(of: image)
                return total + Int(size.width * size.height) * 16
            }
        case .text(let lines, _, _, _, _): return lines.reduce(0) { $0 + $1.utf8.count }
        default: return 0
        }
    }

    /// Decodes text, rejecting binary data. Tolerates a read that ends mid UTF-8 character.
    nonisolated static func decode(_ data: Data) -> (String, String)? {
        if data.starts(with: [0xFF, 0xFE]) || data.starts(with: [0xFE, 0xFF]),
           let text = String(data: data, encoding: .utf16) {
            return (text, "UTF-16")
        }
        if data.contains(0) { return nil }
        // A cut inside a multi-byte character leaves at most 3 dangling bytes.
        for dangling in 0...3 where data.count > dangling {
            if let text = String(data: data.dropLast(dangling), encoding: .utf8) { return (text, "UTF-8") }
        }
        return String(data: data, encoding: .isoLatin1).map { ($0, "ISO Latin 1") }
    }

    public func clearCache() {
        generation += 1
        cache.removeAll()
        cacheOrder.removeAll()
        cachedByteCount = 0
    }
}
