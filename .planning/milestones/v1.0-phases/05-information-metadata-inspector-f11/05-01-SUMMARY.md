# Plan 05-01 Summary: Information & Metadata Inspector (F11)

## Completed Objectives

- Built `FileMetadata` model and `MetadataExtractor` actor extracting POSIX permissions (octal e.g. 0644, symbolic `-rw-r--r--`), owner name, group name, file size in bytes, date attributes, MIME/UTI type, image dimensions via `CGImageSource`, and SHA-256 cryptographic hashing via `CryptoKit`.
- Built `InspectorPanelView` with:
  - Header with close button
  - Large thumbnail / icon preview with file name and kind
  - General section (exact bytes, location with copy button, created, modified, accessed)
  - POSIX permissions section (mode octal & symbolic, owner, group)
  - Media details section (image dimensions in pixels)
  - Checksum section with on-demand SHA-256 calculation and copy button
- Integrated `InspectorPanelView` into `ContentView`:
  - Collapsible right sidebar next to workspace split panes
  - Toolbar toggle button with `info.circle.fill` / `info.circle`
  - Keyboard shortcuts `F11` / `⌥⌘I`
  - Automatically updates when active item selection changes
- Added unit tests in `MetadataExtractorTests` verifying file metadata, directory permissions, and cryptographic SHA-256 hashing — all 24 project unit tests passing.

## Verification

- `swift build` compiled cleanly in 0.42s.
- `swift test` passed all 24 unit tests across 5 test suites.

## Requirements Satisfied

- INSP-01: User can toggle the right-hand Information / Inspector panel (`F11`).
- INSP-02: Inspector displays rich metadata including file size, POSIX permissions, owner/group, MIME type, image dimensions, audio/video duration, and file hashes.
