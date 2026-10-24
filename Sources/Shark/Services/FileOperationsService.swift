import Foundation
import os

public struct RenameRule: Sendable, Equatable {
    public enum PatternType: Sendable {
        case replace
        case addPrefixSuffix
        case formatWithIndex
    }

    public var findText: String
    public var replaceText: String
    public var prefix: String
    public var suffix: String
    public var useNumbering: Bool
    public var startingNumber: Int
    public var paddingDigits: Int

    public init(
        findText: String = "",
        replaceText: String = "",
        prefix: String = "",
        suffix: String = "",
        useNumbering: Bool = false,
        startingNumber: Int = 1,
        paddingDigits: Int = 2
    ) {
        self.findText = findText
        self.replaceText = replaceText
        self.prefix = prefix
        self.suffix = suffix
        self.useNumbering = useNumbering
        self.startingNumber = startingNumber
        self.paddingDigits = paddingDigits
    }

    public func apply(to filename: String, index: Int) -> String {
        let ext = (filename as NSString).pathExtension
        var base = (filename as NSString).deletingPathExtension

        if !findText.isEmpty {
            base = base.replacingOccurrences(of: findText, with: replaceText)
        }

        if !prefix.isEmpty {
            base = prefix + base
        }

        if !suffix.isEmpty {
            base = base + suffix
        }

        if useNumbering {
            let number = startingNumber + index
            let numStr = String(format: "%0\(paddingDigits)d", number)
            base = "\(base)_\(numStr)"
        }

        if ext.isEmpty {
            return base
        } else {
            return "\(base).\(ext)"
        }
    }
}

public enum FileOperationError: LocalizedError, Equatable {
    case invalidName(String)
    case alreadyExists(String)
    case intoItself(String)
    case duplicateResult(String)

    public var errorDescription: String? {
        switch self {
        case .invalidName(let name):
            return L10n.format("“%@” can’t be used as a name. Names can’t be empty, “.” or “..”, contain “/” or “:”, or be longer than 255 bytes.", L10n.literal(name))
        case .alreadyExists(let name):
            return L10n.format("An item named “%@” already exists in this location.", L10n.literal(name))
        case .intoItself(let name):
            return L10n.format("“%@” can’t be moved or copied into itself.", L10n.literal(name))
        case .duplicateResult(let name):
            return L10n.format("More than one item would be named “%@”.", L10n.literal(name))
        }
    }
}

struct PartialMoveError: LocalizedError, Sendable {
    let reason: String
    let remainingMoves: [(source: URL, destination: URL)]
    var errorDescription: String? {
        L10n.format("%@ Some files could not be returned to their original locations. Use Undo to retry recovery. Current locations:\n", reason) + remainingMoves.map { L10n.literal($0.destination.path) }.joined(separator: "\n")
    }
}

