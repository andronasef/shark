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
    /// Release notes (Markdown); GitHub sends null or omits it when there are none.
    let body: String?

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case draft, prerelease, assets, body
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
    private static let appStoreLookup = URL(string: "https://itunes.apple.com/lookup?bundleId=com.increasinglabs.shark")!
    private static let skippedVersionKey = "skippedUpdateVersion"
    private static let lastCheckKey = "lastUpdateCheck"
    /// A constant: network-derived text never reaches the pasteboard.
    private static let brewCommand = "brew upgrade --cask shark"

    private struct AppStoreLookup: Decodable {
        struct Result: Decodable {
            let version: String
            let trackViewUrl: URL
            let releaseNotes: String?
        }
        let results: [Result]
    }

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

    /// The launch check: at most once a day, only when enabled, and silent unless an update is available.
    static func checkAutomatically() {
        guard SharkSettings.shared.automaticallyCheckForUpdates, currentVersion != nil else { return }
        let defaults = UserDefaults.standard
        if let last = defaults.object(forKey: lastCheckKey) as? Date, Date().timeIntervalSince(last) < 24 * 60 * 60 { return }
        // Stamped before fetching so a failing network still checks at most once a day.
        defaults.set(Date(), forKey: lastCheckKey)
        Task { await check(manual: false) }
    }

    private static var installChannel: InstallChannel {
        let fileManager = FileManager.default
        let hasReceipt = Bundle.main.appStoreReceiptURL.map { fileManager.fileExists(atPath: $0.path) } ?? false
        let hasCask = ["/opt/homebrew/Caskroom/shark", "/usr/local/Caskroom/shark"].contains { fileManager.fileExists(atPath: $0) }
        return channel(hasReceipt: hasReceipt, hasCask: hasCask)
    }

    private static func check(manual: Bool) async {
        guard let current = currentVersion else {
            if manual {
                showInfo("Update checking is unavailable in development builds.",
                         "This build’s version is “\(rawVersion ?? "missing")”, which is not a release version.")
            }
            return
        }
        let channel = installChannel
        do {
            guard let update = try await newestUpdate(for: channel, current: current) else {
                if manual { showInfo("You’re up to date", "Shark \(current) is the newest version.") }
                return
            }
            // Only the automatic check honours a skipped version.
            if !manual, UserDefaults.standard.string(forKey: skippedVersionKey) == update.version.description { return }
            showUpdateAlert(latest: update.version, current: current, channel: channel,
                            actionURL: update.url, notes: update.notes)
        } catch {
            if manual { NSAlert(error: error).runModal() }
        }
    }

    private static func newestUpdate(for channel: InstallChannel,
                                     current: SemanticVersion) async throws -> (version: SemanticVersion, url: URL, notes: String?)? {
        if channel == .appStore {
            let lookup = try await fetch(AppStoreLookup.self, from: appStoreLookup)
            guard let result = lookup.results.first, let version = SemanticVersion(result.version),
                  version > current else { return nil }
            return (version, result.trackViewUrl, result.releaseNotes)
        }
        let releases = try await fetch([GitHubRelease].self, from: releasesAPI, accept: "application/vnd.github+json")
        guard let release = newestRelease(in: releases, newerThan: current),
              let version = SemanticVersion(release.tagName) else { return nil }
        return (version, release.downloadURL, release.body)
    }

    private static func fetch<T: Decodable>(_ type: T.Type, from url: URL, accept: String? = nil) async throws -> T {
        var request = URLRequest(url: url)
        if let accept { request.setValue(accept, forHTTPHeaderField: "Accept") }
        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw URLError(.badServerResponse) }
        return try JSONDecoder().decode(type, from: data)
    }

    private static func showUpdateAlert(latest: SemanticVersion, current: SemanticVersion,
                                        channel: InstallChannel, actionURL: URL, notes: String?) {
        let alert = NSAlert()
        alert.messageText = "Shark \(latest) is available"
        alert.informativeText = "You have \(current)."
        if let notes = releaseNotes(notes) { alert.accessoryView = notesView(notes) }
        switch channel {
        case .appStore:
            alert.addButton(withTitle: "Open App Store")
        case .homebrew:
            alert.informativeText += " Run \(brewCommand) in Terminal to update."
            alert.addButton(withTitle: "Copy Command")
        case .dmg:
            alert.addButton(withTitle: "Download")
        }
        alert.addButton(withTitle: "Skip This Version")
        alert.addButton(withTitle: "Later")

        switch alert.runModal() {
        case .alertFirstButtonReturn:
            performAction(for: channel, url: actionURL)
        case .alertSecondButtonReturn:
            UserDefaults.standard.set(latest.description, forKey: skippedVersionKey)
        default:
            break
        }
    }

    private static func performAction(for channel: InstallChannel, url: URL) {
        switch channel {
        case .homebrew:
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(brewCommand, forType: .string)
        case .appStore:
            guard url.scheme == "https" else { return openHTTPS(url) }
            var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            components?.scheme = "macappstore"
            if let storeURL = components?.url, NSWorkspace.shared.open(storeURL) { return }
            NSWorkspace.shared.open(url)
        case .dmg:
            openHTTPS(url)
        }
    }

    /// Opens network-derived URLs only over https; anything else falls back to the releases page.
    private static func openHTTPS(_ url: URL) {
        NSWorkspace.shared.open(url.scheme == "https" ? url : releasesPage)
    }

    /// Release notes as display text, or nil when there are none. Links stay clickable.
    nonisolated static func releaseNotes(_ markdown: String?) -> NSAttributedString? {
        guard let markdown = markdown?.trimmingCharacters(in: .whitespacesAndNewlines), !markdown.isEmpty else { return nil }
        let options = AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        let text = (try? NSMutableAttributedString(AttributedString(markdown: markdown, options: options)))
            ?? NSMutableAttributedString(string: markdown)
        let all = NSRange(location: 0, length: text.length)
        text.addAttribute(.font, value: NSFont.systemFont(ofSize: NSFont.smallSystemFontSize), range: all)
        text.addAttribute(.foregroundColor, value: NSColor.labelColor, range: all)
        return text
    }

    private static func notesView(_ notes: NSAttributedString) -> NSView {
        let scrollView = NSTextView.scrollableTextView()
        scrollView.frame = NSRect(x: 0, y: 0, width: 360, height: 160)
        scrollView.borderType = .bezelBorder
        scrollView.autohidesScrollers = true
        let textView = scrollView.documentView as! NSTextView
        textView.isEditable = false
        textView.drawsBackground = false
        textView.textContainerInset = NSSize(width: 4, height: 6)
        textView.textStorage?.setAttributedString(notes)
        // Fit short notes; scroll beyond 160 pt.
        if let layout = textView.layoutManager, let container = textView.textContainer {
            textView.frame.size.width = scrollView.contentSize.width
            layout.ensureLayout(for: container)
            let height = ceil(layout.usedRect(for: container).height) + textView.textContainerInset.height * 2 + 4
            scrollView.frame.size.height = min(160, height)
        }
        return scrollView
    }

    private static func showInfo(_ message: String, _ informative: String) {
        let alert = NSAlert()
        alert.messageText = message
        alert.informativeText = informative
        alert.runModal()
    }
}
