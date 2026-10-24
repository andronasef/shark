import Foundation
import AppKit
import Darwin
import Observation
import SwiftTerm

/// A window owns the session; the drawer only borrows its terminal view.
@Observable
@MainActor
public final class PTYSession: NSObject {
    public var outputText = ""
    public private(set) var currentWorkingDirectory: URL
    public private(set) var hasReportedDirectory = false
    public private(set) var isRunning = false
    public private(set) var hasStarted = false
    public private(set) var exitCode: Int32?
    public private(set) var fontSize: Double
    public private(set) var terminalView: LocalProcessTerminalView?
    @ObservationIgnored private let preferences: UserDefaults
    @ObservationIgnored private var closeGuard: TerminalWindowCloseGuard?
    static let fontPreferenceKey = "terminalFontSize"

    public init(workingDirectory: URL = FileManager.default.homeDirectoryForCurrentUser,
                preferences: UserDefaults = .standard) {
        currentWorkingDirectory = workingDirectory
        self.preferences = preferences
        let saved = preferences.object(forKey: Self.fontPreferenceKey) as? Double ?? 12
        fontSize = saved.isFinite ? min(36, max(8, saved)) : 12
        super.init()
    }

    public func prepareInitialDirectory(_ directory: URL) {
        guard !hasStarted else { return }
        currentWorkingDirectory = directory
    }

    /// Browsing never sends shell input or pretends the shell changed directory.
    public func syncDirectory(to directory: URL) {}

    /// SwiftTerm cannot establish that arbitrary shells have an empty, safe prompt.
    /// Return a command for the clipboard, with no Enter, leaving live input untouched.
    @discardableResult
    public func useDirectory(_ directory: URL) throws -> String {
        let resolved = try TerminalOpener.directory(for: directory)
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: directory.path, isDirectory: &isDirectory),
              isDirectory.boolValue, FileManager.default.isReadableFile(atPath: resolved.path) else {
            throw CocoaError(.fileReadNoPermission, userInfo: [NSFilePathErrorKey: directory.path])
        }
        return Self.directoryChangeCommand(to: resolved).trimmingCharacters(in: .newlines)
    }

    static func directoryChangeCommand(to directory: URL) -> String {
        "cd -- " + directory.path.shellQuoted + "\n"
    }

    public func makeTerminalView() -> LocalProcessTerminalView {
        if let terminalView { return terminalView }
        let view = SharkTerminalView(frame: NSRect(x: 0, y: 0, width: 800, height: 220))
        view.session = self
        view.processDelegate = self
        view.font = NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
        view.nativeBackgroundColor = NSColor(white: 0.12, alpha: 1)
        view.nativeForegroundColor = NSColor(white: 0.94, alpha: 1)
        terminalView = view
        return view
    }

    public func start() {
        guard !hasStarted else { return }
        let view = makeTerminalView()
        hasStarted = true
        view.startProcess(executable: ProcessInfo.processInfo.environment["SHELL"] ?? "/bin/zsh",
                          args: ["-l"], currentDirectory: currentWorkingDirectory.path)
        isRunning = view.process.running
    }

    public func restart() {
        terminate()
        terminalView?.removeFromSuperview()
        terminalView = nil
        hasStarted = false
        hasReportedDirectory = false
        exitCode = nil
        start()
    }

    public func focus() {
        guard isRunning, let terminalView else { return }
        terminalView.window?.makeFirstResponder(terminalView)
        TerminalKeyboardOwnership.shared.refresh(in: terminalView.window)
    }

    public func sendInput(_ input: String) {
        guard isRunning, let terminalView else { return }
        terminalView.process.send(data: ArraySlice(input.utf8))
    }

    public func adjustFontSize(by delta: Double) {
        guard delta.isFinite else { return }
        fontSize = min(36, max(8, fontSize + delta))
        preferences.set(fontSize, forKey: Self.fontPreferenceKey)
        terminalView?.font = NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
    }

    public func resetFontSize() { adjustFontSize(by: 12 - fontSize) }

    public func clear() {
        outputText = ""
        // Render locally; Ctrl-L would instead alter an interactive program or live input.
        terminalView?.clearScrollback()
        terminalView?.feed(text: "\u{1b}[2J\u{1b}[H")
    }

    public func terminate() {
        if let process = terminalView?.process, process.running {
            let foreground = tcgetpgrp(process.childfd)
            if foreground > 0 { kill(-foreground, SIGHUP) }
            if process.shellPid > 0 { kill(-process.shellPid, SIGHUP) }
            terminalView?.terminate()
        }
        isRunning = false
    }

    func attachWindow(_ window: NSWindow) {
        if closeGuard?.window === window { return }
        closeGuard = TerminalWindowCloseGuard(window: window, session: self)
    }
}

extension PTYSession: @preconcurrency LocalProcessTerminalViewDelegate {
    public func sizeChanged(source: LocalProcessTerminalView, newCols: Int, newRows: Int) {}
    public func setTerminalTitle(source: LocalProcessTerminalView, title: String) {}
    public func hostCurrentDirectoryUpdate(source: SwiftTerm.TerminalView, directory: String?) {
        guard source === terminalView, let directory, let url = URL(string: directory), url.isFileURL else { return }
        currentWorkingDirectory = url
        hasReportedDirectory = true
    }
    public func processTerminated(source: SwiftTerm.TerminalView, exitCode: Int32?) {
        guard source === terminalView else { return }
        self.exitCode = exitCode
        isRunning = false
        // A dead terminal remains selectable for copying, but refuses new input.
    }
}

extension String {
    /// Literal POSIX shell argument, including spaces, quotes, and mixed-direction paths.
    var shellQuoted: String { "'" + replacingOccurrences(of: "'", with: "'\\''") + "'" }
}
