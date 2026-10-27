import SwiftUI
import SwiftTerm
import AppKit

public struct MillerColumnsView: View {
    @Environment(WorkspaceState.self) private var workspace: WorkspaceState?
    let navigationState: NavigationState
    let onActivate: (FileItem) -> Void
    let contextMenuBuilder: (FileItem) -> AnyView

    @State private var owningWindowNumber: Int?
    @State private var coordinator = MillerColumnsCoordinator()
    @State private var eventMonitor: Any?

    public init(
        navigationState: NavigationState,
        onActivate: @escaping (FileItem) -> Void,
        @ViewBuilder contextMenu: @escaping (FileItem) -> some View
    ) {
        self.navigationState = navigationState
        self.onActivate = onActivate
        self.contextMenuBuilder = { item in AnyView(DeferredMenu { contextMenu(item) }) }
    }

    public var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: true) {
                HStack(alignment: .top, spacing: 0) {
                    ForEach(Array(coordinator.columns.enumerated()), id: \.element.id) { index, column in
                        columnView(column: column, columnIndex: index)
                            .id("column-\(index)")

                        Divider()
                    }

                    if let preview = coordinator.previewItem {
                        columnPreviewView(item: preview)
                            .id("column-preview")
                    }
                }
            }
            .background(Color(NSColor.controlBackgroundColor))
            .onChange(of: coordinator.columns.count) { _, newCount in
                withAnimation(.easeOut(duration: 0.2)) {
                    if coordinator.previewItem != nil {
                        proxy.scrollTo("column-preview", anchor: .trailing)
                    } else {
                        proxy.scrollTo("column-\(newCount - 1)", anchor: .trailing)
                    }
                }
            }
            .onChange(of: coordinator.previewItem?.id) { _, _ in
                if coordinator.previewItem != nil {
                    withAnimation(.easeOut(duration: 0.2)) {
                        proxy.scrollTo("column-preview", anchor: .trailing)
                    }
                }
            }
        }
        .background(WindowNumberReader { owningWindowNumber = $0 })
        .onAppear {
            coordinator.reset(rootDirectory: navigationState.currentURL, items: navigationState.filteredAndSortedItems,
                              showHidden: navigationState.showHiddenFiles)
            setupKeyMonitor()
        }
        .onDisappear {
            coordinator.cancelLoads()
            removeKeyMonitor()
        }
        .onChange(of: navigationState.currentURL) { _, newURL in
            if coordinator.columns.first?.directoryURL != newURL {
                coordinator.reset(rootDirectory: newURL, items: [], showHidden: navigationState.showHiddenFiles)
            }
        }
        .onChange(of: navigationState.showHiddenFiles) { _, hidden in
            coordinator.updateRoot(items: navigationState.filteredAndSortedItems, showHidden: hidden)
        }
        .onChange(of: navigationState.filteredAndSortedItems) { _, items in
            coordinator.updateRoot(items: items, showHidden: navigationState.showHiddenFiles)
        }
    }

    // MARK: - Single Column View
    @ViewBuilder
    private func columnView(column: MillerColumn, columnIndex: Int) -> some View {
        VStack(spacing: 0) {
            if column.isLoading {
                VStack {
                    Spacer()
                    ProgressView()
                        .scaleEffect(0.8)
                    Text(L10n.text("Loading..."))
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                    Spacer()
                }
                .frame(width: 240)
            } else if column.items.isEmpty {
                VStack {
                    Spacer()
                    Text(L10n.text("Empty"))
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .frame(width: 240)
            } else {
                ScrollView {
                    LazyVStack(spacing: 1) {
                        ForEach(column.items) { item in
                            let isSelected = column.selectedURL == item.url
                            let isActiveColumn = coordinator.activeColumnIndex == columnIndex

                            HStack(spacing: 6) {
                                FileItemIconView(item: item, size: 16)
                                    .frame(width: 16, height: 16)

                                Text(item.name)
                                    .font(.system(size: 12))
                                    .lineLimit(1)
                                    .foregroundColor(isSelected ? .white : .primary)

                                Spacer()

                                if item.isDirectory {
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary.opacity(0.6))
                                }
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(
                                        isSelected
                                            ? (isActiveColumn ? Color.accentColor : Color.secondary.opacity(0.3))
                                            : Color.clear
                                    )
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                coordinator.selectItem(item, inColumn: columnIndex)
                                navigationState.selectedItemIDs = [item.url]
                            }
                            .simultaneousGesture(
                                TapGesture(count: 2).onEnded {
                                    onActivate(item)
                                }
                            )
                            .fileDragSource(item: item, navigationState: navigationState, orderedItems: column.items)
                            .onRightClickSelect {
                                navigationState.selectedItemIDs = [item.url]
                            }
                            .dropDestination(for: URL.self) { urls, _ in
                                guard item.isNavigableDirectory else { return false }
                                let modifiers = NSEvent.modifierFlags
                                Task { await navigationState.drop(urls, into: item.url, modifiers: modifiers) }
                                return true
                            }
                            .contextMenu {
                                contextMenuBuilder(item)
                            }
                            .fileHoverPreview(item, isRenaming: navigationState.renamingItemURL == item.url)
                        }
                    }
                    .padding(4)
                }
                .frame(width: 240)
            }
        }
        .frame(minHeight: 300, maxHeight: .infinity)
    }

    // MARK: - Column Preview Pane (Leaf File)
    @ViewBuilder
    private func columnPreviewView(item: FileItem) -> some View {
        VStack(spacing: 16) {
            // Big preview icon
            FileItemIconView(item: item, size: 80)
                .frame(width: 80, height: 80)
                .padding(.top, 24)

            // Name & Kind
            VStack(spacing: 4) {
                Text(item.name)
                    .font(.system(size: 14, weight: .semibold))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)

                Text(item.kindDescription.isEmpty ? (item.isDirectory ? L10n.text("Folder") : L10n.text("Document")) : item.kindDescription)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)

            Divider()
                .padding(.horizontal, 16)

            // Metadata Grid
            VStack(alignment: .leading, spacing: 8) {
                metadataRow(label: L10n.text("Size"), value: item.formattedSize)
                metadataRow(label: L10n.text("Modified"), value: formatDate(item.dateModified))
                metadataRow(label: L10n.text("Created"), value: formatDate(item.dateCreated))
                metadataRow(label: L10n.text("Permissions"), value: String(format: "%o", item.posixPermissions))
                metadataRow(label: L10n.text("Where"), value: item.url.deletingLastPathComponent().path)
            }
            .font(.system(size: 11))
            .padding(.horizontal, 16)

            Spacer()

            // Quick Actions
            HStack(spacing: 12) {
                Button(action: {
                    QuickLookCoordinator.shared.toggleQuickLook(for: [item.url])
                }) {
                    Label(L10n.text("Quick Look"), systemImage: "eye")
                        .font(.system(size: 11))
                }
                .buttonStyle(.bordered)

                Button(action: {
                    onActivate(item)
                }) {
                    Label(L10n.text("Open"), systemImage: "arrow.up.forward.app")
                        .font(.system(size: 11))
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.bottom, 24)
        }
        .frame(width: 280)
        .background(Color(NSColor.windowBackgroundColor).opacity(0.5))
    }

    private func metadataRow(label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(label)
                .foregroundColor(.secondary)
                .frame(width: 75, alignment: .trailing)
            Text(value)
                .foregroundColor(.primary)
                .lineLimit(2)
                .truncationMode(.middle)
            Spacer()
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    // MARK: - Keyboard Handling
    private func setupKeyMonitor() {
        guard eventMonitor == nil else { return }
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [self] event in
            guard workspace?.sidebarHasKeyboardFocus != true, workspace?.isCommandPalettePresented != true else { return event }
            guard workspace == nil || workspace?.activeNavigationState === navigationState,
                  event.modifierFlags.intersection([.command, .option, .control]).isEmpty else { return event }
            // Don't intercept if user is typing in a text field
            if let responder = NSApp.keyWindow?.firstResponder,
               responder is NSTextView || responder is NSTextField || responder is SwiftTerm.TerminalView {
                return event
            }

            switch event.keyCode {
            case 126: // Up Arrow
                coordinator.moveSelection(by: -1)
                return nil
            case 125: // Down Arrow
                coordinator.moveSelection(by: 1)
                return nil
            case 123: // Left Arrow
                coordinator.navigateLeft()
                return nil
            case 124: // Right Arrow
                coordinator.navigateRight()
                return nil
            default:
                return event
            }
        }
    }

    private func removeKeyMonitor() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }
}
