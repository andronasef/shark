import AppKit
import SwiftUI
import SwiftTerm
import XCTest
@testable import Shark

@MainActor
final class TerminalKeyboardTests: XCTestCase {
    func testDirectoryMonitorLeavesTerminalTypingAlone() throws {
        _ = NSApplication.shared
        var delivered = false
        let observer = try XCTUnwrap(NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            delivered = true
            return event
        })
        defer { NSEvent.removeMonitor(observer) }
        let workspace = WorkspaceState(initialURL: URL(fileURLWithPath: "/"))
        let host = NSHostingView(rootView: DirectoryView(navigationState: workspace.activeNavigationState).environment(workspace))
        let window = KeyboardTestWindow(contentRect: NSRect(x: 0, y: 0, width: 600, height: 400),
                                        styleMask: [.borderless], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        let container = NSView(frame: NSRect(x: 0, y: 0, width: 600, height: 400))
        host.frame = container.bounds
        container.addSubview(host)
        window.contentView = container
        window.makeKeyAndOrderFront(nil)
        host.layoutSubtreeIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.1))
        let terminal = LocalProcessTerminalView(frame: NSRect(x: 0, y: 0, width: 400, height: 100))
        container.addSubview(terminal)
        XCTAssertTrue(window.makeFirstResponder(terminal))
        defer { window.close() }
        let event = try XCTUnwrap(NSEvent.keyEvent(with: .keyDown, location: .zero, modifierFlags: [],
            timestamp: 0, windowNumber: window.windowNumber, context: nil,
            characters: "x", charactersIgnoringModifiers: "x", isARepeat: false, keyCode: 7))
        NSApp.sendEvent(event)
        XCTAssertTrue(delivered, "Directory type-to-select must not swallow terminal keystrokes")
    }
}

private final class KeyboardTestWindow: NSWindow {
    override var canBecomeKey: Bool { true }
}

