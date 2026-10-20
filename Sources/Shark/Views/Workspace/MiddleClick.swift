import SwiftUI
import AppKit

@MainActor
public enum MiddleClick {
    public static var target: (id: UUID, action: () -> Void)?
    private static var monitor: Any?

    public static func install() {
        guard monitor == nil else { return }
        monitor = NSEvent.addLocalMonitorForEvents(matching: .otherMouseUp) { event in
            if event.buttonNumber == 2, let t = MiddleClick.target {
                t.action()
                return nil
            }
            return event
        }
    }
}

public struct MiddleClickModifier: ViewModifier {
    let action: () -> Void
    @State private var id = UUID()

    public func body(content: Content) -> some View {
        content
            .onHover { isHovered in
                if isHovered {
                    MiddleClick.target = (id, action)
                } else if MiddleClick.target?.id == id {
                    MiddleClick.target = nil
                }
            }
    }
}

public extension View {
    func onMiddleClick(_ action: @escaping () -> Void) -> some View {
        modifier(MiddleClickModifier(action: action))
    }
}
