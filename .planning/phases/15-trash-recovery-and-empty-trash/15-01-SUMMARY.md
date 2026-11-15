---
phase: 15-trash-recovery-and-empty-trash
plan: "01"
requirements-completed: [TRASH-01, TRASH-02, TRASH-03]
verifier: executor self-check
---
Added TrashRecordStore, FileOperationsService.putBack, TrashEmptier (Services/TrashRecovery.swift), Put Back / Empty Trash… menu items (item and background menus in the Trash, sidebar Trash row), 15 strings in 8 languages, entitlements and Info.plist usage text, 8 tests. Known limit: a Put Back of an item the Trash had renamed has no undo step.
