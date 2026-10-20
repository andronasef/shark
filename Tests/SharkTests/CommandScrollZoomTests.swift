import AppKit
import SwiftUI
import XCTest
@testable import Shark

@MainActor
final class CommandScrollZoomTests: XCTestCase {
    func testCommandScrollReachesZoomHandler() throws {
        _ = NSApplication.shared
        var deltas: [CGFloat] = []
        let host = NSHostingView(rootView:
            ScrollView {
                Color.clear.frame(width: 300, height: 1000)
            }
            .onCommandScrollZoom { deltas.append($0) }
        )
        let window = NSWindow(contentRect: NSRect(x: 100, y: 100, width: 300, height: 300),
                              styleMask: [.borderless], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.contentView = host
        window.orderFront(nil)
        defer { window.close() }
        host.layoutSubtreeIfNeeded()

        // Scroll events must be caught even when AppKit routes them directly to
        // the scroll view rather than hit-testing the SwiftUI overlay again.
        let cgEvent = try XCTUnwrap(CGEvent(scrollWheelEvent2Source: nil, units: .line,
                                           wheelCount: 1, wheel1: 3, wheel2: 0, wheel3: 0))
        cgEvent.flags = .maskCommand
        cgEvent.location = NSPoint(x: 150,
                                  y: try XCTUnwrap(NSScreen.screens.first).frame.maxY - 150)
        let scroll = try XCTUnwrap(NSEvent(cgEvent: cgEvent))
        scroll.setValue(window.windowNumber, forKey: "windowNumber")
        XCTAssertEqual(scroll.locationInWindow.x, 150, accuracy: 1)
        XCTAssertEqual(scroll.locationInWindow.y, 150, accuracy: 1)
        NSApp.sendEvent(scroll)
        XCTAssertEqual(deltas.count, 1)
        XCTAssertGreaterThan(deltas.first ?? 0, 0)
    }
}
