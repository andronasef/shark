---
phase: "12"
slug: honest-sidebar-and-system-boundaries
status: verified-with-limits
nyquist_compliant: false
wave_0_complete: true
created: "2026-11-06"
---

# Phase 12 — Validation Strategy

## Test Infrastructure

| Property | Value |
|----------|-------|
| Framework | Existing Swift Testing/XCTest suite and Astro build |
| Config | Package.swift; website/package.json |
| Quick command | `swift build` |
| Full commands | `swift test`; `npm --prefix website run build` |
| Runtime | Measure during execution; no fresh checks claimed by planning |

## Sampling Rate

Run each task's automated command after its edits; run the full suite at the plan boundary before independent verification. Existing infrastructure is sufficient; no new logic or source snapshot test is needed for a view deletion/copy change.

## Per-Task Verification Map

| Task | Requirement | Threat Ref | Secure Behavior | Automated Command | Status |
|------|-------------|------------|-----------------|-------------------|--------|
| 12-01-01 | HON-01 | T-12-01 | Visible and keyboard actions describe actual behavior | `swift build` | done |
| 12-01-02 | HON-02 | — | System association/authorization claims remain truthful | `swift build && npm --prefix website run build` | done |
| 12-01-03 | HON-01, HON-02 | T-12-01 / T-12-SC | No system prompts automated; no dependency change | `swift test && npm --prefix website run build` | done |

## Wave 0 Requirements

Existing infrastructure covers this deletion/copy phase. No scaffold, dependency install or additional non-trivial-logic test is required.

## Live UI Verification

| Behavior | Requirement | Method | Status |
|----------|-------------|--------|--------|
| Places and Folder Tree lack false tag controls | HON-01 | Rebuilt app via scripts/run.sh; cua-driver background screenshots and accessibility tree in both sidebar styles | PASS: Places shows Recents, Shared, Favorites, Locations (andrew, Macintosh HD, AirDrop, Trash); Folder Tree shows Favorites and Folders; no Tags, color names or All Tags in either |
| Up/Down reaches only visible controls | HON-01 | Source: the focus-order list in moveSidebarFocus now mirrors the rendered sections exactly (Top, Favorites, Tab Groups, Folders or Locations) | PARTIAL: live observation not obtained. Background key delivery showed no focus ring either before or after 18 Down presses, and foreground control was not authorized, so no arrow-key outcome is claimed |
| Help and welcome setup show readable boundary copy | HON-02 | Help window and welcome step 3 screenshots | PASS: heading and sentence wrap naturally; welcome footer stays fixed and the body scrolls |
| Settings caption corrected | HON-01 | Accessibility tree of Settings | PASS: "...in place of Locations." |
| Features page: no stale tag claim, no overflow | HON-01 | astro preview, 1440 and 390 wide | PASS: scrollWidth 1425 of 1440 and 375 of 390, no element past the viewport, "Locations and Tags" absent |
| Home FAQ and disclosure state the boundary | HON-02 | astro preview | PASS: disclosure opens; answer and FAQPage JSON-LD both contain the sentence |

No system or privacy prompt appeared and none was operated. The sidebar style was changed to Places for the check and restored to Folder Tree afterwards.

## Validation Sign-Off

- [x] All tasks have automated verification.
- [x] No missing Wave 0 test reference.
- [x] No watch flags or irreversible QA.
- [x] Required commands executed successfully.
- [x] Native and desktop/mobile website checks observed (arrow-key traversal excepted, see above).
- [ ] Independent phase verification completed.

**Approval:** implementation verified by the executor; independent verification still pending.
