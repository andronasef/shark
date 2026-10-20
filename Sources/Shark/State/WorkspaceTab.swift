import Foundation
import Observation

public enum PaneIdentifier: String, CaseIterable, Codable, Sendable {
    case primary
    case secondary
}

public enum TabColor: String, Codable, CaseIterable, Sendable {
    case red
    case orange
    case yellow
    case green
    case blue
    case purple
    case gray
}

@Observable
@MainActor
public final class WorkspaceTab: Identifiable {
    public let id: UUID
    public var isSplit: Bool
    public var isPinned: Bool
    public var isLocked: Bool
    public var color: TabColor?
    public var activePane: PaneIdentifier
    public let primaryPane: NavigationState
    public let secondaryPane: NavigationState

    public init(
        id: UUID = UUID(),
        initialURL: URL? = nil,
        isSplit: Bool = false,
        isPinned: Bool = false,
        isLocked: Bool = false,
        color: TabColor? = nil
    ) {
        self.id = id
        self.isSplit = isSplit
        self.isPinned = isPinned
        self.isLocked = isLocked
        self.color = color
        self.activePane = .primary
        self.primaryPane = NavigationState(initialURL: initialURL)
        self.secondaryPane = NavigationState(initialURL: initialURL)
    }

    public var activeNavigationState: NavigationState {
        switch activePane {
        case .primary: return primaryPane
        case .secondary: return secondaryPane
        }
    }

    public var title: String {
        let pName = primaryPane.currentURL.lastPathComponent.isEmpty ? "Macintosh HD" : primaryPane.currentURL.lastPathComponent
        if isSplit {
            let sName = secondaryPane.currentURL.lastPathComponent.isEmpty ? "Macintosh HD" : secondaryPane.currentURL.lastPathComponent
            return "\(pName) | \(sName)"
        }
        return pName
    }

    public var tooltipText: String {
        var lines: [String]
        if isSplit {
            lines = [
                "Left: \(primaryPane.currentURL.path)",
                "Right: \(secondaryPane.currentURL.path)"
            ]
        } else {
            lines = [activeNavigationState.currentURL.path]
        }
        if isPinned {
            lines.insert(title, at: 0)
        }
        if isLocked {
            lines.append("Locked")
        }
        return lines.joined(separator: "\n")
    }

    public func toggleSplit() {
        isSplit.toggle()
        if isSplit {
            // When opening secondary pane, navigate to same or related directory
            if secondaryPane.items.isEmpty {
                secondaryPane.navigateTo(primaryPane.currentURL)
            }
        } else {
            // Revert active pane to primary if secondary was active
            activePane = .primary
        }
    }

    public func toggleActivePane() {
        guard isSplit else { return }
        activePane = (activePane == .primary) ? .secondary : .primary
    }
}
