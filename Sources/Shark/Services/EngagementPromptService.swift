import Foundation
import Observation
import StoreKit
import AppKit

public enum EngagementPromptType: String, Sendable, CaseIterable {
    case rateAppStore
    case shareWithFriends
}

/// Service that coordinates asking happy, active users to rate Shark on the Mac App Store
/// or share Shark with friends at natural usage milestones.
@Observable
@MainActor
public final class EngagementPromptService {
    public static let shared = EngagementPromptService()

    public private(set) var activePrompt: EngagementPromptType?

    public let defaults: UserDefaults
    public var currentDate: @Sendable () -> Date
    public var isAppStoreProvider: @MainActor () -> Bool

    // Persistence Keys
    public static let firstLaunchDateKey = "engagementFirstLaunchDate"
    public static let activeDaysKey = "engagementActiveDays"
    public static let interactionCountKey = "engagementInteractionCount"
    public static let hasRatedKey = "engagementHasRated"
    public static let ratingPresentationsKey = "engagementRatingPresentations"
    public static let lastRatingPromptDateKey = "engagementLastRatingPromptDate"
    public static let hasSharedKey = "engagementHasShared"
    public static let sharePresentationsKey = "engagementSharePresentations"
    public static let lastSharePromptDateKey = "engagementLastSharePromptDate"

