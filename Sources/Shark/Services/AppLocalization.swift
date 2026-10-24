import Foundation
import SwiftUI

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
    /// Captured once: changing the preference takes effect after relaunch, consistently
    /// for SwiftUI, AppKit menus and dialogs.
    public static let language: AppLanguage = resolvedLanguage(
        preference: AppLanguage.preference(UserDefaults.standard.string(forKey: preferenceKey)),
        preferredLanguages: Locale.preferredLanguages
    )
    public static var locale: Locale { Locale(identifier: language.rawValue) }
    public static var layoutDirection: LayoutDirection { language.isRightToLeft ? .rightToLeft : .leftToRight }

    public static func resolvedLanguage(preference: AppLanguage, preferredLanguages: [String]) -> AppLanguage {
        if preference != .system { return preference }
        let supported = AppLanguage.allCases.filter { $0 != .system }.map(\.rawValue)
        let match = Bundle.preferredLocalizations(from: supported, forPreferences: preferredLanguages).first ?? "en"
        return AppLanguage(rawValue: match) ?? .en
    }

    public static func configureAtStartup() {
        // Process-only override also guides AppKit's standard menu strings. Never
        // persist AppleLanguages, so System Default continues to follow macOS.
        var arguments = UserDefaults.standard.volatileDomain(forName: UserDefaults.argumentDomain)
        arguments["AppleLanguages"] = [language.rawValue]
        UserDefaults.standard.setVolatileDomain(arguments, forName: UserDefaults.argumentDomain)
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
