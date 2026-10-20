import AppKit
import XCTest
@testable import Shark

@MainActor
final class TerminalOpeningTests: XCTestCase {
    private var directory: URL!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try FileManager.default.removeItem(at: directory)
    }

    func testExternalTerminalReceivesDirectoryAndExplicitApplication() async throws {
        let application = URL(fileURLWithPath: "/System/Applications/Utilities/Terminal.app")
        var receivedURLs: [URL] = []
        var receivedApplication: URL?
        let opener = TerminalOpener(findApplication: { application }, openURLs: { urls, app in
            receivedURLs = urls
            receivedApplication = app
        })
        try await opener.open(at: directory)
        XCTAssertEqual(receivedURLs, [directory.standardizedFileURL])
        XCTAssertEqual(receivedApplication, application)
    }

    func testFileOpensItsParentAndMissingTargetsNeverLaunch() async throws {
        let file = directory.appendingPathComponent("note.txt")
        try Data().write(to: file)
        var received: [URL] = []
        let opener = TerminalOpener(findApplication: { URL(fileURLWithPath: "/Terminal.app") }, openURLs: { urls, _ in received = urls })
        try await opener.open(at: file)
        XCTAssertEqual(received, [directory.standardizedFileURL])
        received = []
        do {
            try await opener.open(at: directory.appendingPathComponent("missing"))
            XCTFail("Missing paths must report an error")
        } catch {
            XCTAssertTrue(received.isEmpty)
        }
    }

    func testEmbeddedTerminalTargetsClickedFolderWithoutNavigatingBrowser() throws {
        let workspace = WorkspaceState(initialURL: URL(fileURLWithPath: "/"))
        let tab = workspace.activeTab
        tab.isSplit = true
        tab.secondaryPane.currentURL = directory
        try workspace.openEmbeddedTerminal(at: directory, from: tab.secondaryPane)
        XCTAssertTrue(workspace.isTerminalVisible)
        XCTAssertEqual(tab.activePane, .secondary)
        XCTAssertEqual(tab.primaryPane.currentURL.path, "/")
        XCTAssertEqual(tab.secondaryPane.currentURL, directory)
        XCTAssertEqual(workspace.embeddedTerminalRequest?.directory, directory.standardizedFileURL)
        let firstRequest = workspace.embeddedTerminalRequest?.id
        try workspace.openEmbeddedTerminal(at: directory, from: tab.secondaryPane)
        XCTAssertNotEqual(workspace.embeddedTerminalRequest?.id, firstRequest)
    }

    func testEmbeddedDirectoryCommandPreservesLiteralShellCharacters() throws {
        let folder = directory.appendingPathComponent("folder 'quoted' $HOME `literal`")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        process.arguments = ["-c", PTYSession.directoryChangeCommand(to: folder) + "pwd -P"]
        let output = Pipe()
        process.standardOutput = output
        try process.run()
        let data = output.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        XCTAssertEqual(process.terminationStatus, 0)
        let actual = URL(fileURLWithPath: String(decoding: data, as: UTF8.self).trimmingCharacters(in: .newlines))
        XCTAssertEqual(actual.resolvingSymlinksInPath().path, folder.resolvingSymlinksInPath().path)
    }

    func testEmbeddedTerminalFileUsesParent() throws {
        let file = directory.appendingPathComponent("note.txt")
        try Data().write(to: file)
        let workspace = WorkspaceState()
        try workspace.openEmbeddedTerminal(at: file, from: workspace.activeNavigationState)
        XCTAssertEqual(workspace.embeddedTerminalRequest?.directory, directory.standardizedFileURL)
    }
}
