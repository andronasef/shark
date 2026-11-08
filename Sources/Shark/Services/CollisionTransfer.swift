import Foundation

public enum CollisionChoice: Sendable, Equatable {
    case replace, keepBoth, skip, stop, merge
}

public enum TransferMode: Sendable {
    case move, copy
}

/// What the user is asked when a name is already taken in the destination.
public struct CollisionPrompt: Identifiable, Sendable {
    public let id = UUID()
    public let incoming: FileItem
    public let existing: FileItem
    public let mode: TransferMode
    /// Both are real folders (not packages or links), so their contents can be combined.
    public let canMerge: Bool
    /// More conflicts may follow, so "Apply to all" is worth offering.
    public let mayRepeat: Bool
}

public typealias CollisionHandler = @Sendable (CollisionPrompt) async -> (choice: CollisionChoice, applyToAll: Bool)

public struct TransferResult: Sendable {
    /// Every change made, in order. Completed work stays here when the run stops or fails.
    public var actions: [FileUndoAction] = []
    public var stopped = false
    public var error: (any Error)?

    /// One undo step for the whole transfer.
    public func undoAction(for mode: TransferMode) -> FileUndoAction? {
        switch actions.count {
        case 0: return nil
        case 1: return actions[0]
        default: return .batch(name: L10n.text(mode == .move ? "Move" : "Copy"), actions: actions)
        }
    }
}

extension FileItem {
    /// A snapshot for the conflict dialog.
    static func describing(_ url: URL) -> FileItem {
        let keys: Set<URLResourceKey> = [.isDirectoryKey, .isPackageKey, .isSymbolicLinkKey, .fileSizeKey,
                                         .contentModificationDateKey, .creationDateKey, .localizedTypeDescriptionKey]
        let values = try? url.resourceValues(forKeys: keys)
        let isLink = values?.isSymbolicLink ?? false
        return FileItem(
            url: url,
            name: url.lastPathComponent,
            isDirectory: !isLink && (values?.isDirectory ?? false),
            isPackage: values?.isPackage ?? false,
            isSymlink: isLink,
            fileSize: Int64(values?.fileSize ?? 0),
            dateModified: values?.contentModificationDate ?? Date(),
            dateCreated: values?.creationDate ?? Date(),
            kindDescription: values?.localizedTypeDescription ?? ""
        )
    }
}

private struct TransferRun {
    let mode: TransferMode
    let mayRepeat: Bool
    let resolve: CollisionHandler
    var folderSticky: CollisionChoice?
    var fileSticky: CollisionChoice?
    var actions: [FileUndoAction] = []
    var stopped = false
}

extension FileOperationsService {
    /// Moves or copies `items` into `destinationDir`, asking `resolve` whenever a name is taken.
    ///
    /// With no name clash this is the all-or-nothing `move` / `copy`. With clashes the items are
    /// handled one at a time: nothing is ever deleted (Replace sends the old item to the Trash),
    /// and a Stop or a failure keeps what was already done, recorded in the result for undo.
    public func transfer(items: [URL], to destinationDir: URL, mode: TransferMode,
                         resolve: @escaping CollisionHandler) async -> TransferResult {
        let dir = destinationDir.standardizedFileURL
        let sources = items.map(\.standardizedFileURL)
        var result = TransferResult()
        guard hasNameClash(sources, in: dir) else {
            do {
                switch mode {
                case .move:
                    let pairs = try move(items: sources, to: dir)
                    if !pairs.isEmpty { result.actions = [.move(pairs: pairs)] }
                case .copy:
                    result.actions = [.create(urls: try copy(items: sources, to: dir), name: L10n.text("Copy"))]
                }
            } catch {
                if let partial = error as? PartialMoveError { result.actions = [.move(pairs: partial.remainingMoves)] }
                result.error = error
            }
            return result
        }

        var run = TransferRun(mode: mode, mayRepeat: sources.count > 1, resolve: resolve)
        do {
            for item in sources where !run.stopped { try await place(item, into: dir, run: &run) }
        } catch {
            result.error = error
        }
        result.actions = run.actions
        result.stopped = run.stopped
        return result
    }

    /// The name Keep Both gives an incoming item: "name 2", "name 3", keeping the extension.
    func keepBothName(for filename: String, in directory: URL) -> URL {
        let ext = (filename as NSString).pathExtension
        let base = (filename as NSString).deletingPathExtension
        var counter = 2
        while true {
            let name = ext.isEmpty ? "\(base) \(counter)" : "\(base) \(counter).\(ext)"
            let candidate = directory.appendingPathComponent(name)
            if !exists(candidate) { return candidate }
            counter += 1
        }
    }

