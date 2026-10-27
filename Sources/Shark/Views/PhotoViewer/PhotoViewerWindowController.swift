import AppKit
import SwiftUI
import UniformTypeIdentifiers

@MainActor
final class PhotoViewerWindowController: NSWindowController, NSWindowDelegate {
    private static var viewers: [PhotoViewerWindowController] = []
    let state: PhotoViewerState

    static func supports(url: URL) -> Bool {
        UTType(filenameExtension: url.pathExtension)?.conforms(to: .image) == true
    }
    static func snapshot(items: [FileItem], selectedURLs: Set<URL>? = nil) -> [URL] {
        items.filter { !$0.isDirectory && supports(url: $0.url) && (selectedURLs?.contains($0.url) ?? true) }.map(\.url)
    }
    @discardableResult
    static func open(items: [FileItem], initialURL: URL, selectedURLs: Set<URL>? = nil) -> PhotoViewerWindowController? {
        let urls = snapshot(items: items, selectedURLs: selectedURLs)
        guard !urls.isEmpty else { return nil }
        let controller = PhotoViewerWindowController(urls: urls, initialURL: initialURL)
        viewers.append(controller)
        controller.showWindow(nil)
        controller.window?.makeKeyAndOrderFront(nil)
        return controller
    }
    init(urls: [URL], initialURL: URL) {
        state = PhotoViewerState(urls: urls, initialURL: initialURL)
        let window = PhotoWindow(contentRect: NSRect(x: 0, y: 0, width: 1000, height: 760),
            styleMask: [.titled, .closable, .miniaturizable, .resizable], backing: .buffered, defer: false)
        super.init(window: window)
        window.title = L10n.text("Shark Photo Viewer")
        window.minSize = NSSize(width: 600, height: 440)
        window.collectionBehavior.insert(.fullScreenPrimary)
        window.appearance = SharkSettings.shared.selectedAppearance.nsAppearance
        window.contentView = NSHostingView(rootView: PhotoViewerView(state: state, toggleFullScreen: { [weak window] in window?.toggleFullScreen(nil) })
            .environment(\.locale, AppLocalization.locale)
            .environment(\.layoutDirection, AppLocalization.layoutDirection)
            .preferredColorScheme(SharkSettings.shared.selectedAppearance.colorScheme))
        window.delegate = self
        window.center()
        state.load()
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    func windowDidBecomeKey(_ notification: Notification) { state.setActive(true) }
    func windowDidResignKey(_ notification: Notification) { state.setActive(false) }
    func windowDidMiniaturize(_ notification: Notification) { state.setActive(false) }
    func windowDidDeminiaturize(_ notification: Notification) { state.setActive(true) }
    func windowWillClose(_ notification: Notification) {
        state.stop()
        Self.viewers.removeAll { $0 === self }
    }
}

private final class PhotoWindow: NSWindow {
    override func cancelOperation(_ sender: Any?) {
        if styleMask.contains(.fullScreen) { toggleFullScreen(sender) } else { close() }
    }
}
