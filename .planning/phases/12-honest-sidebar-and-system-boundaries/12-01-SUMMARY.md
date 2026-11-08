---
phase: 12-honest-sidebar-and-system-boundaries
plan: "01"
subsystem: ui
tags: [swiftui, sidebar, help, website]
requires: []
provides:
  - Places sidebar without fake Tags controls or focus stops
  - System Open/Save boundary explained in Help, welcome setup, FAQ and catalog
affects: [phase-19-tags]
tech-stack:
  added: []
  patterns: ["Focus order in moveSidebarFocus mirrors rendered sections"]
key-files:
  modified:
    - Sources/Shark/Views/Sidebar/PlacesSidebarView.swift
    - Sources/Shark/Views/Help/HelpView.swift
    - Sources/Shark/Views/Onboarding/OnboardingView.swift
    - Sources/Shark/Views/Settings/SettingsView.swift
    - website/src/data/features.ts
    - website/src/pages/index.astro
key-decisions:
  - "Kept the dormant Tags collapse preference untouched; no migration"
  - "Localized the two new strings and the corrected Settings caption in all eight languages"
requirements-completed: [HON-01, HON-02]
coverage:
  - id: D1
    description: "No Tags section, color filters or All Tags in either sidebar style"
    requirement: HON-01
    verification:
      - kind: automated_ui
        ref: "cua-driver accessibility tree and screenshots of Places and Folder Tree"
        status: pass
    human_judgment: false
  - id: D2
    description: "Arrow-key traversal skips removed rows"
    requirement: HON-01
    verification: []
    human_judgment: true
    rationale: "Focus order is a list built from the rendered sections and was checked by reading the source; live arrow-key behavior could not be observed with background input"
  - id: D3
    description: "Boundary copy in Help, welcome, FAQ and catalog"
    requirement: HON-02
    verification:
      - kind: automated_ui
        ref: "Help and welcome screenshots; built FAQ and JSON-LD read in preview"
        status: pass
    human_judgment: false
duration: 55min
completed: 2026-11-08
status: complete
---

# Phase 12 Plan 01: Honest Sidebar Summary

**Removed the fake Tags sidebar section and its keyboard stops, and stated in Help, welcome setup, the FAQ and the catalog that other apps keep the macOS Open and Save dialogs.**

## Accomplishments
- Deleted `tagItems`, the Tags section and its focus-order entries together.
- Corrected the stale "in place of Locations and Tags" wording in Settings (all eight languages), the catalog, DESIGN.md and a website guide.
- Added the boundary sentence to Help, welcome setup, the FAQ (with its structured data) and the default-folder-app entry.

## Task Commits
All three tasks shipped as one fix commit, as the plan asked: `1960e03` (fix).

## Deviations from Plan
**[Rule 3 - Blocking] Stale Metal toolchain path broke `swift test`.** The cached build pointed at a mount that no longer existed. Deleted `.build/out` (generated output only); tests then ran: XCTest and Swift Testing both pass with 0 failures.

**Total deviations:** 1 auto-fixed. **Impact:** none on source.

## Issues Encountered
- Live arrow-key traversal was not observable: background key delivery shows no focus ring and foreground control was not authorized. Recorded as a human-judgment item rather than passed.
- `docs/launch/marketing.md` and `docs/launch/reddit.md` carry someone else's uncommitted edits; left unstaged.

## Next Phase Readiness
Ready for Phase 13. Real tags (Phase 19) can add a Tags section back to the focus-order list in the same change.

---
*Phase: 12-honest-sidebar-and-system-boundaries*
*Completed: 2026-11-08*
