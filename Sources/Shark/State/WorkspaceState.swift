import Foundation
import Observation

public enum TabPlacement: Sendable {
    case end
    case afterActive
}

public struct EmbeddedTerminalRequest: Identifiable, Equatable {
    public let id = UUID()
    public let directory: URL
}

@Observable
@MainActor
public final class WorkspaceState {
    public var tabs: [WorkspaceTab] = []
    public var activeTabID: UUID
    public var closedTabs: [ClosedTab] = []
    public var isTerminalVisible: Bool = false
    public var sidebarHasKeyboardFocus: Bool = false
    public var embeddedTerminalRequest: EmbeddedTerminalRequest?
    public var isCommandPalettePresented: Bool = false

    public func openEmbeddedTerminal(at url: URL, from source: NavigationState) throws {
        let directory = try TerminalOpener.directory(for: url)
        if let owner = tabs.first(where: { $0.primaryPane === source || $0.secondaryPane === source }) {
            activeTabID = owner.id
            owner.activePane = owner.primaryPane === source ? .primary : .secondary
        }
        embeddedTerminalRequest = EmbeddedTerminalRequest(directory: directory)
        isTerminalVisible = true
    }

    public init(initialURL: URL? = nil) {
        let firstTab = WorkspaceTab(initialURL: initialURL)
        self.tabs = [firstTab]
        self.activeTabID = firstTab.id
        self.closedTabs = []
    }

    public init(snapshot: WorkspaceSnapshot) {
        var restoredTabs: [WorkspaceTab] = []
        for tabSnap in snapshot.tabs {
            let tab = WorkspaceState.buildTab(from: tabSnap)
            restoredTabs.append(tab)
        }

        // Ensure non-empty invariant
        if restoredTabs.isEmpty {
            let fallback = WorkspaceTab(initialURL: FileManager.default.homeDirectoryForCurrentUser)
            restoredTabs = [fallback]
        }

        // Enforce pinned-prefix invariant with stable partition
        let pinned = restoredTabs.filter { $0.isPinned }
        let unpinned = restoredTabs.filter { !$0.isPinned }
        let finalTabs = pinned + unpinned

        let chosenID: UUID
        if let targetID = snapshot.activeTabID, finalTabs.contains(where: { $0.id == targetID }) {
            chosenID = targetID
        } else {
            chosenID = finalTabs.first!.id
        }

        self.tabs = finalTabs
        self.activeTabID = chosenID
        // Cap closed tabs at 20
        self.closedTabs = Array(snapshot.closedTabs.prefix(20))
    }

    public var pinnedCount: Int {
        tabs.filter { $0.isPinned }.count
    }

    public var unpinnedTabs: [WorkspaceTab] {
        tabs.filter { !$0.isPinned }
    }

    public var pinnedTabs: [WorkspaceTab] {
        tabs.filter { $0.isPinned }
    }

    public var activeTab: WorkspaceTab {
        if let found = tabs.first(where: { $0.id == activeTabID }) {
            return found
        }
        return tabs.first!
    }

    public var activeNavigationState: NavigationState {
        activeTab.activeNavigationState
    }

    public func newTab(
        url: URL? = nil,
        placement: TabPlacement = .end,
        select: Bool = true
    ) {
        let targetURL = url ?? activeNavigationState.currentURL
        let tab = WorkspaceTab(initialURL: targetURL)

        let insertIndex: Int
        switch placement {
        case .end:
            insertIndex = tabs.count
        case .afterActive:
            if let activeIndex = tabs.firstIndex(where: { $0.id == activeTabID }) {
                insertIndex = activeIndex + 1
            } else {
                insertIndex = tabs.count
            }
        }

        let clamped = max(pinnedCount, insertIndex)
        tabs.insert(tab, at: min(clamped, tabs.count))
        if select {
            activeTabID = tab.id
        }
    }

