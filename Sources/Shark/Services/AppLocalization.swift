import Foundation
import SwiftUI
import AppKit

/// Preference IDs are persisted independently of translated display names.
public enum AppLanguage: String, CaseIterable, Identifiable, Sendable {
    case system, en, ar, es, fr, de
    case ptBR = "pt-BR"
    case zhHans = "zh-Hans"
    case ja

    public var id: String { rawValue }
    public static func preference(_ value: String?) -> Self { value.flatMap(Self.init(rawValue:)) ?? .system }
    public var isRightToLeft: Bool { self == .ar }
    public var displayName: String {
        switch self {
        case .system: L10n.text("System Default")
        case .en: "English"
        case .ar: "العربية"
        case .es: "Español"
        case .fr: "Français"
        case .de: "Deutsch"
        case .ptBR: "Português (Brasil)"
        case .zhHans: "简体中文"
        case .ja: "日本語"
        }
    }
}

public enum AppLocalization {
    public static let preferenceKey = "appLanguage"

    /// Dynamic resolved language: changing the preference takes effect immediately
    /// in the UI, and persists across launches.
    public static var language: AppLanguage {
        resolvedLanguage(
            preference: AppLanguage.preference(UserDefaults.standard.string(forKey: preferenceKey)),
            preferredLanguages: Locale.preferredLanguages
        )
    }

    public static var locale: Locale { Locale(identifier: language.rawValue) }

    /// Window-level layout direction must remain coherent with the host macOS WindowServer.
    /// On macOS, window controls (traffic lights), sidebar tracking separator, and NSToolbar
    /// are strictly anchored to the top-left unless the host OS itself runs in RTL (e.g. Arabic macOS).
    /// If macOS is LTR, forcing .rightToLeft onto NavigationSplitView detaches the sidebar from
    /// the traffic lights and collapses toolbar items into the overflow chevron.
    @MainActor
    public static var layoutDirection: LayoutDirection {
        if language.isRightToLeft && NSApp?.userInterfaceLayoutDirection == .rightToLeft {
            return .rightToLeft
        }
        return .leftToRight
    }

    public static func resolvedLanguage(preference: AppLanguage, preferredLanguages: [String]) -> AppLanguage {
        if preference != .system { return preference }
        let supported = AppLanguage.allCases.filter { $0 != .system }.map(\.rawValue)
        let match = Bundle.preferredLocalizations(from: supported, forPreferences: preferredLanguages).first ?? "en"
        return AppLanguage(rawValue: match) ?? .en
    }

    public static func configureAtStartup() {
        updateProcessArguments()
    }

    public static func updateProcessArguments() {
        // Process-only override also guides AppKit's standard menu strings. Never
        // persist AppleLanguages, so System Default continues to follow macOS.
        var arguments = UserDefaults.standard.volatileDomain(forName: UserDefaults.argumentDomain)
        let pref = AppLanguage.preference(UserDefaults.standard.string(forKey: preferenceKey))
        if pref == .system {
            arguments.removeValue(forKey: "AppleLanguages")
        } else {
            arguments["AppleLanguages"] = [pref.rawValue]
        }
        UserDefaults.standard.setVolatileDomain(arguments, forName: UserDefaults.argumentDomain)
    }

    /// The app bundle (or bare executable, for `swift run`) to start again.
    static func relaunchTarget(bundleURL: URL, executableURL: URL?) -> URL? {
        var current = bundleURL
        while current.path != "/" {
            if current.pathExtension == "app" { return current }
            current = current.deletingLastPathComponent()
        }
        return executableURL
    }

    /// Waits (up to 10 s) for this process to exit before reopening, so two copies never run at
    /// once and a cancelled quit doesn't leave a second instance behind.
    static func relaunchScript(pid: Int32, target: URL) -> [String] {
        let launch = target.pathExtension == "app" ? "/usr/bin/open \"$1\"" : "\"$1\" &"
        return ["-c", "for i in $(seq 100); do kill -0 \(pid) 2>/dev/null || { \(launch); exit 0; }; sleep 0.1; done", "relaunch", target.path]
    }

    @MainActor
    public static func relaunchApp() {
        guard let target = relaunchTarget(bundleURL: Bundle.main.bundleURL, executableURL: Bundle.main.executableURL) else { return }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        process.arguments = relaunchScript(pid: ProcessInfo.processInfo.processIdentifier, target: target)
        do { try process.run() } catch { return }
        NSApp.terminate(nil)
    }

    /// Offers to restart now; a running terminal command would end, so it is never automatic.
    @MainActor
    public static func confirmRelaunch() {
        let alert = NSAlert()
        alert.messageText = L10n.text("Restart Shark to apply the language?")
        alert.informativeText = L10n.text("Your tabs are restored after restarting. Commands running in the terminal will stop.")
        alert.addButton(withTitle: L10n.text("Restart Now"))
        alert.addButton(withTitle: L10n.text("Later"))
        if alert.runModal() == .alertFirstButtonReturn { relaunchApp() }
    }

    public static func bundle(for language: AppLanguage) -> Bundle {
        let selected = language == .system ? Self.language : language
        guard let path = Bundle.module.path(forResource: selected.rawValue, ofType: "lproj"),
              let bundle = Bundle(path: path) else { return Bundle.module }
        return bundle
    }

    public static func catalog(for language: AppLanguage) throws -> [String: String] {
        guard let url = bundle(for: language).url(forResource: "Localizable", withExtension: "strings") else {
            throw CocoaError(.fileNoSuchFile)
        }
        return try PropertyListSerialization.propertyList(from: Data(contentsOf: url), format: nil) as? [String: String] ?? [:]
    }
}

/// English source keys remain stable across translations. Never pass user names,
/// filesystem paths, shell commands, or persisted identifiers through this API.
public enum L10n {
    public static func text(_ key: String) -> String {
        text(key, language: AppLocalization.language)
    }
    public static func text(_ key: String, language: AppLanguage) -> String {
        AppLocalization.bundle(for: language).localizedString(forKey: key, value: key, table: nil)
    }
    public static func format(_ key: String, _ arguments: CVarArg...) -> String {
        String(format: text(key), locale: AppLocalization.locale, arguments: arguments)
    }
    public static func items(_ count: Int) -> String { format("items.count", count) }
    public static func results(_ count: Int) -> String { format("results.count", count) }
    public static func tabs(_ count: Int) -> String { format("tabs.count", count) }
    /// Unicode first-strong isolation preserves mixed-script filenames inside RTL UI.
    public static func literal(_ value: String) -> String { "\u{2068}\(value)\u{2069}" }
}
