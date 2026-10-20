import AppKit
import SwiftUI
import XCTest
@testable import Shark

@MainActor
final class SplitPaneFocusTests: XCTestCase {
    func testClickingActivePaneReturnsKeyboardFocusFromSidebar() throws {
        let workspace = WorkspaceState(initialURL: URL(fileURLWithPath: "/"))
        workspace.sidebarHasKeyboardFocus = true
        let window = makeWindow(rootView: DualPaneContainerView(tab: workspace.activeTab).environment(workspace))
        defer { window.close() }
        NSApp.sendEvent(try middleDown(in: window, at: NSPoint(x: 100, y: 285)))
        XCTAssertFalse(workspace.sidebarHasKeyboardFocus)
    }
    func testInteractingWithRightPaneRoutesParentNavigationToIt() throws {
        let workspace = WorkspaceState(initialURL: URL(fileURLWithPath: "/Users/left"))
        let tab = workspace.activeTab
        tab.isSplit = true
        tab.secondaryPane.navigateTo(URL(fileURLWithPath: "/Users/right"))
        let window = makeWindow(rootView: DualPaneContainerView(tab: tab).environment(workspace))
        defer { window.close() }

        // A pane header is outside the DirectoryView's old tap recognizer.
        NSApp.sendEvent(try middleDown(in: window, at: NSPoint(x: 440, y: 285)))
        XCTAssertEqual(tab.activePane, .secondary)
        workspace.activeNavigationState.goUp()
        XCTAssertEqual(tab.secondaryPane.currentURL.path, "/Users")
        XCTAssertEqual(tab.primaryPane.currentURL.path, "/Users/left")
    }

    func testSwitchingBackToLeftPaneAndOtherWindows() throws {
        let workspace = WorkspaceState(initialURL: URL(fileURLWithPath: "/"))
        let tab = workspace.activeTab
        tab.isSplit = true
        tab.activePane = .secondary
        let window = makeWindow(rootView: DualPaneContainerView(tab: tab).environment(workspace))
        let other = makeWindow(rootView: Color.clear)
        defer { window.close(); other.close() }

        NSApp.sendEvent(try middleDown(in: other, at: NSPoint(x: 100, y: 285)))
        XCTAssertEqual(tab.activePane, .secondary)
        NSApp.sendEvent(try middleDown(in: window, at: NSPoint(x: 100, y: 285)))
        XCTAssertEqual(tab.activePane, .primary)
    }

    func testParentFolderShortcutAffectsOnlyActiveRightPane() throws {
        let workspace = WorkspaceState(initialURL: URL(fileURLWithPath: "/Users/left"))
        let tab = workspace.activeTab
        tab.isSplit = true
        tab.secondaryPane.navigateTo(URL(fileURLWithPath: "/Users/right"))
        tab.activePane = .secondary
        let window = makeWindow(rootView: DualPaneContainerView(tab: tab).environment(workspace))
        defer { window.close() }
        let event = try XCTUnwrap(NSEvent.keyEvent(
            with: .keyDown, location: .zero, modifierFlags: [.option, .function],
            timestamp: 0, windowNumber: window.windowNumber, context: nil,
            characters: "\u{F700}", charactersIgnoringModifiers: "\u{F700}", isARepeat: false, keyCode: 126
        ))
        XCTAssertTrue(window.performKeyEquivalent(with: event))
        XCTAssertEqual(tab.primaryPane.currentURL.path, "/Users/left")
        XCTAssertEqual(tab.secondaryPane.currentURL.path, "/Users")
    }

    private func makeWindow<Content: View>(rootView: Content) -> NSWindow {
        _ = NSApplication.shared
        let window = NSWindow(contentRect: NSRect(x: 100, y: 100, width: 600, height: 300),
                              styleMask: [.borderless], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        let host = NSHostingView(rootView: rootView)
        window.contentView = host
        window.orderFront(nil)
        host.layoutSubtreeIfNeeded()
        return window
    }

    private func middleDown(in window: NSWindow, at point: NSPoint) throws -> NSEvent {
        let cgEvent = try XCTUnwrap(CGEvent(mouseEventSource: nil, mouseType: .otherMouseDown,
                                          mouseCursorPosition: point, mouseButton: .center))
        cgEvent.location = NSPoint(x: point.x, y: try XCTUnwrap(NSScreen.screens.first).frame.maxY - point.y)
        let event = try XCTUnwrap(NSEvent(cgEvent: cgEvent))
        event.setValue(window.windowNumber, forKey: "windowNumber")
        XCTAssertEqual(event.locationInWindow.x, point.x, accuracy: 1)
        XCTAssertEqual(event.locationInWindow.y, point.y, accuracy: 1)
        return event
    }
}
