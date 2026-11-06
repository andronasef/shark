# Shark — Finder-look File Manager with QTTabBar & Explorer Power

## What This Is

Shark is a native macOS file manager built with Swift 6, SwiftUI and AppKit. It combines Finder's familiar appearance with QTTabBar's tab and folder tools and Explorer's file-management ergonomics. Power users remain first; everyday Mac users moving off Finder need familiar, complete daily workflows too.

## Core Value

A file manager that looks like native macOS Finder and makes daily file work safe, fast, and reachable by mouse or keyboard.

## Current Milestone: v2.1 Everyday Mac Workflows

**Goal:** Implement all three agreed groups of everyday Mac features while preserving Shark's existing power workflows and data safety.

**Target features:**
- Group 1: honest Tags patch; shared collision choices; extraction; Put Back and Empty Trash; extension warnings; iCloud; live scoped search; Finder tags.
- Group 2: Recents and configurable places; copy progress, pause and cancel; aliases/symlinks; spring loading; Get Info additions; Connect to Server.
- Group 3: Quick Actions; Group By; Smart Folders; direct AirDrop; Print; native Services.

This is an internal planning milestone, not a public version bump. No release, deployment or PR is requested. The user authorized all groups and reasonable native implementation defaults on 2026-11-06; Group 3 is no longer deferred. Complete decisions: `EVERYDAY-MAC-MILESTONE.md`. Traceable acceptance: `REQUIREMENTS.md`.

## Requirements

### Validated

Recorded as completed by the previous milestones; this is historical evidence, not a new validation run:

- ✓ Native async browsing, sidebar/favorites, breadcrumbs/history, split panes/tabs, view modes/filtering, Quick Look, PTY terminal, inspector, file operations and FSEvents — v1.0, phases 1–6.
- ✓ Pro tabs and session restore, Explorer clipboard/undo/path/status ergonomics, cascading folder menus and hover previews, tab groups, command palette/menu/keyboard coverage, Finder visual polish and Columns view — v2.0, phases 7–11.
- ✓ Later quick-task history and subsequent features remain in Git, `quick/`, and the website feature catalog; preserve them.

### Active

- [ ] All v2.1 requirements in `REQUIREMENTS.md`, mapped once each to phases 12–31.
- [ ] File operations preserve originals, make collision choices explicit, and keep partial failure/cancel/undo coherent.
- [ ] Virtual locations retain their query and operate on actual result URLs.
- [ ] Features ship with Help, public catalog, changelog, design rules and verification in the same feature commit.

### Out of Scope

- Remote protocol implementations — macOS mounts supported servers; Shark browses the resulting volumes.
- Proprietary cloud-provider API clients — public macOS file and iCloud APIs suffice here.
- Replacing system Open/Save dialogs in other apps — these remain macOS's interface.
- Private Finder internals or unsupported system integrations — native public APIs and honest app handoffs only.
- Publishing, deployment, App Store submission, public release version/tag changes — not requested.

## Context

- macOS 14+, Swift 6 strict concurrency, SwiftUI with AppKit bridges, `@Observable` state, actor-isolated file services.
- Existing public app version at intake: 1.0.0-alpha.4. Internal GSD v2.0 was recorded complete; its snapshot is archived under `milestones/v2.0-*`.
- Build/test: `swift build`, `swift test`. `bash scripts/run.sh` builds/bundles/re-signs/relaunches the native app.
- Website: `npm run build` from `website/`; inventory in `website/src/data/features.ts`.
- At intake only unrelated `.claude/` was untracked. Volume eject was already committed as `a19a03d`; no pending eject commit is needed.
- Do focused phase research against current public APIs as needed; avoid assuming archive-format support, universal Trash access requirements, fabricated iCloud progress, or Finder Smart Folder interoperability.

## Constraints

- **Visual authority:** `PRODUCT.md`, `DESIGN.md`; native controls, materials, symbols, accent color and accessibility.
- **Safety:** Trash or undo for destructive actions; safe staging; no overwrites, traversal or symlink escapes; no irreversible QA on real user files or Trash.
- **Performance:** No disk I/O or large transformations blocking the main actor; preserve large-directory behavior.
- **Dependencies:** No dependency for behavior covered by system APIs or a few lines of Swift/AppKit.
- **Verification:** Source/build alone is insufficient for visible UI; inspect the running app. System privacy prompts belong to the user.
- **Truth:** Public inventory includes only implemented behavior. Record unavailable account/device/system verification explicitly.
- **Commits:** One conventional feature/fix commit at a time, including its Help/catalog/changelog/design updates.

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Finder familiarity is the minimum for everyday users; power users remain first | Users can adopt Shark for daily work | Accepted 2026-11-06 |
| Implement all three groups now | Latest explicit user scope supersedes earlier deferral | Accepted 2026-11-06 |
| Spotlight with a cancellable name-walk fallback, no private index | Native search and unindexed-volume coverage | Planned |
| Replace destinations through Trash with undo; shared conflict UI | Avoid silent loss and inconsistent entry points | Planned |
| Network mounting, AirDrop, Services and applicable app handoffs use public macOS APIs | Familiar behavior without private integrations | Planned |
| Group 3 uses restrained native defaults documented per phase | User authorized autonomous implementation | Planned |
| v2.1 is planning identity only | Do not conflate historical GSD versions with public releases | Accepted 2026-11-06 |

## Evolution

After each phase transition, move verified requirements to Validated, update decisions and current behavior, and preserve unmet items as active or blocked. After each milestone, review scope, core value, constraints and context against what actually shipped. Never mark a requirement complete merely because its plan ran.

---
*Last updated: 2026-11-06 after starting the authorized Everyday Mac Workflows milestone.*
