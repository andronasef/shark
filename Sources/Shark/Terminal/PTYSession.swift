import Foundation
import Darwin
import Observation
import SwiftTerm

@Observable
@MainActor
public final class PTYSession {
    public var outputText: String = ""
    public var currentWorkingDirectory: URL
    public private(set) var isRunning: Bool = false

    public weak var terminalView: LocalProcessTerminalView?

    public init(workingDirectory: URL = FileManager.default.homeDirectoryForCurrentUser) {
        self.currentWorkingDirectory = workingDirectory
    }

    public func attach(terminalView: LocalProcessTerminalView) {
        self.terminalView = terminalView
        self.isRunning = true
    }

    public func start() {
        self.isRunning = true
    }

    public func sendInput(_ input: String) {
        if let terminalView {
            terminalView.process.send(data: ArraySlice(input.utf8))
        } else {
            outputText.append(input)
        }
    }

    /// Types a `cd` into the shell, but only while the shell itself owns the terminal. When a
    /// program such as vim or psql is in the foreground the keystrokes would go to that program,
    /// so the drawer keeps its old directory instead.
    public func syncDirectory(to directory: URL) {
        guard let terminalView else {
            currentWorkingDirectory = directory
            return
        }
        guard let process = terminalView.process, process.running, tcgetpgrp(process.childfd) == process.shellPid else { return }
        currentWorkingDirectory = directory
        let command = "\u{15}" + Self.directoryChangeCommand(to: directory)
        process.send(data: ArraySlice(command.utf8))
    }

    static func directoryChangeCommand(to directory: URL) -> String {
        "cd -- " + directory.path.shellQuoted + "\n"
    }

    public func clear() {
        outputText = ""
        if let terminalView {
            // Send Ctrl+L (clear screen) to terminal
            terminalView.process.send(data: ArraySlice([0x0c]))
        }
    }

    public func terminate() {
        self.isRunning = false
        self.terminalView = nil
    }
}

extension String {
    /// POSIX single-quoted form: safe to paste into any sh-compatible shell, because nothing
    /// inside single quotes is expanded ($(…), backticks, variables).
    var shellQuoted: String {
        "'" + replacingOccurrences(of: "'", with: "'\\''") + "'"
    }
}