public actor FileOperationsService {
    public static let shared = FileOperationsService()

    private let fileManager: FileManager

    init(fileManager: FileManager = .default) { self.fileManager = fileManager }

    /// Rejects names the file system would misread as paths or refuse outright.
    public nonisolated static func validateName(_ name: String) throws {
        if name.isEmpty || name == "." || name == ".." || name.contains("/") || name.contains(":")
            || name.utf8.count > 255 {
            throw FileOperationError.invalidName(name)
        }
    }

    /// True when `directory` is `item` or lies inside it.
    public nonisolated static func isSelfOrDescendant(_ directory: URL, of item: URL) -> Bool {
        let dir = directory.standardizedFileURL.resolvingSymlinksInPath().path
        let src = item.standardizedFileURL.resolvingSymlinksInPath().path
        return dir == src || dir.hasPrefix(src.hasSuffix("/") ? src : src + "/")
    }

    public nonisolated static func isSameVolume(_ a: URL, _ b: URL) -> Bool {
        let key: Set<URLResourceKey> = [.volumeIdentifierKey]
        guard let va = try? a.resourceValues(forKeys: key).volumeIdentifier,
              let vb = try? b.resourceValues(forKeys: key).volumeIdentifier else { return true }
        return va.isEqual(vb)
    }

    public func createFolder(named name: String, at parent: URL) throws -> URL {
        try Self.validateName(name)
        var destination = parent.appendingPathComponent(name, isDirectory: true)
        var counter = 1

        while fileManager.fileExists(atPath: destination.path) {
            destination = parent.appendingPathComponent("\(name) \(counter)", isDirectory: true)
            counter += 1
        }

        try fileManager.createDirectory(at: destination, withIntermediateDirectories: false)
        return destination
    }

    public func createFile(named name: String, at parent: URL, content: Data? = nil) throws -> URL {
        try Self.validateName(name)
        let ext = (name as NSString).pathExtension
        let base = (name as NSString).deletingPathExtension

        var destination = parent.appendingPathComponent(name, isDirectory: false)
        var counter = 1

        while fileManager.fileExists(atPath: destination.path) {
            let newName = ext.isEmpty ? "\(base) \(counter)" : "\(base) \(counter).\(ext)"
            destination = parent.appendingPathComponent(newName, isDirectory: false)
            counter += 1
        }

        try (content ?? Data()).write(to: destination, options: .withoutOverwriting)
        return destination
    }

    /// Moves items into `destinationDir`. Never overwrites: everything is checked before the first
    /// move, items already in the folder are skipped, and a failure part-way moves the finished ones back.
    @discardableResult
    public func move(items: [URL], to destinationDir: URL) throws -> [(source: URL, destination: URL)] {
        let dir = destinationDir.standardizedFileURL
        var plan: [(source: URL, destination: URL)] = []
        for item in items.map(\.standardizedFileURL) {
            if item.deletingLastPathComponent().path == dir.path { continue }
            if Self.isSelfOrDescendant(dir, of: item) { throw FileOperationError.intoItself(item.lastPathComponent) }
            let destination = dir.appendingPathComponent(item.lastPathComponent)
            if fileManager.fileExists(atPath: destination.path)
                || plan.contains(where: { $0.destination.lastPathComponent.caseInsensitiveCompare(destination.lastPathComponent) == .orderedSame }) {
                throw FileOperationError.alreadyExists(item.lastPathComponent)
            }
            plan.append((item, destination))
        }
        return try performMoves(plan)
    }

    /// Copies items into `destinationDir`, naming collisions "name copy N". Returns the created URLs.
    /// A failure part-way removes the copies this call made, including a half-written one.
    @discardableResult
    public func copy(items: [URL], to destinationDir: URL) throws -> [URL] {
        try copy(items.map { ($0, destinationDir) })
    }

    @discardableResult
    public func duplicate(items: [URL]) throws -> [URL] {
        try copy(items.map { ($0, $0.deletingLastPathComponent()) })
    }

    private func copy(_ requests: [(item: URL, directory: URL)]) throws -> [URL] {
        for request in requests where Self.isSelfOrDescendant(request.directory, of: request.item) {
            throw FileOperationError.intoItself(request.item.lastPathComponent)
        }
        var created: [URL] = []
        for request in requests {
            let target = availableCopyName(for: request.item.lastPathComponent, in: request.directory)
            do {
                try fileManager.copyItem(at: request.item, to: target)
            } catch {
                // Everything removed here was created by this call, so deleting it loses no user data.
                // A target that appeared after the name check belongs to someone else: leave it.
                let partial = (error as? CocoaError)?.code == .fileWriteFileExists ? [] : [target]
                for url in created + partial { try? fileManager.removeItem(at: url) }
                throw error
            }
            created.append(target)
        }
        return created
    }

    private func availableCopyName(for filename: String, in directory: URL) -> URL {
        var target = directory.appendingPathComponent(filename)
        let ext = (filename as NSString).pathExtension
        let base = (filename as NSString).deletingPathExtension
        var counter = 1
        while fileManager.fileExists(atPath: target.path) {
            let newName = ext.isEmpty ? "\(base) copy \(counter)" : "\(base) copy \(counter).\(ext)"
            target = directory.appendingPathComponent(newName)
            counter += 1
        }
        return target
    }

    public func rename(item: URL, to newName: String) throws -> URL {
        try Self.validateName(newName)
        let destination = item.deletingLastPathComponent().appendingPathComponent(newName)
        if item.lastPathComponent == newName { return item }
        // A case-only change ("foo" → "Foo") finds the item itself on a case-insensitive volume.
        let caseOnly = item.lastPathComponent.caseInsensitiveCompare(newName) == .orderedSame
        if !caseOnly && fileManager.fileExists(atPath: destination.path) {
            throw FileOperationError.alreadyExists(newName)
        }
        try fileManager.moveItem(at: item, to: destination)
        return destination
    }

    /// Moves items to the Trash and returns where each one landed, for undo.
    /// A failure part-way puts the already-trashed items back.
    public func trash(items: [URL]) throws -> [(original: URL, inTrash: URL)] {
        var done: [(original: URL, inTrash: URL)] = []
        for item in items {
            var resulting: NSURL?
            do {
                try fileManager.trashItem(at: item, resultingItemURL: &resulting)
            } catch {
                for entry in done.reversed() { try? fileManager.moveItem(at: entry.inTrash, to: entry.original) }
                throw error
            }
            if let inTrash = resulting as URL? { done.append((item, inTrash)) }
        }
        return done
    }

    /// Renames every item or none. Names are validated and checked for collisions first; the renames
    /// then go through temporary names so swaps work, and a failure rolls all of them back.
    public func batchRename(items: [URL], rule: RenameRule) throws -> [URL] {
        var plan: [(source: URL, destination: URL)] = []
        var seen = Set<String>()
        let sources = Set(items.map { $0.standardizedFileURL.path.lowercased() })
        for (index, item) in items.enumerated() {
            let newName = rule.apply(to: item.lastPathComponent, index: index)
            try Self.validateName(newName)
            let destination = item.deletingLastPathComponent().appendingPathComponent(newName)
            guard seen.insert(destination.standardizedFileURL.path.lowercased()).inserted else {
                throw FileOperationError.duplicateResult(newName)
            }
            if newName == item.lastPathComponent { continue }
            if fileManager.fileExists(atPath: destination.path),
               !sources.contains(destination.standardizedFileURL.path.lowercased()) {
                throw FileOperationError.alreadyExists(newName)
            }
            plan.append((item, destination))
        }

        let staged = plan.map { entry in
            (source: entry.source,
             destination: entry.source.deletingLastPathComponent().appendingPathComponent(".shark-rename-\(UUID().uuidString)"))
        }
        let moved = try performMoves(staged)
        do {
            _ = try performMoves(zip(moved, plan).map { ($0.destination, $1.destination) })
        } catch {
            for entry in moved.reversed() { try? fileManager.moveItem(at: entry.destination, to: entry.source) }
            throw error
        }
        let renamed = Dictionary(uniqueKeysWithValues: plan.map { ($0.source, $0.destination) })
        return items.map { renamed[$0] ?? $0 }
    }

    /// Runs the moves in order; if one fails, the earlier ones are moved back before rethrowing.
    private func performMoves(_ moves: [(source: URL, destination: URL)]) throws -> [(source: URL, destination: URL)] {
        var done: [(source: URL, destination: URL)] = []
        for move in moves {
            do {
                try fileManager.moveItem(at: move.source, to: move.destination)
            } catch {
                var remaining: [(source: URL, destination: URL)] = []
                for entry in done.reversed() {
                    do { try fileManager.moveItem(at: entry.destination, to: entry.source) }
                    catch { remaining.append(entry) }
                }
                if !remaining.isEmpty { throw PartialMoveError(reason: error.localizedDescription, remainingMoves: remaining.reversed()) }
                throw error
            }
            done.append(move)
        }
        return done
    }

    public func compress(items: [URL]) async throws -> URL {
        guard let first = items.first else {
            throw NSError(domain: "FileOperationsError", code: 2, userInfo: [NSLocalizedDescriptionKey: L10n.text("No items to compress")])
        }
        let parentDir = first.deletingLastPathComponent()
        let archiveName: String
        if items.count == 1 {
            archiveName = first.deletingPathExtension().lastPathComponent + ".zip"
        } else {
            archiveName = "Archive.zip"
        }

        var destination = parentDir.appendingPathComponent(archiveName)
        var counter = 1
        let archiveBase = (archiveName as NSString).deletingPathExtension
        while fileManager.fileExists(atPath: destination.path) {
            destination = parentDir.appendingPathComponent("\(archiveBase) \(counter).zip")
            counter += 1
        }

        try Task.checkCancellation()
        // Keep partial output private. Publishing with moveItem never replaces a file that
        // another process created while ditto was running.
        let work = parentDir.appendingPathComponent(".shark-compress-\(UUID().uuidString)", isDirectory: true)
        try fileManager.createDirectory(at: work, withIntermediateDirectories: false)
        defer { try? fileManager.removeItem(at: work) }
        let output = work.appendingPathComponent("output.zip")
        let source: URL
        if items.count == 1 {
            source = first
        } else {
            // ditto can archive only one source. Stage each input under its own name
            // so selected folders stay separate, preserving resource forks and attributes.
            source = work.appendingPathComponent("contents", isDirectory: true)
            try fileManager.createDirectory(at: source, withIntermediateDirectories: false)
            for item in items {
                try await runCompressionHelper(arguments: [item.path, source.appendingPathComponent(item.lastPathComponent).path])
            }
        }
        var arguments = ["-c", "-k", "--sequesterRsrc"]
        if items.count == 1 { arguments.append("--keepParent") }
        try await runCompressionHelper(arguments: arguments + [source.path, output.path])
        try Task.checkCancellation()
        try fileManager.moveItem(at: output, to: destination)
        return destination
    }

    /// Suspends the actor while ditto runs. The lock serializes launch, cancellation and exit,
    /// so a cancellation cannot miss a just-launched process or reuse a completed process ID.
    private func runCompressionHelper(arguments: [String]) async throws {
        try Task.checkCancellation()
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
        process.arguments = arguments
        let runningPID = OSAllocatedUnfairLock<pid_t>(initialState: 0)
        let status: Int32 = try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                process.terminationHandler = { process in
                    runningPID.withLock { $0 = 0 }
                    continuation.resume(returning: process.terminationStatus)
                }
                do {
                    try runningPID.withLock { pid in
                        try Task.checkCancellation()
                        try process.run()
                        pid = process.processIdentifier
                        if Task.isCancelled { kill(pid, SIGTERM) }
                    }
                } catch {
                    process.terminationHandler = nil
                    continuation.resume(throwing: error)
                }
            }
        } onCancel: {
            runningPID.withLock { pid in
                if pid > 0 { kill(pid, SIGTERM) }
            }
        }
        try Task.checkCancellation()
        guard status == 0 else {
            throw NSError(domain: "FileOperationsError", code: Int(status), userInfo: [NSLocalizedDescriptionKey: L10n.format("Compression failed with status %d", status)])
        }
    }

}