    // Business Rules
    public static let rateRequiredDays: Int = 7
    public static let rateRequiredActiveDays: Int = 3
    public static let rateRequiredInteractions: Int = 20
    public static let shareRequiredDays: Int = 14
    public static let shareRequiredInteractions: Int = 100
    public static let snoozeDays: Int = 14
    public static let promptSeparationDays: Int = 7
    public static let maxPresentations: Int = 2

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone.current
        return formatter
    }()

    public init(
        defaults: UserDefaults = .standard,
        currentDate: @escaping @Sendable () -> Date = { Date() },
        isAppStoreProvider: (@MainActor () -> Bool)? = nil
    ) {
        self.defaults = defaults
        self.currentDate = currentDate
        self.isAppStoreProvider = isAppStoreProvider ?? { UpdateChecker.isAppStoreInstall }
        initializeFirstLaunchIfNeeded()
    }

    private func initializeFirstLaunchIfNeeded() {
        if defaults.object(forKey: Self.firstLaunchDateKey) == nil {
            defaults.set(currentDate(), forKey: Self.firstLaunchDateKey)
        }
    }

    public var firstLaunchDate: Date {
        (defaults.object(forKey: Self.firstLaunchDateKey) as? Date) ?? currentDate()
    }

    public var activeDaysCount: Int {
        (defaults.stringArray(forKey: Self.activeDaysKey) ?? []).count
    }

    public var interactionCount: Int {
        defaults.integer(forKey: Self.interactionCountKey)
    }

    public var hasRated: Bool {
        defaults.bool(forKey: Self.hasRatedKey)
    }

    public var hasShared: Bool {
        defaults.bool(forKey: Self.hasSharedKey)
    }

    public var ratingPresentations: Int {
        defaults.integer(forKey: Self.ratingPresentationsKey)
    }

    public var sharePresentations: Int {
        defaults.integer(forKey: Self.sharePresentationsKey)
    }

    public var lastRatingPromptDate: Date? {
        defaults.object(forKey: Self.lastRatingPromptDateKey) as? Date
    }

    public var lastSharePromptDate: Date? {
        defaults.object(forKey: Self.lastSharePromptDateKey) as? Date
    }

    // MARK: - Usage Recording

    /// Records today in the set of active calendar days.
    public func recordActiveDay() {
        let todayString = Self.dayFormatter.string(from: currentDate())
        var days = Set(defaults.stringArray(forKey: Self.activeDaysKey) ?? [])
        if !days.contains(todayString) {
            days.insert(todayString)
            defaults.set(Array(days), forKey: Self.activeDaysKey)
        }
    }

    /// Records a user interaction (navigation, tab switch, file operation).
    public func recordInteraction() {
        recordActiveDay()
        let count = interactionCount + 1
        defaults.set(count, forKey: Self.interactionCountKey)
        evaluatePromptEligibility()
    }

    // MARK: - Eligibility Engine

    public func evaluatePromptEligibility() {
        guard activePrompt == nil else { return }

        let now = currentDate()
        let calendar = Calendar.current
        let daysSinceFirstLaunch = calendar.dateComponents([.day], from: firstLaunchDate, to: now).day ?? 0

        // 1. App Store Rating Check
        if isAppStoreProvider(),
           !hasRated,
           ratingPresentations < Self.maxPresentations,
           daysSinceFirstLaunch >= Self.rateRequiredDays,
           activeDaysCount >= Self.rateRequiredActiveDays,
           interactionCount >= Self.rateRequiredInteractions {

            let snoozePassed: Bool
            if let last = lastRatingPromptDate {
                let daysSinceLast = calendar.dateComponents([.day], from: last, to: now).day ?? 0
                snoozePassed = daysSinceLast >= Self.snoozeDays
            } else {
                snoozePassed = true
            }

            if snoozePassed {
                defaults.set(ratingPresentations + 1, forKey: Self.ratingPresentationsKey)
                defaults.set(now, forKey: Self.lastRatingPromptDateKey)
                activePrompt = .rateAppStore
                return
            }
        }

        // 2. Share with Friends Check (all install channels)
        if !hasShared,
           sharePresentations < Self.maxPresentations,
           daysSinceFirstLaunch >= Self.shareRequiredDays,
           interactionCount >= Self.shareRequiredInteractions {

            let snoozePassed: Bool
            if let last = lastSharePromptDate {
                let daysSinceLast = calendar.dateComponents([.day], from: last, to: now).day ?? 0
                snoozePassed = daysSinceLast >= Self.snoozeDays
            } else {
                snoozePassed = true
            }

            let separationPassed: Bool
            if let lastRate = lastRatingPromptDate {
                let daysSinceRate = calendar.dateComponents([.day], from: lastRate, to: now).day ?? 0
                separationPassed = daysSinceRate >= Self.promptSeparationDays
            } else {
                separationPassed = true
            }

            if snoozePassed && separationPassed {
                defaults.set(sharePresentations + 1, forKey: Self.sharePresentationsKey)
                defaults.set(now, forKey: Self.lastSharePromptDateKey)
                activePrompt = .shareWithFriends
                return
            }
        }
    }

    // MARK: - User Actions

    public func rateDirectly(requestReviewAction: (() -> Void)? = nil) {
        defaults.set(true, forKey: Self.hasRatedKey)
        activePrompt = nil

        if let requestReviewAction {
            requestReviewAction()
        } else {
            NSWorkspace.shared.open(AppLinks.macAppStoreReview)
        }
    }

    public func shareShark(from view: NSView? = nil) {
        defaults.set(true, forKey: Self.hasSharedKey)
        activePrompt = nil

        let shareText = L10n.text("Check out Shark — a lightning-fast, keyboard-driven dual-pane file manager for Mac!")
        let shareURL = isAppStoreProvider() ? AppLinks.macAppStore : AppLinks.website
        let items: [Any] = [shareText, shareURL]
        let picker = NSSharingServicePicker(items: items)

        if let view {
            picker.show(relativeTo: view.bounds, of: view, preferredEdge: .minY)
        } else if let window = NSApp.keyWindow, let contentView = window.contentView {
            picker.show(relativeTo: .zero, of: contentView, preferredEdge: .minY)
        }
    }

    public func snooze(prompt: EngagementPromptType) {
        // Presentation count and last prompt date were already stamped when prompt opened
        activePrompt = nil
    }

    public func dismissPermanently(prompt: EngagementPromptType) {
        switch prompt {
        case .rateAppStore:
            defaults.set(true, forKey: Self.hasRatedKey)
        case .shareWithFriends:
            defaults.set(true, forKey: Self.hasSharedKey)
        }
        activePrompt = nil
    }

    #if DEBUG
    public func simulatePrompt(_ prompt: EngagementPromptType) {
        activePrompt = prompt
    }
    #endif
}
