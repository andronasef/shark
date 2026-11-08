# Phase 13: Safe Shared Collision Choices - Context

**Gathered:** 2026-11-08
**Status:** Executed

## Phase Boundary
Paste and drag/drop ask Replace / Keep Both / Skip / Stop (plus Merge for folders and Apply to all) instead of refusing or silently renaming. COLL-01..04. Extract (14) and Put Back (15) reuse the engine.

## Decisions (from the agreed grilling rounds)
- Replace sends the old item to the Trash; undo restores it. Keep Both is the default button, names "name 2", "name 3", keeps the extension. Duplicate keeps "name copy".
- Merge only for two real folders; links to folders and packages are never merged into. Apply to all: Merge decides folder conflicts only.
- Stop and failures keep completed work as one undo step. With no name clash the existing all-or-nothing move/copy still runs.
- One sheet in the folder view, driven by NavigationState; the engine takes a handler so other callers (Extract, Put Back) can supply their own.
