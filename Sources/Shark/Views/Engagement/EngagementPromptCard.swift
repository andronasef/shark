import SwiftUI
import StoreKit

public struct EngagementPromptCard: View {
    public let prompt: EngagementPromptType
    public let onPrimaryAction: () -> Void
    public let onSnooze: () -> Void
    public let onDismiss: () -> Void

    @Environment(\.requestReview) private var requestReview

    public init(
        prompt: EngagementPromptType,
        onPrimaryAction: @escaping () -> Void,
        onSnooze: @escaping () -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.prompt = prompt
        self.onPrimaryAction = onPrimaryAction
        self.onSnooze = onSnooze
        self.onDismiss = onDismiss
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(alignment: .center, spacing: 10) {
                iconBadge

                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 8)

                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.tertiary)
                        .frame(width: 18, height: 18)
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .help(L10n.text("Don't ask again"))
            }

            // Message
            Text(message)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(2)

            // Buttons
            HStack(spacing: 8) {
                Spacer()

                Button(action: onSnooze) {
                    Text(L10n.text("Maybe Later"))
                        .font(.system(size: 12))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                }
                .buttonStyle(.borderless)
                .foregroundStyle(.secondary)

                Button(action: handlePrimary) {
                    HStack(spacing: 4) {
                        Image(systemName: primaryIconName)
                            .font(.system(size: 11, weight: .medium))
                        Text(primaryActionTitle)
                            .font(.system(size: 12, weight: .medium))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                }
                .buttonStyle(.borderedProminent)
                .tint(accentTint)
                .controlSize(.small)
            }
        }
        .padding(14)
        .frame(width: 340)
        .liquidGlassCard(cornerRadius: 14, material: .popover)
    }

    private func handlePrimary() {
        if prompt == .rateAppStore {
            requestReview()
        }
        onPrimaryAction()
    }

    @ViewBuilder
    private var iconBadge: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(badgeBackground)
                .frame(width: 32, height: 32)

            Image(systemName: badgeIconName)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
        }
    }

    private var badgeBackground: LinearGradient {
        switch prompt {
        case .rateAppStore:
            return LinearGradient(
                colors: [Color.blue, Color.cyan],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .shareWithFriends:
            return LinearGradient(
                colors: [Color.indigo, Color.purple],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var badgeIconName: String {
        switch prompt {
        case .rateAppStore: return "star.fill"
        case .shareWithFriends: return "sparkles"
        }
    }

    private var title: String {
        switch prompt {
        case .rateAppStore:
            return L10n.text("Enjoying Shark?")
        case .shareWithFriends:
            return L10n.text("100 Fast Hops! 🎉")
        }
    }

    private var subtitle: String {
        switch prompt {
        case .rateAppStore:
            return L10n.text("Mac App Store Review")
        case .shareWithFriends:
            return L10n.text("Milestone Reached")
        }
    }

    private var message: String {
        switch prompt {
        case .rateAppStore:
            return L10n.text("If Shark makes managing your files faster, rating it on the Mac App Store helps other Mac users discover it!")
        case .shareWithFriends:
            return L10n.text("You've navigated over 100 folders and tabs! Share Shark with friends or coworkers who love fast Mac tools.")
        }
    }

    private var primaryActionTitle: String {
        switch prompt {
        case .rateAppStore:
            return L10n.text("Rate on App Store")
        case .shareWithFriends:
            return L10n.text("Share with Friends")
        }
    }

    private var primaryIconName: String {
        switch prompt {
        case .rateAppStore:
            return "arrow.up.forward.app"
        case .shareWithFriends:
            return "square.and.arrow.up"
        }
    }

    private var accentTint: Color {
        switch prompt {
        case .rateAppStore:
            return Color.blue
        case .shareWithFriends:
            return Color.indigo
        }
    }
}
