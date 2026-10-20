import XCTest
import AppKit
import UniformTypeIdentifiers
@testable import Shark

@MainActor
final class SidebarFavoritesTests: XCTestCase {
    func testShortcutDragUsesSeparateTypeFromFileMoves() async throws {
        let shortcut = FavoriteShortcutTransfer(url: URL(fileURLWithPath: "/Users/test/Projects"))
        let data = try JSONEncoder().encode(shortcut)
        let provider = NSItemProvider()
        provider.registerDataRepresentation(forTypeIdentifier: UTType.sharkFavorite.identifier, visibility: .all) { completion in
            completion(data, nil)
            return nil
        }
        XCTAssertFalse(provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier))
        let decoded = await SidebarDropReader.urls(from: [provider])
        XCTAssertEqual(decoded, [shortcut.url])
    }
    func testAncestorIndicatorUsesPathBoundaries() {
        let projects = URL(fileURLWithPath: "/Users/test/Projects")
        XCTAssertTrue(SidebarFavoritesStore.contains(projects, currentFolder: projects.appendingPathComponent("Shark/Sources")))
        XCTAssertFalse(SidebarFavoritesStore.contains(projects, currentFolder: projects))
        XCTAssertFalse(SidebarFavoritesStore.contains(projects, currentFolder: URL(fileURLWithPath: "/Users/test/Projects-old")))
    }
    func testInsertionReorderingAndPersistence() throws {
        let suite = "shark-sidebar-test-\(UUID())"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = SidebarFavoritesStore(defaults: defaults)
        for favorite in store.items { store.remove(favorite.id) }
        let a = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let b = a.appendingPathComponent("B")
        try FileManager.default.createDirectory(at: b, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: a) }
        XCTAssertTrue(store.insert([a, b, a], at: 0))
        XCTAssertEqual(store.items.count, 2)
        let identity = store.items[0].id
        XCTAssertTrue(store.insert([a], at: 2))
        XCTAssertEqual(store.items.map(\.url), [b.standardizedFileURL, a.standardizedFileURL])
        XCTAssertEqual(store.items[1].id, identity)
        XCTAssertEqual(SidebarFavoritesStore(defaults: defaults).items, store.items)
        store.remove(identity)
        XCTAssertTrue(FileManager.default.fileExists(atPath: a.path))
    }

    func testMissingTargetsRemainUntilRemovedAndCanBeRelocated() throws {
        let suite = "shark-sidebar-test-\(UUID())"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = SidebarFavoritesStore(defaults: defaults)
        let target = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: target, withIntermediateDirectories: true)
        XCTAssertTrue(store.insert([target], at: 0))
        let id = store.items[0].id
        try FileManager.default.removeItem(at: target)
        XCTAssertFalse(store.items[0].isAvailable)
        XCTAssertTrue(store.insert([target], at: 0), "Unavailable shortcuts can still be reordered")
        XCTAssertFalse(store.insert([target.appendingPathComponent("not-a-folder")], at: 0))
        store.relocate(id, to: FileManager.default.temporaryDirectory)
        XCTAssertEqual(store.items[0].id, id)
        XCTAssertTrue(store.items[0].isAvailable)
    }
}
