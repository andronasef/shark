import XCTest
@testable import Shark

@MainActor
final class CommandPaletteAndKeyboardTests: XCTestCase {
    var workspace: WorkspaceState!
    var tempDirectory: URL!

    override func setUp() async throws {
        workspace = WorkspaceState()
        tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    override func tearDown() async throws {
        try? FileManager.default.removeItem(at: tempDirectory)
        workspace = nil
    }

    func testCommandPaletteIndexingAndCategories() {
        let items = CommandPaletteService.shared.allItems(for: workspace)
        XCTAssertFalse(items.isEmpty)

        // Verify categories exist
        let actions = items.filter { $0.category == .actions }
        let places = items.filter { $0.category == .navigation }

        XCTAssertFalse(actions.isEmpty, "Should index core actions")
        XCTAssertFalse(places.isEmpty, "Should index standard places")

        // Verify key actions present
        XCTAssertTrue(actions.contains(where: { $0.id == "action-toggle-split" }))
        XCTAssertTrue(actions.contains(where: { $0.id == "action-toggle-terminal" }))
        XCTAssertTrue(actions.contains(where: { $0.id == "action-new-tab" }))
        XCTAssertTrue(actions.contains(where: { $0.id == "action-show-hidden" }))
    }

    func testCommandPaletteFuzzySearch() {
        // Search "split"
        let splitResults = CommandPaletteService.shared.filter(query: "split", for: workspace)
        XCTAssertFalse(splitResults.isEmpty)
        XCTAssertEqual(splitResults.first?.id, "action-toggle-split")

        // Search "term"
        let termResults = CommandPaletteService.shared.filter(query: "term", for: workspace)
        XCTAssertFalse(termResults.isEmpty)
        XCTAssertEqual(termResults.first?.id, "action-toggle-terminal")

        // Search "desk"
        let deskResults = CommandPaletteService.shared.filter(query: "desk", for: workspace)
        XCTAssertFalse(deskResults.isEmpty)
        XCTAssertEqual(deskResults.first?.id, "place-desktop")
    }

    func testCommandPalettePathSearch() {
        // Path starting with ~
        let tildeResults = CommandPaletteService.shared.filter(query: "~/Downloads", for: workspace)
        XCTAssertEqual(tildeResults.count, 1)
        let first = tildeResults.first!
        XCTAssertEqual(first.category, .path)
        XCTAssertTrue(first.title.contains("~/Downloads"))

        // Path starting with /
        let rootResults = CommandPaletteService.shared.filter(query: "/Applications", for: workspace)
        XCTAssertEqual(rootResults.count, 1)
        XCTAssertEqual(rootResults.first?.category, .path)
    }

    func testWorkspaceCommandPaletteToggle() {
        XCTAssertFalse(workspace.isCommandPalettePresented)
        workspace.toggleCommandPalette()
        XCTAssertTrue(workspace.isCommandPalettePresented)
        workspace.toggleCommandPalette()
        XCTAssertFalse(workspace.isCommandPalettePresented)
    }

    func testTypeToSelectCoordinatorPrefixMatch() {
        let nav = workspace.activeNavigationState
        let item1 = FileItem(url: tempDirectory.appendingPathComponent("Apple.txt"), name: "Apple.txt", isDirectory: false)
        let item2 = FileItem(url: tempDirectory.appendingPathComponent("Banana.txt"), name: "Banana.txt", isDirectory: false)
        let item3 = FileItem(url: tempDirectory.appendingPathComponent("Cherry.txt"), name: "Cherry.txt", isDirectory: false)
        nav.items = [item1, item2, item3]

        TypeToSelectCoordinator.shared.clear()

        // Type 'B'
        TypeToSelectCoordinator.shared.appendCharacter("B", in: nav)
        XCTAssertEqual(nav.selectedItemIDs, [item2.url])

        // Type 'a' -> "Ba" -> matches Banana
        TypeToSelectCoordinator.shared.appendCharacter("a", in: nav)
        XCTAssertEqual(nav.selectedItemIDs, [item2.url])

        // Clear and type 'c' -> matches Cherry
        TypeToSelectCoordinator.shared.clear()
        TypeToSelectCoordinator.shared.appendCharacter("c", in: nav)
        XCTAssertEqual(nav.selectedItemIDs, [item3.url])
    }

    func testSharkSettingsDefaultValues() {
        let settings = SharkSettings.shared
        XCTAssertEqual(settings.defaultViewMode, DefaultViewModeSetting.list.rawValue)
        XCTAssertEqual(settings.startupLocation, DefaultStartupLocation.home.rawValue)
        XCTAssertFalse(settings.showHiddenFilesByDefault)
        XCTAssertTrue(settings.hoverPreviewEnabled)
        XCTAssertEqual(settings.hoverPreviewDelayMs, 350.0)

        // Verify startup location urls
        XCTAssertEqual(DefaultStartupLocation.home.url.path, FileManager.default.homeDirectoryForCurrentUser.path)
        XCTAssertFalse(DefaultStartupLocation.desktop.url.path.isEmpty)
        XCTAssertFalse(DefaultStartupLocation.documents.url.path.isEmpty)
    }
}
