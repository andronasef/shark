import Foundation
import Observation

public enum FileUndoAction: Sendable {
    case move(pairs: [(source: URL, destination: URL)])
    case rename(original: URL, current: URL)
    case batchRename(pairs: [(source: URL, destination: URL)])
    case trash(restorations: [(original: URL, inTrash: URL)])
    /// Items an operation created (copy, duplicate, new folder). Undo moves them to the Trash.
    case create(urls: [URL], name: String)
    /// Redo of a `create`: the created items are put back from the Trash.
    case restoreCreated(restorations: [(original: URL, inTrash: URL)], name: String)

    public var actionDescription: String {
        switch self {
        case .move: return "Move"
        case .rename, .batchRename: return "Rename"
        case .trash: return "Trash"
        case .create(_, let name), .restoreCreated(_, let name): return name
        }
    }
}

/// App-wide file undo history. Every mutating file operation records here, so ⌘Z always undoes
/// the most recent one. The file I/O runs off the main actor.
@Observable
@MainActor
public final class FileUndoService {
    public static let shared = FileUndoService()

    private var undoStack: [FileUndoAction] = []
    private var redoStack: [FileUndoAction] = []

    public var canUndo: Bool { !undoStack.isEmpty }
    public var canRedo: Bool { !redoStack.isEmpty }

    public var currentUndoDescription: String? {
        undoStack.last?.actionDescription
    }

    public var currentRedoDescription: String? {
        redoStack.last?.actionDescription
    }

    public init() {}

    public func record(_ action: FileUndoAction) {
        undoStack.append(action)
        redoStack.removeAll()
    }

    public func clear() {
        undoStack.removeAll()
        redoStack.removeAll()
    }

    /// On failure the action stays on the undo stack, so it can be retried.
    public func undo() async throws {
        guard let action = undoStack.popLast() else { return }
        do {
            redoStack.append(try await Self.reverse(action))
        } catch {
            undoStack.append(action)
            throw error
        }
    }

    public func redo() async throws {
        guard let action = redoStack.popLast() else { return }
        do {
            undoStack.append(try await Self.replay(action))
        } catch {
            redoStack.append(action)
            throw error
        }
    }

    /// Undoes `action` and returns what redo needs.
    private nonisolated static func reverse(_ action: FileUndoAction) async throws -> FileUndoAction {
        switch action {
        case .move(let pairs):
            try moveBack(pairs.map { ($0.destination, $0.source) })
            return action
        case .batchRename(let pairs):
            try moveStaged(pairs.map { ($0.destination, $0.source) })
            return action
        case .rename(let original, let current):
            try moveBack([(current, original)])
            return action
        case .trash(let restorations):
            try moveBack(restorations.map { ($0.inTrash, $0.original) })
            return action
        case .create(let urls, let name):
            let present = urls.filter { FileManager.default.fileExists(atPath: $0.path) }
            let restorations = try await FileOperationsService.shared.trash(items: present)
            return .restoreCreated(restorations: restorations, name: name)
        case .restoreCreated(let restorations, let name):
            try moveBack(restorations.map { ($0.original, $0.inTrash) })
            return .create(urls: restorations.map(\.original), name: name)
        }
    }

    /// Redoes `action` and returns what undo needs.
    private nonisolated static func replay(_ action: FileUndoAction) async throws -> FileUndoAction {
        switch action {
        case .move(let pairs):
            try moveBack(pairs.map { ($0.source, $0.destination) })
            return action
        case .batchRename(let pairs):
            try moveStaged(pairs.map { ($0.source, $0.destination) })
            return action
        case .rename(let original, let current):
            try moveBack([(original, current)])
            return action
        case .trash(let restorations):
            try moveBack(restorations.map { ($0.original, $0.inTrash) })
            return action
        case .restoreCreated(let restorations, let name):
            try moveBack(restorations.map { ($0.inTrash, $0.original) })
            return .create(urls: restorations.map(\.original), name: name)
        case .create:
            return try await reverse(action)
        }
    }

    /// Moves each item that is still where the operation left it. Never overwrites: an occupied
    /// destination stops the undo with an error instead of replacing what is there now.
    private nonisolated static func moveBack(_ moves: [(from: URL, to: URL)]) throws {
        let fileManager = FileManager.default
        let present = moves.reversed().filter { fileManager.fileExists(atPath: $0.from.path) }
        for move in present {
            let caseOnly = move.from.path.caseInsensitiveCompare(move.to.path) == .orderedSame
            if !caseOnly && fileManager.fileExists(atPath: move.to.path) {
                throw FileOperationError.alreadyExists(move.to.lastPathComponent)
            }
        }
        var done: [(from: URL, to: URL)] = []
        do {
            for move in present {
                try fileManager.moveItem(at: move.from, to: move.to)
                done.append(move)
            }
        } catch {
            for move in done.reversed() { try? fileManager.moveItem(at: move.to, to: move.from) }
            throw error
        }
    }

    /// Renames through temporary names first, so a batch that swaps names ("a"↔"b") can be reversed.
    private nonisolated static func moveStaged(_ moves: [(from: URL, to: URL)]) throws {
        let present = moves.filter { FileManager.default.fileExists(atPath: $0.from.path) }
        let sources = Set(present.map { $0.from.standardizedFileURL.path })
        for move in present where FileManager.default.fileExists(atPath: move.to.path) {
            let caseOnly = move.from.path.caseInsensitiveCompare(move.to.path) == .orderedSame
            guard sources.contains(move.to.standardizedFileURL.path) || caseOnly else {
                throw FileOperationError.alreadyExists(move.to.lastPathComponent)
            }
        }
        let staged = present.map { ($0.from, $0.from.deletingLastPathComponent().appendingPathComponent(".shark-rename-\(UUID().uuidString)")) }
        try moveBack(staged)
        do {
            try moveBack(zip(staged, present).map { ($0.1, $1.to) })
        } catch {
            try? moveBack(staged.map { ($0.1, $0.0) })
            throw error
        }
    }
}
