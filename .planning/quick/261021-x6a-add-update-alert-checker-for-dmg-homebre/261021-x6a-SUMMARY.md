---
phase: quick-261021-x6a
plan: 01
subsystem: updates
status: complete
tags: [updates, semver, github-releases, homebrew, app-store, settings]
requires: []
provides:
  - "UpdateChecker (manual + daily automatic check, alert-only)"
  - "SemanticVersion (full SemVer precedence)"
  - "SharkSettings.automaticallyCheckForUpdates"
affects: [SharkApp menus, Settings › General, CHANGELOG, website features catalog]
tech-stack:
  added: []
  patterns: ["async URLSession on the main actor, nonisolated static pure helpers for tests"]
key-files:
  created:
    - Sources/Shark/Services/UpdateChecker.swift
    - Tests/SharkTests/UpdateCheckerTests.swift
  modified:
    - Sources/Shark/SharkApp.swift
    - Sources/Shark/Services/SharkSettings.swift
    - Sources/Shark/Views/Settings/SettingsView.swift
    - CHANGELOG.md
    - website/src/data/features.ts
decisions:
  - "The App Store version must parse as X.Y.Z; anything else is treated as up to date (per plan)"
  - "Skipped version is stored and compared as the normalized SemVer string (no leading v)"
metrics:
  duration: ~5min
  completed: 2026-10-21
actuals:
  tokens: 5400
  tasks: 3
  commits: 3
plan_head_before: 0ef4199d5b40a907b808433ba697c551a25965e3
plan_head_after: 48e1df20e58601eda952315b8f4b4d2def15b118
---

# Quick 261021-x6a Plan 01: Update Alert Checker Summary

Alert-only update checker with no new dependency. It uses SemVer-correct GitHub release picking (prereleases only for prerelease users, drafts skipped, .dmg asset or release-page fallback) and adds an iTunes lookup for App Store installs. The action button follows the install channel: Download, Copy Command (`brew upgrade --cask shark`) or Open App Store. It runs from Shark › Check for Updates… and from a once-a-day launch check you can turn off.

## Tasks

| Task | Name | Commit | Files |
| ---- | ---- | ------ | ----- |
| 1 (tracer, TDD) | Menu item → GitHub check → DMG alert, pure logic under test | d225435 | UpdateChecker.swift, UpdateCheckerTests.swift, SharkApp.swift |
| 2 | Homebrew / App Store channels, daily launch check, skip handling, settings toggle | 23150f7 | UpdateChecker.swift, SharkApp.swift, SharkSettings.swift, SettingsView.swift |
| 3 | CHANGELOG [Unreleased] ### Added + features.ts `update-alerts` | 48e1df2 | CHANGELOG.md, website/src/data/features.ts |

## Checks actually run

- **TDD RED:** `swift build --build-tests` failed with "cannot find type 'SemanticVersion' / 'GitHubRelease'" before the implementation existed.
- **swift build:** clean after Tasks 1 and 2, with no warnings from the new code.
- **swift test --filter UpdateCheckerTests:** 12/12 passed. The tests cover SemVer spec ordering, numeric core ordering, v-prefix and build metadata, invalid strings, draft drop, stable vs prerelease filtering, highest-wins, nil cases, .dmg vs .dmg.sha256, zip-only fallback to html_url, and channel precedence.
- **swift test (full suite):** 130 tests, 0 failures.
- **Website build:** `npm --prefix website run build` failed because `npm` resolves to a runner that rejects `--prefix`. `npm run build` inside `website/` succeeded (3 pages), and `dist/features/index.html` contains the new entry. The page was not checked visually at desktop or mobile sizes. It is one text entry in an existing grid.
- **Running app (`bash scripts/run.sh` + cua-driver):**
  - The launch produced no alert. Only the main window was present, which is expected because the dev version 1.0 skips silently.
  - Shark › Check for Updates… exists in the app menu. Invoking it showed the alert "Update checking is unavailable in development builds." / "This build's version is "1.0", which is not a release version." with OK. That proves menu → checker → alert end to end.
  - Settings › General shows a new "Updates" section with "Automatically check for updates", on by default, and the caption. It fits the 480x360 window without scrolling (screenshot checked).

## Not verified (for UAT)

The real update-available alert could not be shown from the running app. Dev builds report version 1.0, so the network path never runs there. To see it, run a build stamped with a release version older than the latest tag, such as a packaged 1.0.0-alpha build. That would exercise these paths:
- the DMG Download button
- Skip This Version
- the Homebrew Copy Command button (needs Caskroom/shark)
- the App Store path (needs a receipt; the lookup currently returns resultCount 0)
- the 24h throttle

## Deviations from Plan

None in the code. One verification note: the plan's `npm --prefix website run build` command does not work in this environment. The equivalent `npm run build` from `website/` was run instead.

Branch: the orchestrator told me to run on `main` in the main working tree, so the commits are on `main` and were not pushed.

## Threat Flags

None beyond the plan's threat model. T-x6a-01: only https URLs are opened, the releases page is the fallback, and the App Store URL is only rewritten to macappstore after an https check. T-x6a-02: the pasteboard gets the compile-time constant. T-x6a-03: typed Decodable, non-200 throws, and errors are silent when automatic.

## Self-Check: PASSED

- FOUND: Sources/Shark/Services/UpdateChecker.swift, Tests/SharkTests/UpdateCheckerTests.swift
- FOUND commits: d225435, 23150f7, 48e1df2 (ancestors of HEAD)
