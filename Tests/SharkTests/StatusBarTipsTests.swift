import Foundation
import Testing
@testable import Shark

@MainActor
struct StatusBarTipsTests {
    @Test func onlyOneOfTenRollsShowsATip() {
        let results = (0..<10).compactMap { StatusBarTips.choose(roll: $0, index: 0) }
        #expect(results == [StatusBarTips.tips[0]])
        #expect(StatusBarTips.choose(roll: 0, index: -1) == nil)
    }

    @Test func catalogHasDistinctTipsAndTranslationsInEveryLanguage() throws {
        #expect(StatusBarTips.tips.count == 93)
        #expect(Set(StatusBarTips.tips.map { $0.localizedText(language: .en) }).count == StatusBarTips.tips.count)
        for language in AppLanguage.allCases where language != .system {
            let catalog = try AppLocalization.catalog(for: language)
            for tip in StatusBarTips.tips {
                #expect(catalog[tip.title]?.isEmpty == false, "Missing title: \(language) \(tip.title)")
                if !tip.context.isEmpty {
                    #expect(catalog[tip.context]?.isEmpty == false, "Missing context: \(language) \(tip.context)")
                }
                // Keyboard symbols and function keys do not need translation; words and gestures do.
                if !tip.shortcut.isEmpty && !tip.shortcut.hasPrefix("F") && !tip.shortcut.contains(where: { "⌘⌃⌥⇧".contains($0) }) {
                    #expect(catalog[tip.shortcut]?.isEmpty == false, "Missing hint: \(language) \(tip.shortcut)")
                }
            }
        }
    }

    @Test func disabledOptionalGesturesAreNotSuggested() throws {
        for setting in [MouseSetting.tabDoubleClickPin, .tabStripScroll] {
            let previous = UserDefaults.standard.object(forKey: setting.key)
            defer {
                if let previous { UserDefaults.standard.set(previous, forKey: setting.key) }
                else { UserDefaults.standard.removeObject(forKey: setting.key) }
            }
            let index = try #require(StatusBarTips.tips.firstIndex { $0.mouseSetting == setting })
            UserDefaults.standard.set(false, forKey: setting.key)
            #expect(StatusBarTips.choose(roll: 0, index: index) == nil)
            UserDefaults.standard.set(true, forKey: setting.key)
            #expect(StatusBarTips.choose(roll: 0, index: index) == StatusBarTips.tips[index])
        }
    }

    @Test func photoShortcutsKeepTheirLocalizedContext() {
        let tip = StatusBarTips.tips.first { $0.title == "Fit to Window" }!
        #expect(tip.localizedText(language: .en) == "Photo Viewer: Fit to Window (⌘0)")
        #expect(tip.localizedText(language: .ar).contains(L10n.text("Photo Viewer", language: .ar)))
    }

    @Test func selectionAndOperationsDismissTips() {
        let state = NavigationState(initialURL: URL(fileURLWithPath: "/tmp"))
        state.statusBarTip = StatusBarTips.tips[0]
        state.selectedItemIDs = [URL(fileURLWithPath: "/tmp/file")]
        #expect(state.statusBarTip == nil)
        state.selectedItemIDs = []
        #expect(state.statusBarTip == nil)
        state.statusBarTip = StatusBarTips.tips[1]
        state.activeOperationTitle = "Copying"
        #expect(state.statusBarTip == nil)
        state.activeOperationTitle = nil
        #expect(state.statusBarTip == nil)
    }
}
