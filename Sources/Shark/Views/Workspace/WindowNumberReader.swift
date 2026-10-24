import AppKit
import SwiftUI

/// Scopes local event monitors to the window that actually owns a view.
struct WindowNumberReader: NSViewRepresentable {
    let onChange: (Int?) -> Void
    func makeNSView(context: Context) -> ReaderView {
        let view = ReaderView()
        view.onChange = onChange
        return view
    }
    func updateNSView(_ view: ReaderView, context: Context) { view.onChange = onChange }

    final class ReaderView: NSView {
        var onChange: ((Int?) -> Void)?
        override func hitTest(_ point: NSPoint) -> NSView? { nil }
        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            let number = window?.windowNumber
            DispatchQueue.main.async { [weak self] in self?.onChange?(number) }
        }
    }
}
