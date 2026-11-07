import Foundation
import Testing
@testable import Shark

@MainActor
struct EngagementPromptServiceTests {

    private func makeIsolatedService(
        initialDate: Date = Date(),
        isAppStore: Bool = true
    ) -> (EngagementPromptService, UserDefaults, @Sendable (Date) -> Void) {
        let suiteName = "EngagementPromptServiceTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        final class DateBox: @unchecked Sendable {
            var current: Date
            init(_ date: Date) { self.current = date }
        }
        let box = DateBox(initialDate)

        let service = EngagementPromptService(
            defaults: defaults,
            currentDate: { box.current },
            isAppStoreProvider: { isAppStore }
        )

        let advanceDate: @Sendable (Date) -> Void = { newDate in
            box.current = newDate
        }

        return (service, defaults, advanceDate)
    }

    @Test func testInitialStateDoesNotTriggerPrompt() {
        let (service, _, _) = makeIsolatedService()
        #expect(service.activePrompt == nil)
        #expect(service.hasRated == false)
        #expect(service.hasShared == false)
        #expect(service.interactionCount == 0)
        #expect(service.ratingPresentations == 0)
        #expect(service.sharePresentations == 0)
    }

    @Test func testRatingPromptRequiresSevenDays() {
        let calendar = Calendar.current
        let start = Date()
        let (service, _, setDate) = makeIsolatedService(initialDate: start, isAppStore: true)

        // Day 1: 10 interactions
        for _ in 0..<10 { service.recordInteraction() }
        #expect(service.activePrompt == nil)

        // Day 3: 10 more interactions (total 20), but only 2 days elapsed
        let day3 = calendar.date(byAdding: .day, value: 2, to: start)!
        setDate(day3)
        for _ in 0..<10 { service.recordInteraction() }
        #expect(service.activePrompt == nil)

        // Day 6: still before 7 days
        let day6 = calendar.date(byAdding: .day, value: 5, to: start)!
        setDate(day6)
        service.recordInteraction()
        #expect(service.activePrompt == nil)

        // Day 8: 7+ days, 3+ active days, 20+ interactions -> triggers!
        let day8 = calendar.date(byAdding: .day, value: 7, to: start)!
        setDate(day8)
        service.recordInteraction()
        #expect(service.activePrompt == .rateAppStore)
        #expect(service.ratingPresentations == 1)
    }

    @Test func testRatingPromptNeverFiresOnNonAppStoreBuild() {
        let calendar = Calendar.current
        let start = Date()
        let (service, _, setDate) = makeIsolatedService(initialDate: start, isAppStore: false)

        // Simulate 3 distinct days and 50 interactions
        for d in 0..<3 {
            let day = calendar.date(byAdding: .day, value: d * 3, to: start)!
            setDate(day)
            for _ in 0..<20 { service.recordInteraction() }
        }

        // Fast forward 10 days
        let day10 = calendar.date(byAdding: .day, value: 10, to: start)!
        setDate(day10)
        service.recordInteraction()

        // Rating prompt should never appear for non-MAS builds!
        #expect(service.activePrompt != .rateAppStore)
    }

    @Test func testRatingPromptSnoozeAndMaxPresentations() {
        let calendar = Calendar.current
        let start = Date()
        let (service, _, setDate) = makeIsolatedService(initialDate: start, isAppStore: true)

        // Day 1, 2, 3: active days with 20 interactions
        for d in 0..<3 {
            setDate(calendar.date(byAdding: .day, value: d, to: start)!)
            for _ in 0..<7 { service.recordInteraction() }
        }

        // Advance to Day 8 (7+ days elapsed)
        setDate(calendar.date(byAdding: .day, value: 7, to: start)!)
        service.recordInteraction()
        #expect(service.activePrompt == .rateAppStore)
        #expect(service.ratingPresentations == 1)

        // Snooze
        service.snooze(prompt: .rateAppStore)
        #expect(service.activePrompt == nil)

        // After 10 days (under 14 days snooze), should not trigger
        setDate(calendar.date(byAdding: .day, value: 17, to: start)!)
        service.recordInteraction()
        #expect(service.activePrompt == nil)

        // After 14 days snooze (Day 22), triggers 2nd presentation
        setDate(calendar.date(byAdding: .day, value: 21, to: start)!)
        service.recordInteraction()
        #expect(service.activePrompt == .rateAppStore)
        #expect(service.ratingPresentations == 2)

        // Snooze again
        service.snooze(prompt: .rateAppStore)
        #expect(service.activePrompt == nil)

        // After another 14 days, max presentations reached (2), never prompts again
        setDate(calendar.date(byAdding: .day, value: 40, to: start)!)
        service.recordInteraction()
        #expect(service.activePrompt != .rateAppStore)
    }

    @Test func testDismissPermanentlyStopsPrompt() {
        let calendar = Calendar.current
        let start = Date()
        let (service, _, setDate) = makeIsolatedService(initialDate: start, isAppStore: true)

        for d in 0..<3 {
            setDate(calendar.date(byAdding: .day, value: d, to: start)!)
            for _ in 0..<7 { service.recordInteraction() }
        }

        setDate(calendar.date(byAdding: .day, value: 8, to: start)!)
        service.recordInteraction()
        #expect(service.activePrompt == .rateAppStore)

        service.dismissPermanently(prompt: .rateAppStore)
        #expect(service.activePrompt == nil)
        #expect(service.hasRated == true)

        setDate(calendar.date(byAdding: .day, value: 30, to: start)!)
        service.recordInteraction()
        #expect(service.activePrompt == nil)
    }

    @Test func testSharePromptTriggersAt100InteractionsAnd14Days() {
        let calendar = Calendar.current
        let start = Date()
        // Non-App Store build so rating prompt doesn't intercept
        let (service, _, setDate) = makeIsolatedService(initialDate: start, isAppStore: false)

        // 100 interactions before 14 days
        for _ in 0..<100 { service.recordInteraction() }
        #expect(service.activePrompt == nil)

        // Advance to 14+ days
        setDate(calendar.date(byAdding: .day, value: 14, to: start)!)
        service.recordInteraction()
        #expect(service.activePrompt == .shareWithFriends)
        #expect(service.sharePresentations == 1)

        service.snooze(prompt: .shareWithFriends)
        #expect(service.activePrompt == nil)
    }

    @Test func testSharePromptRespectsSeparationFromRatingPrompt() {
        let calendar = Calendar.current
        let start = Date()
        let (service, _, setDate) = makeIsolatedService(initialDate: start, isAppStore: true)

        // Meet rating criteria at day 7 with 105 interactions
        for d in 0..<3 {
            setDate(calendar.date(byAdding: .day, value: d, to: start)!)
            for _ in 0..<35 { service.recordInteraction() }
        }
        let day8 = calendar.date(byAdding: .day, value: 7, to: start)!
        setDate(day8)
        service.recordInteraction()
        #expect(service.activePrompt == .rateAppStore)

        // User rates or dismisses
        service.dismissPermanently(prompt: .rateAppStore)
        #expect(service.activePrompt == nil)

        // Day 14 (7 days after start): 6 days after rating prompt (< 7 day separation)
        let day14 = calendar.date(byAdding: .day, value: 13, to: start)!
        setDate(day14)
        service.recordInteraction()
        #expect(service.activePrompt == nil)

        // Day 16 (8 days after rating prompt, >= 7 separation): share prompt can appear!
        let day16 = calendar.date(byAdding: .day, value: 15, to: start)!
        setDate(day16)
        service.recordInteraction()
        #expect(service.activePrompt == .shareWithFriends)
    }
}
