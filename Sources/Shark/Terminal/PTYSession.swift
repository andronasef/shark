import Foundation
import Observation

@Observable
@MainActor
public final class PTYSession {
    public var outputText: String = ""
    public var currentWorkingDirectory: URL
    public private(set) var isRunning: Bool = false

    private var process: Process?
    private var masterFileHandle: FileHandle?
    private var masterFD: Int32 = -1
    private var slaveFD: Int32 = -1

    public var onOutput: ((String) -> Void)?

    public init(workingDirectory: URL = FileManager.default.homeDirectoryForCurrentUser) {
        self.currentWorkingDirectory = workingDirectory
    }

    isolated deinit {
        terminate()
    }

    public func start() {
        guard !isRunning else { return }

        var master: Int32 = 0
        var slave: Int32 = 0

        guard openpty(&master, &slave, nil, nil, nil) == 0 else {
            outputText = "Failed to allocate pseudo-terminal (openpty error)."
            return
        }

        self.masterFD = master
        self.slaveFD = slave

        let masterHandle = FileHandle(fileDescriptor: master, closeOnDealloc: false)
        let slaveHandle = FileHandle(fileDescriptor: slave, closeOnDealloc: false)
        self.masterFileHandle = masterHandle

        let shellPath = ProcessInfo.processInfo.environment["SHELL"] ?? "/bin/zsh"
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: shellPath)
        proc.arguments = ["-l"]
        proc.currentDirectoryURL = currentWorkingDirectory

        var env = ProcessInfo.processInfo.environment
        env["TERM"] = "xterm-256color"
        env["PWD"] = currentWorkingDirectory.path
        proc.environment = env

        proc.standardInput = slaveHandle
        proc.standardOutput = slaveHandle
        proc.standardError = slaveHandle

        do {
            try proc.run()
            self.process = proc
            self.isRunning = true

            // Close slave in parent process now that child process has inherited it
            close(slave)
            self.slaveFD = -1

            // Asynchronously read terminal output via GCD-backed readabilityHandler
            masterHandle.readabilityHandler = { [weak self] handle in
                let data = handle.availableData
                if data.isEmpty {
                    handle.readabilityHandler = nil
                    Task { @MainActor [weak self] in
                        self?.isRunning = false
                    }
                    return
                }

                if let str = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .ascii) {
                    Task { @MainActor [weak self] in
                        guard let self else { return }
                        self.outputText.append(str)
                        if self.outputText.count > 100_000 {
                            self.outputText = String(self.outputText.suffix(50_000))
                        }
                        self.onOutput?(str)
                    }
                }
            }
        } catch {
            self.outputText = "Failed to launch shell (\(shellPath)): \(error.localizedDescription)"
            close(master)
            close(slave)
            self.masterFD = -1
            self.slaveFD = -1
        }
    }

    public func sendInput(_ input: String) {
        guard let data = input.data(using: .utf8), let handle = masterFileHandle else { return }
        try? handle.write(contentsOf: data)
    }

    public func syncDirectory(to directory: URL) {
        guard isRunning else {
            currentWorkingDirectory = directory
            return
        }

        if currentWorkingDirectory.standardizedFileURL.path != directory.standardizedFileURL.path {
            currentWorkingDirectory = directory
            let escapedPath = directory.path.replacingOccurrences(of: "\"", with: "\\\"")
            sendInput("\ncd \"\(escapedPath)\"\n")
        }
    }

    public func clear() {
        outputText = ""
    }

    public func terminate() {
        masterFileHandle?.readabilityHandler = nil
        try? masterFileHandle?.close()
        masterFileHandle = nil

        if let proc = process {
            kill(proc.processIdentifier, SIGKILL)
            proc.terminate()
            self.process = nil
        }

        if masterFD >= 0 {
            close(masterFD)
            masterFD = -1
        }
        if slaveFD >= 0 {
            close(slaveFD)
            slaveFD = -1
        }
        isRunning = false
    }
}
