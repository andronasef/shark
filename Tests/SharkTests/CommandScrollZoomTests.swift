import AppKit
import SwiftUI
import XCTest
@testable import Shark

@MainActor
final class CommandScrollZoomTests: XCTestCase {
    func testCommandScrollResizesOnlyHoveredPaneOncePerEvent() throws {
        let first = NavigationState(initialURL: URL(fileURLWithPath: "/"))
        let second = NavigationState(initialURL: URL(fileURLWithPath: "/"))
        var firstCalls = 0
        var secondCalls = 0
        let window = makeWindow(rootView: HStack(spacing: 0) {
            ScrollView { Color.clear.frame(height: 1000) }
                .frame(width: 150)
                .onCommandScrollZoom {
                    firstCalls += 1
                    first.adjustZoom(delta: $0)
                }
            ScrollView { Color.clear.frame(height: 1000) }
                .frame(width: 150)
                .onCommandScrollZoom {
                    secondCalls += 1
                    second.adjustZoom(delta: $0)
                }
        })
        defer { window.close() }

        // Deliver through AppKit, without relying on a new overlay hit test.
        NSApp.sendEvent(try scroll(in: window, at: NSPoint(x: 75, y: 150), delta: 3))
        XCTAssertGreaterThan(first.iconSize, 80)
        XCTAssertEqual(firstCalls, 1)
        XCTAssertEqual(second.iconSize, 80)
        XCTAssertEqual(secondCalls, 0)

        NSApp.sendEvent(try scroll(in: window, at: NSPoint(x: 75, y: 150), delta: -3))
        XCTAssertEqual(first.iconSize, 80)
        XCTAssertEqual(firstCalls, 2)

        NSApp.sendEvent(try scroll(in: window, at: NSPoint(x: 225, y: 150), delta: -3))
        XCTAssertLessThan(second.iconSize, 80)
        XCTAssertEqual(secondCalls, 1)
        XCTAssertEqual(firstCalls, 2)
    }

    func testUnmodifiedOutsideAndOtherWindowScrollDoNotZoom() throws {
        var calls = 0
        let window = makeWindow(rootView: Color.clear.onCommandScrollZoom { _ in calls += 1 })
        let otherWindow = makeWindow(rootView: Color.clear)
        defer {
            window.close()
            otherWindow.close()
        }

        NSApp.sendEvent(try scroll(in: window, modifiers: []))
        NSApp.sendEvent(try scroll(in: window, at: NSPoint(x: 350, y: 150)))
        NSApp.sendEvent(try scroll(in: otherWindow))
        NSApp.sendEvent(try scroll(in: window, delta: 0))
        XCTAssertEqual(calls, 0)

        NSApp.sendEvent(try scroll(in: window))
        XCTAssertEqual(calls, 1)
    }

    func testRemovingZoomViewStopsHandlingEvents() throws {
        var calls = 0
        let window = makeWindow(rootView: Color.clear.onCommandScrollZoom { _ in calls += 1 })
        defer { window.close() }
        NSApp.sendEvent(try scroll(in: window))
        XCTAssertEqual(calls, 1)

        // Retain the old host to verify detachment removes its monitor even
        // before the representable is deallocated.
        let oldHost = window.contentView
        window.contentView = NSView(frame: NSRect(x: 0, y: 0, width: 300, height: 300))
        try withExtendedLifetime(oldHost) {
            NSApp.sendEvent(try scroll(in: window))
        }
        XCTAssertEqual(calls, 1)
    }

    private func makeWindow<Content: View>(rootView: Content) -> NSWindow {
        _ = NSApplication.shared
        let host = NSHostingView(rootView: rootView)
        let window = NSWindow(contentRect: NSRect(x: 100, y: 100, width: 300, height: 300),
                              styleMask: [.borderless], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.contentView = host
        window.orderFront(nil)
        host.layoutSubtreeIfNeeded()
        return window
    }

    private func scroll(in window: NSWindow, at point: NSPoint = NSPoint(x: 150, y: 150),
                        delta: Int32 = 3, modifiers: NSEvent.ModifierFlags = .command) throws -> NSEvent {
        let cgEvent = try XCTUnwrap(CGEvent(scrollWheelEvent2Source: nil, units: .line,
                                           wheelCount: 1, wheel1: delta, wheel2: 0, wheel3: 0))
        cgEvent.flags = CGEventFlags(rawValue: UInt64(modifiers.rawValue))
        cgEvent.location = NSPoint(x: point.x,
                                  y: try XCTUnwrap(NSScreen.screens.first).frame.maxY - point.y)
        let event = try XCTUnwrap(NSEvent(cgEvent: cgEvent))
        // CGEvent-backed synthetic events have no window. Associate the window
        // after conversion; the event's existing location becomes window-local.
        event.setValue(window.windowNumber, forKey: "windowNumber")
        XCTAssertEqual(event.locationInWindow.x, point.x, accuracy: 1)
        XCTAssertEqual(event.locationInWindow.y, point.y, accuracy: 1)
        return event
    }
}
