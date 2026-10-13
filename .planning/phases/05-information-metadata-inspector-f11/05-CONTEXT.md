# Phase 5: Information & Metadata Inspector (F11) - Context

**Gathered:** 2026-10-13
**Status:** Ready for planning
**Mode:** Autonomous (Dolphin F11 Metadata Inspector)

<domain>
## Phase Boundary

Implement KDE Dolphin's signature F11 Information panel:
1. Right-side collapsible inspector panel toggled via `F11`, toolbar button, or `Cmd+Option+I`.
2. Rich metadata extraction: exact bytes, POSIX octal & symbolic permissions, owner/group names, MIME/UTI type, creation/modification/access dates.
3. Extended media inspection: image dimensions (CGImageSource), audio/video duration (AVFoundation).
4. On-demand SHA-256 cryptographic checksum calculation with one-click copy.
5. Directory summary mode when no file is selected.

Requirements covered: INSP-01, INSP-02.
</domain>

<decisions>
## Implementation Decisions

### 1. Metadata Extractor Engine
- `MetadataExtractor`: Actor analyzing local file URLs asynchronously.
- Extracts POSIX attributes (`stat`), owner name via `getpwuid`, group name via `getgrgid`.
- Extracts image dimensions using CoreGraphics `CGImageSourceCreateWithURL`.
- Computes SHA-256 hash using CryptoKit `SHA256.hash(data:)` in background thread.

### 2. Inspector Panel UI
- `InspectorPanelView`: Collapsible right-hand sidebar.
- Top section: Large preview thumbnail / icon, primary title, kind tag.
- Sections:
  - "General": Size, Location, Where, Created, Modified, Accessed
  - "Permissions": Mode octal (`0755`), Symbolic (`-rwxr-xr-x`), Owner, Group
  - "Media": Resolution / dimensions (for images/videos)
  - "Checksum": SHA-256 hash with calculate button and copy button.

</decisions>