    public func togglePin(id: UUID) {
        guard let index = tabs.firstIndex(where: { $0.id == id }) else { return }
        let tab = tabs[index]
        tab.isPinned.toggle()
        tabs.remove(at: index)

        if tab.isPinned {
            let dest = pinnedCount
            tabs.insert(tab, at: dest)
        } else {
            let dest = pinnedCount
            tabs.insert(tab, at: dest)
        }
    }

    public func toggleLock(id: UUID) {
        guard let tab = tabs.first(where: { $0.id == id }) else { return }
        tab.isLocked.toggle()
    }

    public func setColor(_ color: TabColor?, for id: UUID) {
        guard let tab = tabs.first(where: { $0.id == id }) else { return }
        tab.color = color
    }

    public func duplicateTab(id: UUID) {
        guard let index = tabs.firstIndex(where: { $0.id == id }) else { return }
        let source = tabs[index]

        let copy = WorkspaceTab(
            initialURL: source.primaryPane.currentURL,
            isSplit: source.isSplit,
            isPinned: source.isPinned,
            isLocked: false,
            color: source.color
        )

        copy.primaryPane.viewMode = source.primaryPane.viewMode
        copy.primaryPane.sortField = source.primaryPane.sortField
        copy.primaryPane.sortAscending = source.primaryPane.sortAscending
        copy.primaryPane.showHiddenFiles = source.primaryPane.showHiddenFiles
        copy.primaryPane.iconSize = source.primaryPane.iconSize

        if source.isSplit {
            copy.secondaryPane.navigateTo(source.secondaryPane.currentURL)
            copy.secondaryPane.viewMode = source.secondaryPane.viewMode
            copy.secondaryPane.sortField = source.secondaryPane.sortField
            copy.secondaryPane.sortAscending = source.secondaryPane.sortAscending
            copy.secondaryPane.showHiddenFiles = source.secondaryPane.showHiddenFiles
            copy.secondaryPane.iconSize = source.secondaryPane.iconSize
            copy.activePane = source.activePane
        }

        let destIndex = index + 1
        let clamped = source.isPinned ? min(destIndex, pinnedCount) : max(pinnedCount, destIndex)
        tabs.insert(copy, at: min(clamped, tabs.count))
        activeTabID = copy.id
    }

    public func closeTab(id: UUID) {
        guard let index = tabs.firstIndex(where: { $0.id == id }) else { return }
        let tabToClose = tabs[index]

        let snap = snapshotForTab(tabToClose)
        closedTabs.insert(ClosedTab(tab: snap, index: index), at: 0)
        if closedTabs.count > 20 {
            closedTabs.removeLast()
        }

        let closingActive = (id == activeTabID)

        if tabs.count == 1 {
            let homeTab = WorkspaceTab(initialURL: FileManager.default.homeDirectoryForCurrentUser)
            tabs = [homeTab]
            activeTabID = homeTab.id
            return
        }

        tabs.remove(at: index)

        if closingActive {
            let nextIndex = min(index, tabs.count - 1)
            activeTabID = tabs[nextIndex].id
        }
    }

    public func closeOtherTabs(id: UUID) {
        guard tabs.contains(where: { $0.id == id }) else { return }

        var remaining: [WorkspaceTab] = []
        for (idx, tab) in tabs.enumerated() {
            if tab.id == id || tab.isPinned || tab.isLocked {
                remaining.append(tab)
            } else {
                let snap = snapshotForTab(tab)
                closedTabs.insert(ClosedTab(tab: snap, index: idx), at: 0)
            }
        }
        if closedTabs.count > 20 {
            closedTabs = Array(closedTabs.prefix(20))
        }

        tabs = remaining
        activeTabID = id
    }

