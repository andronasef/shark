# Native Liquid Glass for Shark

Status: proposed UI design and implementation sequence; product code unchanged.

## Intent

Make Shark's navigation chrome feel like native Finder on macOS Tahoe. The supplied screenshot anchors the layout: inset sidebar, leading history and folder title, trailing action groups and search, narrow tabs, and a spacious file canvas. Assumption: “the original” means Apple's Finder; the screenshot is a layout reference, not a specification for fixed dark colors or simulated glass outlines.

Preserve tabs, split panes, terminal, inspector, file operations, shortcuts, and all four file views. This is a material and chrome adoption pass, not a navigation redesign.

## What exists

- `Views/Navigation/LiquidGlassView.swift` wraps `NSVisualEffectView`, adding a gradient outline and shadow for cards. This is legacy vibrancy, not the native Liquid Glass material.
- `Views/ContentView.swift` uses a native toolbar but embeds custom captioned stacks, plain buttons, a painted history group, and a painted search field.
- `Views/Workspace/TabStripView.swift` uses a legacy header material; `TabItemView.swift` paints opaque selected and inactive backgrounds.
- `Views/Sidebar/PlacesSidebarView.swift` uses a sidebar list with custom row selection fills; preserve native material ownership while auditing these overrides.
- Several directory, inspector, and palette surfaces add opaque fills that need a surface-by-surface audit.
- `SharkSettings.liquidGlassTranslucency` is exposed in Settings but has no rendering consumers. Make its behavior explicit and effective.
- Package deployment target is macOS 14. Local host is 26.6.2 and selected SDK is 27.0, so native APIs can be compiled here; older build environments need an explicit SDK prerequisite.

## UI decisions

### Window and sidebar

Keep `NavigationSplitView` and native window decorations. Let the system own window curvature, traffic lights, toolbar material, active-window appearance, and sidebar geometry. Keep sidebar width bounds of 170–280 pt, ideal 210 pt. Avoid a second manually stroked glass card inside the system sidebar. Preserve sidebar sections, tags, and selection behavior. Sidebar translucency should respond to the desktop and window activation; content must stay legible over bright wallpaper.

### Toolbar

Retain the screenshot's order: history + folder title, flexible separation, Path, View, Group, Share, Tags, Actions, Search. Keep Up navigation available. Use standard toolbar buttons and semantic groups so the OS supplies shared glass backplates. Remove painted control backgrounds that mask them. Keep the four-way View picker as a single logical group.

Use normal icon-only presentation and tooltips/accessibility labels by default; expose captions through native toolbar display modes where supported instead of hard-coded 9 pt labels inside each control. Search should use a native search control or SwiftUI search placement if it preserves the existing focus, filtering, and shortcut behavior. At the current 850 pt minimum window width, allow standard toolbar overflow; search must remain reachable. Do not shrink hit targets to force every action onto one row.

### Tabs, file canvas, and supporting panels

Keep the 28 pt tab strip and its centered single-tab layout. Replace the solid gray selected pill with restrained adaptive selection, consistent with the adjacent toolbar. Retain close, pin, lock, tint, middle-click, group, and restore interactions. Avoid one glass surface per tab and avoid stacking glass over an already glass-backed header.

Use a stable semantic background for the file canvas; glass belongs primarily to navigation and controls. Preserve filename contrast, icon colors, selection, and column/table readability. Use thin semantic dividers or native scroll-edge treatment where supported. The screenshot's outline around every surface should not be reproduced as a permanent custom border.

Keep path/status bars visually subordinate. Inspector content and the terminal remain readable functional surfaces. Standard menus, popovers, and sheets should use system presentation first. For the custom command palette or preview card, use one native glass surface where appropriate and remove redundant opaque fills, simulated highlights, or duplicate shadows.

## Platform and accessibility contract

