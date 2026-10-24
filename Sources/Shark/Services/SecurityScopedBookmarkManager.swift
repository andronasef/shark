import AppKit
import Foundation
import os

/// Manages security-scoped bookmarks and user-granted folder permissions under macOS App Sandbox.
@MainActor
public final class SecurityScopedBookmarkManager {
    public static let shared = SecurityScopedBookmarkManager()

    private let logger = Logger(subsystem: "com.increasinglabs.shark", category: "SandboxBookmarks")
    private let storageURL: URL
    private var bookmarks: [String: Data] = [:]
    private var activeAccessCounts: [String: (url: URL, count: Int)] = [:]

    /// Indicates whether the app is currently running inside an App Sandbox container.
    public var isSandboxed: Bool {
        if ProcessInfo.processInfo.environment["APP_SANDBOX_CONTAINER_ID"] != nil {
            return true
        }
        return NSHomeDirectory().contains("/Library/Containers/")
    }

    public init(storageURL: URL? = nil) {
        if let custom = storageURL {
            self.storageURL = custom
        } else {
            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
                ?? FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support", isDirectory: true)
            let sharkDir = appSupport.appendingPathComponent("Shark", isDirectory: true)
            try? FileManager.default.createDirectory(at: sharkDir, withIntermediateDirectories: true)
            self.storageURL = sharkDir.appendingPathComponent("bookmarks.json")
        }
        loadBookmarks()
        reactivateStoredBookmarks()
    }

    // MARK: - Access Checking

    /// Checks if a given URL is currently accessible for reading without errors.
    public func isAccessible(url: URL) -> Bool {
        let path = url.standardizedFileURL.path
        return FileManager.default.isReadableFile(atPath: path)
    }

    /// Ensures that the app has active security-scoped access to the given URL.
    /// If not currently accessible, tries resolving stored bookmarks.
    /// If still inaccessible, returns false (caller can prompt the user).
    @discardableResult
    public func ensureAccess(to url: URL) -> Bool {
        if isAccessible(url: url) {
            return true
        }
        // Try activating any stored bookmark for this path or its ancestors
        if activateBookmarkForPathOrAncestors(url) {
            return isAccessible(url: url)
        }
        return false
    }

    // MARK: - Bookmark Creation & Resolution

    /// Creates and persists a security-scoped bookmark for the specified URL.
    @discardableResult
    public func saveBookmark(for url: URL) throws -> Data {
        let standardized = url.standardizedFileURL
        let options: URL.BookmarkCreationOptions = isSandboxed ? [.withSecurityScope] : []
        let data = try standardized.bookmarkData(
            options: options,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )

        let key = standardized.path
        bookmarks[key] = data
        saveBookmarks()
        startAccessing(url: standardized)
        return data
    }

    /// Resolves bookmark data into a security-scoped URL and activates access.
    public func resolveBookmark(data: Data) -> URL? {
        var isStale = false
        let options: URL.BookmarkResolutionOptions = isSandboxed ? [.withSecurityScope] : []
        do {
            let resolvedURL = try URL(
                resolvingBookmarkData: data,
                options: options,
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )
            if isStale {
                _ = try? saveBookmark(for: resolvedURL)
            }
            startAccessing(url: resolvedURL)
            return resolvedURL
        } catch {
            logger.error("Failed to resolve bookmark: \(error, privacy: .public)")
            return nil
        }
    }

    // MARK: - Resource Access Lifecycle

    /// Begins accessing a security-scoped resource, tracking open counts.
    @discardableResult
    public func startAccessing(url: URL) -> Bool {
        guard isSandboxed else { return true }
        let standardized = url.standardizedFileURL
        let key = standardized.path

        if let existing = activeAccessCounts[key] {
            activeAccessCounts[key] = (existing.url, existing.count + 1)
            return true
        }

        let success = standardized.startAccessingSecurityScopedResource()
        if success {
            activeAccessCounts[key] = (standardized, 1)
        }
        return success
    }

    /// Stops accessing a security-scoped resource when all references are released.
    public func stopAccessing(url: URL) {
        guard isSandboxed else { return }
        let standardized = url.standardizedFileURL
        let key = standardized.path

        guard let existing = activeAccessCounts[key] else { return }
        if existing.count <= 1 {
            existing.url.stopAccessingSecurityScopedResource()
            activeAccessCounts.removeValue(forKey: key)
        } else {
            activeAccessCounts[key] = (existing.url, existing.count - 1)
        }
    }

    // MARK: - User Permission Prompt (NSOpenPanel)

    /// Prompts the user with NSOpenPanel to grant access to the requested folder.
    /// Under App Sandbox, user selection through NSOpenPanel grants temporary access and allows creating a persistent bookmark.
    public func promptUserForAccess(to targetURL: URL, message: String? = nil) async -> Bool {
        let panel = NSOpenPanel()
        panel.message = message ?? L10n.text("Grant Shark access to browse and manage files in this folder.")
        panel.prompt = L10n.text("Grant Access")
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = false

        // Suggest the closest existing directory
        var candidate = targetURL.standardizedFileURL
        while candidate.path != "/" && !FileManager.default.fileExists(atPath: candidate.path) {
            candidate = candidate.deletingLastPathComponent()
        }
        panel.directoryURL = candidate

        let response = await withCheckedContinuation { continuation in
            panel.begin { result in
                continuation.resume(returning: result)
            }
        }

        guard response == .OK, let selectedURL = panel.url else {
            return false
        }

        do {
            try saveBookmark(for: selectedURL)
            logger.info("Successfully saved user-granted bookmark for \(selectedURL.path, privacy: .public)")
            return true
        } catch {
            logger.error("Failed to save bookmark for user-selected folder: \(error, privacy: .public)")
            return false
        }
    }

    // MARK: - Internal Storage & Restoration

    private func activateBookmarkForPathOrAncestors(_ targetURL: URL) -> Bool {
        var current = targetURL.standardizedFileURL
        while current.path != "/" {
            let key = current.path
            if let data = bookmarks[key], resolveBookmark(data: data) != nil {
                if isAccessible(url: targetURL) {
                    return true
                }
            }
            current = current.deletingLastPathComponent()
        }
        return false
    }

    private func reactivateStoredBookmarks() {
        guard isSandboxed else { return }
        for (_, data) in bookmarks {
            _ = resolveBookmark(data: data)
        }
    }

    private func loadBookmarks() {
        guard FileManager.default.fileExists(atPath: storageURL.path) else { return }
        do {
            let data = try Data(contentsOf: storageURL)
            self.bookmarks = try JSONDecoder().decode([String: Data].self, from: data)
        } catch {
            logger.error("Failed to load bookmarks: \(error, privacy: .public)")
        }
    }

    private func saveBookmarks() {
        do {
            let data = try JSONEncoder().encode(bookmarks)
            try data.write(to: storageURL, options: .atomic)
        } catch {
            logger.error("Failed to save bookmarks: \(error, privacy: .public)")
        }
    }
}
