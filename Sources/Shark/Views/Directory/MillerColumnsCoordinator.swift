import Foundation
import SwiftUI
import Combine

public struct MillerColumn: Identifiable, Sendable {
    public var id: URL { directoryURL }
    public let directoryURL: URL
    public var items: [FileItem]
    public var selectedURL: URL?
    public var isLoading: Bool

    public init(
        directoryURL: URL,
        items: [FileItem] = [],
        selectedURL: URL? = nil,
        isLoading: Bool = false
    ) {
        self.directoryURL = directoryURL
        self.items = items
        self.selectedURL = selectedURL
        self.isLoading = isLoading
    }
}

@MainActor
@Observable
public final class MillerColumnsCoordinator {
    public var columns: [MillerColumn] = []
    public var previewItem: FileItem?
    public var activeColumnIndex: Int = 0

    public init() {}

    public func reset(rootDirectory: URL) {
        columns = [MillerColumn(directoryURL: rootDirectory, isLoading: true)]
        previewItem = nil
        activeColumnIndex = 0
        loadColumn(at: 0, directoryURL: rootDirectory)
    }

    public func loadColumn(at index: Int, directoryURL: URL) {
        Task {
            do {
                let showHidden = SharkSettings.shared.showHiddenFilesByDefault
                let items = try await FileSystemService.shared.contentsOfDirectory(at: directoryURL, showHidden: showHidden)
                let filtered = items
                let sorted = filtered.sorted { a, b in
                    if a.isDirectory != b.isDirectory {
                        return a.isDirectory && !b.isDirectory
                    }
                    return a.name.localizedStandardCompare(b.name) == .orderedAscending
                }

                if index < self.columns.count && self.columns[index].directoryURL == directoryURL {
                    self.columns[index].items = sorted
                    self.columns[index].isLoading = false
                }
            } catch {
                if index < self.columns.count && self.columns[index].directoryURL == directoryURL {
                    self.columns[index].items = []
                    self.columns[index].isLoading = false
                }
            }
        }
    }

    public func selectItem(_ item: FileItem, inColumn index: Int) {
        guard index < columns.count else { return }

        activeColumnIndex = index
        columns[index].selectedURL = item.url

        // Truncate any columns beyond this one
        if columns.count > index + 1 {
            columns.removeSubrange((index + 1)..<columns.count)
        }

        if item.isDirectory {
            previewItem = nil
            let newColumn = MillerColumn(directoryURL: item.url, isLoading: true)
            columns.append(newColumn)
            loadColumn(at: index + 1, directoryURL: item.url)
        } else {
            previewItem = item
        }
    }

    public func moveSelection(by delta: Int) {
        guard activeColumnIndex < columns.count else { return }
        let col = columns[activeColumnIndex]
        guard !col.items.isEmpty else { return }

        let currentIdx: Int
        if let sel = col.selectedURL, let found = col.items.firstIndex(where: { $0.url == sel }) {
            currentIdx = found
        } else {
            currentIdx = delta > 0 ? -1 : col.items.count
        }

        let newIdx = max(0, min(col.items.count - 1, currentIdx + delta))
        let targetItem = col.items[newIdx]
        selectItem(targetItem, inColumn: activeColumnIndex)
    }

    public func navigateRight() {
        if activeColumnIndex + 1 < columns.count {
            activeColumnIndex += 1
            if let first = columns[activeColumnIndex].items.first, columns[activeColumnIndex].selectedURL == nil {
                selectItem(first, inColumn: activeColumnIndex)
            }
        }
    }

    public func navigateLeft() {
        if activeColumnIndex > 0 {
            activeColumnIndex -= 1
        }
    }
}
