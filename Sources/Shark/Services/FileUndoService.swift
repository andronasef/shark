import Foundation
import Observation

public enum FileUndoAction: Sendable {
    case move(pairs: [(source: URL, destination: URL)])
    case copy(createdURLs: [URL], originalSources: [URL], destinationDir: URL)
    case rename(original: URL, current: URL)
    case trash(restorations: [(original: URL, inTrash: URL)])

    public var actionDescription: String {
        switch self {
        case .move: return "Move"
        case .copy: return "Copy"
        case .rename: return "Rename"
        case .trash: return "Trash"
        }
    }
}

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

    public func undo() async throws {
        guard let action = undoStack.popLast() else { return }
        let fileManager = FileManager.default

        switch action {
        case .move(let pairs):
            for pair in pairs.reversed() {
                if fileManager.fileExists(atPath: pair.destination.path) {
                    try fileManager.moveItem(at: pair.destination, to: pair.source)
                }
            }
            redoStack.append(.move(pairs: pairs))

        case .copy(let createdURLs, let originalSources, let destinationDir):
            for created in createdURLs {
                if fileManager.fileExists(atPath: created.path) {
                    try fileManager.removeItem(at: created)
                }
            }
            redoStack.append(.copy(createdURLs: createdURLs, originalSources: originalSources, destinationDir: destinationDir))

        case .rename(let original, let current):
            if fileManager.fileExists(atPath: current.path) {
                try fileManager.moveItem(at: current, to: original)
                redoStack.append(.rename(original: original, current: current))
            }

        case .trash(let restorations):
            for item in restorations {
                if fileManager.fileExists(atPath: item.inTrash.path) {
                    try fileManager.moveItem(at: item.inTrash, to: item.original)
                }
            }
            redoStack.append(.trash(restorations: restorations))
        }
    }

    public func redo() async throws {
        guard let action = redoStack.popLast() else { return }
        let fileManager = FileManager.default

        switch action {
        case .move(let pairs):
            for pair in pairs {
                if fileManager.fileExists(atPath: pair.source.path) {
                    try fileManager.moveItem(at: pair.source, to: pair.destination)
                }
            }
            undoStack.append(.move(pairs: pairs))

        case .copy(let createdURLs, let originalSources, let destinationDir):
            try await FileOperationsService.shared.copy(items: originalSources, to: destinationDir)
            undoStack.append(.copy(createdURLs: createdURLs, originalSources: originalSources, destinationDir: destinationDir))

        case .rename(let original, let current):
            if fileManager.fileExists(atPath: original.path) {
                try fileManager.moveItem(at: original, to: current)
                undoStack.append(.rename(original: original, current: current))
            }

        case .trash(let restorations):
            for item in restorations {
                if fileManager.fileExists(atPath: item.original.path) {
                    try fileManager.moveItem(at: item.original, to: item.inTrash)
                }
            }
            undoStack.append(.trash(restorations: restorations))
        }
    }
}
