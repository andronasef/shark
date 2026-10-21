import XCTest
@testable import Shark

@MainActor
final class DefaultFolderAppTests: XCTestCase {
    private let shark = URL(fileURLWithPath: "/Applications/Shark.app")
    private let finder = URL(fileURLWithPath: "/System/Library/CoreServices/Finder.app")

    private func defaults() -> UserDefaults {
        let name = "SharkTests.DefaultFolderApp.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        addTeardownBlock { UserDefaults.standard.removePersistentDomain(forName: name) }
        return defaults
    }

    func testWelcomeAppearsOnceAndCanBeReopenedFromHelp() {
        let defaults = defaults()
        let onboarding = OnboardingState(defaults: defaults)
        onboarding.presentIfNeeded()
        XCTAssertTrue(onboarding.isPresented)
        onboarding.isPresented = false
        onboarding.presentIfNeeded()
        XCTAssertFalse(onboarding.isPresented)
        let relaunched = OnboardingState(defaults: defaults)
        relaunched.presentIfNeeded()
        XCTAssertFalse(relaunched.isPresented)
        relaunched.show()
        XCTAssertTrue(relaunched.isPresented)
    }

    func testMakeDefaultAndRestoreFinderVerifyActualAssociation() async {
        var current = finder
        let service = DefaultFolderAppService(applicationURL: shark,
            currentApplication: { current }, setDefaultApplication: { current = $0 }, findFinder: { self.finder })
        XCTAssertFalse(service.isSharkDefault)
        let changed = await service.makeSharkDefault()
        XCTAssertTrue(changed)
        XCTAssertTrue(service.isSharkDefault)
        XCTAssertNil(service.errorMessage)
        let restored = await service.restoreFinder()
        XCTAssertTrue(restored)
        XCTAssertFalse(service.isSharkDefault)
        XCTAssertEqual(service.currentApplicationURL, finder)
        XCTAssertFalse(service.isChanging)
    }

    func testUnchangedAssociationDoesNotClaimSuccess() async {
        let service = DefaultFolderAppService(applicationURL: shark,
            currentApplication: { self.finder }, setDefaultApplication: { _ in })
        let changed = await service.makeSharkDefault()
        XCTAssertFalse(changed)
        XCTAssertFalse(service.isSharkDefault)
        XCTAssertNotNil(service.errorMessage)
        XCTAssertFalse(service.isChanging)
    }

    func testErrorRefreshesStatusAndCanBeRetried() async {
        var current = finder
        var shouldThrow = true
        let service = DefaultFolderAppService(applicationURL: shark,
            currentApplication: { current }, setDefaultApplication: { target in
                if shouldThrow { throw CocoaError(.fileReadNoPermission) }
                current = target
            })
        let failed = await service.makeSharkDefault()
        XCTAssertFalse(failed)
        XCTAssertNotNil(service.errorMessage)
        shouldThrow = false
        let retried = await service.makeSharkDefault()
        XCTAssertTrue(retried)
        XCTAssertNil(service.errorMessage)
    }

    func testActualAssociationWinsOverReportedError() async {
        var current = finder
        let service = DefaultFolderAppService(applicationURL: shark,
            currentApplication: { current }, setDefaultApplication: { target in
                current = target
                throw CocoaError(.fileReadUnknown)
            })
        let changed = await service.makeSharkDefault()
        XCTAssertTrue(changed)
        XCTAssertTrue(service.isSharkDefault)
        XCTAssertNil(service.errorMessage)
    }

    func testRefreshReflectsExternalChangesAndUnknownDefault() {
        var current: URL? = nil
        let service = DefaultFolderAppService(applicationURL: shark, currentApplication: { current })
        XCTAssertNil(service.currentApplicationURL)
        current = shark
        service.refresh()
        XCTAssertTrue(service.isSharkDefault)
        current = finder
        service.refresh()
        XCTAssertFalse(service.isSharkDefault)
    }

    func testMissingFinderReportsFailure() async {
        let service = DefaultFolderAppService(applicationURL: shark,
            currentApplication: { self.shark }, findFinder: { nil })
        let restored = await service.restoreFinder()
        XCTAssertFalse(restored)
        XCTAssertNotNil(service.errorMessage)
        XCTAssertTrue(service.isSharkDefault)
    }

    func testUnsupportedFolderAssociationOffersManualSetupWithoutClaimingSuccess() async {
        let service = DefaultFolderAppService(applicationURL: shark, currentApplication: { self.finder },
            setDefaultApplication: { _ in throw NSError(domain: NSOSStatusErrorDomain, code: -50) })
        let changed = await service.makeSharkDefault()
        XCTAssertFalse(changed)
        XCTAssertFalse(service.isSharkDefault)
        XCTAssertTrue(service.requiresManualSetup)
        XCTAssertTrue(service.errorMessage?.contains("Manual Setup") == true)
        let restored = await service.restoreFinder()
        XCTAssertTrue(restored)
        XCTAssertFalse(service.requiresManualSetup)
        XCTAssertNil(service.errorMessage)
    }

