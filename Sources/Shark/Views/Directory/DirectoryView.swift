import SwiftUI
import AppKit

public struct DirectoryView: View {
    @Bindable var navigationState: NavigationState

    public init(navigationState: NavigationState) {
        self.navigationState = navigationState
    }

    public var body: some View {
        VStack(spacing: 0) {
            contentArea
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            statusBar
        }
        .task(id: navigationState.currentURL) {
            await navigationState.reloadCurrentDirectory()
        }
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
                        Image(systemName: item.systemIconName)
                            .foregroundColor(item.isDirectory ? .accentColor : .primary)
                            .frame(width: 16)
                        Text(item.name)
                            .lineLimit(1)
                        Spacer()
                        Text(item.formattedSize)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
                    )
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
            .padding(8)
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

        Button("Copy Path") {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(item.url.path, forType: .string)
        }

        Divider()

        Button(role: .destructive, action: {
            try? FileManager.default.trashItem(at: item.url, resultingItemURL: nil)
            Task { await navigationState.reloadCurrentDirectory() }
        }) {
            Label("Move to Trash", systemImage: "trash")
        }
    }
}
