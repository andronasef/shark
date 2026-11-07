# Quick Task Summary: Mac App Store Rating & Share with Friends Prompts

## 1. Overview
Implemented polite, non-intrusive, and prominent prompts to invite active users to:
1. **Rate Shark on the Mac App Store**: Strictly gated to Mac App Store distribution builds after 7+ days of usage, 3+ distinct active calendar days, and 20+ folder/tab interactions.
2. **Share Shark with Friends**: For all distribution channels after 14+ days of usage and a 100+ interaction milestone, separated by a 7-day cooldown buffer after the rating prompt.

## 2. Key Changes & Implementations

### Services & Logic
- **[`Sources/Shark/Services/AppLinks.swift`](file:///Users/andrew/Documents/Work/Dev/Projects/Personalss/shark/Sources/Shark/Services/AppLinks.swift)**: Added `macAppStoreId = "6825086341"`, `macAppStore`, `macAppStoreReview` (`macappstore://apps.apple.com/app/id6825086341?action=write-review`), and `macAppStoreWebReview`.
- **[`Sources/Shark/Services/UpdateChecker.swift`](file:///Users/andrew/Documents/Work/Dev/Projects/Personalss/shark/Sources/Shark/Services/UpdateChecker.swift)**: Exposed `public static var isAppStoreInstall: Bool` based on receipt presence.
- **[`Sources/Shark/Services/EngagementPromptService.swift`](file:///Users/andrew/Documents/Work/Dev/Projects/Personalss/shark/Sources/Shark/Services/EngagementPromptService.swift)**:
  - Tracks first launch date, distinct calendar active days, interaction counts, presentation counts (capped at 2), snooze timestamps (14-day intervals), and dismissal flags.
  - Exposes `recordInteraction()`, `rateDirectly()`, `shareShark()`, `snooze(prompt:)`, and `dismissPermanently(prompt:)`.
  - Supports dependency injection for testing dates, `UserDefaults`, and install channel providers.
- **[`Sources/Shark/State/NavigationState.swift`](file:///Users/andrew/Documents/Work/Dev/Projects/Personalss/shark/Sources/Shark/State/NavigationState.swift)** & **[`Sources/Shark/State/WorkspaceState.swift`](file:///Users/andrew/Documents/Work/Dev/Projects/Personalss/shark/Sources/Shark/State/WorkspaceState.swift)**:
  - Wired interaction triggers into folder changes (`currentURL.didSet`) and new tab creation (`newTab`).

### User Interface & Menus
- **[`Sources/Shark/Views/Engagement/EngagementPromptCard.swift`](file:///Users/andrew/Documents/Work/Dev/Projects/Personalss/shark/Sources/Shark/Views/Engagement/EngagementPromptCard.swift)**:
  - Visible, floating liquid glass card (`.liquidGlassCard(cornerRadius: 14, material: .popover)`) with SF Symbol badge, clear title, friendly copy, prominent primary action button, subtle "Maybe Later" snooze, and permanent dismiss "✕" button.
  - Integrates `@Environment(\.requestReview)`.
- **[`Sources/Shark/Views/ContentView.swift`](file:///Users/andrew/Documents/Work/Dev/Projects/Personalss/shark/Sources/Shark/Views/ContentView.swift)**:
  - Anchored as an overlay at bottom-trailing with liquid spring physics animation.
- **[`Sources/Shark/SharkApp.swift`](file:///Users/andrew/Documents/Work/Dev/Projects/Personalss/shark/Sources/Shark/SharkApp.swift)** (`HelpCommands`):
  - Added "Rate Shark on Mac App Store…" (MAS builds only) and "Share Shark with Friends…" (all builds) under the Help menu.

### Localization
- Added all 13 strings translated across all 8 supported languages:
  - English (`en`), Arabic (`ar`), German (`de`), Spanish (`es`), French (`fr`), Japanese (`ja`), Portuguese (Brazil) (`pt-BR`), and Simplified Chinese (`zh-Hans`).

### Testing & Verification
- **[`Tests/SharkTests/EngagementPromptServiceTests.swift`](file:///Users/andrew/Documents/Work/Dev/Projects/Personalss/shark/Tests/SharkTests/EngagementPromptServiceTests.swift)**:
  - 7 Swift Testing unit tests verifying initial state, 7-day threshold, MAS-only gating, 14-day snooze, 2-presentation ceiling, permanent dismiss, and share prompt separation.
  - Full test suite passed (240+ tests across the project).
