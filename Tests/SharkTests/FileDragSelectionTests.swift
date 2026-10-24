import Foundation
import Testing
@testable import Shark

struct FileDragSelectionTests {
    @Test func selectedDragCarriesWholeSelectionInVisibleOrder() {
        let a = URL(fileURLWithPath: "/tmp/صورة 'one'.jpg")
        let b = URL(fileURLWithPath: "/tmp/two.jpg")
        #expect(FileDragSelection.urls(dragged: a, selected: [a, b], ordered: [b, a]) == [b, a])
        #expect(FileDragSelection.urls(dragged: b, selected: [a], ordered: [a, b]) == [b])
    }

    @Test func externalPayloadDeduplicatesAndDoesNotMoveChildrenTwice() {
        let parent = URL(fileURLWithPath: "/tmp/album")
        let child = parent.appendingPathComponent("one.jpg")
        let sibling = URL(fileURLWithPath: "/tmp/album-other")
        #expect(FileDragSelection.normalized([child, parent, parent, sibling]) == [parent, sibling])
    }
}
