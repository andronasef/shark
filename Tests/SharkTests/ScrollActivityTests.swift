import Testing
@testable import Shark

@MainActor
struct ScrollActivityTests {
    @Test func scrollingSettlesAfterEventsStop() async throws {
        let activity = ScrollActivity(monitoring: false)
        activity.noteScroll(settleMilliseconds: 250)
        #expect(activity.isScrolling)
        try await Task.sleep(for: .milliseconds(40))
        #expect(activity.isScrolling)
        activity.noteScroll(settleMilliseconds: 250) // a later event extends the scroll
        try await Task.sleep(for: .milliseconds(40))
        #expect(activity.isScrolling)
        try await Task.sleep(for: .milliseconds(350))
        #expect(!activity.isScrolling)
    }
}
