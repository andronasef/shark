import SwiftUI

public struct PlacesSidebarView: View {
    @Bindable var navigationState: NavigationState
    @State private var places: [SidebarItem] = []
    @State private var volumes: [SidebarItem] = []
    @State private var favorites: [SidebarItem] = []

    private let fileSystemService = FileSystemService.shared

    public init(navigationState: NavigationState) {
        self.navigationState = navigationState
    }

    public var body: some View {
        List {
            Section(header: Text("Places").font(.caption).foregroundColor(.secondary)) {
                ForEach(places) { item in
                    sidebarRow(for: item)
                }
            }

            Section(header: Text("Drives & Volumes").font(.caption).foregroundColor(.secondary)) {
                ForEach(volumes) { item in
                    sidebarRow(for: item)
                }
            }

            if !favorites.isEmpty {
                Section(header: Text("Favorites").font(.caption).foregroundColor(.secondary)) {
                    ForEach(favorites) { item in
                        sidebarRow(for: item)
                    }
                }
            }

            Section {
                let trashURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".Trash")
                let trashItem = SidebarItem(
                    name: "Trash",
                    url: trashURL,
                    iconName: "trash",
                    section: .system
                )
                sidebarRow(for: trashItem)
            }
        }
        .listStyle(.sidebar)
        .task {
            await loadSidebarItems()
        }
    }

    @ViewBuilder
    private func sidebarRow(for item: SidebarItem) -> some View {
        Button(action: {
            navigationState.navigateTo(item.url)
        }) {
            HStack(spacing: 8) {
                Image(systemName: item.iconName)
                    .foregroundColor(.accentColor)
                    .frame(width: 18)
                Text(item.name)
                    .lineLimit(1)
                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.vertical, 3)
        .padding(.horizontal, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(navigationState.currentURL.path == item.url.path ? Color.accentColor.opacity(0.18) : Color.clear)
        )
    }

    private func loadSidebarItems() async {
        places = await fileSystemService.standardPlaces()
        volumes = await fileSystemService.mountedVolumes()
    }
}
