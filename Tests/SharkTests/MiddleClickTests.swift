import AppKit
import SwiftUI
import XCTest
@testable import Shark

@MainActor
final class MiddleClickTests: XCTestCase {
    func testMiddleClickClosesOnlyTheTabUnderThePointerWithoutHover() throws {
        let workspace = WorkspaceState(initialURL: URL(fileURLWithPath: "/"))
        workspace.newTab()
        let secondID = workspace.activeTabID
        let window = makeWindow(rootView: TabStripView(workspace: workspace).frame(height: 28))
        defer { window.close() }

        NSApp.sendEvent(try mouseUp(in: window, at: NSPoint(x: 75, y: 50)))
        XCTAssertEqual(workspace.tabs.map(\.id), [secondID])
        XCTAssertEqual(workspace.activeTabID, secondID)
        XCTAssertEqual(workspace.closedTabs.count, 1)
    }

    func testOtherButtonsAndOtherWindowsDoNotInvokeAction() throws {
        var calls = 0
        let window = makeWindow(rootView: Color.clear.onMiddleClick { calls += 1 })
        let other = makeWindow(rootView: Color.clear)
        defer { window.close(); other.close() }

        NSApp.sendEvent(try mouseUp(in: other, at: NSPoint(x: 75, y: 50)))
        NSApp.sendEvent(try mouseUp(in: window, at: NSPoint(x: 350, y: 50)))
        NSApp.sendEvent(try mouseUp(in: window, at: NSPoint(x: 75, y: 50), button: .right))
        XCTAssertEqual(calls, 0)
        NSApp.sendEvent(try mouseUp(in: window, at: NSPoint(x: 75, y: 50)))
        XCTAssertEqual(calls, 1)
    }

    func testDetachedViewCannotHandleMiddleClicks() throws {
        var calls = 0
        let window = makeWindow(rootView: Color.clear.onMiddleClick { calls += 1 })
        defer { window.close() }
        let host = window.contentView
        window.contentView = NSView(frame: NSRect(x: 0, y: 0, width: 300, height: 100))
        try withExtendedLifetime(host) {
            NSApp.sendEvent(try mouseUp(in: window, at: NSPoint(x: 75, y: 50)))
        }
        XCTAssertEqual(calls, 0)
    }

    private func makeWindow<Content: View>(rootView: Content) -> NSWindow {
        _ = NSApplication.shared
        let host = NSHostingView(rootView: rootView)
        let window = NSWindow(contentRect: NSRect(x: 100, y: 100, width: 300, height: 100),
                              styleMask: [.borderless], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.contentView = host
        window.orderFront(nil)
        host.layoutSubtreeIfNeeded()
        return window
    }

    private func mouseUp(in window: NSWindow, at point: NSPoint, button: CGMouseButton = .center) throws -> NSEvent {
        let type: CGEventType = button == .right ? .rightMouseUp : .otherMouseUp
        let cgEvent = try XCTUnwrap(CGEvent(mouseEventSource: nil, mouseType: type,
                                          mouseCursorPosition: point, mouseButton: button))
        cgEvent.location = NSPoint(x: point.x, y: try XCTUnwrap(NSScreen.screens.first).frame.maxY - point.y)
        let event = try XCTUnwrap(NSEvent(cgEvent: cgEvent))
        event.setValue(window.windowNumber, forKey: "windowNumber")
        XCTAssertEqual(event.locationInWindow.x, point.x, accuracy: 1)
        XCTAssertEqual(event.locationInWindow.y, point.y, accuracy: 1)
        return event
    }
}
