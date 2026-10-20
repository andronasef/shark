---
version: 1
slug: "sources-shark-views-contentview-swift"
primary_target: "Sources/Shark/Views/ContentView.swift"
related_targets: []
---

# Shark main window

Scope: the whole main window (toolbar, tab strip, sidebar, panes, status bar, palette, menus). Mode: Operate.
Audience and task: Mac power users and Windows/KDE switchers managing files all day; navigate, select, copy/move, open, find.
Constraints: Finder look (PRODUCT.md standing preference); native controls only; keyboard plus mouse parity.

## Direction contract

THESIS: Finder you'd mistake for Apple's, with QTTabBar's tabs and Explorer's discoverability. It refuses the toolbar wall of captioned buttons and the hidden-power Finder default: every capability is visible in a menu, the context menu, or Cmd+K.
OWN-WORLD: Canon. System window materials, sidebar vibrancy, SF Pro 13/11, SF Symbols monochrome, system accent for selection and focus only. Tabs follow Safari/Finder: equal-width, with close on hover, pin as a compact icon tab, and an optional user tint dot (QTTabBar colouring) as the only extra colour.
STORY: The user sees a Finder window, notices the real tab strip and the status bar readout, and then finds Cut/Paste, Copy Path, and subfolder menus where Explorer taught them to look.
FIRST VIEWPORT: Unified toolbar with Back/Forward, title, view picker, group, action, split, terminal, and search. Below it a full-width tab strip at 28pt. Sidebar on the left. The list or grid fills the centre, with an optional path bar and status bar along the bottom: items, selection size, free space, and a job progress readout.
FORM: canon (category standard) — chosen by the user; seed: c057ae9ddaa2e67c
SIGNATURE: Hovering a breadcrumb or a folder chevron opens its subfolders as a cascading menu (the QTTabBar move), and Cmd+K reaches any action or recent folder.
FINISH: unreviewed and undocumented is unfinished; this build ends with the finish review, the verdict, DESIGN.md, and every shipping raster carrying its provenance
