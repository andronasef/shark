---
phase: 16-extension-change-warnings
status: human_needed
verifier: executor self-check (lean GSD)
---
- Unit: ExtensionChangeTests 4/4 (stem rename, remove, change, folder, dotfile, added extension, case-only, double extension). Build passes.
- NOT verified live: the alert in the running app (modal dialogs could not be driven reliably through background input). Batch Rename is not covered by the warning.
