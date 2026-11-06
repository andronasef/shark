---
phase: "12"
slug: honest-sidebar-and-system-boundaries
status: draft
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
| 12-01-01 | HON-01 | T-12-01 | Visible and keyboard actions describe actual behavior | `swift build` | pending |
| 12-01-02 | HON-02 | — | System association/authorization claims remain truthful | `swift build && npm --prefix website run build` | pending |
| 12-01-03 | HON-01, HON-02 | T-12-01 / T-12-SC | No system prompts automated; no dependency change | `swift test && npm --prefix website run build` | pending |

## Wave 0 Requirements

Existing infrastructure covers this deletion/copy phase. No scaffold, dependency install or additional non-trivial-logic test is required.

## Live UI Verification

| Behavior | Requirement | Method | Status |
|----------|-------------|--------|--------|
| Places and Folder Tree lack false tag controls; Up/Down reaches only visible controls | HON-01 | Rebuilt native app, cua-driver; exercise section collapse and surviving navigation | pending |
| Help and welcome setup show readable boundary copy | HON-02 | Rebuilt native app, inspect natural wrapping and scrollable body | pending |
| Features is readable with no stale tag claim or horizontal overflow | HON-01 | Built page at 1440×900 and 390×844 using permitted browser tools | pending |
| Home FAQ and disclosure state actual system-dialog boundary | HON-02 | Built home page using permitted browser tools | pending |

Agent-verifiable UI checks do not themselves require a user approval checkpoint. Stop only for a real privacy/system prompt or unavailable validation route. Never mark an unperformed check green.

## Validation Sign-Off

- [x] All tasks have automated verification.
- [x] No missing Wave 0 test reference.
- [x] No watch flags or irreversible QA.
- [ ] Required commands executed successfully.
- [ ] Native and desktop/mobile website checks observed.
- [ ] Independent phase verification completed.

**Approval:** pending execution and independent verification.
