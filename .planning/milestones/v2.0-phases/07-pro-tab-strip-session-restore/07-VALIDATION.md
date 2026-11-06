---
phase: "7"
slug: "pro-tab-strip-session-restore"
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-10-20"
---

# Phase 7 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution. Source: 07-RESEARCH.md § Validation Architecture.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | XCTest (SwiftPM testTarget `SharkTests`) |
| **Config file** | none — Package.swift testTarget |
| **Quick run command** | `swift test --filter WorkspaceStateTests` / `swift test --filter SessionStoreTests` |
| **Full suite command** | `swift test` |
| **Estimated runtime** | ~5 seconds (plus build) |

---

## Sampling Rate

- **After every task commit:** `swift build` + the quick filter for the touched suite
- **After every plan wave:** `swift test`
- **Before `/gsd-verify-work`:** full suite green + cua-driver GUI script below
- **Max feedback latency:** 60 seconds

---

## Per-Task Verification Map

Filled by the planner per task (`<automated>` blocks). Requirement → test map:

| Requirement | Behavior | Test Type | Automated Command | File Exists | Status |
|-------------|----------|-----------|-------------------|-------------|--------|
| TAB-01 | tooltip/title text for single, split, pinned, locked | unit | `swift test --filter WorkspaceStateTests` | ❌ W0 | ⬜ pending |
| TAB-02 | moveTab reorders, clamps to pinned/unpinned group | unit | `swift test --filter WorkspaceStateTests` | ❌ W0 | ⬜ pending |
| TAB-03 | closed history cap 20, reopen at original index | unit | `swift test --filter WorkspaceStateTests` | ❌ W0 | ⬜ pending |
| TAB-04 | duplicate, pin, lock, colour, close others/right keep pinned+locked | unit | `swift test --filter WorkspaceStateTests` | ❌ W0 | ⬜ pending |
| TAB-05 | pinned-prefix invariant | unit | `swift test --filter WorkspaceStateTests` | ❌ W0 | ⬜ pending |
| TAB-06 | snapshot JSON round-trip, corrupt → nil, missing path → ancestor, debounce write | unit | `swift test --filter SessionStoreTests` | ❌ W0 | ⬜ pending |
| TAB-07 | background open after current, locked owner opens foreground, select(number:) | unit | `swift test --filter WorkspaceStateTests` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `Tests/SharkTests/SessionStoreTests.swift` — TAB-06 (temp fileURL only, never the real session.json)
- [ ] Extend `Tests/SharkTests/WorkspaceStateTests.swift` — TAB-02/03/04/05/07 model ops
- [ ] `SessionStore.init(fileURL:)` injection point

---

## Manual-Only Verifications (cua-driver against the running app)

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Strip look (1 tab visible, equal widths, hover close, tooltip, light/dark) | TAB-01 | visual | `scripts/run.sh`, screenshot via get_window_state in both appearances |
| Drag reorder, middle-click close, double-click empty strip | TAB-02 | pointer gestures | cua drag with dwell; middle-click may be remapped by Mac Mouse Fix |
| ⇧⌘T + Recently Closed submenu | TAB-03 | menu | hotkey + read menu |
| Context menu items & order, Copy Path | TAB-04 | menu | right_click tab, run each item |
| Relaunch restores everything | TAB-06 | process lifecycle | set up tabs, **⌘Q** (not pkill), `open Shark.app`, compare screenshot |
| ⌥⌘1–9, ⌃Tab, ⇧⌘[ ], ⌘-double-click folder | TAB-07 | keyboard/pointer | cua hotkeys and modifier double_click |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
