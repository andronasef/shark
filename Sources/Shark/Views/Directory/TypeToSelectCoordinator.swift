import Foundation
import SwiftUI

@MainActor
public final class TypeToSelectCoordinator {
    public static let shared = TypeToSelectCoordinator()

    private var buffer: String = ""
    private var resetTask: Task<Void, Never>?

    private init() {}

    public func appendCharacter(_ char: Character, in nav: NavigationState) {
        // Ignore if currently editing path or renaming an item
        guard !nav.isEditingPath && nav.renamingItemURL == nil else { return }

        resetTask?.cancel()
        buffer.append(char)

        let query = buffer.lowercased()
        let items = nav.filteredAndSortedItems

        // 1. Prefix match
        if let match = items.first(where: { $0.name.lowercased().hasPrefix(query) }) {
            nav.selectedItemIDs = [match.url]
        }
        // 2. Substring match fallback
        else if let match = items.first(where: { $0.name.lowercased().contains(query) }) {
            nav.selectedItemIDs = [match.url]
        }

        // Auto-reset buffer after 800ms of inactivity
        resetTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 800_000_000)
            guard !Task.isCancelled else { return }
            self?.buffer = ""
        }
    }

    public func clear() {
        resetTask?.cancel()
        buffer = ""
    }
}