- Keep macOS 14 support. Gate native glass APIs with `if #available(macOS 26, *)`; use `NSVisualEffectView` as the older-system fallback. Require a macOS 26-or-newer SDK to build the adoption; runtime guards alone do not make new symbols available to older SDKs.
- Prefer standard toolbar and split-view adoption. Use SwiftUI `glassEffect(_:in:)` only for custom surfaces that need it, and `GlassEffectContainer` for adjacent custom glass elements. Do not reapply glass to controls the system already styles.
- Define one material policy used across custom chrome: native glass when available and enabled; legacy vibrancy on macOS 14/15 when enabled; semantic opaque fills when disabled or Reduce Transparency is enabled. Standard OS chrome continues to follow system preferences; the app setting controls app-owned surfaces.
- Respect Increase Contrast and Reduce Motion. Prefer system treatments; use quiet state transitions, no continuous shimmer or custom refraction animation. Maintain visible keyboard focus and VoiceOver descriptions.
- Rename the visible setting to “Translucent interface” so it accurately describes the fallback, retaining the existing stored key and value.

## Implementation sequence

1. **Baseline and surface audit.** Capture Shark and native Finder on the same machine, folder, appearance, window size, and wallpaper. Record toolbar modes and accessibility settings. Map each background and identify which view owns it. Compare the OS-native result before choosing custom glass.
2. **Material policy.** Update `LiquidGlassView.swift`, `SharkSettings.swift`, and `SettingsView.swift`. Implement availability and accessibility branches; retain a separately named legacy blur wrapper. Remove hard-coded specular strokes on native surfaces. Add focused tests for policy selection if extracted as pure logic.
3. **Window, sidebar, and toolbar.** Update `SharkApp.swift`, `ContentView.swift`, and `PlacesSidebarView.swift`. Adopt standard grouping, native control presentation, search, and sidebar treatment. Verify keyboard focus and toolbar overflow at 850 pt before continuing.
4. **Tabs and secondary chrome.** Update `TabStripView.swift`, `TabItemView.swift`, `BottomPathBarView.swift`, relevant status-bar code in `DirectoryView.swift`, `CommandPaletteView.swift`, and `HoverPreviewCard.swift`. Audit canvas and inspector backgrounds without making the whole window glass. Keep behavior and layout intact.
5. **Verification and documentation.** Build and run tests, then visually compare against native Finder. Update `DESIGN.md` to distinguish native glass from legacy vibrancy, and add concise implemented-change entries to `CHANGELOG.md`. Record actual results and any older-OS verification limits.

## Acceptance checks

- Native toolbar groups and sidebar match the host Finder's material hierarchy; no duplicate borders, stacked blur, or unexplained gray backing masks the effect.
- Verify light/dark appearance, active/inactive window, bright/dark wallpaper, Reduce Transparency, Increase Contrast, Reduce Motion, and the app setting.
- Check 850 × 550 and 1080 × 720 pt windows, large windows, collapsed sidebar, split panes, inspector, and terminal. No clipped toolbar controls or inaccessible search.
- Check grid, list, columns, and gallery; filenames, metadata, selections, and focus remain readable.
- Exercise back/forward/up, search focus and filtering, view switching, tab close/reorder/pin/tint/restore, split navigation, menus, and popovers.
- On macOS 14/15, launch and exercise fallback chrome if a suitable environment is available; otherwise explicitly record this as unverified. Runtime guards are not proof of a tested fallback.
- No custom animation runs at idle; scrolling and resize remain responsive. Investigate performance only if the adoption introduces observable regressions.

## References

- Apple: [Adopting Liquid Glass](https://developer.apple.com/documentation/technologyoverviews/adopting-liquid-glass).
- Apple: [Applying Liquid Glass to custom views](https://developer.apple.com/documentation/swiftui/applying-liquid-glass-to-custom-views).
- Apple: [Build an AppKit app with the new design](https://developer.apple.com/videos/play/wwdc2025/310/).

Builder discretion: exact API grouping/bridging, native search integration, and minor spacing should be settled against the installed SDK and live Finder. Do not introduce private APIs or fixed pixel imitations of Apple's optical effects.
