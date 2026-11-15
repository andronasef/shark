# Phase 14: Safe Archive Extraction — Context

Requirements: EXTRACT-01..03. Decisions: bsdtar (system libarchive) extracts into a private `.shark-extract-<UUID>` staging folder beside the archive; entry names are listed and checked before writing; one top-level item lands directly, several go into a folder named after the archive; placement reuses the Phase 13 collision engine; Archive Utility is offered for formats bsdtar cannot read (StuffIt, ZIPX, encrypted).
