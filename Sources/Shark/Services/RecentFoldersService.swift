import Foundation
import Observation
import OSLog

private let logger = Logger(subsystem: "org.shark.filemanager", category: "RecentFolders")

public struct FolderVisitRecord: Codable, Sendable {
    public let url: URL
    public var visitCount: Int
    public var lastVisited: Date

    public init(url: URL, visitCount: Int = 1, lastVisited: Date = Date()) {
        self.url = url
        self.visitCount = visitCount
        self.lastVisited = lastVisited
    }
}

@Observable
@MainActor
public final class RecentFoldersService {
    public static let shared = RecentFoldersService()

    public private(set) var recentFolders: [URL] = []
    public private(set) var frequentFolders: [URL] = []

    private var visitRecords: [String: FolderVisitRecord] = [:]
    private let storageURL: URL
    private let maxRecents: Int = 30
    private let maxFrequents: Int = 10

    public init(storageURL: URL? = nil) {
        if let custom = storageURL {
            self.storageURL = custom
        } else {
            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            let sharkDir = appSupport.appendingPathComponent("Shark", isDirectory: true)
            try? FileManager.default.createDirectory(at: sharkDir, withIntermediateDirectories: true)
            self.storageURL = sharkDir.appendingPathComponent("recent_folders.json")
        }
        load()
    }

    public func recordVisit(to url: URL) {
        let standardized = url.standardizedFileURL
        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: standardized.path, isDirectory: &isDir), isDir.boolValue else {
            return
        }

        let key = standardized.path
        if var record = visitRecords[key] {
            record.visitCount += 1
            record.lastVisited = Date()
            visitRecords[key] = record
        } else {
            visitRecords[key] = FolderVisitRecord(url: standardized, visitCount: 1, lastVisited: Date())
        }

        updateComputedLists()
        save()
    }

    public func remove(url: URL) {
        let key = url.standardizedFileURL.path
        visitRecords.removeValue(forKey: key)
        updateComputedLists()
        save()
    }

    public func clear() {
        visitRecords.removeAll()
        updateComputedLists()
        save()
    }

    private func updateComputedLists() {
        // Filter out URLs that no longer exist on disk
        let validRecords = visitRecords.values.filter { FileManager.default.fileExists(atPath: $0.url.path) }

        // Recents: sorted by lastVisited descending, capped at maxRecents
        recentFolders = validRecords
            .sorted { $0.lastVisited > $1.lastVisited }
            .prefix(maxRecents)
            .map(\.url)

        // Frequents: sorted by visitCount descending, must have >= 2 visits, capped at maxFrequents
        frequentFolders = validRecords
            .filter { $0.visitCount >= 2 }
            .sorted { $0.visitCount > $1.visitCount }
            .prefix(maxFrequents)
            .map(\.url)
    }

    private func load() {
        guard FileManager.default.fileExists(atPath: storageURL.path) else {
            return
        }
        do {
            let data = try Data(contentsOf: storageURL)
            let records = try JSONDecoder().decode([FolderVisitRecord].self, from: data)
            self.visitRecords = Dictionary(uniqueKeysWithValues: records.map { ($0.url.standardizedFileURL.path, $0) })
            updateComputedLists()
        } catch {
            logger.error("Failed to load recent folders: \(error, privacy: .public)")
        }
    }

    private func save() {
        do {
            let records = Array(visitRecords.values)
            let data = try JSONEncoder().encode(records)
            try data.write(to: storageURL, options: .atomic)
        } catch {
            logger.error("Failed to save recent folders: \(error, privacy: .public)")
        }
    }
}
