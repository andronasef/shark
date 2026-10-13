import Foundation
import SwiftUI

public enum SidebarSection: String, CaseIterable, Identifiable, Sendable {
    case favorites = "Favorites"
    case places = "Places"
    case volumes = "Drives & Volumes"
    case system = "System"

    public var id: String { rawValue }
}

public struct SidebarItem: Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let url: URL
    public let iconName: String
    public let section: SidebarSection
    public let isRemovable: Bool

    public init(
        id: String? = nil,
        name: String,
        url: URL,
        iconName: String,
        section: SidebarSection,
        isRemovable: Bool = false
    ) {
        self.id = id ?? url.path
        self.name = name
        self.url = url
        self.iconName = iconName
        self.section = section
        self.isRemovable = isRemovable
    }
}
