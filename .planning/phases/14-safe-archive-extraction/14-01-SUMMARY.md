---
phase: 14-safe-archive-extraction
plan: "01"
requirements-completed: [EXTRACT-01, EXTRACT-02, EXTRACT-03]
verifier: executor self-check
---
# Summary
Added `ArchiveExtractor` (Sources/Shark/Services), `NavigationState.extract`, an Extract context-menu item, an Archive Utility fallback alert, 9 strings in 8 languages, and 13 tests (traversal, absolute paths, write-through-link, `__MACOSX` junk, real ditto zip, single vs. multi-root, cancellation).
Commits: 36bccb0 (feature), c996f80 (docs).
