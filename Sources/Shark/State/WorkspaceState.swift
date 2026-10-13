import Foundation
import Observation

@Observable
@MainActor
public final class WorkspaceState {
    public var tabs: [WorkspaceTab] = []
    public var activeTabID: UUID

    public init(initialURL: URL? = nil) {
        let firstTab = WorkspaceTab(initialURL: initialURL)
        self.tabs = [firstTab]
        self.activeTabID = firstTab.id
    }

    public var activeTab: WorkspaceTab {
        if let found = tabs.first(where: { $0.id == activeTabID }) {
            return found
        }
        return tabs.first ?? {
            let fallback = WorkspaceTab()
            tabs.append(fallback)
            activeTabID = fallback.id
            return fallback
        }()
    }

    public var activeNavigationState: NavigationState {
        activeTab.activeNavigationState
    }

    public func newTab(url: URL? = nil) {
        let targetURL = url ?? activeNavigationState.currentURL
        let tab = WorkspaceTab(initialURL: targetURL)
        tabs.append(tab)
        activeTabID = tab.id
    }

    public func closeTab(id: UUID) {
        guard tabs.count > 1 else {
            // Keep at least one tab open; navigate to home
            activeNavigationState.navigateTo(FileManager.default.homeDirectoryForCurrentUser)
            return
        }

        if let index = tabs.firstIndex(where: { $0.id == id }) {
            let closingActive = (id == activeTabID)
            tabs.remove(at: index)

            if closingActive {
                let nextIndex = min(index, tabs.count - 1)
                activeTabID = tabs[nextIndex].id
            }
        }
    }

    public func selectTab(id: UUID) {
        if tabs.contains(where: { $0.id == id }) {
            activeTabID = id
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
}