    func testFolderWriterFallsBackOnlyForUnsupportedFolderParameter() async throws {
        var fallbackTargets: [URL] = []
        let writer = FolderAssociationWriter(modern: { _ in
            throw NSError(domain: NSCocoaErrorDomain, code: 256, userInfo: [
                NSUnderlyingErrorKey: NSError(domain: NSOSStatusErrorDomain, code: -50)
            ])
        }, legacy: { fallbackTargets.append($0) })
        try await writer.setDefault(to: shark)
        XCTAssertEqual(fallbackTargets, [shark])
    }

    func testFolderWriterDoesNotFallBackAfterDeniedConsentOrOtherErrors() async {
        for error in [
            NSError(domain: NSCocoaErrorDomain, code: 256),
            NSError(domain: NSCocoaErrorDomain, code: 256, userInfo: [
                NSUnderlyingErrorKey: NSError(domain: NSOSStatusErrorDomain, code: -54)
            ])
        ] {
            var fellBack = false
            let writer = FolderAssociationWriter(modern: { _ in throw error }, legacy: { _ in fellBack = true })
            do {
                try await writer.setDefault(to: shark)
                XCTFail("Must preserve consent failures")
            } catch { }
            XCTAssertFalse(fellBack)
        }
    }

    func testFolderWriterDoesNotFallBackAfterSuccess() async throws {
        var fellBack = false
        let writer = FolderAssociationWriter(modern: { _ in }, legacy: { _ in fellBack = true })
        try await writer.setDefault(to: shark)
        XCTAssertFalse(fellBack)
    }
}

@MainActor
final class ExternalFolderOpeningTests: XCTestCase {
    private var root: URL!

    override func setUpWithError() throws {
        root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try FileManager.default.removeItem(at: root)
    }

    private func folder(_ name: String) throws -> URL {
        let url = root.appendingPathComponent(name, isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    func testMultipleFoldersReuseTabsAndPreserveLockedTabs() throws {
        let first = try folder("First")
        let second = try folder("Second folder")
        let workspace = WorkspaceState(initialURL: first)
        workspace.activeTab.isLocked = true
        XCTAssertTrue(workspace.openExternalFolders([second, second, first]).isEmpty)
        XCTAssertEqual(workspace.tabs.count, 2)
        XCTAssertEqual(workspace.activeTabID, workspace.tabs[0].id)
        XCTAssertEqual(workspace.tabs[0].primaryPane.currentURL, first)
        XCTAssertTrue(workspace.tabs[0].isLocked)
    }

    func testVisibleSecondaryPaneIsReusedButHiddenPaneIsNot() throws {
        let first = try folder("First")
        let second = try folder("Second")
        let workspace = WorkspaceState(initialURL: first)
        workspace.activeTab.isSplit = true
        workspace.activeTab.secondaryPane.navigateTo(second)
        XCTAssertTrue(workspace.openExternalFolders([second]).isEmpty)
        XCTAssertEqual(workspace.tabs.count, 1)
        XCTAssertEqual(workspace.activeTab.activePane, .secondary)
        workspace.activeTab.isSplit = false
        workspace.activeTab.activePane = .primary
        XCTAssertTrue(workspace.openExternalFolders([second]).isEmpty)
        XCTAssertEqual(workspace.tabs.count, 2)
        XCTAssertEqual(workspace.activeNavigationState.currentURL, second)
    }

    func testInvalidURLsFilesAndPackagesAreRejectedWithoutTabs() throws {
        let file = root.appendingPathComponent("file.txt")
        try Data("test".utf8).write(to: file)
        let package = try folder("Example.app")
        let missing = root.appendingPathComponent("missing")
        let remote = URL(string: "https://example.com/folder")!
        let workspace = WorkspaceState(initialURL: root)
        XCTAssertEqual(workspace.openExternalFolders([file, package, missing, remote]), [file, package, missing, remote])
        XCTAssertEqual(workspace.tabs.count, 1)
    }

    func testStandardizedAndSymbolicLinkPathsReuseExistingTab() throws {
        let target = try folder("Target")
        let alias = root.appendingPathComponent("Link")
        try FileManager.default.createSymbolicLink(at: alias, withDestinationURL: target)
        let workspace = WorkspaceState(initialURL: target)
        XCTAssertTrue(workspace.openExternalFolders([alias, target.appendingPathComponent(".")]).isEmpty)
        XCTAssertEqual(workspace.tabs.count, 1)
    }
}
