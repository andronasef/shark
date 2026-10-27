import Foundation
import Testing
@testable import Shark

@MainActor
struct TreeProjectionTests {
    @Test func reopeningAfterHiddenChangeRestoresRememberedDescendants() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root.appendingPathComponent("sub/deep"), withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let suite = "tree-projection-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let model = FolderTreeModel(defaults: defaults)
        let roots = [FolderTreeRoot(url: root, name: "Root", icon: "folder")]
        _ = model.rows(for: roots)
        await model.expand(root, showHidden: false)
        await model.expand(root.appendingPathComponent("sub"), showHidden: false)
        model.collapse(root)
        await model.reloadExpanded(showHidden: true)
        await model.expand(root, showHidden: true)
        #expect(model.rows(for: roots).map(\.name) == ["Root", "sub", "deep"])
    }
}
