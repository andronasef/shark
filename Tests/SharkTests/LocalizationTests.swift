import XCTest
@testable import Shark

final class LocalizationTests: XCTestCase {
    func testUnknownPreferenceUsesSystemDefault() {
        XCTAssertEqual(AppLanguage.preference("unknown"), .system)
        XCTAssertEqual(AppLanguage.preference(nil), .system)
        XCTAssertEqual(AppLanguage.preference("pt-BR"), .ptBR)
    }

    func testArabicDirectionAndLiteralIsolation() {
        XCTAssertTrue(AppLanguage.ar.isRightToLeft)
        XCTAssertFalse(AppLanguage.ja.isRightToLeft)
        XCTAssertEqual(L10n.literal("/Users/أحمد/file.jpg"), "\u{2068}/Users/أحمد/file.jpg\u{2069}")
    }

    func testEveryLanguageHasSameResourceKeysAndFormatArguments() throws {
        let english = try AppLocalization.catalog(for: .en)
        XCTAssertFalse(english.isEmpty)
        for language in AppLanguage.allCases where language != .system {
            let translated = try AppLocalization.catalog(for: language)
            XCTAssertEqual(Set(english.keys), Set(translated.keys), language.rawValue)
            for (key, value) in english {
                XCTAssertEqual(formatTokens(value), formatTokens(translated[key] ?? ""), "\(language.rawValue): \(key)")
            }
        }
    }

    func testSystemPreferenceMatchesSupportedLanguageAndFallsBackToEnglish() {
        XCTAssertEqual(AppLocalization.resolvedLanguage(preference: .system, preferredLanguages: ["ar-EG"]), .ar)
        XCTAssertEqual(AppLocalization.resolvedLanguage(preference: .system, preferredLanguages: ["xx-ZZ"]), .en)
        XCTAssertEqual(AppLocalization.resolvedLanguage(preference: .de, preferredLanguages: ["ja"]), .de)
        XCTAssertEqual(L10n.text("missing.localization.key", language: .fr), "missing.localization.key")
        XCTAssertEqual(L10n.text("Cancel", language: .ar), "إلغاء")
    }

    func testExistingPreferenceIdentifiersRemainReadable() {
        XCTAssertEqual(DefaultStartupLocation(rawValue: "Last Session"), .lastSession)
        XCTAssertEqual(DefaultViewModeSetting(rawValue: "Details (List)"), .list)
    }

    private func formatTokens(_ value: String) -> [String] {
        let expression = try! NSRegularExpression(pattern: "%[0-9$.*]*[d@fslu]")
        return expression.matches(in: value, range: NSRange(value.startIndex..., in: value)).map {
            String(value[Range($0.range, in: value)!])
        }.sorted()
    }
}