    public func closeTabsToRight(id: UUID) {
        guard let targetIndex = tabs.firstIndex(where: { $0.id == id }) else { return }

        var remaining: [WorkspaceTab] = []
        for (idx, tab) in tabs.enumerated() {
            if idx <= targetIndex || tab.isPinned || tab.isLocked {
                remaining.append(tab)
            } else {
                let snap = snapshotForTab(tab)
                closedTabs.insert(ClosedTab(tab: snap, index: idx), at: 0)
            }
        }
        if closedTabs.count > 20 {
            closedTabs = Array(closedTabs.prefix(20))
        }

        tabs = remaining
        if !tabs.contains(where: { $0.id == activeTabID }) {
            activeTabID = id
        }
    }

    public func reopenClosedTab(at closedIndex: Int = 0) {
        guard !closedTabs.isEmpty, closedIndex < closedTabs.count else { return }
        let closed = closedTabs.remove(at: closedIndex)
        let tab = WorkspaceState.buildTab(from: closed.tab)

        let targetIndex = min(closed.index, tabs.count)
        let clamped: Int
        if tab.isPinned {
            clamped = min(targetIndex, pinnedCount)
        } else {
            clamped = max(pinnedCount, min(targetIndex, tabs.count))
        }

        tabs.insert(tab, at: clamped)
        activeTabID = tab.id
    }

    public func selectTab(id: UUID) {
        if tabs.contains(where: { $0.id == id }) {
            activeTabID = id
        }
    }

    public func selectTab(number: Int) {
        if number >= 1 && number <= 8 {
            let index = number - 1
            if index < tabs.count {
                activeTabID = tabs[index].id
            }
        } else if number == 9 {
            if let last = tabs.last {
                activeTabID = last.id
            }
        }
    }

    public func moveTab(id: UUID, to destinationIndex: Int) {
        guard let currIndex = tabs.firstIndex(where: { $0.id == id }) else { return }
        let tab = tabs[currIndex]

        let clampedDest: Int
        if tab.isPinned {
            let maxPinnedIndex = max(0, pinnedCount - 1)
            clampedDest = max(0, min(destinationIndex, maxPinnedIndex))
        } else {
            let minUnpinnedIndex = pinnedCount
            let maxUnpinnedIndex = max(pinnedCount, tabs.count - 1)
            clampedDest = max(minUnpinnedIndex, min(destinationIndex, maxUnpinnedIndex))
        }

        if currIndex == clampedDest { return }
        tabs.remove(at: currIndex)
        tabs.insert(tab, at: clampedDest)
    }

    public func open(_ url: URL, from pane: NavigationState, newTab: Bool) {
        guard let owner = tabs.first(where: { $0.primaryPane === pane || $0.secondaryPane === pane }) else {
            pane.navigateTo(url)
            return
        }

        if newTab {
            let ownerIndex = tabs.firstIndex(where: { $0.id == owner.id }) ?? (tabs.count - 1)
            let newTabItem = WorkspaceTab(initialURL: url)
            let destIndex = max(pinnedCount, ownerIndex + 1)
            tabs.insert(newTabItem, at: min(destIndex, tabs.count))
            // Selection unchanged for background tab
        } else if owner.isLocked {
            let ownerIndex = tabs.firstIndex(where: { $0.id == owner.id }) ?? (tabs.count - 1)
            let newTabItem = WorkspaceTab(initialURL: url)
            let destIndex = max(pinnedCount, ownerIndex + 1)
            tabs.insert(newTabItem, at: min(destIndex, tabs.count))
            activeTabID = newTabItem.id
        } else {
            pane.navigateTo(url)
        }
    }

    public func nextTab() {
        guard tabs.count > 1, let index = tabs.firstIndex(where: { $0.id == activeTabID }) else { return }
        let nextIndex = (index + 1) % tabs.count
        activeTabID = tabs[nextIndex].id
    }

    public func previousTab() {
        guard tabs.count > 1, let index = tabs.firstIndex(where: { $0.id == activeTabID }) else { return }
        let prevIndex = (index - 1 + tabs.count) % tabs.count
        activeTabID = tabs[prevIndex].id
    }

