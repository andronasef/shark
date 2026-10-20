import SwiftUI
import AppKit

public struct InlineRenameField: NSViewRepresentable {
    let initialName: String
    let onCommit: (String) -> Void
    let onCancel: () -> Void

    public init(
        initialName: String,
        onCommit: @escaping (String) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.initialName = initialName
        self.onCommit = onCommit
        self.onCancel = onCancel
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    public func makeNSView(context: Context) -> NSTextField {
        let textField = NSTextField()
        textField.stringValue = initialName
        textField.delegate = context.coordinator
        textField.isBordered = true
        textField.bezelStyle = .roundedBezel
        textField.drawsBackground = true
        textField.backgroundColor = .controlBackgroundColor
        textField.font = .systemFont(ofSize: 12)
        textField.focusRingType = .exterior
        textField.isEditable = true
        textField.isSelectable = true

        DispatchQueue.main.async {
            textField.window?.makeFirstResponder(textField)
            if let editor = textField.currentEditor() {
                let ext = (initialName as NSString).pathExtension
                let baseLength = ext.isEmpty ? initialName.count : (initialName.count - ext.count - 1)
                editor.selectedRange = NSRange(location: 0, length: max(0, baseLength))
            }
        }

        return textField
    }

    public func updateNSView(_ nsView: NSTextField, context: Context) {}

    @MainActor
    public final class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: InlineRenameField
        var didComplete = false

        init(_ parent: InlineRenameField) {
            self.parent = parent
        }

        public func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                commit(control.stringValue)
                return true
            } else if commandSelector == #selector(NSResponder.cancelOperation(_:)) {
                cancel()
                return true
            }
            return false
        }

        public func controlTextDidEndEditing(_ obj: Notification) {
            if let textField = obj.object as? NSTextField {
                commit(textField.stringValue)
            }
        }

        private func commit(_ text: String) {
            guard !didComplete else { return }
            didComplete = true
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty || trimmed == parent.initialName {
                parent.onCancel()
            } else {
                parent.onCommit(trimmed)
            }
        }

        private func cancel() {
            guard !didComplete else { return }
            didComplete = true
            parent.onCancel()
        }
    }
}
