import AppKit
import Foundation
import QuickLookThumbnailing

public enum HoverPreviewData: Sendable {
    case image(NSImage, dimensions: CGSize, fileSizeFormatted: String)
    case text(lines: [String], totalLines: Int, encoding: String, fileSizeFormatted: String)
    case unsupported
}

@MainActor
public final class HoverPreviewService {
    public static let shared = HoverPreviewService()

    private var cache: [URL: HoverPreviewData] = [:]
    private let textExtensions: Set<String> = [
        "txt", "md", "markdown", "swift", "py", "js", "ts", "json",
        "html", "css", "xml", "yaml", "yml", "sh", "zsh", "c", "cpp",
        "h", "hpp", "rs", "go", "rb", "csv", "log", "conf", "ini"
    ]
    private let imageExtensions: Set<String> = [
        "png", "jpg", "jpeg", "gif", "tiff", "tif", "bmp", "webp", "heic", "svg", "ico"
    ]

    private init() {}

    public func fetchPreview(for url: URL) async -> HoverPreviewData {
        let standardized = url.standardizedFileURL
        if let cached = cache[standardized] {
            return cached
        }

        let ext = standardized.pathExtension.lowercased()
        let result: HoverPreviewData

        if imageExtensions.contains(ext) {
            result = await generateImagePreview(for: standardized)
        } else if textExtensions.contains(ext) {
            result = await generateTextPreview(for: standardized)
        } else if ext == "pdf" {
            result = await generatePDFThumbnail(for: standardized)
        } else {
            result = .unsupported
        }

        cache[standardized] = result
        return result
    }

    private func formatFileSize(for url: URL) -> String {
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
              let size = attrs[.size] as? Int64 else {
            return ""
        }
        return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }

    private func generateImagePreview(for url: URL) async -> HoverPreviewData {
        let sizeStr = formatFileSize(for: url)

        // Try loading NSImage
        guard let image = NSImage(contentsOf: url) else {
            return .unsupported
        }

        let size = image.size
        return .image(image, dimensions: size, fileSizeFormatted: sizeStr)
    }

    private func generatePDFThumbnail(for url: URL) async -> HoverPreviewData {
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
                    continuation.resume(returning: .image(rep.nsImage, dimensions: rep.nsImage.size, fileSizeFormatted: sizeStr))
                } else {
                    continuation.resume(returning: .unsupported)
                }
            }
        }
    }

    private func generateTextPreview(for url: URL) async -> HoverPreviewData {
        let sizeStr = formatFileSize(for: url)

        guard let handle = try? FileHandle(forReadingFrom: url) else {
            return .unsupported
        }
        defer { try? handle.close() }

        // Read up to first 8KB to avoid large file memory overhead
        let data = handle.readData(ofLength: 8192)
        guard let text = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .ascii) else {
            return .unsupported
        }

        let allLines = text.components(separatedBy: .newlines)
        let previewLines = Array(allLines.prefix(14))
        let totalCount = allLines.count

        return .text(lines: previewLines, totalLines: totalCount, encoding: "UTF-8", fileSizeFormatted: sizeStr)
    }

    public func clearCache() {
        cache.removeAll()
    }
}
