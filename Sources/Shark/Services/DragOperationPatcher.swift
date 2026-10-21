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

/// Move by default and copy with ⌥, but never an operation the drag source doesn't offer
/// (Safari, Photos and Mail only allow copying); forcing one would reject or break the drop.
@MainActor
private func preferredOperation(original: NSDragOperation, sourceMask: NSDragOperation?) -> NSDragOperation {
    guard original != [] else { return [] }
    let wanted: NSDragOperation = NSEvent.modifierFlags.contains(.option) ? .copy : .move
    guard let mask = sourceMask else { return wanted }
    return mask.contains(wanted) ? wanted : original
}

extension NSView {
    @objc func shark_draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        preferredOperation(original: self.shark_draggingEntered(sender), sourceMask: sender.draggingSourceOperationMask)
    }

    @objc func shark_draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        preferredOperation(original: self.shark_draggingUpdated(sender), sourceMask: sender.draggingSourceOperationMask)
    }
}

extension NSObject {
    // Drag destinations are only driven on the main thread.
    // NSDragDestination is the NSDraggingInfo passed to drop targets, so it knows the source mask.
    @MainActor @objc func shark_setLastDragDestinationOperation(_ operation: UInt) {
        let mask = (self as? NSDraggingInfo)?.draggingSourceOperationMask
        let op = preferredOperation(original: NSDragOperation(rawValue: operation), sourceMask: mask)
        self.shark_setLastDragDestinationOperation(op.rawValue)
    }

    @MainActor @objc func shark_lastDragDestinationOperation() -> UInt {
        let mask = (self as? NSDraggingInfo)?.draggingSourceOperationMask
        return preferredOperation(original: NSDragOperation(rawValue: self.shark_lastDragDestinationOperation()), sourceMask: mask).rawValue
    }
}
