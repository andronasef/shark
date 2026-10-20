import SwiftUI
import AppKit
import Inject

public struct PlacesSidebarView: View {
    @ObserveInjection var inject
    @Bindable var navigationState: NavigationState
    @Environment(WorkspaceState.self) private var workspace: WorkspaceState?
    @State private var favorites: [SidebarItem] = []
    @State private var locations: [SidebarItem] = []

    private let fileSystemService = FileSystemService.shared

    public init(navigationState: NavigationState) {
        self.navigationState = navigationState
    }

    private let tagItems: [(name: String, color: Color)] = [
        ("Red", Color(red: 1.0, green: 0.23, blue: 0.19)),
        ("Orange", Color(red: 1.0, green: 0.58, blue: 0.0)),
        ("Yellow", Color(red: 1.0, green: 0.8, blue: 0.0)),
        ("Green", Color(red: 0.2, green: 0.78, blue: 0.35)),
        ("Blue", Color(red: 0.0, green: 0.48, blue: 1.0)),
        ("Purple", Color(red: 0.69, green: 0.32, blue: 0.87)),
        ("Gray", Color(red: 0.56, green: 0.56, blue: 0.58))
    ]

    public var body: some View {
        List {
            // Standalone top items (Recents, Shared)
            Section {
                sidebarRow(
                    name: "Recents",
                    iconName: "clock",
                    url: FileManager.default.homeDirectoryForCurrentUser,
                    iconColor: .secondary
                )
                sidebarRow(
                    name: "Shared",
                    iconName: "person.2",
                    url: URL(fileURLWithPath: "/Users/Shared"),
                    iconColor: .secondary
                )
            }

            // Favorites section
            Section("Favorites") {
                ForEach(favorites) { item in
                    sidebarRow(
                        name: item.name,
                        iconName: item.iconName,
                        url: item.url,
                        iconColor: .accentColor
                    )
                }
            }

            // Locations section
            Section("Locations") {
                ForEach(locations) { item in
                    sidebarRow(
                        name: item.name,
                        iconName: item.iconName,
                        url: item.url,
                        iconColor: .secondary
                    )
                }
            }

            // Tags section
            Section("Tags") {
                ForEach(tagItems, id: \.name) { tag in
                    Button(action: {
                        navigationState.filterText = tag.name
                    }) {
                        HStack(spacing: 10) {
                            Circle()
                                .fill(tag.color)
                                .frame(width: 10, height: 10)
                            Text(tag.name)
                                .font(.system(size: 13))
                            Spacer()
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .padding(.vertical, 3)
                    .padding(.horizontal, 6)
                }

                Button(action: {}) {
                    HStack(spacing: 10) {
                        Image(systemName: "tag")
                            .foregroundColor(.secondary)
                            .frame(width: 14)
                        Text("All Tags...")
                            .font(.system(size: 13))
                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.vertical, 3)
                .padding(.horizontal, 6)
            }
        }
        .listStyle(.sidebar)
        .task {
            await loadSidebarItems()
        }
        .enableInjection()
    }

    @ViewBuilder
    private func sidebarRow(
        name: String,
        iconName: String,
        url: URL,
        iconColor: Color
    ) -> some View {
        let isSelected = navigationState.currentURL.standardizedFileURL.path == url.standardizedFileURL.path

        Button(action: {
            let isCmd = NSEvent.modifierFlags.contains(.command)
            if let workspace {
                workspace.open(url, from: navigationState, newTab: isCmd)
            } else {
                navigationState.navigateTo(url)
            }
        }) {
            HStack(spacing: 10) {
                Image(systemName: iconName)
                    .font(.system(size: 14))
                    .foregroundColor(isSelected ? .white : iconColor)
                    .frame(width: 18)
                Text(name)
                    .font(.system(size: 13))
                    .foregroundColor(isSelected ? .white : .primary)
                    .lineLimit(1)
                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected ? Color.accentColor : Color.clear)
        )
        .onMiddleClick {
            workspace?.open(url, from: navigationState, newTab: true)
        }
        .contextMenu {
            Button("Open in New Tab") {
                workspace?.open(url, from: navigationState, newTab: true)
            }
        }
        .dropDestination(for: URL.self) { urls, _ in
            Task {
                try? await FileOperationsService.shared.copy(items: urls, to: url)
                if navigationState.currentURL.standardizedFileURL.path == url.standardizedFileURL.path {
                    await navigationState.reloadCurrentDirectory()
                }
            }
            return true
        }
    }

    private func loadSidebarItems() async {
        let places = await fileSystemService.standardPlaces()

        // Favorites: Projects, Applications, Desktop, Documents, Downloads
        let favNames = ["Projects", "Applications", "Desktop", "Documents", "Downloads"]
        var loadedFavorites: [SidebarItem] = []
        for name in favNames {
            if let found = places.first(where: { $0.name == name }) {
                loadedFavorites.append(found)
            }
        }
        // If Projects doesn't exist in standard places, add ~/Developer
        if !loadedFavorites.contains(where: { $0.name == "Projects" }) {
            let projectsURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Developer")
            loadedFavorites.insert(SidebarItem(name: "Projects", url: projectsURL, iconName: "folder.fill", section: .favorites), at: 0)
        }
        self.favorites = loadedFavorites

        // Locations: iCloud Drive, Home, Macintosh HD, AirDrop, Trash, plus mounted volumes
        var loadedLocations: [SidebarItem] = []
        let homeURL = FileManager.default.homeDirectoryForCurrentUser
        let username = homeURL.lastPathComponent

        loadedLocations.append(SidebarItem(name: "iCloud Drive", url: FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Mobile Documents/com~apple~CloudDocs"), iconName: "icloud", section: .places))
        loadedLocations.append(SidebarItem(name: username, url: homeURL, iconName: "house", section: .places))
        loadedLocations.append(SidebarItem(name: "Macintosh HD", url: URL(fileURLWithPath: "/"), iconName: "internaldrive", section: .places))
        loadedLocations.append(SidebarItem(name: "AirDrop", url: URL(fileURLWithPath: "/System/Library/CoreServices/Finder.app"), iconName: "radiowaves.right", section: .places))

        let mounted = await fileSystemService.mountedVolumes()
        for vol in mounted {
            if vol.url.path != "/" {
                loadedLocations.append(vol)
            }
        }

        let trashURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".Trash")
        loadedLocations.append(SidebarItem(name: "Trash", url: trashURL, iconName: "trash", section: .places))

        self.locations = loadedLocations
    }
}
