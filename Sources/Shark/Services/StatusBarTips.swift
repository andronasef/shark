import Foundation

/// One chance in ten per folder visit. Keys match localized app controls and MouseHelp.
enum StatusBarTips {
    struct Tip: Equatable {
        let title: String
        let shortcut: String
        var context: String = ""
        var mouseSetting: MouseSetting? = nil

        func localizedText(language: AppLanguage = AppLocalization.language) -> String {
            let label = L10n.text(title, language: language).trimmingCharacters(in: CharacterSet(charactersIn: ":："))
            let prefix = context.isEmpty ? "" : L10n.text(context, language: language) + ": "
            let suffix = shortcut.isEmpty ? "" : " (" + L10n.text(shortcut, language: language) + ")"
            return prefix + label + suffix
        }
    }

    static let tips = [
        // Navigation and views
        Tip(title: "Focus Address Bar", shortcut: "⌘L"),
        Tip(title: "Command Palette...", shortcut: "⌘K"),
        Tip(title: "Quick Look", shortcut: "Space"),
        Tip(title: "Toggle Dual Split View", shortcut: "F3"),
        Tip(title: "Reopen Closed Tab", shortcut: "⇧⌘T"),
        Tip(title: "Find…", shortcut: "⌘F"),
        Tip(title: "Back", shortcut: "⌘["),
        Tip(title: "Forward", shortcut: "⌘]"),
        Tip(title: "Enclosing Folder", shortcut: "⌘↑"),
        Tip(title: "Go to Folder...", shortcut: "⇧⌘G"),
        Tip(title: "Home", shortcut: "⇧⌘H"),
        Tip(title: "Desktop", shortcut: "⇧⌘D"),
        Tip(title: "Documents", shortcut: "⇧⌘O"),
        Tip(title: "Downloads", shortcut: "⌥⌘L"),
        Tip(title: "Applications", shortcut: "⇧⌘A"),
        Tip(title: "Computer", shortcut: "⇧⌘C"),
        Tip(title: "as Icons", shortcut: "⌘1"),
        Tip(title: "as List", shortcut: "⌘2"),
        Tip(title: "as Columns", shortcut: "⌘3"),
        Tip(title: "as Gallery", shortcut: "⌘4"),
        Tip(title: "Show Hidden Files", shortcut: "⇧⌘."),
        Tip(title: "Show Path Bar", shortcut: "⌥⌘P"),
        Tip(title: "Zoom In", shortcut: "⌘+"),
        Tip(title: "Zoom Out", shortcut: "⌘-"),
        Tip(title: "Actual Size (Reset Zoom)", shortcut: "⌘0"),
        // Tabs and file operations
        Tip(title: "New Tab", shortcut: "⌘T"),
        Tip(title: "Close Tab", shortcut: "⌘W"),
        Tip(title: "Show Next Tab", shortcut: "⌃⇥"),
        Tip(title: "Show Previous Tab", shortcut: "⌃⇧⇥"),
        Tip(title: "Select Last Tab", shortcut: "⌥⌘9"),
        Tip(title: "Duplicate Tab", shortcut: "", context: "Tab"),
        Tip(title: "Pin Tab", shortcut: "", context: "Tab"),
        Tip(title: "Lock Tab", shortcut: "", context: "Tab"),
        Tip(title: "Save Tabs as Group...", shortcut: "", context: "Tab"),
        Tip(title: "Recently Closed", shortcut: "", context: "Tab"),
        Tip(title: "New Folder", shortcut: "⇧⌘N"),
        Tip(title: "New File", shortcut: "", context: "File"),
        Tip(title: "Open Selected", shortcut: "⌘O"),
        Tip(title: "Rename", shortcut: "F2"),
        Tip(title: "Cut", shortcut: "⌘X"),
        Tip(title: "Copy", shortcut: "⌘C"),
        Tip(title: "Paste", shortcut: "⌘V"),
        Tip(title: "Select All", shortcut: "⌘A"),
        Tip(title: "Move to Trash", shortcut: "⌘⌫"),
        Tip(title: "Undo", shortcut: "⌘Z"),
        Tip(title: "Redo", shortcut: "⇧⌘Z"),
        Tip(title: "Batch Rename…", shortcut: "Right-click a selection"),
        Tip(title: "Duplicate", shortcut: "Right-click"),
        Tip(title: "Compress", shortcut: "Right-click"),
        Tip(title: "Full Path", shortcut: "Copy Path"),
        Tip(title: "Relative Path", shortcut: "Copy Path"),
        Tip(title: "POSIX Quoted Path", shortcut: "Copy Path"),
        Tip(title: "Calculate Size", shortcut: "Right-click"),
        Tip(title: "Calculate All Folder Sizes", shortcut: "Command Palette..."),
        Tip(title: "Open With", shortcut: "Right-click"),
        Tip(title: "Show in Finder", shortcut: "Right-click"),
        Tip(title: "Share…", shortcut: "Right-click"),
        // Terminal, previews and preferences
        Tip(title: "Toggle Terminal Drawer", shortcut: "F4"),
        Tip(title: "Open in Terminal", shortcut: "Right-click"),
        Tip(title: "Open in Embedded Terminal", shortcut: "Right-click"),
        Tip(title: "Use Current Folder", shortcut: "The terminal drawer"),
        Tip(title: "File Inspector", shortcut: "⌥⌘I"),
        Tip(title: "Calculate SHA-256", shortcut: "File Inspector"),
        Tip(title: "Open in Shark Photo Viewer", shortcut: "Right-click"),
        Tip(title: "View Selected Photos", shortcut: "Right-click a selection"),
        Tip(title: "Only preview while holding Shift", shortcut: "", context: "Previews"),
        Tip(title: "Auto-play video and audio previews", shortcut: "", context: "Previews"),
        Tip(title: "Show a drop-down arrow beside hovered folders", shortcut: "", context: "Previews"),
        Tip(title: "Sidebar Style:", shortcut: "", context: "General"),
        Tip(title: "Appearance:", shortcut: "", context: "General"),
        Tip(title: "App Language:", shortcut: "", context: "General"),
        Tip(title: "Customize Toolbar…", shortcut: "", context: "View"),
        Tip(title: "Shark Help", shortcut: "⌘?"),
        Tip(title: "All Features", shortcut: "", context: "Help"),
        // Photo viewer (explicit context prevents shortcut ambiguity)
        Tip(title: "Fit to Window", shortcut: "⌘0", context: "Photo Viewer"),
        Tip(title: "Actual Size (100%)", shortcut: "⌘1", context: "Photo Viewer"),
        Tip(title: "Rotate Clockwise", shortcut: "⌘R", context: "Photo Viewer"),
        Tip(title: "Rotate Counter-Clockwise", shortcut: "⇧⌘R", context: "Photo Viewer"),
        Tip(title: "Flip Horizontal", shortcut: "", context: "Photo Viewer"),
        Tip(title: "Flip Vertical", shortcut: "", context: "Photo Viewer"),
        Tip(title: "Copy Image", shortcut: "⌘C", context: "Photo Viewer"),
        Tip(title: "Open in Default App", shortcut: "", context: "Photo Viewer"),
        Tip(title: "Toggle Thumbnail Filmstrip", shortcut: "⌘T", context: "Photo Viewer"),
        Tip(title: "Toggle Photo Info", shortcut: "⌘I", context: "Photo Viewer"),
        // Mouse reminders from MouseHelp (existing localized strings)
        Tip(title: "Middle-click a folder", shortcut: "Open in New Tab"),
        Tip(title: "Middle-click a place or path segment", shortcut: "Open in New Tab"),
        Tip(title: "⌘-click a path segment", shortcut: "Open in New Tab"),
        Tip(title: "Drag a folder into Favorites", shortcut: "Add it as a shortcut. Drop between favorites to choose its place."),
        Tip(title: "Double-click", shortcut: "Pin or unpin the tab.", context: "A tab", mouseSetting: .tabDoubleClickPin),
        Tip(title: "Scroll the wheel", shortcut: "Cycle through tabs. Down is the next tab, up is the previous one.", context: "A tab", mouseSetting: .tabStripScroll),
        Tip(title: "Right-click the + button", shortcut: "Tab Groups."),
        Tip(title: "⌘ + scroll wheel", shortcut: "Make icons larger or smaller."),
        Tip(title: "⌘⇧-click", shortcut: "Add everything from the last clicked item to this one, keeping the current selection."),
    ]

    static func choose(roll: Int = Int.random(in: 0..<10), index: Int = Int.random(in: 0..<tips.count)) -> Tip? {
        guard roll == 0, tips.indices.contains(index) else { return nil }
        let tip = tips[index]
        guard tip.mouseSetting?.isEnabled != false else { return nil }
        return tip
    }
}
