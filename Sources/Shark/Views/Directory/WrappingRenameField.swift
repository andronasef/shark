import SwiftUI
import AppKit

/// Pure rules for the wrapping rename editor.
enum RenameEditorMetrics {
    static let maxLines = 5
    static let verticalInset: CGFloat = 2

    /// UTF-16 range of the name without its extension, as `NSTextView` selection ranges require.
    static func baseNameRange(of name: String) -> NSRange {
        let ns = name as NSString
        let ext = ns.pathExtension
        let length = ext.isEmpty ? ns.length : ns.length - ext.utf16.count - 1
        return NSRange(location: 0, length: max(0, length))
    }

    /// Editor height for the wrapped text: between one and `maxLines` lines, plus the vertical insets.
    static func editorHeight(contentHeight: CGFloat, lineHeight: CGFloat) -> CGFloat {
        let lines = min(max(contentHeight, lineHeight), lineHeight * CGFloat(maxLines))
        return lines + 2 * verticalInset
    }

    /// The trimmed name with line breaks turned into spaces, or nil (cancel) when it is empty or unchanged.
    static func committedName(from text: String, initialName: String) -> String? {
        let name = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .split(whereSeparator: \.isNewline)
            .joined(separator: " ")
        return name.isEmpty || name == initialName ? nil : name
    }
}

/// Icon-view rename editor: shows the whole name wrapped and centered, growing up to `maxLines`.
struct WrappingRenameField: View {
    let initialName: String
    let width: CGFloat
    let onCommit: (String) -> Void
    let onCancel: () -> Void

    @State private var height: CGFloat = 20

    var body: some View {
        Representable(
            initialName: initialName,
            width: width,
            onCommit: onCommit,
            onCancel: onCancel,
            onHeightChange: { height = $0 }
        )
        .frame(width: width, height: height)
    }

    private struct Representable: NSViewRepresentable {
        let initialName: String
        let width: CGFloat
        let onCommit: (String) -> Void
        let onCancel: () -> Void
        let onHeightChange: (CGFloat) -> Void

        func makeCoordinator() -> Coordinator { Coordinator(self) }

        func makeNSView(context: Context) -> NSScrollView {
            let scroll = NSScrollView(frame: NSRect(x: 0, y: 0, width: width, height: 20))
            scroll.hasVerticalScroller = false
            scroll.hasHorizontalScroller = false
            scroll.borderType = .noBorder
            scroll.drawsBackground = false
            scroll.wantsLayer = true
            scroll.layer?.cornerRadius = 4
            scroll.layer?.masksToBounds = true
            scroll.layer?.borderWidth = 1.5
            scroll.layer?.borderColor = NSColor.controlAccentColor.cgColor

            let textView = NSTextView(usingTextLayoutManager: false)
            textView.frame = scroll.bounds
            textView.minSize = NSSize(width: 0, height: 0)
            textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
            textView.isVerticallyResizable = true
            textView.isHorizontallyResizable = false
            textView.autoresizingMask = [.width]
            textView.textContainer?.widthTracksTextView = true
            textView.textContainer?.containerSize = NSSize(width: width, height: CGFloat.greatestFiniteMagnitude)
            textView.textContainerInset = NSSize(width: 0, height: RenameEditorMetrics.verticalInset)
            textView.drawsBackground = true
            textView.backgroundColor = .controlBackgroundColor
            textView.font = .systemFont(ofSize: 12)
            textView.alignment = .center
            textView.baseWritingDirection = .natural
            textView.isRichText = false
            textView.allowsUndo = true
            // The saved name must be exactly what was typed.
            textView.isAutomaticQuoteSubstitutionEnabled = false
            textView.isAutomaticDashSubstitutionEnabled = false
            textView.isAutomaticTextReplacementEnabled = false
            textView.isAutomaticSpellingCorrectionEnabled = false
            textView.isAutomaticLinkDetectionEnabled = false
            textView.isAutomaticDataDetectionEnabled = false
            textView.isContinuousSpellCheckingEnabled = false
            textView.isGrammarCheckingEnabled = false
            textView.string = initialName
            textView.delegate = context.coordinator
            scroll.documentView = textView

            // The wrapped height depends on the width SwiftUI finally gives the editor.
            scroll.postsFrameChangedNotifications = true
            NotificationCenter.default.addObserver(
                context.coordinator, selector: #selector(Coordinator.frameChanged(_:)),
                name: NSView.frameDidChangeNotification, object: scroll)

            let coordinator = context.coordinator
            let name = initialName
            DispatchQueue.main.async { [weak textView] in
                guard let textView else { return }
                textView.window?.makeFirstResponder(textView)
                textView.setSelectedRange(RenameEditorMetrics.baseNameRange(of: name))
                coordinator.reportHeight(of: textView)
            }
            return scroll
        }

        func updateNSView(_ nsView: NSScrollView, context: Context) {}

        @MainActor
        final class Coordinator: NSObject, NSTextViewDelegate {
            let parent: Representable
            private var didComplete = false
            private var lastHeight: CGFloat = 0

            init(_ parent: Representable) { self.parent = parent }

            deinit { NotificationCenter.default.removeObserver(self) }

            @objc func frameChanged(_ note: Notification) {
                guard let scroll = note.object as? NSScrollView, let textView = scroll.documentView as? NSTextView else { return }
                DispatchQueue.main.async { [weak self, weak textView] in
                    guard let textView else { return }
                    self?.reportHeight(of: textView)
                }
            }

            func reportHeight(of textView: NSTextView) {
                guard let layout = textView.layoutManager, let container = textView.textContainer else { return }
                layout.ensureLayout(for: container)
                let lineHeight = layout.defaultLineHeight(for: textView.font ?? .systemFont(ofSize: 12))
                let height = RenameEditorMetrics.editorHeight(
                    contentHeight: layout.usedRect(for: container).height, lineHeight: lineHeight)
                guard height != lastHeight else { return }
                lastHeight = height
                parent.onHeightChange(height)
            }

            func textDidChange(_ notification: Notification) {
                if let textView = notification.object as? NSTextView { reportHeight(of: textView) }
            }

            func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
                switch commandSelector {
                case #selector(NSResponder.insertNewline(_:)):
                    commit(textView.string)
                case #selector(NSResponder.cancelOperation(_:)):
                    cancel()
                case #selector(NSResponder.insertNewlineIgnoringFieldEditor(_:)),
                     #selector(NSResponder.insertLineBreak(_:)),
                     #selector(NSResponder.insertTab(_:)),
                     #selector(NSResponder.insertBacktab(_:)):
                    break
                default:
                    return false
                }
                return true
            }

            func textDidEndEditing(_ notification: Notification) {
                if let textView = notification.object as? NSTextView { commit(textView.string) }
            }

            private func commit(_ text: String) {
                guard !didComplete else { return }
                didComplete = true
                if let name = RenameEditorMetrics.committedName(from: text, initialName: parent.initialName) {
                    parent.onCommit(name)
                } else {
                    parent.onCancel()
                }
            }

            private func cancel() {
                guard !didComplete else { return }
                didComplete = true
                parent.onCancel()
            }
        }
    }
}
