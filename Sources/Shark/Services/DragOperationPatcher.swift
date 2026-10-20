import AppKit
import ObjectiveC

/// Intercepts drag destination and window/view drag operations so that
/// dragging items defaults to `.move` (clean mouse pointer without badges)
/// and dynamically switches to `.copy` (green + badge) only when Alt (Option) is held down.
@MainActor
public enum DragOperationPatcher {
    private static var hasPatched = false

    public static func install() {
        guard !hasPatched else { return }
        hasPatched = true

        // 1. Swizzle NSView drag methods
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

        // 2. Swizzle NSDragDestination internal methods which control the OS drag cursor badge
        if let dragDestClass = NSClassFromString("NSDragDestination") {
            let setOpSel = Selector(("_setLastDragDestinationOperation:"))
            let sharkSetOpSel = #selector(NSObject.shark_setLastDragDestinationOperation(_:))
            swizzle(cls: dragDestClass, original: setOpSel, swizzled: sharkSetOpSel)

            let lastOpSel = Selector(("_lastDragDestinationOperation"))
            let sharkLastOpSel = #selector(NSObject.shark_lastDragDestinationOperation)
            swizzle(cls: dragDestClass, original: lastOpSel, swizzled: sharkLastOpSel)
        }
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

extension NSObject {
    @objc func shark_setLastDragDestinationOperation(_ operation: UInt) {
        var op = operation
        if op != 0 {
            let isAlt = NSEvent.modifierFlags.contains(.option)
            op = isAlt ? NSDragOperation.copy.rawValue : NSDragOperation.move.rawValue
        }
        self.shark_setLastDragDestinationOperation(op)
    }

    @objc func shark_lastDragDestinationOperation() -> UInt {
        let orig = self.shark_lastDragDestinationOperation()
        guard orig != 0 else { return 0 }
        let isAlt = NSEvent.modifierFlags.contains(.option)
        return isAlt ? NSDragOperation.copy.rawValue : NSDragOperation.move.rawValue
    }
}
