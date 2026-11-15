import Foundation

/// Where Shark moved items to the Trash, kept across launches so Put Back can work later.
/// Items Shark did not trash have no record, and Shark never guesses their original place.
public final class TrashRecordStore: @unchecked Sendable {
    public static let shared = TrashRecordStore(fileURL: TrashRecordStore.defaultFileURL)

    struct Record: Codable, Equatable {
        var original: String
        var inTrash: String
        var date: Date
    }

    static let limit = 2000

    private let lock = NSLock()
    private var records: [Record]
    private let fileURL: URL?

    static var defaultFileURL: URL? {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent("Shark/trash-records.json")
    }

    public init(fileURL: URL?) {
        self.fileURL = fileURL
        let data = fileURL.flatMap { try? Data(contentsOf: $0) }
        records = data.flatMap { try? JSONDecoder().decode([Record].self, from: $0) } ?? []
    }

    public func add(_ pairs: [(original: URL, inTrash: URL)]) {
        guard !pairs.isEmpty else { return }
        lock.lock(); defer { lock.unlock() }
        let now = Date()
        for pair in pairs {
            let trashed = pair.inTrash.standardizedFileURL.path
            records.removeAll { $0.inTrash == trashed }
            records.append(Record(original: pair.original.standardizedFileURL.path, inTrash: trashed, date: now))
        }
        if records.count > Self.limit { records.removeFirst(records.count - Self.limit) }
        save()
    }

    /// The original place of an item that is in the Trash now, or nil when Shark did not put it there.
    public func original(forTrashed url: URL) -> URL? {
        lock.lock(); defer { lock.unlock() }
        let path = url.standardizedFileURL.path
        guard let record = records.last(where: { $0.inTrash == path }),
              FileManager.default.fileExists(atPath: path) else { return nil }
        return URL(fileURLWithPath: record.original)
    }

    public func remove(trashed urls: [URL]) {
        lock.lock(); defer { lock.unlock() }
        let paths = Set(urls.map { $0.standardizedFileURL.path })
        let before = records.count
        records.removeAll { paths.contains($0.inTrash) }
        if records.count != before { save() }
    }

    /// Drops records whose item has left the Trash. Only runs when the Trash folder can be listed,
    /// because an unreadable Trash makes every item look gone.
    public func prune(trashFolder: URL) {
        guard (try? FileManager.default.contentsOfDirectory(atPath: trashFolder.path)) != nil else { return }
        lock.lock(); defer { lock.unlock() }
        let before = records.count
        records.removeAll { !FileManager.default.fileExists(atPath: $0.inTrash) }
        if records.count != before { save() }
    }

    var count: Int { lock.lock(); defer { lock.unlock() }; return records.count }

    private func save() {
        guard let fileURL else { return }
        try? FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        if let data = try? JSONEncoder().encode(records) { try? data.write(to: fileURL, options: .atomic) }
    }
}

public struct PutBackResult: Sendable {
    public var transfer = TransferResult()
    /// Items left in the Trash, each with the reason. Nothing in this list was lost.
    public var skipped: [(url: URL, reason: String)] = []
    /// Where the restored items ended up.
    public var restored: [URL] = []
}

public enum TrashLocation {
    public static var userTrash: URL {
        FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".Trash", isDirectory: true)
    }

    public static func isTrash(_ url: URL) -> Bool {
        url.standardizedFileURL.resolvingSymlinksInPath().path == userTrash.standardizedFileURL.resolvingSymlinksInPath().path
    }
}

extension FileOperationsService {
    /// Moves recorded Trash items back to where they came from. Name clashes go through `resolve`.
    /// Items without a record, or whose original folder is gone, stay in the Trash and are reported.
    public func putBack(items: [URL], store: TrashRecordStore = .shared,
                        resolve: @escaping CollisionHandler) async -> PutBackResult {
        var result = PutBackResult()
        for trashed in items {
            guard let original = store.original(forTrashed: trashed) else {
                result.skipped.append((trashed, L10n.text("Shark has no record of where this item came from.")))
                continue
            }
            let parent = original.deletingLastPathComponent()
            var isDir: ObjCBool = false
            guard fileManager.fileExists(atPath: parent.path, isDirectory: &isDir), isDir.boolValue else {
                result.skipped.append((trashed, L10n.format("The folder “%@” no longer exists.", L10n.literal(parent.lastPathComponent))))
                continue
            }
            do {
                let moved = try await place(trashed, as: original.lastPathComponent, into: parent, resolve: resolve)
                result.transfer.actions += moved.transfer.actions
                if let error = moved.transfer.error { result.transfer.error = error }
                if moved.transfer.stopped { result.transfer.stopped = true }
                if moved.placed { result.restored.append(original); store.remove(trashed: [trashed]) }
                if moved.transfer.stopped || moved.transfer.error != nil { break }
            } catch {
                result.skipped.append((trashed, error.localizedDescription))
            }
        }
        return result
    }

    /// The Trash may have renamed the item ("report 2") to avoid a clash there. In that case it is
    /// first moved into a private folder next to its destination under its original name.
    private func place(_ trashed: URL, as name: String, into parent: URL,
                       resolve: @escaping CollisionHandler) async throws -> (transfer: TransferResult, placed: Bool) {
        if trashed.lastPathComponent == name {
            let result = await transfer(items: [trashed], to: parent, mode: .move, resolve: resolve)
            return (result, result.actions.isEmpty == false)
        }
        let staging = parent.appendingPathComponent(".shark-putback-\(UUID().uuidString)", isDirectory: true)
        try fileManager.createDirectory(at: staging, withIntermediateDirectories: false)
        defer { try? fileManager.removeItem(at: staging) }
        let staged = staging.appendingPathComponent(name)
        try fileManager.moveItem(at: trashed, to: staged)
        var result = await transfer(items: [staged], to: parent, mode: .move, resolve: resolve)
        if fileManager.fileExists(atPath: staged.path) {
            // Skipped or stopped: the item goes back to the Trash under the name it had there.
            try? fileManager.moveItem(at: staged, to: trashed)
            return (result, false)
        }
        // The staging folder is removed, so a step that moved out of it can't be undone by path.
        result.actions = []
        return (result, true)
    }
}

/// Empty Trash is done by Finder, which owns the Trash. Shark only asks, after the user confirmed.
public enum TrashEmptier {
    public enum Outcome: Sendable, Equatable {
        case done
        /// The user (or policy) has not allowed Shark to control Finder.
        case notAllowed
        case failed(String)
    }

    /// `errAEEventNotPermitted`: the user denied the Automation prompt.
    static let notPermittedCode = -1743

    public static func emptyViaFinder() async -> Outcome {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                var error: NSDictionary?
                NSAppleScript(source: "tell application \"Finder\" to empty trash")?.executeAndReturnError(&error)
                guard let error else { return continuation.resume(returning: .done) }
                let code = error[NSAppleScript.errorNumber] as? Int
                if code == notPermittedCode { return continuation.resume(returning: .notAllowed) }
                let message = error[NSAppleScript.errorMessage] as? String ?? L10n.text("Finder did not empty the Trash.")
                continuation.resume(returning: .failed(message))
            }
        }
    }
}
