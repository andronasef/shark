import AppKit
import ObjectiveC

/// Swizzles NSView drag destination handlers so dragging operations
/// reflect `.move` by default and dynamically show `.copy` (green + badge)
/// only when the Alt (Option) key is held down.
@MainActor
public enum DragOperationPatcher {
    private static var hasPatched = false

    public static func install() {
        guard !hasPatched else { return }
        hasPatched = true

        swizzle(
            cls: NSView.self,
            original: #selector(NSView.draggingEntered(_:)),
            swizzled: #selector(NSView.shark_draggingEntered(_:))
        )
        swizzle(
            cls: NSView.self,
            original: #selector(NSView.draggingUpdated(_:)),
            swizzled: #selector(NSView.shark_draggingUpdated(_:))
        )
    }

    private static func swizzle(cls: AnyClass, original: Selector, swizzled: Selector) {
        guard let originalMethod = class_getInstanceMethod(cls, original),
              let swizzledMethod = class_getInstanceMethod(cls, swizzled) else { return }
        method_exchangeImplementations(originalMethod, swizzledMethod)
    }
}

extension NSView {
    @objc func shark_draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        let op = self.shark_draggingEntered(sender)
        guard op != [] else { return [] }
        return NSEvent.modifierFlags.contains(.option) ? .copy : .move
    }

    @objc func shark_draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        let op = self.shark_draggingUpdated(sender)
        guard op != [] else { return [] }
        return NSEvent.modifierFlags.contains(.option) ? .copy : .move
    }
}
