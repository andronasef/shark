---
phase: quick-261107-rate-and-share-prompts
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - Sources/Shark/Services/EngagementPromptService.swift
  - Sources/Shark/Services/UpdateChecker.swift
  - Sources/Shark/Services/AppLinks.swift
  - Sources/Shark/Views/Engagement/EngagementPromptCard.swift
  - Sources/Shark/Views/ContentView.swift
  - Sources/Shark/SharkApp.swift
  - Sources/Shark/State/NavigationState.swift
  - Sources/Shark/Resources/en.lproj/Localizable.strings
  - Sources/Shark/Resources/ar.lproj/Localizable.strings
  - Sources/Shark/Resources/de.lproj/Localizable.strings
  - Sources/Shark/Resources/es.lproj/Localizable.strings
  - Sources/Shark/Resources/fr.lproj/Localizable.strings
  - Sources/Shark/Resources/ja.lproj/Localizable.strings
  - Sources/Shark/Resources/pt-BR.lproj/Localizable.strings
  - Sources/Shark/Resources/zh-Hans.lproj/Localizable.strings
  - Tests/SharkTests/EngagementPromptServiceTests.swift
autonomous: true
requirements: [quick-261107-rate-and-share-prompts]

estimate:
  tokens: 25000
  raw_tokens: 25000
  tasks: 3
  confidence: high

must_haves:
  truths:
    - "App Store rating prompt only displays if install channel is verified Mac App Store."
    - "Rating prompt requires at least 7 elapsed days, 3 distinct active calendar days, and 20 user interactions."
    - "Friend-sharing prompt triggers after at least 14 elapsed days and 100 user interactions across all channels."
    - "Prompts appear as a visible, floating liquid glass card at the bottom of the window, dismissible and snoozable for 14 days (max 2 presentations)."
    - "Help menu contains permanent entries for Rate on Mac App Store (App Store builds) and Share Shark with Friends (all builds)."
    - "Localizations are provided for all 8 supported languages (en, ar, de, es, fr, ja, pt-BR, zh-Hans)."
    - "Unit test suite verifies eligibility rules, cooldowns, suppression, and channel filtering."
  artifacts:
    - path: Sources/Shark/Services/EngagementPromptService.swift
      provides: "Engagement tracking, eligibility engine, StoreKit review and NSSharingServicePicker triggers"
    - path: Sources/Shark/Views/Engagement/EngagementPromptCard.swift
      provides: "Prominent floating glass card UI"
    - path: Tests/SharkTests/EngagementPromptServiceTests.swift
      provides: "Unit tests for engagement rules"
---

# Quick Plan: App Store Rating & Share with Friends Prompts

## Tasks

### Task 1: EngagementPromptService & Channel Integration
- Expose install channel detection in UpdateChecker.swift and Mac App Store URLs in AppLinks.swift.
- Create EngagementPromptService.swift with configurable date math, active calendar days set, interaction counting, snooze, and permanent completion.
- Support SKStoreReviewController.requestReview and fallback to App Store write-review URL.
- Support NSSharingServicePicker with Shark website link and promotional text.

### Task 2: Floating Card UI, ContentView & Help Menu
- Create EngagementPromptCard.swift matching Shark's liquid glass design.
- Embed in ContentView.swift overlay with smooth transition.
- Record interactions on navigation and tab events.
- Add permanent menu items under Help in SharkApp.swift.

### Task 3: Localizations & Unit Tests
- Add strings to all 8 .lproj/Localizable.strings files.
- Write tests in Tests/SharkTests/EngagementPromptServiceTests.swift validating all eligibility rules.
