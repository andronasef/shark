import SwiftUI
import AppKit

public struct DirectoryView: View {
    @Bindable var navigationState: NavigationState

    public init(navigationState: NavigationState) {
        self.navigationState = navigationState
    }

    public var body: some View {
        Group {
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
                    detailsList
                case .grid:
                    iconsGrid
                case .compact:
                    compactList
                }
            }
        }
        .task(id: navigationState.currentURL) {
            await navigationState.reloadCurrentDirectory()
        }
    }

    // MARK: - Details / Table View
    private var detailsList: some View {
        Table(navigationState.filteredAndSortedItems, selection: $navigationState.selectedItemIDs) {
            TableColumn("Name") { item in
                HStack(spacing: 8) {
                    Image(systemName: item.systemIconName)
                        .foregroundColor(item.isDirectory ? .accentColor : .primary)
                        .frame(width: 18)
                    Text(item.name)
                        .lineLimit(1)
                }
                .contentShape(Rectangle())
                .onTapGesture(count: 2) {
                    handleActivate(item)
                }
                .contextMenu {
                    contextMenu(for: item)
                }
            }
            .width(min: 180, ideal: 300)

            TableColumn("Size") { item in
                Text(item.formattedSize)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            .width(min: 80, ideal: 100)

            TableColumn("Date Modified") { item in
                Text(item.dateModified.formatted(date: .abbreviated, time: .shortened))
                    .foregroundColor(.secondary)
            }
            .width(min: 120, ideal: 160)

            TableColumn("Kind") { item in
                Text(item.kindDescription)
                    .foregroundColor(.secondary)
            }
            .width(min: 100, ideal: 140)

            TableColumn("Permissions") { item in
                Text(item.permissionsString)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            .width(min: 90, ideal: 110)
        }
    }

    // MARK: - Grid / Icons View
    private var iconsGrid: some View {
        ScrollView {
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: navigationState.iconSize, maximum: navigationState.iconSize + 40), spacing: 16)],
                spacing: 16
            ) {
                ForEach(navigationState.filteredAndSortedItems) { item in
                    let isSelected = navigationState.selectedItemIDs.contains(item.id)
                    VStack(spacing: 6) {
                        Image(systemName: item.systemIconName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: navigationState.iconSize * 0.55, height: navigationState.iconSize * 0.55)
                            .foregroundColor(item.isDirectory ? .accentColor : .primary)

                        Text(item.name)
                            .font(.system(size: 11))
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 4)
                    }
                    .frame(width: navigationState.iconSize + 20, height: navigationState.iconSize + 30)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 1.5)
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
            .padding()
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
