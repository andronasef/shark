import Testing
@testable import Shark

@MainActor
struct ScrollActivityTests {
    @Test func scrollingSettlesAfterEventsStop() async throws {
        let activity = ScrollActivity(monitoring: false)
        activity.noteScroll(settleMilliseconds: 40)
        #expect(activity.isScrolling)
        try await Task.sleep(for: .milliseconds(20))
        activity.noteScroll(settleMilliseconds: 40) // a later event extends the scroll
        try await Task.sleep(for: .milliseconds(25))
        #expect(activity.isScrolling)
        try await Task.sleep(for: .milliseconds(120))
        #expect(!activity.isScrolling)
    }
}
