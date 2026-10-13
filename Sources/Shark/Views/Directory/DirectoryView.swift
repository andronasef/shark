import SwiftUI
import AppKit

public struct DirectoryView: View {
    @Bindable var navigationState: NavigationState

    @State private var fseventsWatcher = FSEventsWatcher()
    @State private var showingNewItemSheet: NewItemType?
    @State private var showingBatchRenameSheet = false

    public init(navigationState: NavigationState) {
        self.navigationState = navigationState
    }

    public var body: some View {
        VStack(spacing: 0) {
            contentArea
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .dropDestination(for: URL.self) { urls, _ in
                    handleDrop(urls: urls)
                    return true
                }

            statusBar
        }
        .task(id: navigationState.currentURL) {
            await navigationState.reloadCurrentDirectory()
            setupFSEventsWatcher()
        }
        .onDisappear {
            fseventsWatcher.stop()
        }
        .sheet(item: $showingNewItemSheet) { itemType in
            NewItemSheet(
                type: itemType,
                parentURL: navigationState.currentURL,
                onCreated: {
                    Task { await navigationState.reloadCurrentDirectory() }
                }
            )
        }
        .sheet(isPresented: $showingBatchRenameSheet) {
            let selectedItems = navigationState.items.filter { navigationState.selectedItemIDs.contains($0.id) }
            BatchRenameSheet(
                items: selectedItems,
                onRenameComplete: {
                    Task { await navigationState.reloadCurrentDirectory() }
                }
            )
        }
        .contextMenu {
            directoryBackgroundContextMenu
        }
    }

    private func setupFSEventsWatcher() {
        fseventsWatcher.stop()
        fseventsWatcher.onChange = { [weak navigationState] in
            Task { @MainActor in
                await navigationState?.reloadCurrentDirectory()
            }
        }
        fseventsWatcher.watch(url: navigationState.currentURL)
    }

