# Product Hunt Launch Draft: Shark 🦈

> **Status:** Ready for submission  
> **Target Release:** Shark 1.0  
> **Assets Folder:** [`docs/producthunt/`](file:///Users/andrew/Documents/Work/Dev/Projects/Personalss/shark/docs/producthunt/)  

---

## 1. Listing Overview

- **Product Name:** `Shark` (or `Shark — A Better Mac File Manager`)
- **Tagline (under 60 chars):**  
  `A native Mac file manager for people who live in folders`  
  *(Alternative 1: `Dual panes, tabs & terminal in a blazingly fast Mac manager`)*  
  *(Alternative 2: `The fast, keyboard-first native Finder alternative`)*
- **Primary Category:** `Developer Tools`
- **Secondary Categories:** `Mac`, `Productivity`, `Open Source`, `Tech`
- **Pricing:** `Free` (or `Free / Open Source with App Store option`)
- **Website URL:** `https://github.com/andronasef/shark`
- **App Store URL:** `https://apps.apple.com/app/shark-better-finder/id6825086341`

---

## 2. Visual Assets Checklist

All media prepared in the required 16:9 Retina & square specifications:

| Asset | File | Size | Description |
|---|---|---|---|
| **Thumbnail / Icon** | [`docs/producthunt/thumbnail.png`](file:///Users/andrew/Documents/Work/Dev/Projects/Personalss/shark/docs/producthunt/thumbnail.png) | 512 × 512 | Glowing Shark emblem on Obsidian stage |
| **Gallery Slide 1** | [`docs/producthunt/01-tabs-and-split.png`](file:///Users/andrew/Documents/Work/Dev/Projects/Personalss/shark/docs/producthunt/01-tabs-and-split.png) | 2560 × 1440 | Infinite Tabs & Dual Split View |
| **Gallery Slide 2** | [`docs/producthunt/02-hover-preview.png`](file:///Users/andrew/Documents/Work/Dev/Projects/Personalss/shark/docs/producthunt/02-hover-preview.png) | 2560 × 1440 | Instant Hover Preview without opening apps |
| **Gallery Slide 3** | [`docs/producthunt/03-subfolder-navigation.png`](file:///Users/andrew/Documents/Work/Dev/Projects/Personalss/shark/docs/producthunt/03-subfolder-navigation.png) | 2560 × 1440 | Cascading Deep Subfolder Flyout Navigation |
| **Gallery Slide 4** | [`docs/producthunt/04-integrated-terminal.png`](file:///Users/andrew/Documents/Work/Dev/Projects/Personalss/shark/docs/producthunt/04-integrated-terminal.png) | 2560 × 1440 | Embedded Developer Terminal synced to active folder |

---

## 3. Product Description (Short / Pitch)

**Finder was designed for casual browsing. Shark is built for people who work.**

If you’re a developer, designer, or power user, you probably spend half your day juggling 8 overlapping Finder windows, opening Terminal just to `cd` into a directory you’re already looking at, and hitting Spacebar on a dozen files just to find the right asset.

Shark reimagines file management on macOS from the ground up:
- **Dual Panes (F3):** Keep project folders side-by-side. Move or copy files seamlessly without window clutter.
- **Infinite Tabs (⌘T):** Pin tabs, color-code them, lock sessions, and pick up right where you left off.
- **Integrated Terminal (F4):** A real hardware-accelerated terminal drawer that automatically syncs its directory to your active folder.
- **Instant Hover Previews:** Hover over images, code, markdown, audio, and video to peek inside instantly.
- **Deep Cascading Subfolders:** Hover over folder arrows to fly 5 levels deep into nested trees without losing your place.
- **100% Native Swift & SwiftUI:** No Electron, no web wrappers, zero lag, minimal memory footprint.

---

## 4. Maker's First Comment (Launch Comment)

```text
Hey Product Hunt! 👋 I’m Andrew, the creator of Shark.

Like many of you, I spend hours inside nested directories every day. macOS Finder is iconic, but the moment you need to compare two project directories, drag assets between branches, or jump straight into a shell, you find yourself fighting multiple windows and losing your flow.

Existing third-party file managers either feel like Windows 95 ports, rely on heavy Electron wrappers, or cost $40+ with bloated feature sets.

I wanted something that feels like Apple designed it for power users:
⚡ 100% Native: Built with Swift, AppKit, and SwiftUI. Starts instantly, sips battery, and uses minimal RAM.
📂 Dual Panes & Tabs: Split the window with F3, drag files between panes, and pin the tabs you use daily.
💻 Embedded Terminal: Press F4 and a terminal drawer slides open, already cd’d into whatever folder you’re browsing.
👁️ Hover Previews: Peek at code, images, audio, and documents without pressing spacebar or opening another app.
🌳 Cascading Subfolder Menus: Traverse nested folder trees at the speed of thought.
⌨️ Keyboard-First: ⌘K command palette, quick path jumper (⌘L), and intuitive shortcuts for everything.

Shark is available today on GitHub and the Mac App Store. 

I’d love to hear your feedback: What’s your biggest frustration with Finder, and what feature should we build next?

Thank you for checking out Shark! 🦈
```

---

## 5. Key Highlights / Bullet Points for Social & Launch

- **Platform:** macOS 14+ (Sonoma, Sequoia, and future versions)
- **Architecture:** Universal (Apple Silicon M1/M2/M3/M4 & Intel)
- **Tech Stack:** Swift, SwiftUI, AppKit, SwiftTerm
- **Keyboard Shortcuts to Highlight:**
  - `F3` — Toggle Dual Split Panes
  - `F4` — Toggle Embedded Terminal Drawer
  - `⌘K` — Universal Command Palette
  - `⌘L` — Direct Path Jump
  - `⌘T` / `⇧⌘T` — New Tab / Reopen Closed Tab
  - `Space` — QuickLook Inspector
