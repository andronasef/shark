import SwiftUI
import AppKit
import Inject

public struct PlacesSidebarView: View {
    @ObserveInjection var inject
    @Bindable var navigationState: NavigationState
    @Environment(WorkspaceState.self) private var workspace: WorkspaceState?
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @State private var favoritesStore = SidebarFavoritesStore.shared
    @FocusState private var sidebarFocus: String?
    @State private var hoveredRow: String?
    @State private var dropTargetRow: String?
    @State private var locations: [SidebarItem] = Self.standardLocations

    private let fileSystemService = FileSystemService.shared

    public init(navigationState: NavigationState) {
        self.navigationState = navigationState
    }

    private let tagItems: [(name: String, color: Color)] = [
        ("Red", Color(red: 1.0, green: 0.23, blue: 0.19)),
        ("Orange", Color(red: 1.0, green: 0.58, blue: 0.0)),
        ("Yellow", Color(red: 1.0, green: 0.9, blue: 0.12)),
        ("Green", Color(red: 0.2, green: 0.9, blue: 0.34)),
        ("Blue", Color(red: 0.0, green: 0.48, blue: 1.0)),
        ("Purple", Color(red: 0.82, green: 0.36, blue: 0.96)),
        ("Gray", Color(red: 0.56, green: 0.56, blue: 0.58))
    ]

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Standalone top items (Recents, Shared)
                VStack(spacing: 0) {
                    sidebarRow(
                        name: "Recents",
                        iconName: "clock",
                        url: FileManager.default.homeDirectoryForCurrentUser
                    )
                    sidebarRow(
                        name: "Shared",
                        iconName: "folder.badge.person.crop",
                        url: URL(fileURLWithPath: "/Users/Shared")
                    )
                }

