import SwiftUI
import AppKit

public struct CommandScrollZoomModifier: ViewModifier {
    let onZoom: (CGFloat) -> Void
    @State private var isHovered: Bool = false
    @State private var monitor: Any? = nil

    public init(onZoom: @escaping (CGFloat) -> Void) {
        self.onZoom = onZoom
    }

    public func body(content: Content) -> some View {
        content
            .onHover { hovered in
                isHovered = hovered
                if hovered {
                    startMonitoring()
                } else {
                    stopMonitoring()
                }
            }
            .onDisappear {
                stopMonitoring()
            }
    }

    private func startMonitoring() {
        guard monitor == nil else { return }
        monitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { [self] event in
            // Check if Command key is held
            if event.modifierFlags.contains(.command) && isHovered {
                let delta = event.scrollingDeltaY
                if abs(delta) > 0.1 {
                    onZoom(delta)
                    // Intercept so the scroll view does not scroll vertically while zooming
                    return nil
                }
            }
            return event
        }
    }

    private func stopMonitoring() {
        if let existing = monitor {
            NSEvent.removeMonitor(existing)
            monitor = nil
        }
    }
}

public extension View {
    func onCommandScrollZoom(perform action: @escaping (CGFloat) -> Void) -> some View {
        modifier(CommandScrollZoomModifier(onZoom: action))
    }
}
