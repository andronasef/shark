import Foundation

/// One chance in ten per folder visit; render existing localized command names.
enum StatusBarTips {
    struct Tip: Equatable {
        let title: String
        let shortcut: String
    }

    static let tips = [
        Tip(title: "Edit Path (⌘L)", shortcut: ""),
        Tip(title: "Command Palette...", shortcut: "⌘K"),
        Tip(title: "Quick Look", shortcut: "Space"),
        Tip(title: "Toggle Split View (F3)", shortcut: ""),
        Tip(title: "Reopen Closed Tab", shortcut: "⇧⌘T"),
    ]

    static func choose(roll: Int = Int.random(in: 0..<10), index: Int = Int.random(in: 0..<tips.count)) -> Tip? {
        guard roll == 0, tips.indices.contains(index) else { return nil }
        return tips[index]
    }
}