    public func toggleSplit() {
        activeTab.toggleSplit()
    }

    public func toggleActivePane() {
        activeTab.toggleActivePane()
    }

    public func toggleCommandPalette() {
        isCommandPalettePresented.toggle()
    }

    public func snapshot() -> WorkspaceSnapshot {
        let tabSnaps = tabs.map { snapshotForTab($0) }
        return WorkspaceSnapshot(tabs: tabSnaps, activeTabID: activeTabID, closedTabs: closedTabs)
    }

    private func snapshotForTab(_ tab: WorkspaceTab) -> TabSnapshot {
        var primaryBookmark: Data? = nil
        var secondaryBookmark: Data? = nil
        if SecurityScopedBookmarkManager.shared.isSandboxed {
            primaryBookmark = try? SecurityScopedBookmarkManager.shared.saveBookmark(for: tab.primaryPane.currentURL)
            secondaryBookmark = try? SecurityScopedBookmarkManager.shared.saveBookmark(for: tab.secondaryPane.currentURL)
        }

        let primarySnap = PaneSnapshot(
            url: tab.primaryPane.currentURL,
            viewMode: String(describing: tab.primaryPane.viewMode),
            sortField: String(describing: tab.primaryPane.sortField),
            sortAscending: tab.primaryPane.sortAscending,
            showHidden: tab.primaryPane.showHiddenFiles,
            iconSize: tab.primaryPane.iconSize,
            bookmarkData: primaryBookmark
        )
        let secondarySnap = PaneSnapshot(
            url: tab.secondaryPane.currentURL,
            viewMode: String(describing: tab.secondaryPane.viewMode),
            sortField: String(describing: tab.secondaryPane.sortField),
            sortAscending: tab.secondaryPane.sortAscending,
            showHidden: tab.secondaryPane.showHiddenFiles,
            iconSize: tab.secondaryPane.iconSize,
            bookmarkData: secondaryBookmark
        )
        return TabSnapshot(
            id: tab.id,
            isPinned: tab.isPinned,
            isLocked: tab.isLocked,
            color: tab.color,
            isSplit: tab.isSplit,
            activePane: tab.activePane,
            primary: primarySnap,
            secondary: secondarySnap
        )
    }

    private static func buildTab(from snap: TabSnapshot) -> WorkspaceTab {
        if let data = snap.primary.bookmarkData {
            _ = SecurityScopedBookmarkManager.shared.resolveBookmark(data: data)
        }
        if let data = snap.secondary.bookmarkData {
            _ = SecurityScopedBookmarkManager.shared.resolveBookmark(data: data)
        }

        let validPrimaryURL = existingAncestor(snap.primary.url)
        let validSecondaryURL = existingAncestor(snap.secondary.url)

        let tab = WorkspaceTab(
            id: snap.id,
            initialURL: validPrimaryURL,
            isSplit: snap.isSplit,
            isPinned: snap.isPinned,
            isLocked: snap.isLocked,
            color: snap.color
        )
        tab.activePane = snap.activePane

        tab.primaryPane.viewMode = snap.primary.decodedViewMode
        tab.primaryPane.sortField = snap.primary.decodedSortField
        tab.primaryPane.sortAscending = snap.primary.sortAscending
        tab.primaryPane.showHiddenFiles = snap.primary.showHidden
        tab.primaryPane.iconSize = snap.primary.iconSize

        tab.secondaryPane.navigateTo(validSecondaryURL)
        tab.secondaryPane.viewMode = snap.secondary.decodedViewMode
        tab.secondaryPane.sortField = snap.secondary.decodedSortField
        tab.secondaryPane.sortAscending = snap.secondary.sortAscending
        tab.secondaryPane.showHiddenFiles = snap.secondary.showHidden
        tab.secondaryPane.iconSize = snap.secondary.iconSize

        return tab
    }
}
