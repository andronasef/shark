import SwiftUI

public enum DefaultStartupLocation: String, CaseIterable, Identifiable, Sendable {
    case home = "Home"
    case desktop = "Desktop"
    case documents = "Documents"
    case downloads = "Downloads"
    case lastSession = "Last Session"

    public var id: String { rawValue }

    public var url: URL {
        let homeURL = FileManager.default.homeDirectoryForCurrentUser
        switch self {
        case .home, .lastSession:
            return homeURL
        case .desktop:
            return FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first ?? homeURL
        case .documents:
            return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first ?? homeURL
        case .downloads:
            return FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first ?? homeURL
        }
    }
}

public enum DefaultViewModeSetting: String, CaseIterable, Identifiable, Sendable {
    case icons = "Icons (Grid)"
    case list = "Details (List)"
    case compact = "Columns (Compact)"
    case gallery = "Gallery"

    public var id: String { rawValue }

    public var viewMode: ViewMode {
        switch self {
        case .icons: return .grid
        case .list: return .details
        case .compact: return .compact
        case .gallery: return .gallery
        }
    }
}

@MainActor
public final class SharkSettings: ObservableObject {
    public static let shared = SharkSettings()

    @AppStorage("defaultViewMode") public var defaultViewMode: String = DefaultViewModeSetting.list.rawValue
    @AppStorage("startupLocation") public var startupLocation: String = DefaultStartupLocation.home.rawValue
    @AppStorage("showHiddenFilesByDefault") public var showHiddenFilesByDefault: Bool = false
    @AppStorage("hoverPreviewEnabled") public var hoverPreviewEnabled: Bool = true
    @AppStorage("hoverPreviewDelayMs") public var hoverPreviewDelayMs: Double = 350.0
    @AppStorage("hoverPreviewRequiresShift") public var hoverPreviewRequiresShift: Bool = false
    @AppStorage("hoverPreviewAutoplay") public var hoverPreviewAutoplay: Bool = true
    @AppStorage("openNewTabsAtEnd") public var openNewTabsAtEnd: Bool = true
    @AppStorage("confirmBeforeClosingMultipleTabs") public var confirmBeforeClosingMultipleTabs: Bool = false
    @AppStorage("liquidGlassTranslucency") public var liquidGlassTranslucency: Bool = true

    private init() {}
}
