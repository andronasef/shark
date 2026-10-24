import AppKit
import UniformTypeIdentifiers

enum FileContextSelection {
    static func items(clicked: FileItem, selected: Set<URL>, ordered: [FileItem]) -> [FileItem] {
        selected.contains(clicked.url) ? ordered.filter { selected.contains($0.url) } : [clicked]
    }
}

@MainActor
enum OpenWithService {
    static func commonApplications(_ lists: [[URL]]) -> [URL] {
        guard let first = lists.first else { return [] }
        return Array(Set(first)).filter { app in lists.dropFirst().allSatisfy { $0.contains(app) } }
            .sorted { $0.deletingPathExtension().lastPathComponent.localizedStandardCompare($1.deletingPathExtension().lastPathComponent) == .orderedAscending }
    }

    /// Open With is offered only when every target is a file.
    static func canOpenWith(_ items: [FileItem]) -> Bool { !items.isEmpty && items.allSatisfy { !$0.isDirectory } }

    /// One Launch Services query per distinct content type, cached, so building a menu for a large
    /// selection never touches each file. A type's handlers rarely change while Shark runs.
    /// ponytail: process-lifetime cache; clear it on NSWorkspace app install notifications if stale lists show up.
    private static var applicationsByType: [String: [URL]] = [:]

    static func applications(for items: [FileItem]) -> [URL] {
        guard canOpenWith(items) else { return [] }
        let types = Set(items.map { contentTypeKey(for: $0.url) })
        return commonApplications(types.map { key in
            if let cached = applicationsByType[key] { return cached }
            let apps = UTType(key).map { NSWorkspace.shared.urlsForApplications(toOpen: $0) } ?? []
            applicationsByType[key] = apps
            return apps
        })
    }

    /// Derived from the file name (no disk read); unknown extensions fall back to generic data.
    nonisolated static func contentTypeKey(for url: URL) -> String {
        (UTType(filenameExtension: url.pathExtension) ?? .data).identifier
    }

    static func open(_ urls: [URL], with app: URL, onError: @escaping @MainActor @Sendable (String) -> Void) {
        NSWorkspace.shared.open(urls, withApplicationAt: app, configuration: .init()) { _, error in
            if let error { DispatchQueue.main.async { onError(error.localizedDescription) } }
        }
    }

    static func chooseApplication(for urls: [URL], onError: @escaping @MainActor @Sendable (String) -> Void) {
        let picker = NSOpenPanel()
        picker.title = L10n.text("Choose an Application")
        picker.directoryURL = URL(fileURLWithPath: "/Applications")
        picker.canChooseFiles = true
        picker.canChooseDirectories = false
        picker.allowedContentTypes = [.applicationBundle]
        picker.begin { response in
            guard response == .OK, let app = picker.url else { return }
            open(urls, with: app, onError: onError)
        }
    }

    static func share(_ urls: [URL]) {
        guard let view = NSApp.keyWindow?.contentView else { return }
        let picker = NSSharingServicePicker(items: urls)
        picker.show(relativeTo: CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 1, height: 1), of: view, preferredEdge: .minY)
    }
}
