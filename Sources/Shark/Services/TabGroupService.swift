import Foundation
import Observation
import OSLog

private let logger = Logger(subsystem: "org.shark.filemanager", category: "TabGroups")

public struct SavedTabSnapshot: Codable, Sendable, Identifiable {
    public var id: UUID
    public var primaryPath: String
    public var secondaryPath: String?
    public var isSplit: Bool
    public var color: TabColor?
    public var isPinned: Bool
    public var isLocked: Bool

    public init(
        id: UUID = UUID(),
        primaryPath: String,
        secondaryPath: String? = nil,
        isSplit: Bool = false,
        color: TabColor? = nil,
        isPinned: Bool = false,
        isLocked: Bool = false
    ) {
        self.id = id
        self.primaryPath = primaryPath
        self.secondaryPath = secondaryPath
        self.isSplit = isSplit
        self.color = color
        self.isPinned = isPinned
        self.isLocked = isLocked
    }
}

public struct TabGroup: Identifiable, Codable, Sendable {
    public let id: UUID
    public var name: String
    public var createdAt: Date
    public var tabs: [SavedTabSnapshot]

    public init(id: UUID = UUID(), name: String, createdAt: Date = Date(), tabs: [SavedTabSnapshot]) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.tabs = tabs
    }
}

@Observable
@MainActor
public final class TabGroupService {
    public static let shared = TabGroupService()

    public private(set) var groups: [TabGroup] = []

    private let storageURL: URL

    public init(storageURL: URL? = nil) {
        if let custom = storageURL {
            self.storageURL = custom
        } else {
            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            let sharkDir = appSupport.appendingPathComponent("Shark", isDirectory: true)
            try? FileManager.default.createDirectory(at: sharkDir, withIntermediateDirectories: true)
            self.storageURL = sharkDir.appendingPathComponent("tab_groups.json")
        }
        load()
    }

    public func saveGroup(name: String, tabs: [WorkspaceTab]) -> TabGroup {
        let snapshots = tabs.map { tab in
            SavedTabSnapshot(
                primaryPath: tab.primaryPane.currentURL.path,
                secondaryPath: tab.isSplit ? tab.secondaryPane.currentURL.path : nil,
                isSplit: tab.isSplit,
                color: tab.color,
                isPinned: tab.isPinned,
                isLocked: tab.isLocked
            )
        }

        let newGroup = TabGroup(name: name, tabs: snapshots)
        groups.append(newGroup)
        save()
        return newGroup
    }

    public func deleteGroup(id: UUID) {
        groups.removeAll { $0.id == id }
        save()
    }

    public func renameGroup(id: UUID, newName: String) {
        guard let index = groups.firstIndex(where: { $0.id == id }) else { return }
        groups[index].name = newName
        save()
    }

    public func restore(group: TabGroup, into workspace: WorkspaceState, replace: Bool = true) {
        if replace {
            workspace.tabs.removeAll()
        }

        for snapshot in group.tabs {
            let primaryURL = URL(fileURLWithPath: snapshot.primaryPath)
            let tab = WorkspaceTab(
                initialURL: primaryURL,
                isSplit: snapshot.isSplit,
                isPinned: snapshot.isPinned,
                isLocked: snapshot.isLocked,
                color: snapshot.color
            )
            if let sec = snapshot.secondaryPath {
                tab.secondaryPane.navigateTo(URL(fileURLWithPath: sec))
            }
            workspace.tabs.append(tab)
        }

        if workspace.tabs.isEmpty {
            workspace.tabs.append(WorkspaceTab())
        }
        workspace.activeTabID = workspace.tabs.first?.id ?? UUID()
    }

    private func load() {
        guard FileManager.default.fileExists(atPath: storageURL.path) else { return }
        do {
            let data = try Data(contentsOf: storageURL)
            self.groups = try JSONDecoder().decode([TabGroup].self, from: data)
        } catch {
            logger.error("Failed to load tab groups: \(error, privacy: .public)")
        }
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(groups)
            try data.write(to: storageURL, options: .atomic)
        } catch {
            logger.error("Failed to save tab groups: \(error, privacy: .public)")
        }
    }
}
