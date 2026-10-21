import AppKit

/// A SemVer 2.0 version (`MAJOR.MINOR.PATCH[-prerelease][+build]`). Build metadata is dropped.
struct SemanticVersion: Comparable, Sendable, CustomStringConvertible {
    let major: Int
    let minor: Int
    let patch: Int
    let prerelease: [String]

    init?(_ string: String) {
        var s = Substring(string.trimmingCharacters(in: .whitespacesAndNewlines))
        if s.first == "v" || s.first == "V" { s = s.dropFirst() }
        if let plus = s.firstIndex(of: "+") { s = s[..<plus] }

        let core: Substring
        if let dash = s.firstIndex(of: "-") {
            core = s[..<dash]
            let identifiers = s[s.index(after: dash)...].split(separator: ".", omittingEmptySubsequences: false)
            guard identifiers.allSatisfy({ !$0.isEmpty }) else { return nil }
            prerelease = identifiers.map(String.init)
        } else {
            core = s
            prerelease = []
        }

        let numbers = core.split(separator: ".", omittingEmptySubsequences: false).map { Self.numeric($0) }
        guard numbers.count == 3, let major = numbers[0], let minor = numbers[1], let patch = numbers[2] else { return nil }
        self.major = major
        self.minor = minor
        self.patch = patch
    }

    var isPrerelease: Bool { !prerelease.isEmpty }

    var description: String {
        "\(major).\(minor).\(patch)" + (prerelease.isEmpty ? "" : "-" + prerelease.joined(separator: "."))
    }

    static func < (a: Self, b: Self) -> Bool {
        if (a.major, a.minor, a.patch) != (b.major, b.minor, b.patch) {
            return (a.major, a.minor, a.patch) < (b.major, b.minor, b.patch)
        }
        // A release ranks above any of its prereleases.
        if a.prerelease.isEmpty || b.prerelease.isEmpty { return !a.prerelease.isEmpty && b.prerelease.isEmpty }
        for (x, y) in zip(a.prerelease, b.prerelease) where x != y {
            switch (numeric(x), numeric(y)) {
            case let (i?, j?): return i < j
            case (.some, nil): return true
            case (nil, .some): return false
            case (nil, nil): return x < y
            }
        }
        return a.prerelease.count < b.prerelease.count
    }

    private static func numeric<S: StringProtocol>(_ s: S) -> Int? {
        guard !s.isEmpty, s.allSatisfy({ ("0"..."9").contains($0) }) else { return nil }
        return Int(s)
    }
}

struct GitHubRelease: Decodable, Sendable {
    struct Asset: Decodable, Sendable {
        let name: String
        let browserDownloadURL: URL

        enum CodingKeys: String, CodingKey {
            case name
            case browserDownloadURL = "browser_download_url"
        }
    }

    let tagName: String
    let draft: Bool
    let prerelease: Bool
    let htmlURL: URL
    let assets: [Asset]

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case draft, prerelease, assets
        case htmlURL = "html_url"
    }

    /// The release's `.dmg` installer, or its release page when it has none.
    var downloadURL: URL {
        assets.first { $0.name.hasSuffix(".dmg") }?.browserDownloadURL ?? htmlURL
    }
}

enum InstallChannel: Sendable {
    case appStore, homebrew, dmg
}

/// Alert-only update checks. Shark never downloads or installs anything itself.
@MainActor
enum UpdateChecker {
    private static let releasesAPI = URL(string: "https://api.github.com/repos/andronasef/shark/releases?per_page=10")!
    private static let releasesPage = URL(string: "https://github.com/andronasef/shark/releases")!
    private static let skippedVersionKey = "skippedUpdateVersion"

    nonisolated static func channel(hasReceipt: Bool, hasCask: Bool) -> InstallChannel {
        hasReceipt ? .appStore : hasCask ? .homebrew : .dmg
    }

    nonisolated static func newestRelease(in releases: [GitHubRelease], newerThan current: SemanticVersion) -> GitHubRelease? {
        let candidates = releases.compactMap { release -> (SemanticVersion, GitHubRelease)? in
            guard !release.draft, current.isPrerelease || !release.prerelease,
                  let version = SemanticVersion(release.tagName) else { return nil }
            return (version, release)
        }
        guard let best = candidates.max(by: { $0.0 < $1.0 }), best.0 > current else { return nil }
        return best.1
    }

    private static var rawVersion: String? {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
    }

    static var currentVersion: SemanticVersion? { rawVersion.flatMap(SemanticVersion.init) }

    static func checkNow() {
        Task { await check(manual: true) }
    }

    private static func check(manual: Bool) async {
        guard let current = currentVersion else {
            if manual {
                showInfo("Update checking is unavailable in development builds.",
                         "This build’s version is “\(rawVersion ?? "missing")”, which is not a release version.")
            }
            return
        }
        do {
            let releases = try await fetch([GitHubRelease].self, from: releasesAPI, accept: "application/vnd.github+json")
            guard let release = newestRelease(in: releases, newerThan: current),
                  let latest = SemanticVersion(release.tagName) else {
                if manual { showInfo("You’re up to date", "Shark \(current) is the newest version.") }
                return
            }
            showUpdateAlert(latest: latest, current: current, channel: .dmg, actionURL: release.downloadURL)
        } catch {
            if manual { NSAlert(error: error).runModal() }
        }
    }

    private static func fetch<T: Decodable>(_ type: T.Type, from url: URL, accept: String? = nil) async throws -> T {
        var request = URLRequest(url: url)
        if let accept { request.setValue(accept, forHTTPHeaderField: "Accept") }
        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw URLError(.badServerResponse) }
        return try JSONDecoder().decode(type, from: data)
    }

    private static func showUpdateAlert(latest: SemanticVersion, current: SemanticVersion,
                                        channel: InstallChannel, actionURL: URL) {
        let alert = NSAlert()
        alert.messageText = "Shark \(latest) is available"
        alert.informativeText = "You have \(current)."
        alert.addButton(withTitle: "Download")
        alert.addButton(withTitle: "Skip This Version")
        alert.addButton(withTitle: "Later")

        switch alert.runModal() {
        case .alertFirstButtonReturn:
            openHTTPS(actionURL)
        case .alertSecondButtonReturn:
            UserDefaults.standard.set(latest.description, forKey: skippedVersionKey)
        default:
            break
        }
    }

    /// Opens network-derived URLs only over https; anything else falls back to the releases page.
    private static func openHTTPS(_ url: URL) {
        NSWorkspace.shared.open(url.scheme == "https" ? url : releasesPage)
    }

    private static func showInfo(_ message: String, _ informative: String) {
        let alert = NSAlert()
        alert.messageText = message
        alert.informativeText = informative
        alert.runModal()
    }
}
