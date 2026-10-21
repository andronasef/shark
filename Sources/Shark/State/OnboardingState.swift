import Foundation
import Observation

@Observable
@MainActor
final class OnboardingState {
    var isPresented = false
    private let defaults: UserDefaults
    private static let presentedKey = "hasSeenWelcomeToShark"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func presentIfNeeded() {
        guard !defaults.bool(forKey: Self.presentedKey) else { return }
        // Remember presentation so Skip, Escape, and closing the window all respect the dismissal.
        defaults.set(true, forKey: Self.presentedKey)
        show()
    }

    func show() {
        isPresented = true
    }
}