    /// True when any item would land on an existing name, or two items share a name.
    private func hasNameClash(_ items: [URL], in dir: URL) -> Bool {
        var seen = Set<String>()
        for item in items where item.deletingLastPathComponent().path != dir.path {
            let name = item.lastPathComponent
            if exists(dir.appendingPathComponent(name)) || !seen.insert(name.lowercased()).inserted { return true }
        }
        return false
    }

    /// Existence of the item itself: a dangling link still counts, and a link is never followed.
    private func exists(_ url: URL) -> Bool {
        (try? fileManager.attributesOfItem(atPath: url.path)) != nil
    }

    /// A real folder that Merge may open. Links to folders and packages (.app, .pages) are not.
    private func isMergeableFolder(_ url: URL) -> Bool {
        let values = try? url.resourceValues(forKeys: [.isDirectoryKey, .isSymbolicLinkKey, .isPackageKey])
        return values?.isSymbolicLink != true && values?.isDirectory == true && values?.isPackage != true
    }

    private func place(_ item: URL, into dir: URL, run: inout TransferRun) async throws {
        let name = item.lastPathComponent
        let destination = dir.appendingPathComponent(name)
        if item.deletingLastPathComponent().path == dir.path {
            // Already here: a move does nothing, a copy is a duplicate.
            if run.mode == .copy { try perform(item, to: availableCopyName(for: name, in: dir), run: &run) }
            return
        }
        if Self.isSelfOrDescendant(dir, of: item) { throw FileOperationError.intoItself(name) }
        guard exists(destination) else { return try perform(item, to: destination, run: &run) }

        let canMerge = isMergeableFolder(item) && isMergeableFolder(destination)
        var choice = canMerge ? run.folderSticky : run.fileSticky
        if choice == nil {
            let prompt = CollisionPrompt(incoming: .describing(item), existing: .describing(destination),
                                         mode: run.mode, canMerge: canMerge, mayRepeat: run.mayRepeat || canMerge)
            let answer = await run.resolve(prompt)
            choice = answer.choice
            if answer.applyToAll {
                // Merge only makes sense for folders, so it must not decide the file conflicts.
                if answer.choice == .merge { run.folderSticky = .merge } else { run.folderSticky = answer.choice; run.fileSticky = answer.choice }
            }
        }
        switch choice ?? .stop {
        case .stop:
            run.stopped = true
        case .skip:
            break
        case .keepBoth:
            try perform(item, to: keepBothName(for: name, in: dir), run: &run)
        case .replace:
            // Replacing an item that holds the source would trash the very thing being moved.
            if Self.isSelfOrDescendant(item.deletingLastPathComponent(), of: destination) {
                throw FileOperationError.intoItself(name)
            }
            var trashed: NSURL?
            try fileManager.trashItem(at: destination, resultingItemURL: &trashed)
            let recorded = run.actions.count
            if let inTrash = trashed as URL? { run.actions.append(.trash(restorations: [(destination, inTrash)])) }
            do {
                try perform(item, to: destination, run: &run)
            } catch {
                // Put the old item back so a failed Replace loses nothing.
                if let inTrash = trashed as URL? { try? fileManager.moveItem(at: inTrash, to: destination) }
                run.actions.removeSubrange(recorded...)
                throw error
            }
        case .merge:
            guard canMerge else { return }
            let children = try fileManager.contentsOfDirectory(at: item, includingPropertiesForKeys: nil, options: [])
            for child in children where !run.stopped { try await place(child, into: destination, run: &run) }
            // A moved-from folder that ended up empty goes to the Trash (undoable) instead of lingering.
            if run.mode == .move, !run.stopped,
               (try? fileManager.contentsOfDirectory(atPath: item.path))?.isEmpty == true {
                var trashed: NSURL?
                try fileManager.trashItem(at: item, resultingItemURL: &trashed)
                if let inTrash = trashed as URL? { run.actions.append(.trash(restorations: [(item, inTrash)])) }
            }
        }
    }

    private func perform(_ item: URL, to target: URL, run: inout TransferRun) throws {
        switch run.mode {
        case .move:
            try fileManager.moveItem(at: item, to: target)
            run.actions.append(.move(pairs: [(item, target)]))
        case .copy:
            try fileManager.copyItem(at: item, to: target)
            run.actions.append(.create(urls: [target], name: L10n.text("Copy")))
        }
    }
}
