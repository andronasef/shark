<p align="center">
  <img src="Resources/AppIcon.png" width="112" alt="Shark app icon">
</p>

<h1 align="center">Shark – File Manager</h1>
<p align="center">
  <a href="https://github.com/andronasef/shark/releases"><img alt="Download the latest release" src="https://img.shields.io/github/v/release/andronasef/shark?include_prereleases&label=download&logo=github&color=0069d4"></a>
  <a href="https://github.com/andronasef/homebrew-shark"><img alt="Homebrew cask: andronasef/shark/shark" src="https://img.shields.io/badge/brew-andronasef%2Fshark%2Fshark-fbb040?logo=homebrew&logoColor=white"></a>
  <a href="https://apps.apple.com/us/app/shark-better-finder/id6825086341"><img alt="Mac App Store: in review" src="https://img.shields.io/badge/Mac_App_Store-in_review-0d96f6?logo=appstore&logoColor=white"></a>
  <a href="https://github.com/andronasef/shark/releases"><img alt="Total downloads" src="https://img.shields.io/github/downloads/andronasef/shark/total?color=586674"></a>
  <img alt="macOS 14 or later" src="https://img.shields.io/badge/macOS-14%2B-18232e?logo=apple&logoColor=white">
</p>
<p align="center">A native Mac file manager for people who live in their folders.</p>
<p align="center">macOS 14+ · Apple silicon & Intel · Built with Swift and SwiftUI</p>
<p align="center">
  <a href="https://shark.andronasef.com/">Website</a> ·
  <a href="https://youtu.be/SoQqCcbbE1c">Trailer</a> ·
  <a href="https://github.com/andronasef/shark">GitHub</a> ·
  <a href="https://userhq.increasinglabs.com/increasing-labs/shark">Feedback & Feature Requests</a> ·
  Created by <a href="https://andronasef.com/">Andrew Nasef</a>
</p>

Shark brings tabs, split panes, an embedded terminal, and quick previews into a familiar Mac interface. Keep your project folders open, move files between locations, and look inside things without losing your place.

## Four things to try first

### 1. Keep folders side by side

Open folders in tabs, then press **F3** for a second pane. Drag files between the panes to move them, or hold **Option** to copy. Pin the tabs you use all day; Shark restores your session when you return.

![Shark showing multiple folder tabs and two panes, with folders on the left and photo thumbnails on the right](docs/screenshots/tabs-and-split.png)

### 2. Bring the terminal to your files

Press **F4** to open a real terminal below your files. It follows the active folder, so you can browse to a project and start working from the same window.

![Shark's embedded terminal drawer open beneath the current folder](docs/screenshots/terminal.png)

### 3. Preview without opening another app

Hover over a file to see what's inside: images, text, documents, video, and audio. Media previews have playback controls. Adjust the delay, require Shift to preview, or turn previews off in **Settings → Previews**.

![A photo hover preview floating over Shark's file browser](docs/screenshots/hover-preview.png)

### 4. Browse deeper without leaving your folder

Hover over a folder and click its little arrow to browse a cascading menu of its contents. Keep going into subfolders, then click to open an item. **Command-click** a folder to open it in a new tab; **Option-click** to copy an item for pasting elsewhere.

![A cascading subfolder menu in Shark, showing nested project folders](docs/screenshots/subfolder-menu.png)

## Get started

### Install via Homebrew

```bash
brew install --cask andronasef/shark/shark
```

Or tap the official repository first:

```bash
brew tap andronasef/shark
brew install --cask shark
```

### Mac App Store

[Shark on the Mac App Store](https://apps.apple.com/us/app/shark-better-finder/id6825086341) is waiting for Apple's review; the link works once it is approved.

### Direct download

Download the latest `Shark-<version>.dmg` from the [**Releases** page](https://github.com/andronasef/shark/releases), open it, and drag **Shark.app** onto **Applications**. Public downloads built by the release action are Developer ID signed and notarized by Apple.

Open a folder from the sidebar, or press **⌘L**, type a path, and press Return. macOS may ask for access to protected folders such as Documents or Downloads; allow the folders you want to browse.

Shark requires **macOS Sonoma 14 or later**. Liquid Glass chrome is available on macOS 26+; earlier versions use system material fallbacks. On keyboards where the function keys control system features, hold **Fn** when using F3 or F4.

## A few useful keys

| Action | Shortcut |
| --- | --- |
| New tab / reopen a closed tab | ⌘T / ⇧⌘T |
| Enter a folder path | ⌘L |
| Go to the enclosing folder | ⌘↑ |
| Toggle split panes | F3 |
| Toggle terminal | F4 |
| Open the command palette | ⌘K |
| Quick Look selected files | Space |
| Cut / copy / paste | ⌘X / ⌘C / ⌘V |
| Show hidden files | ⇧⌘. |
| Open the inspector | ⌥⌘I |

Prefer the mouse? **Help → Shark Help** lists what clicks, hovering, dragging, and scrolling do in each part of the window. Optional gestures live in **Settings → Mouse**.

## More for everyday work

- **Four views:** icons, details, columns, and gallery.
- **Find your way:** filename filtering, editable paths, favorites, and a command palette.
- **File tools:** batch rename, duplicate, compress, drag and drop, and move to Trash.
- **Inspect files:** sizes, permissions, metadata, and SHA-256 checksums.
- **Make tabs yours:** reorder, pin, lock, color, group, and reopen closed tabs.

## Build from source

Install **Xcode 26 or newer** and select it as your active developer directory. The current source uses the macOS 26 SDK while targeting macOS 14+. From the repository root:

```sh
swift build
swift test
bash scripts/run.sh
```

The run script builds and opens `Shark.app`. Swift Package Manager fetches [SwiftTerm](https://github.com/migueldeicaza/SwiftTerm) for the terminal and [Inject](https://github.com/krzysztofzablocki/Inject) for development hot reload.

For a local universal package:

```sh
scripts/package.sh 0.7.0
```

## Links

- **Website:** [shark.andronasef.com](https://shark.andronasef.com/)
- **Repository:** [github.com/andronasef/shark](https://github.com/andronasef/shark)
- **Feedback & Bug Reports:** [Shark Feedback Board](https://userhq.increasinglabs.com/increasing-labs/shark)
- **Author:** [Andrew Nasef](https://andronasef.com/)

## Contributing

Bug reports, small fixes, documentation improvements, and feature ideas are welcome.

- **Found a bug?** Submit a report on the [Shark Feedback Board](https://userhq.increasinglabs.com/increasing-labs/shark) with your macOS version, steps to reproduce, what you expected, and what happened. Screenshots help; hide any personal file names or paths.
- **Have a bigger idea?** Share a feature request on the [Shark Feedback Board](https://userhq.increasinglabs.com/increasing-labs/shark) to discuss it before starting a large change.
- **Want to send a fix?** Fork the repository, create a branch, and follow the build instructions above. Keep each pull request focused on one change.

Before opening a pull request, run `swift test` and check the app itself if you changed the UI. Add tests for non-trivial logic and a changelog entry for meaningful changes. Include a short description of the change and how you tested it; add screenshots for visual changes.

Keep the interface native to macOS. Update the design guide when changing layout or interaction rules, and the in-app Help when changing mouse gestures.

## License

Shark is licensed under the [Apache License 2.0](LICENSE). Copyright 2026 Andrew Nasef.
