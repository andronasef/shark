---
phase: 13-safe-shared-collision-choices
plan: "01"
subsystem: file-operations
tags: [swift, undo, collisions, sheet]
provides:
  - FileOperationsService.transfer with a CollisionHandler (reusable by Extract and Put Back)
  - FileUndoAction.batch for multi-step undo
  - CollisionSheet
key-files:
  created:
    - Sources/Shark/Services/CollisionTransfer.swift
    - Sources/Shark/Views/Operations/CollisionSheet.swift
    - Tests/SharkTests/CollisionTransferTests.swift
  modified:
    - Sources/Shark/State/NavigationState.swift
    - Sources/Shark/Services/FileUndoService.swift
    - Sources/Shark/Views/Directory/DirectoryView.swift
requirements-completed: [COLL-01, COLL-02, COLL-03, COLL-04]
coverage:
  - id: D1
    description: "Replace, Keep Both, Skip, Stop, Apply to all, Merge, undo/redo and link safety"
    verification:
      - kind: unit
        ref: "Tests/SharkTests/CollisionTransferTests.swift (14 tests)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Sheet shows both items with size and date and Replace/undo work in the app"
    verification:
      - kind: automated_ui
        ref: "cua-driver: paste onto an existing name, Replace, then Cmd-Z, with files read back from disk"
        status: pass
    human_judgment: false
  - id: D3
    description: "Drag-and-drop path, Merge sheet and Keep Both observed live"
    verification: []
    human_judgment: true
    rationale: "Drop and Merge share the tested engine and sheet but were not driven live"
duration: 95min
completed: 2026-11-08
status: complete
---

# Phase 13: Safe Shared Collision Choices

**Paste and drop now ask Replace, Keep Both, Skip or Stop (with Merge and Apply to all), keep the old item in the Trash on Replace, and undo each transfer as one step.**

## Deviations from Plan
- Phase planning was lean: no separate research/PLAN/plan-check agents were run; the design was settled in the earlier grilling rounds and the code was read directly.
- `testCutPasteNeverOverwritesExistingItem` asserted the old "refuse" behavior and would now hang waiting for an answer. Replaced with `testCutPasteAsksBeforeTouchingAnExistingItem`.

## Issues Encountered
- Any caller of `NavigationState.paste/drop` without UI blocks until the sheet is answered. Fine in the app (the sheet always exists); tests must answer.
- Merge-move trashes the emptied source folder (undoable) rather than deleting it.
- The existing item in the sheet takes the incoming name on case-insensitive disks ("a.txt" for an on-disk "A.txt").
