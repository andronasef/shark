import AppKit
import CoreServices
import Observation
import UniformTypeIdentifiers
import os

/// The system association is authoritative; a saved preference cannot tell us the default app.
@Observable
@MainActor
final class DefaultFolderAppService {
    static let shared = DefaultFolderAppService()

    private(set) var currentApplicationURL: URL?
    private(set) var isChanging = false
    private(set) var errorMessage: String?
    private(set) var requiresManualSetup = false

    private let applicationURL: URL
    private let currentApplication: () -> URL?
    private let setDefaultApplication: (URL) async throws -> Void
    private let findFinder: () -> URL?

    init(
        applicationURL: URL = Bundle.main.bundleURL,
        currentApplication: @escaping () -> URL? = { NSWorkspace.shared.urlForApplication(toOpen: .folder) },
        setDefaultApplication: @escaping (URL) async throws -> Void = { try await FolderAssociationWriter().setDefault(to: $0) },
        findFinder: @escaping () -> URL? = {
            NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.finder")
        }
    ) {
        self.applicationURL = applicationURL
        self.currentApplication = currentApplication
        self.setDefaultApplication = setDefaultApplication
        self.findFinder = findFinder
        refresh()
    }

    var isSharkDefault: Bool {
        guard let currentApplicationURL else { return false }
        return Self.sameApplication(currentApplicationURL, applicationURL)
    }

    var currentApplicationName: String {
        guard let currentApplicationURL else { return L10n.text("Unknown") }
        return FileManager.default.displayName(atPath: currentApplicationURL.path)
    }

    func refresh() {
        currentApplicationURL = currentApplication()
    }

    @discardableResult
    func makeSharkDefault() async -> Bool {
        await changeDefault(to: applicationURL)
    }

    @discardableResult
    func restoreFinder() async -> Bool {
        guard let finder = findFinder() else {
            errorMessage = L10n.text("Finder could not be found. Try again after reopening Shark.")
            return false
        }
        return await changeDefault(to: finder)
    }

    private func changeDefault(to target: URL) async -> Bool {
        guard !isChanging else { return false }
        isChanging = true
        errorMessage = nil
        requiresManualSetup = false
        defer { isChanging = false }
        refresh()
        if let currentApplicationURL, Self.sameApplication(currentApplicationURL, target) { return true }

        var requestError: Error?
        do {
            try await setDefaultApplication(target)
        } catch {
            requestError = error
            Logger(subsystem: "com.increasinglabs.shark", category: "DefaultFolderApp")
                .error("Default folder app request failed: \(String(describing: error as NSError), privacy: .public)")
        }
        // Consent can be declined, or the system can report an error despite applying the change.
        refresh()
        if let currentApplicationURL, Self.sameApplication(currentApplicationURL, target) { return true }
        if let failure = requestError as NSError? {
            let status = failure.userInfo[NSUnderlyingErrorKey] as? NSError ?? failure
            if status.domain == NSOSStatusErrorDomain, status.code == -50 {
                requiresManualSetup = true
                errorMessage = L10n.text("macOS rejected one-click setup. Manual Setup is a separate option that requires restarting your Mac and may not work on this macOS version.")
                return false
            }
        }
        var message = L10n.text("The default folder app was not changed. You can try again here.")
        if let requestError {
            message += " \(requestError.localizedDescription)"
        }
        errorMessage = message
        return false
    }

    private static func sameApplication(_ lhs: URL, _ rhs: URL) -> Bool {
        if lhs.resolvingSymlinksInPath().standardizedFileURL == rhs.resolvingSymlinksInPath().standardizedFileURL {
            return true
        }
        // Installing or moving Shark must not make another copy of the same application look unrelated.
        guard let leftID = Bundle(url: lhs)?.bundleIdentifier,
              let rightID = Bundle(url: rhs)?.bundleIdentifier else { return false }
        return leftID == rightID
    }
}

/// macOS 26 can reject folder UTIs with paramErr before presenting consent in the newer API.
/// Keep the public Launch Services folder association API for that case alone, never a denial.
@MainActor
struct FolderAssociationWriter {
    var modern: (URL) async throws -> Void = {
        try await NSWorkspace.shared.setDefaultApplication(at: $0, toOpen: .folder)
    }
    var legacy: (URL) throws -> Void = { application in
        guard let identifier = Bundle(url: application)?.bundleIdentifier else {
            throw CocoaError(.fileReadCorruptFile)
        }
        let registration = LSRegisterURL(application as CFURL, true)
        guard registration == noErr else { throw NSError(domain: NSOSStatusErrorDomain, code: Int(registration)) }
        let status = LSSetDefaultRoleHandlerForContentType(UTType.folder.identifier as CFString, .all, identifier as CFString)
        guard status == noErr else { throw NSError(domain: NSOSStatusErrorDomain, code: Int(status)) }
    }

    func setDefault(to application: URL) async throws {
        do {
            try await modern(application)
        } catch {
            let failure = error as NSError
            let underlying = failure.userInfo[NSUnderlyingErrorKey] as? NSError
            let status = underlying ?? failure
            guard status.domain == NSOSStatusErrorDomain, status.code == -50 else { throw error }
            try legacy(application)
        }
    }
}
