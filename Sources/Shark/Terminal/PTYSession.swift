import Foundation
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

    public func syncDirectory(to directory: URL) {
        currentWorkingDirectory = directory
        if let terminalView {
            let escapedPath = directory.path.replacingOccurrences(of: "\"", with: "\\\"")
            terminalView.process.send(data: ArraySlice("\ncd \"\(escapedPath)\"\n".utf8))
        }
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
