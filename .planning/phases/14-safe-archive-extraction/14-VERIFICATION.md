---
phase: 14-safe-archive-extraction
status: passed
verifier: executor self-check (lean GSD, no verifier agent)
---
- Unit: ArchiveExtractorTests 13/13 pass; full suite passes except `ExternalFolderOpeningTests.testRevealOpensParentFolderAndSelectsItem` (/var vs /private/var path comparison), which belongs to the separate Reveal commit 29b6d67, not this phase.
- Live: right-clicked a ditto-made proj.zip in the running app; Extract appeared after Compress; picking it produced `proj/a.txt` and `proj/b.txt` and left no staging folder.
- Not driven live: the name-conflict re-extract, Stop mid-extraction, and the Archive Utility alert (covered by unit tests / code only).
