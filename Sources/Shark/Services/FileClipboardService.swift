import Foundation
import AppKit
import Observation

public enum ClipboardMode: Sendable, Codable {
    case cut
    case copy
}

@Observable
@MainActor
public final class FileClipboardService {
    public static let shared = FileClipboardService()

    private static let cutMarkerType = NSPasteboard.PasteboardType("org.shark.clipboard.cut")

    public private(set) var items: Set<URL> = []
    public private(set) var mode: ClipboardMode = .copy

    public init() {}

    public func cut(_ urls: [URL]) {
        let normalized = urls.map { $0.standardizedFileURL }
        self.items = Set(normalized)
        self.mode = .cut
        syncToSystemPasteboard(urls: normalized, isCut: true)
    }

    public func copy(_ urls: [URL]) {
        let normalized = urls.map { $0.standardizedFileURL }
        self.items = Set(normalized)
        self.mode = .copy
        syncToSystemPasteboard(urls: normalized, isCut: false)
    }

    public func isCut(_ url: URL) -> Bool {
        guard mode == .cut else { return false }
        return items.contains(url.standardizedFileURL)
    }

    public func clear() {
        items.removeAll()
        mode = .copy
        NSPasteboard.general.clearContents()
    }

    public var hasItemsToPaste: Bool {
        if !items.isEmpty { return true }
        return readSystemPasteboardURLs() != nil
    }

    /// Reads URLs from either internal state or system pasteboard
    public func getPasteableURLs() -> (urls: [URL], mode: ClipboardMode)? {
        if !items.isEmpty {
            return (Array(items), mode)
        }
        if let systemURLs = readSystemPasteboardURLs() {
            let isCut = NSPasteboard.general.types?.contains(Self.cutMarkerType) == true
            return (systemURLs, isCut ? .cut : .copy)
        }
        return nil
    }

    private func syncToSystemPasteboard(urls: [URL], isCut: Bool) {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.writeObjects(urls as [NSURL])
        if isCut {
            pb.setData(Data([1]), forType: Self.cutMarkerType)
        }
    }

    private func readSystemPasteboardURLs() -> [URL]? {
        let pb = NSPasteboard.general
        guard let classes = [NSURL.self] as? [AnyClass],
              let urls = pb.readObjects(forClasses: classes, options: nil) as? [URL],
              !urls.isEmpty else {
            return nil
        }
        return urls
    }
}
