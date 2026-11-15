---
phase: 15-trash-recovery-and-empty-trash
status: human_needed
verifier: executor self-check (lean GSD)
---
- Unit: TrashRecoveryTests 8/8 (persistence across reopen, unknown items, prune safety, restore, Keep Both on clash, Stop keeps record, missing folder, renamed-by-Trash). Full suite passes except the existing Reveal path test (/var vs /private/var), unrelated.
- NOT verified live: the Put Back and Empty Trash menu items in the running app, the Finder Automation prompt, and listing ~/.Trash (it needs Full Disk Access; this shell and the QA driver could not read it). Background input would not select/trash a file reliably. A human should: trash a file in Shark, open the Trash, Put Back; and try Empty Trash with Automation allowed and denied.