    // MARK: - Main Content Area
    @ViewBuilder
    private var contentArea: some View {
        if navigationState.isLoading && navigationState.items.isEmpty {
            VStack(spacing: 12) {
                ProgressView()
                Text("Loading directory...")
                    .foregroundColor(.secondary)
                    .font(.callout)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let error = navigationState.errorMessage {
            VStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.orange)
                Text("Unable to open directory")
                    .font(.headline)
                Text(error)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                Button("Try Again") {
                    Task { await navigationState.reloadCurrentDirectory() }
                }
                .buttonStyle(.borderedProminent)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if navigationState.filteredAndSortedItems.isEmpty {
            VStack(spacing: 8) {
                Image(systemName: "folder")
                    .font(.system(size: 40))
                    .foregroundColor(.secondary.opacity(0.5))
                Text(navigationState.filterText.isEmpty ? "Folder is Empty" : "No Matching Items")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            switch navigationState.viewMode {
            case .details:
                DetailsTableView(
                    navigationState: navigationState,
                    onActivate: handleActivate,
                    contextMenu: contextMenu
                )
            case .grid:
                IconsGridView(
                    navigationState: navigationState,
                    onActivate: handleActivate,
                    contextMenu: contextMenu
                )
            case .compact:
                compactList
            case .gallery:
                galleryView
            }
        }
    }

    // MARK: - Compact List View
    private var compactList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 2) {
                ForEach(navigationState.filteredAndSortedItems) { item in
                    let isSelected = navigationState.selectedItemIDs.contains(item.id)
                    HStack(spacing: 8) {
                        Image(nsImage: NSWorkspace.shared.icon(forFile: item.url.path))
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 16, height: 16)
                        Text(item.name)
                            .font(.system(size: 12))
                            .foregroundColor(isSelected ? .white : .primary)
                            .lineLimit(1)
                        Spacer()
                        Text(item.formattedSize)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(isSelected ? Color.accentColor : Color.clear)
                    )
                    .contentShape(Rectangle())
                    .draggable(item.url)
                    .onTapGesture {
                        navigationState.selectedItemIDs = [item.id]
                    }
                    .onTapGesture(count: 2) {
                        handleActivate(item)
                    }
                    .contextMenu {
                        contextMenu(for: item)
                    }
                }
            }
            .padding(8)
        }
    }

    // MARK: - Gallery View
    private var galleryView: some View {
        VStack(spacing: 0) {
            let selectedItem = navigationState.filteredAndSortedItems.first { navigationState.selectedItemIDs.contains($0.id) }
                ?? navigationState.filteredAndSortedItems.first

            // Hero Preview Area
            if let item = selectedItem {
                VStack(spacing: 12) {
                    Spacer()
                    Image(nsImage: NSWorkspace.shared.icon(forFile: item.url.path))
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: 180, maxHeight: 180)
                        .shadow(color: .black.opacity(0.2), radius: 6, y: 3)

                    Text(item.name)
                        .font(.headline)
                        .lineLimit(1)

                    Text("\(item.kindDescription) • \(item.formattedSize)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(nsColor: .windowBackgroundColor).opacity(0.4))
            }

            Divider()

            // Horizontal Filmstrip
            ScrollView(.horizontal, showsIndicators: true) {
                LazyHStack(spacing: 12) {
                    ForEach(navigationState.filteredAndSortedItems) { item in
                        let isSelected = navigationState.selectedItemIDs.contains(item.id)
                        VStack(spacing: 4) {
                            Image(nsImage: NSWorkspace.shared.icon(forFile: item.url.path))
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 48, height: 48)

                            Text(item.name)
                                .font(.system(size: 10, weight: isSelected ? .medium : .regular))
                                .foregroundColor(isSelected ? .white : .primary)
                                .lineLimit(1)
                                .frame(width: 60)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(isSelected ? Color.accentColor : Color.clear)
                                )
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            navigationState.selectedItemIDs = [item.id]
                        }
                        .onTapGesture(count: 2) {
                            handleActivate(item)
                        }
                        .contextMenu {
                            contextMenu(for: item)
                        }
                    }
                }
                .padding(10)
            }
            .frame(height: 90)
        }
    }

    // MARK: - Dolphin Status Bar
    private var statusBar: some View {
        HStack(spacing: 12) {
            let total = navigationState.items.count
            let filtered = navigationState.filteredAndSortedItems.count
            let selected = navigationState.selectedItemIDs.count

            HStack(spacing: 6) {
                if !navigationState.filterText.isEmpty {
                    Text("\(filtered) of \(total) items")
                } else {
                    Text("\(total) items")
                }

                if selected > 0 {
                    Text("(\(selected) selected)")
                        .foregroundColor(.accentColor)
                }
            }
            .font(.system(size: 11))
            .foregroundColor(.secondary)

            Spacer()

            if navigationState.viewMode == .grid {
                HStack(spacing: 6) {
                    Image(systemName: "photo")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)

                    Slider(value: $navigationState.iconSize, in: 48...192, step: 8)
                        .frame(width: 100)

                    Image(systemName: "photo.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.6))
        .overlay(Divider(), alignment: .top)
    }

    // MARK: - Actions
    private func handleActivate(_ item: FileItem) {
        if item.isNavigableDirectory {
            navigationState.navigateTo(item.url)
        } else {
            NSWorkspace.shared.open(item.url)
        }
    }

    private func handleDrop(urls: [URL]) {
        let destination = navigationState.currentURL
        Task {
            try? await FileOperationsService.shared.copy(items: urls, to: destination)
            await navigationState.reloadCurrentDirectory()
        }
    }

    @ViewBuilder
    private func contextMenu(for item: FileItem) -> some View {
        Button("Open") {
            handleActivate(item)
        }

        Button("Quick Look") {
            QuickLookCoordinator.shared.toggleQuickLook(for: [item.url])
        }

        Button("Show in Finder") {
            NSWorkspace.shared.activateFileViewerSelecting([item.url])
        }

        Divider()

        Button("Duplicate") {
            Task {
                try? await FileOperationsService.shared.duplicate(items: [item.url])
                await navigationState.reloadCurrentDirectory()
            }
        }

        if navigationState.selectedItemIDs.count > 1 {
            Button("Batch Rename...") {
                showingBatchRenameSheet = true
            }
        }

        Button("Copy Path") {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(item.url.path, forType: .string)
        }

        Divider()

        Button("Move to Trash", role: .destructive) {
            Task {
                try? await FileOperationsService.shared.trash(items: [item.url])
                await navigationState.reloadCurrentDirectory()
            }
        }
    }

    @ViewBuilder
    private var directoryBackgroundContextMenu: some View {
        Button("New Folder") {
            showingNewItemSheet = .folder
        }

        Button("New File") {
            showingNewItemSheet = .file
        }

        Divider()

        Button("Reload") {
            Task {
                await navigationState.reloadCurrentDirectory()
            }
        }

        Button("Show Hidden Files") {
            navigationState.showHiddenFiles.toggle()
        }

        Divider()

        Button("Copy Path") {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(navigationState.currentURL.path, forType: .string)
        }
    }
}
