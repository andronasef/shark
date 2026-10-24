import AppKit
import SwiftUI
import SwiftTerm
import XCTest
@testable import Shark

@MainActor
final class TerminalKeyboardTests: XCTestCase {
    func testTerminalOwnershipAndFontShortcuts() throws {
        _ = NSApplication.shared
        let session = PTYSession(preferences: UserDefaults(suiteName: "TerminalKeyboard." + UUID().uuidString)!)
        let terminal = session.makeTerminalView()
        let window = KeyboardTestWindow(contentRect: NSRect(x: 0, y: 0, width: 400, height: 200),
                                        styleMask: [.borderless], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.contentView = terminal
        XCTAssertTrue(window.makeFirstResponder(terminal))
        XCTAssertTrue(TerminalKeyboardOwnership.ownsFirstResponder(in: window))
        TerminalKeyboardOwnership.shared.refresh(in: window)
        XCTAssertTrue(TerminalKeyboardOwnership.shared.isFocused(in: window))
        for (character, expected) in [("+", 13.0), ("-", 12.0), ("0", 12.0)] {
            let event = try XCTUnwrap(NSEvent.keyEvent(with: .keyDown, location: .zero,
                modifierFlags: .command, timestamp: 0, windowNumber: window.windowNumber,
                context: nil, characters: character, charactersIgnoringModifiers: character,
                isARepeat: false, keyCode: 0))
            XCTAssertTrue(terminal.performKeyEquivalent(with: event))
            XCTAssertEqual(session.fontSize, expected)
        }
        XCTAssertFalse(TerminalKeyboardOwnership.ownsFirstResponder(in: nil))
        TerminalKeyboardOwnership.shared.clear(in: window)
        XCTAssertFalse(TerminalKeyboardOwnership.shared.isFocused(in: window))
        session.terminate()
    }

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


final class TerminalKeyRoutingTests: XCTestCase {
    private func key(_ code: Int) -> String { String(UnicodeScalar(UInt16(code))!) }

    func testShellOwnsMenuKeysWithoutCommand() {
        XCTAssertTrue(TerminalKeyRouting.shellOwns(modifiers: [], characters: key(NSF2FunctionKey)), "F2 must not rename a file")
        XCTAssertTrue(TerminalKeyRouting.shellOwns(modifiers: [], characters: key(NSF3FunctionKey)))
        XCTAssertTrue(TerminalKeyRouting.shellOwns(modifiers: .control, characters: "\t"), "⌃Tab must not switch tabs")
        XCTAssertTrue(TerminalKeyRouting.shellOwns(modifiers: .option, characters: key(NSLeftArrowFunctionKey)))
        XCTAssertTrue(TerminalKeyRouting.shellOwns(modifiers: .control, characters: "c"))
    }

    func testAppKeepsCommandShortcutsAndDrawerToggles() {
        XCTAssertFalse(TerminalKeyRouting.shellOwns(modifiers: .command, characters: "t"))
        XCTAssertFalse(TerminalKeyRouting.shellOwns(modifiers: [], characters: key(NSF4FunctionKey)), "F4 hides the drawer")
        XCTAssertFalse(TerminalKeyRouting.shellOwns(modifiers: .control, characters: "`"))
        XCTAssertFalse(TerminalKeyRouting.shellOwns(modifiers: [], characters: "a"), "plain typing takes the normal keyDown path")
    }
}
