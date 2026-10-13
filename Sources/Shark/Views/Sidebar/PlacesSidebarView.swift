import SwiftUI

public struct PlacesSidebarView: View {
    @Bindable var navigationState: NavigationState
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
            Section(header: Text("Favorites").font(.caption).fontWeight(.semibold).foregroundColor(.secondary)) {
                ForEach(favorites) { item in
                    sidebarRow(
                        name: item.name,
                        iconName: item.iconName,
                        url: item.url,
                        iconColor: .secondary
                    )
                }
            }

            // Locations section
            Section(header: Text("Locations").font(.caption).fontWeight(.semibold).foregroundColor(.secondary)) {
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
            Section(header: Text("Tags").font(.caption).fontWeight(.semibold).foregroundColor(.secondary)) {
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
            navigationState.navigateTo(url)
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
        let fm = FileManager.default
        let home = fm.homeDirectoryForCurrentUser

        // Favorites
        var favs: [SidebarItem] = []

        // Projects (check if exists, else Dev or Documents)
        let projectsURL = home.appendingPathComponent("Documents/Work/Dev/Projects")
        if fm.fileExists(atPath: projectsURL.path) {
            favs.append(SidebarItem(name: "Projects", url: projectsURL, iconName: "folder", section: .places))
        }

        // Applications
        if let appURL = fm.urls(for: .applicationDirectory, in: .localDomainMask).first {
            favs.append(SidebarItem(name: "Applications", url: appURL, iconName: "app.badge", section: .places))
        }

        // Desktop
        if let deskURL = fm.urls(for: .desktopDirectory, in: .userDomainMask).first {
            favs.append(SidebarItem(name: "Desktop", url: deskURL, iconName: "menubar.dock.rectangle", section: .places))
        }

        // Documents
        if let docURL = fm.urls(for: .documentDirectory, in: .userDomainMask).first {
            favs.append(SidebarItem(name: "Documents", url: docURL, iconName: "doc.text", section: .places))
        }

        // Downloads
        if let dlURL = fm.urls(for: .downloadsDirectory, in: .userDomainMask).first {
            favs.append(SidebarItem(name: "Downloads", url: dlURL, iconName: "arrow.down.circle", section: .places))
        }

        self.favorites = favs

        // Locations
        var locs: [SidebarItem] = []

        // iCloud Drive
        let iCloudURL = home.appendingPathComponent("Library/Mobile Documents/com~apple~CloudDocs")
        locs.append(SidebarItem(name: "iCloud Drive", url: iCloudURL, iconName: "cloud", section: .places))

        // User Home
        locs.append(SidebarItem(name: home.lastPathComponent, url: home, iconName: "house", section: .places))

        // Macintosh HD (Root)
        locs.append(SidebarItem(name: "Macintosh HD", url: URL(fileURLWithPath: "/"), iconName: "internaldrive", section: .volumes))

        // AirDrop
        let airdropURL = URL(fileURLWithPath: "/System/Library/CoreServices/Finder.app")
        locs.append(SidebarItem(name: "AirDrop", url: airdropURL, iconName: "radiowaves.right", section: .places))

        // Mounted volumes
        let extraVolumes = await fileSystemService.mountedVolumes()
        for vol in extraVolumes where vol.url.path != "/" {
            locs.append(vol)
        }

        // Trash
        let trashURL = home.appendingPathComponent(".Trash")
        locs.append(SidebarItem(name: "Trash", url: trashURL, iconName: "trash", section: .system))

        self.locations = locs
    }
}
