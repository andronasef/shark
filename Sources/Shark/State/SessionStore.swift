import Foundation
import Observation
import os

@MainActor
public final class SessionStore {
    public let fileURL: URL
    private let logger = Logger(subsystem: "Shark", category: "Session")
    private var saveTask: Task<Void, Never>?

    public init(fileURL: URL = URL.applicationSupportDirectory.appending(path: "Shark/session.json")) {
        self.fileURL = fileURL
    }

    public func restore() -> WorkspaceState? {
        guard let data = try? Data(contentsOf: fileURL) else {
            return nil
        }
        do {
            let snapshot = try JSONDecoder().decode(WorkspaceSnapshot.self, from: data)
            return WorkspaceState(snapshot: snapshot)
        } catch {
            logger.error("Session restore failed: \(error, privacy: .public); starting fresh")
            return nil
        }
    }

    public func startAutosave(_ ws: WorkspaceState) {
        withObservationTracking {
            _ = ws.snapshot()
        } onChange: { [weak self] in
            Task { @MainActor in
                self?.changed(ws)
            }
        }
    }

    private func changed(_ ws: WorkspaceState) {
        startAutosave(ws)
        saveTask?.cancel()
        saveTask = Task {
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled else { return }
            saveNow(ws)
        }
    }

    public func saveNow(_ ws: WorkspaceState) {
        saveTask?.cancel()
        do {
            let dir = fileURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(ws.snapshot())
            try data.write(to: fileURL, options: .atomic)
        } catch {
            logger.error("Session save failed: \(error, privacy: .public)")
        }
    }
}
