import AVFoundation
import AppKit
import Foundation
import QuickLookThumbnailing
import UniformTypeIdentifiers

public enum HoverPreviewData: Sendable {
    /// `dimensions` is `.zero` when the pixel size is unknown (e.g. a document thumbnail).
    case image(NSImage, dimensions: CGSize, fileSizeFormatted: String)
    case text(lines: [String], totalLines: Int, encoding: String, fileSizeFormatted: String, truncated: Bool)
    case media(url: URL, isVideo: Bool, fileSizeFormatted: String)
    case unsupported
}

@MainActor
public final class HoverPreviewService {
    public static let shared = HoverPreviewService()

    static let textReadLimit = 32 * 1024
    static let previewLineLimit = 40

    private enum Kind { case image, text, media(isVideo: Bool), quickLook }

    private var cache: [String: HoverPreviewData] = [:]
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
        // Keyed by modification date so an edited file never shows a stale preview.
        let modified = (try? standardized.resourceValues(forKeys: [.contentModificationDateKey]))?
            .contentModificationDate?.timeIntervalSinceReferenceDate ?? 0
        let key = "\(standardized.path)|\(modified)"
        if let cached = cache[key] { return cached }

        let result: HoverPreviewData
        switch kind(of: standardized) {
        case .image: result = generateImagePreview(for: standardized)
        case .text: result = generateTextPreview(for: standardized)
        case .media(let isVideo): result = await generateMediaPreview(for: standardized, isVideo: isVideo)
        case .quickLook: result = await generateThumbnail(for: standardized)
        case nil: result = .unsupported
        }

        // Full-resolution images are large; keep the cache small rather than tracking cost.
        if cache.count >= 24 { cache.removeAll() }
        cache[key] = result
        return result
    }

    private func formatFileSize(for url: URL) -> String {
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
              let size = attrs[.size] as? Int64 else {
            return ""
        }
        return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }

    private func generateImagePreview(for url: URL) -> HoverPreviewData {
        guard let image = NSImage(contentsOf: url) else { return .unsupported }
        let pixels = image.representations
            .map { CGSize(width: $0.pixelsWide, height: $0.pixelsHigh) }
            .max { $0.width < $1.width }
        let dimensions = (pixels?.width ?? 0) > 0 ? pixels! : image.size
        return .image(image, dimensions: dimensions, fileSizeFormatted: formatFileSize(for: url))
    }

    private func generateMediaPreview(for url: URL, isVideo: Bool) async -> HoverPreviewData {
        // AVPlayer silently shows nothing for containers it cannot decode (mkv, avi, ...).
        guard (try? await AVURLAsset(url: url).load(.isPlayable)) == true else { return .unsupported }
        return .media(url: url, isVideo: isVideo, fileSizeFormatted: formatFileSize(for: url))
    }

    private func generateThumbnail(for url: URL) async -> HoverPreviewData {
        let sizeStr = formatFileSize(for: url)
        let request = QLThumbnailGenerator.Request(
            fileAt: url,
            size: CGSize(width: 320, height: 240),
            scale: 2.0,
            representationTypes: .thumbnail
        )

        return await withCheckedContinuation { continuation in
            QLThumbnailGenerator.shared.generateBestRepresentation(for: request) { rep, _ in
                if let rep = rep {
                    continuation.resume(returning: .image(rep.nsImage, dimensions: .zero, fileSizeFormatted: sizeStr))
                } else {
                    continuation.resume(returning: .unsupported)
                }
            }
        }
    }

    private func generateTextPreview(for url: URL) -> HoverPreviewData {
        guard let handle = try? FileHandle(forReadingFrom: url) else { return .unsupported }
        defer { try? handle.close() }

        // Only the head of the file: large logs must not be loaded to show a snippet.
        let data = handle.readData(ofLength: Self.textReadLimit)
        guard let (text, encoding) = Self.decode(data) else { return .unsupported }

        let allLines = text.components(separatedBy: .newlines)
        return .text(
            lines: Array(allLines.prefix(Self.previewLineLimit)),
            totalLines: allLines.count,
            encoding: encoding,
            fileSizeFormatted: formatFileSize(for: url),
            truncated: data.count == Self.textReadLimit
        )
    }

    /// Decodes text, rejecting binary data. Tolerates a read that ends mid UTF-8 character.
    static func decode(_ data: Data) -> (String, String)? {
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
        cache.removeAll()
    }
}
