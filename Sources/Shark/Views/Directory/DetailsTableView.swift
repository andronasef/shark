import SwiftUI
import AppKit

public struct DetailsTableView: View {
    @Bindable var navigationState: NavigationState
    let onActivate: (FileItem) -> Void
    let contextMenuBuilder: (FileItem) -> AnyView

    public init(
        navigationState: NavigationState,
        onActivate: @escaping (FileItem) -> Void,
        @ViewBuilder contextMenu: @escaping (FileItem) -> some View
    ) {
        self.navigationState = navigationState
        self.onActivate = onActivate
        self.contextMenuBuilder = { AnyView(contextMenu($0)) }
    }

    public var body: some View {
        Table(
            navigationState.filteredAndSortedItems,
            selection: $navigationState.selectedItemIDs,
            sortOrder: Binding(
                get: { [keyPathComparator] },
                set: { newOrder in
                    handleSortChange(newOrder)
                }
            )
        ) {
            TableColumn("Name", value: \.name) { item in
                HStack(spacing: 8) {
                    Image(systemName: item.systemIconName)
                        .foregroundColor(item.isDirectory ? .accentColor : .primary)
                        .frame(width: 18)
                    Text(item.name)
                        .lineLimit(1)
                }
                .contentShape(Rectangle())
                .onTapGesture(count: 2) {
                    onActivate(item)
                }
                .contextMenu {
                    contextMenuBuilder(item)
                }
            }
            .width(min: 200, ideal: 320)

            TableColumn("Size", value: \.fileSize) { item in
                Text(item.formattedSize)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            .width(min: 80, ideal: 100)

            TableColumn("Date Modified", value: \.dateModified) { item in
                Text(item.dateModified.formatted(date: .abbreviated, time: .shortened))
                    .foregroundColor(.secondary)
            }
            .width(min: 130, ideal: 160)

            TableColumn("Kind", value: \.kindDescription) { item in
                Text(item.kindDescription)
                    .foregroundColor(.secondary)
            }
            .width(min: 100, ideal: 140)

            TableColumn("Permissions", value: \.permissionsString) { item in
                Text(item.permissionsString)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            .width(min: 90, ideal: 110)
        }
    }

    private var keyPathComparator: KeyPathComparator<FileItem> {
        switch navigationState.sortField {
        case .name:
            return KeyPathComparator(\.name, order: navigationState.sortAscending ? .forward : .reverse)
        case .size:
            return KeyPathComparator(\.fileSize, order: navigationState.sortAscending ? .forward : .reverse)
        case .dateModified:
            return KeyPathComparator(\.dateModified, order: navigationState.sortAscending ? .forward : .reverse)
        case .kind:
            return KeyPathComparator(\.kindDescription, order: navigationState.sortAscending ? .forward : .reverse)
        case .permissions:
            return KeyPathComparator(\.permissionsString, order: navigationState.sortAscending ? .forward : .reverse)
        }
    }

    private func handleSortChange(_ order: [KeyPathComparator<FileItem>]) {
        guard let first = order.first else { return }
        navigationState.sortAscending = (first.order == .forward)

        if first.keyPath == \FileItem.name {
            navigationState.sortField = .name
        } else if first.keyPath == \FileItem.fileSize {
            navigationState.sortField = .size
        } else if first.keyPath == \FileItem.dateModified {
            navigationState.sortField = .dateModified
        } else if first.keyPath == \FileItem.kindDescription {
            navigationState.sortField = .kind
        } else if first.keyPath == \FileItem.permissionsString {
            navigationState.sortField = .permissions
        }
    }
}
