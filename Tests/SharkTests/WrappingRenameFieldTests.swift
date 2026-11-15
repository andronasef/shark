import Foundation
import Testing
@testable import Shark

struct WrappingRenameFieldTests {
    @Test func baseNameRangeExcludesExtension() {
        #expect(RenameEditorMetrics.baseNameRange(of: "report.pdf") == NSRange(location: 0, length: 6))
        #expect(RenameEditorMetrics.baseNameRange(of: "README") == NSRange(location: 0, length: 6))
        #expect(RenameEditorMetrics.baseNameRange(of: "archive.tar.gz") == NSRange(location: 0, length: 11))
        #expect(RenameEditorMetrics.baseNameRange(of: ".gitignore") == NSRange(location: 0, length: 10))
    }

    @Test func baseNameRangeCountsUTF16Units() {
        #expect(RenameEditorMetrics.baseNameRange(of: "Cafe\u{301}.txt") == NSRange(location: 0, length: 5))
        #expect(RenameEditorMetrics.baseNameRange(of: "😀.png") == NSRange(location: 0, length: 2))
        let arabic = "حب ودفا 12-11-2026 mp4.09.53"
        #expect(RenameEditorMetrics.baseNameRange(of: arabic)
            == NSRange(location: 0, length: (arabic as NSString).length - 3))
    }

    @Test func editorHeightClampsToLineLimits() {
        let line: CGFloat = 14
        let inset = RenameEditorMetrics.verticalInset
        #expect(RenameEditorMetrics.editorHeight(contentHeight: 14, lineHeight: line) == line + 2 * inset)
        #expect(RenameEditorMetrics.editorHeight(contentHeight: 42, lineHeight: line) == 3 * line + 2 * inset)
        #expect(RenameEditorMetrics.editorHeight(contentHeight: 126, lineHeight: line) == 5 * line + 2 * inset)
        #expect(RenameEditorMetrics.editorHeight(contentHeight: 0, lineHeight: line) == line + 2 * inset)
    }

    @Test func committedNameNormalisesText() {
        #expect(RenameEditorMetrics.committedName(from: "  new.txt \n", initialName: "old.txt") == "new.txt")
        #expect(RenameEditorMetrics.committedName(from: "a\nb", initialName: "old.txt") == "a b")
        #expect(RenameEditorMetrics.committedName(from: "a\r\nb", initialName: "old.txt") == "a b")
        #expect(RenameEditorMetrics.committedName(from: "  \n", initialName: "old.txt") == nil)
        #expect(RenameEditorMetrics.committedName(from: "old.txt", initialName: "old.txt") == nil)
    }
}
