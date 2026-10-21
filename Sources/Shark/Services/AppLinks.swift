import Foundation
import AppKit

/// Central registry for project links and about information.
@MainActor
public enum AppLinks {
    public static let repository = URL(string: "https://github.com/andronasef/shark")!
    public static let website = URL(string: "https://shark.andronasef.com/")!
    public static let author = URL(string: "https://andronasef.com/")!
    public static let feedback = URL(string: "https://userhq.increasinglabs.com/increasing-labs/shark")!

    /// Displays the standard About panel populated with credits and external links.
    public static func showAboutPanel() {
        let credits = NSMutableAttributedString()

        let baseFont = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)
        let boldFont = NSFont.boldSystemFont(ofSize: NSFont.smallSystemFontSize)
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        paragraph.lineSpacing = 4

        func append(_ text: String, font: NSFont = baseFont, url: URL? = nil) {
            var attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .paragraphStyle: paragraph
            ]
            if let url {
                attributes[.link] = url
                attributes[.foregroundColor] = NSColor.linkColor
            } else {
                attributes[.foregroundColor] = NSColor.labelColor
            }
            credits.append(NSAttributedString(string: text, attributes: attributes))
        }

        append("Created by ")
        append("Andrew Nasef", font: boldFont, url: author)
        append("\n\n")
        append("Website", url: website)
        append("  •  ")
        append("GitHub", url: repository)
        append("  •  ")
        append("Feedback", url: feedback)

        let options: [NSApplication.AboutPanelOptionKey: Any] = [
            .credits: credits
        ]
        NSApp.orderFrontStandardAboutPanel(options: options)
    }
}
