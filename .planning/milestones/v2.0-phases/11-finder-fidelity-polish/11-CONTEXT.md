# Phase 11: Finder Fidelity Polish & Liquid Glass - Context

## Objective
Elevate Shark's visual and tactile fidelity so it matches Apple's native Finder in beauty, polish, and liquid glass vibrancy in light and dark mode, while delivering a genuine Miller Columns view (⌘3), robust empty/error/permission states, complete accessibility semantics, and a published DESIGN.md.

## Requirements
- **POL-01**: Visual fidelity to Finder in light and dark mode (toolbar, sidebar, list/icon/column/gallery, selection pills, focus rings, typography, spacing).
- **POL-02**: Real Columns (Miller Columns) view: cascading directory columns horizontally scrollable, rightward preview column for files with metadata and thumbnail, arrow-key navigation (← / → moves between columns, ↑ / ↓ selects items).
- **POL-03**: Empty, loading, error, and permission-denied states:
  - Empty: informative typography and shortcuts ("Folder is Empty — Drag files here or ⇧⌘N").
  - Loading: graceful indeterminate progress indicator.
  - Permission Denied: clear explanation and "Open System Settings" button for Full Disk Access.
  - Error: clear error message and "Go Up" or "Go Home" actions.
- **POL-04**: Accessibility & Reduced Motion:
  - Accessibility labels and hints on all interactive elements.
  - `@Environment(\.accessibilityReduceMotion)` respected across transitions and hover animations.
- **POL-05**: DESIGN.md documenting complete visual design tokens, interaction patterns, materials, layout grids, and keyboard system.
- **POL-06**: Liquid Glass & Translucent Vibrancy:
  - Native macOS materials (`NSVisualEffectView` with `.behindWindow`, `.sidebar`, `.headerView`) bleed through desktop wallpaper smoothly.