                // Favorites section
                SidebarSectionGroup("Favorites", focus: $sidebarFocus, onDropFolders: { urls in
                    favoritesStore.insert(urls, at: favoritesStore.items.count)
                }) {
                    favoriteInsertion(at: 0)
                    ForEach(Array(favoritesStore.items.enumerated()), id: \.element.id) { index, item in
                        sidebarRow(
                            name: item.name,
                            iconName: item.iconName,
                            url: item.url,
                            favorite: item
                        )
                        .draggable(FavoriteShortcutTransfer(url: item.url))
                        favoriteInsertion(at: index + 1)
                    }
                    Button { addFavorite() } label: {
                        Label("Add Favorite…", systemImage: "plus")
                            .font(.system(size: 12))
                            .frame(maxWidth: .infinity, minHeight: 28, alignment: .leading)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .focusable()
                    .focused($sidebarFocus, equals: "Favorites:add")
                    .onKeyPress(.space) { addFavorite(); return .handled }
                    .onKeyPress(.return) { addFavorite(); return .handled }
                    .modifier(SidebarRowFeedback(isFocused: sidebarFocus == "Favorites:add"))
                }

                // Tab Groups section
                if !TabGroupService.shared.groups.isEmpty {
                    SidebarSectionGroup("Tab Groups", focus: $sidebarFocus) {
                        ForEach(TabGroupService.shared.groups) { group in
                            Button(action: {
                                if let ws = workspace {
                                    TabGroupService.shared.restore(group: group, into: ws, replace: false)
                                }
                            }) {
                                HStack(spacing: 10) {
                                    Image(systemName: "square.grid.2x2")
                                        .font(.system(size: 17))
                                        .foregroundStyle(.primary)
                                        .frame(width: 22)
                                    Text(group.name)
                                        .font(.system(size: 14))
                                        .lineLimit(1)
                                    Spacer()
                                    Text("\(group.tabs.count)")
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)
                                }
                                .frame(height: 32)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .focusable()
                            .focused($sidebarFocus, equals: "Tab Groups:" + group.id.uuidString)
                            .onKeyPress(.space) {
                                if let workspace { TabGroupService.shared.restore(group: group, into: workspace, replace: false) }
                                return .handled
                            }
                            .onKeyPress(.return) {
                                if let workspace { TabGroupService.shared.restore(group: group, into: workspace, replace: false) }
                                return .handled
                            }
                            .padding(.horizontal, 10)
                            .modifier(SidebarRowFeedback(isFocused: sidebarFocus == "Tab Groups:" + group.id.uuidString))
                            .contextMenu {
                                Button("Restore (Replace All)") {
                                    if let ws = workspace {
                                        TabGroupService.shared.restore(group: group, into: ws, replace: true)
                                    }
                                }
                                Button("Append Tabs") {
                                    if let ws = workspace {
                                        TabGroupService.shared.restore(group: group, into: ws, replace: false)
                                    }
                                }
                                Divider()
                                Button("Delete Group", role: .destructive) {
                                    TabGroupService.shared.deleteGroup(id: group.id)
                                }
                            }
                        }
                    }
                }



                // Locations section
                SidebarSectionGroup("Locations", focus: $sidebarFocus) {
                    ForEach(locations) { item in
                        sidebarRow(
                            name: item.name,
                            iconName: item.iconName,
                            url: item.url
                            )
                    }
                }

                // Tags section
                SidebarSectionGroup("Tags", focus: $sidebarFocus) {
                    ForEach(tagItems, id: \.name) { tag in
                        Button(action: {
                            navigationState.filterText = tag.name
                        }) {
                            HStack(spacing: 10) {
                                Circle()
                                    .fill(tag.color)
                                    .frame(width: 13, height: 13)
                                    .frame(width: 22)
                                Text(tag.name)
                                    .font(.system(size: 14))
                                Spacer()
                            }
                            .frame(height: 32)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .focusable()
                        .focused($sidebarFocus, equals: "Tags:" + tag.name)
                        .onKeyPress(.space) { navigationState.filterText = tag.name; return .handled }
                        .onKeyPress(.return) { navigationState.filterText = tag.name; return .handled }
                        .padding(.horizontal, 10)
                        .modifier(SidebarRowFeedback(isFocused: sidebarFocus == "Tags:" + tag.name))
                    }

                    Button(action: {}) {
                        HStack(spacing: 10) {
                            HStack(spacing: -6) {
                                Circle().stroke(lineWidth: 1.4)
                                Circle().stroke(lineWidth: 1.4)
                            }
                            .frame(width: 18, height: 12)
                            .frame(width: 22)
                            .accessibilityHidden(true)
                            Text("All Tags...")
                                .font(.system(size: 14))
                                .foregroundColor(.primary)
                            Spacer()
                        }
                        .frame(height: 32)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .focusable()
                    .focused($sidebarFocus, equals: "Tags:all")
                    .padding(.horizontal, 10)
                    .modifier(SidebarRowFeedback(isFocused: sidebarFocus == "Tags:all"))
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 9)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .background {
            sidebarBackdrop
                .padding(.horizontal, 6)
                .padding(.bottom, 6)
                .padding(.top, 4)
                .ignoresSafeArea(edges: .top)
                .allowsHitTesting(false)
        }
        .task {
            await loadSidebarItems()
        }
        .onKeyPress(.downArrow) { moveSidebarFocus(by: 1); return .handled }
        .onKeyPress(.upArrow) { moveSidebarFocus(by: -1); return .handled }
        .onChange(of: sidebarFocus) { _, focus in
            workspace?.sidebarHasKeyboardFocus = focus != nil
        }
        .onDisappear { workspace?.sidebarHasKeyboardFocus = false }
        .enableInjection()
    }

    private var sidebarBackdrop: some View {
        let shape = RoundedRectangle(cornerRadius: 20, style: .continuous)
        return shape
            .fill(reduceTransparency ? AnyShapeStyle(Color(nsColor: .windowBackgroundColor)) : AnyShapeStyle(.ultraThinMaterial))
            .overlay {
                if colorScheme == .dark {
                    shape.fill(
                        LinearGradient(
                            colors: [Color(red: 0.05, green: 0.16, blue: 0.22).opacity(0.5), Color(red: 0.08, green: 0.11, blue: 0.11).opacity(0.65)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
            }
            .overlay {
                shape.strokeBorder(
                    LinearGradient(
                        colors: [Color.accentColor.opacity(0.55), Color.primary.opacity(0.12), Color.primary.opacity(0.18)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 0.75
                )
            }
    }

    @ViewBuilder
    private func sidebarRow(
        name: String,
        iconName: String,
        url: URL,
        favorite: SidebarFavorite? = nil
    ) -> some View {
        let section = favorite != nil ? "Favorites" : (name == "Recents" || name == "Shared" ? "Top" : "Locations")
        let rowID = "\(section):\(url.path)"
        let available = favorite?.isAvailable ?? true
        let isAncestor = favorite != nil && SidebarFavoritesStore.contains(url, currentFolder: navigationState.currentURL)
        let isSelected = name != "Recents" && navigationState.currentURL.standardizedFileURL.path == url.standardizedFileURL.path

        let activate = {
            sidebarFocus = rowID
            guard available else {
                if let favorite { locateFavorite(favorite) }
                return
            }
            let isCmd = NSEvent.modifierFlags.contains(.command)
            if let workspace {
                workspace.open(url, from: navigationState, newTab: isCmd)
            } else {
                navigationState.navigateTo(url)
            }
        }

        Button(action: activate) {
            HStack(spacing: 10) {
                Group {
                    if name == "Applications" {
                        Path { path in
                            path.move(to: CGPoint(x: 8, y: 3))
                            path.addLine(to: CGPoint(x: 17, y: 19))
                            path.move(to: CGPoint(x: 13, y: 3))
                            path.addLine(to: CGPoint(x: 4, y: 19))
                            path.move(to: CGPoint(x: 3, y: 14))
                            path.addLine(to: CGPoint(x: 19, y: 14))
                        }
                        .stroke(style: StrokeStyle(lineWidth: 2, lineCap: .round))
                        .frame(width: 22, height: 22)
                    } else if name == "AirDrop" {
                        Path { path in
                            for radius in [9.0, 6.0, 3.0] {
                                for degree in stride(from: 130.0, through: 410.0, by: 5) {
                                    let angle = degree * .pi / 180
                                    let point = CGPoint(x: 11 + radius * cos(angle), y: 10 + radius * sin(angle))
                                    if degree == 130 { path.move(to: point) }
                                    else { path.addLine(to: point) }
                                }
                            }
                            path.move(to: CGPoint(x: 11, y: 11))
                            path.addLine(to: CGPoint(x: 5, y: 21))
                            path.addLine(to: CGPoint(x: 17, y: 21))
                            path.closeSubpath()
                        }
                        .stroke(style: StrokeStyle(lineWidth: 1.3, lineCap: .round, lineJoin: .round))
                        .frame(width: 22, height: 22)
                    } else if name == "Desktop" {
                        RoundedRectangle(cornerRadius: 2)
                            .stroke(lineWidth: 1.4)
                            .overlay(alignment: .top) {
                                Rectangle().frame(height: 1.4).padding(.top, 4)
                            }
                            .frame(width: 18, height: 14)
                            .frame(width: 22, height: 22)
                    } else {
                        Image(systemName: iconName)
                            .font(.system(size: 17, weight: .regular))
                            .frame(width: 22)
                    }
                }
                .foregroundStyle(.primary)
                .accessibilityHidden(true)

                Text(name)
                    .font(.system(size: 14, weight: isSelected ? .medium : .regular))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Spacer()
                if !available {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .accessibilityLabel("Folder unavailable")
                } else if isAncestor && !isSelected {
                    Circle().fill(Color.accentColor.opacity(0.7)).frame(width: 5, height: 5)
                        .accessibilityLabel("Contains current folder")
                }
            }
            .opacity(available ? 1 : 0.55)
            .frame(height: 32)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.primary.opacity(isSelected ? 0.09 : hoveredRow == rowID ? 0.045 : 0))
        )
        .overlay {
            if dropTargetRow == rowID {
                RoundedRectangle(cornerRadius: 6).strokeBorder(Color.accentColor, lineWidth: 2)
                    .background(Color.accentColor.opacity(0.08))
            }
            if sidebarFocus == rowID {
                RoundedRectangle(cornerRadius: 6).strokeBorder(Color.accentColor, lineWidth: 1.5)
            }
        }
        .focusable()
        .focusEffectDisabled()
        .focused($sidebarFocus, equals: rowID)
        .onKeyPress(.space) { activate(); return .handled }
        .onKeyPress(.return) { activate(); return .handled }
        .onHover { hoveredRow = $0 ? rowID : nil }
        .onKeyPress(.leftArrow) {
            guard section != "Top" else { return .ignored }
            sidebarFocus = "\(section):header"
            return .handled
        }
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .help(available ? url.path : "Folder unavailable. Click to locate it.")
        .onMiddleClick {
            guard available else { return }
            workspace?.open(url, from: navigationState, newTab: true)
        }
        .contextMenu {
            Button("Open in New Tab") {
                workspace?.open(url, from: navigationState, newTab: true)
            }
            .disabled(!available)
            Button("Show in Finder") { NSWorkspace.shared.activateFileViewerSelecting([url]) }
                .disabled(!available)
            if let favorite {
                Button("Locate Folder…") { locateFavorite(favorite) }
                Divider()
                Button("Remove from Favorites") { favoritesStore.remove(favorite.id) }
            }
        }
        .dropDestination(for: URL.self) { urls, _ in
            guard available else { return false }
            let isAltHeld = NSEvent.modifierFlags.contains(.option)
            Task {
                do {
                    if isAltHeld {
                        try await FileOperationsService.shared.copy(items: urls, to: url)
                    } else {
                        try await FileOperationsService.shared.move(items: urls, to: url)
                    }
                } catch { NSAlert(error: error).runModal() }
                if navigationState.currentURL.standardizedFileURL.path == url.standardizedFileURL.path {
                    await navigationState.reloadCurrentDirectory()
                }
            }
            return true
        } isTargeted: { targeted in
            dropTargetRow = targeted ? rowID : nil
        }
    }

    private func moveSidebarFocus(by offset: Int) {
        var order = ["Top:" + FileManager.default.homeDirectoryForCurrentUser.path, "Top:/Users/Shared"]
        func expanded(_ section: String) -> Bool {
            UserDefaults.standard.object(forKey: "sidebar.section.\(section).expanded") as? Bool ?? true
        }
        order.append("Favorites:header")
        if expanded("Favorites") {
            order += favoritesStore.items.map { "Favorites:" + $0.url.path }
            order.append("Favorites:add")
        }
        if !TabGroupService.shared.groups.isEmpty {
            order.append("Tab Groups:header")
            if expanded("Tab Groups") { order += TabGroupService.shared.groups.map { "Tab Groups:" + $0.id.uuidString } }
        }
        order.append("Locations:header")
        if expanded("Locations") { order += locations.map { "Locations:" + $0.url.path } }
        order.append("Tags:header")
        if expanded("Tags") {
            order += tagItems.map { "Tags:" + $0.name }
            order.append("Tags:all")
        }
        let current = sidebarFocus.flatMap { order.firstIndex(of: $0) } ?? (offset > 0 ? -1 : order.count)
        sidebarFocus = order[max(0, min(current + offset, order.count - 1))]
    }

    private func favoriteInsertion(at index: Int) -> some View {
        FavoriteInsertionTarget { urls in favoritesStore.insert(urls, at: index) }
    }

    private func addFavorite() {
        let panel = NSOpenPanel()
        panel.title = "Add Folder to Favorites"
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = true
        panel.prompt = "Add"
        panel.begin { response in
            if response == .OK { _ = favoritesStore.insert(panel.urls, at: favoritesStore.items.count) }
        }
    }

    private func locateFavorite(_ favorite: SidebarFavorite) {
        let panel = NSOpenPanel()
        panel.title = "Locate \(favorite.name)"
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.prompt = "Choose"
        panel.begin { response in
            if response == .OK, let url = panel.url { favoritesStore.relocate(favorite.id, to: url) }
        }
    }

    private static var standardLocations: [SidebarItem] {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return [
            SidebarItem(name: "iCloud Drive", url: home.appendingPathComponent("Library/Mobile Documents/com~apple~CloudDocs"), iconName: "icloud", section: .places),
            SidebarItem(name: home.lastPathComponent, url: home, iconName: "house", section: .places),
            SidebarItem(name: "Macintosh HD", url: URL(fileURLWithPath: "/"), iconName: "internaldrive", section: .places),
            SidebarItem(name: "AirDrop", url: URL(fileURLWithPath: "/System/Library/CoreServices/Finder.app"), iconName: "airdrop", section: .places),
            SidebarItem(name: "Trash", url: home.appendingPathComponent(".Trash"), iconName: "trash", section: .places)
        ]
    }

    private func loadSidebarItems() async {
        // Render standard places immediately; volume discovery may wait on filesystem work.
        let mounted = await fileSystemService.mountedVolumes()
        guard !Task.isCancelled else { return }
        var updated = Self.standardLocations
        updated.insert(contentsOf: mounted.filter { $0.url.path != "/" }, at: updated.count - 1)
        locations = updated
    }

}
