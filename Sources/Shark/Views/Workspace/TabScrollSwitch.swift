import SwiftUI
import AppKit

/// Turns scroll-wheel/trackpad movement into whole tab steps.
struct ScrollStepAccumulator {
    /// Points of trackpad travel per tab. One wheel notch counts as one step.
    static let pointsPerStep: CGFloat = 30
    private var remainder: CGFloat = 0

    /// Returns tabs to move: positive for next, negative for previous.
    mutating func add(delta: CGFloat, precise: Bool) -> Int {
        // Scrolling down (negative delta) moves to the next tab, like a browser's tab strip.
        remainder -= precise ? delta : delta * Self.pointsPerStep
        let steps = Int(remainder / Self.pointsPerStep)
        remainder -= CGFloat(steps) * Self.pointsPerStep
        return steps
    }

    mutating func reset() { remainder = 0 }
}

/// Scrolling the wheel over the tab strip cycles through tabs.
struct TabScrollSwitchModifier: ViewModifier {
    let onStep: (Int) -> Void

    func body(content: Content) -> some View {
        content.overlay(TabScrollRegion(onStep: onStep))
    }
}

private struct TabScrollRegion: NSViewRepresentable {
    let onStep: (Int) -> Void

    func makeNSView(context: Context) -> TabScrollNSView {
        let view = TabScrollNSView()
        view.onStep = onStep
        return view
    }

    func updateNSView(_ view: TabScrollNSView, context: Context) {
        view.onStep = onStep
    }

    static func dismantleNSView(_ view: TabScrollNSView, coordinator: ()) {
        view.stopMonitoring()
    }
}

private final class TabScrollNSView: NSView {
    var onStep: ((Int) -> Void)?
    private var monitor: Any?
    private var accumulator = ScrollStepAccumulator()

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        stopMonitoring()
        guard window != nil else { return }
        // A monitor, because the strip's own ScrollView would otherwise take the wheel event.
        monitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { [weak self] event in
            guard let self, MouseSetting.tabStripScroll.isEnabled,
                  event.window === self.window,
                  !self.isHiddenOrHasHiddenAncestor,
                  self.bounds.intersection(self.visibleRect).contains(self.convert(event.locationInWindow, from: nil))
            else { return event }
            // ⌘-scroll is icon zoom and must keep working everywhere.
            guard !event.modifierFlags.contains(.command) else { return event }
            // Inertia after a trackpad flick would otherwise skip through every tab.
            guard event.momentumPhase.isEmpty else { return nil }
            if event.phase == .began { self.accumulator.reset() }
            let delta = abs(event.scrollingDeltaY) >= abs(event.scrollingDeltaX) ? event.scrollingDeltaY : event.scrollingDeltaX
            let steps = self.accumulator.add(delta: delta, precise: event.hasPreciseScrollingDeltas)
            if steps != 0 { self.onStep?(steps) }
            return nil
        }
    }

    func stopMonitoring() {
        if let monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
    }

    override func hitTest(_ point: NSPoint) -> NSView? { nil }
}

extension View {
    func onTabScroll(_ onStep: @escaping (Int) -> Void) -> some View {
        modifier(TabScrollSwitchModifier(onStep: onStep))
    }
}
