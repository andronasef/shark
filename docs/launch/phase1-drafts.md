# Shark launch, Phase 1 drafts

> Listing name for new submissions: **Shark – File Manager**. The drafts and patches below were written, and the listings and pull requests submitted, under the old name "Shark - Better Finder"; they are kept as a record of what was posted. Prose can say "Shark".

Nothing here has been submitted. Review, edit, then tell me which ones to send.

Status when written:

- AlternativeTo: the form is filled in your Edge (already signed in) and open in a tab, not submitted. Filled: name, website, short and full description, Free, Open source / Apache 2.0, source URL, tags (tabbed-file-manager, two-panel-file-manager), platform Mac, author Andrew Nasef (andronasef.com), icon, and the four App Store screenshots (converted to JPEG under 3MB, since the PNGs of 01 and 02 are over the limit). Also filled: all eight supported languages (English, Arabic, German, Spanish, French, Japanese, Portuguese, Chinese), more tags (finder, file-preview, batch-renamer), the trailer video, and Homebrew cask `andronasef/shark/shark`. Risk: the form says it checks each package against its catalogue on save, and Shark is in a personal tap, not core Homebrew. If the save rejects it, clear that one field and resubmit. Left empty on purpose: country of origin, social links.
- AlternativeTo: submitted by you on 27 Oct 2026, waiting in the normal review queue. The "alternative to" links can only be added after it's approved. A paid priority review ($5) or "we finish it" ($15) is offered; not bought.
- awesome-mac and open-source-mac-os-apps: patches are ready as `docs/launch/awesome-mac.patch` and `docs/launch/open-source-mac-os-apps.patch` (made against each repo's current default branch). No fork and no PR exists yet.
- MacUpdate: signed in with Google, the Submit App form in Edge is filled (name, URLs, version 1.0.0-alpha.2, free, descriptions, system requirements, icon, 4 screenshots, note to the review team) and not submitted.
- macapps.link: skipped. It's a Ninite-style installer list last updated in 2022, and its request form wants your email.
- Section 6 sites: copy ready, forms not opened.

Facts used (all checked against the repo):

- Version: 1.0.0-alpha.2 (alpha, say so everywhere)
- Free, open source, Apache 2.0
- macOS 14+, Apple silicon and Intel, Swift / SwiftUI / AppKit
- Install: `brew install --cask andronasef/shark/shark`, or DMG from GitHub Releases
- Mac App Store: submitted, in review (do not link it as live until Apple approves)
- Site: https://shark.andronasef.com · Repo: https://github.com/andronasef/shark
- Screenshots: `docs/screenshots/` (tabs-and-split, terminal, hover-preview, subfolder-menu, list-view) and `docs/producthunt/` (16:9 slides, 512px thumbnail)
- Icon: `Resources/AppIcon.png`
- Trailer: https://youtu.be/SoQqCcbbE1c (linked in the README; use it in every post and form that takes a video, and as the first line of social posts)

Not claimed anywhere: speed numbers, memory numbers, user counts, testimonials. There are none.

---

## 0. Shared copy

### Maker story (the base for every post)

I used Windows for years. After I moved to a Mac, the thing I missed most was File Explorer. I could type a path into the address bar, cut and paste files, keep a folder tree on the left, and read the item count in a status bar. Finder hides most of that or doesn't have it.

I wanted a Finder with superpowers that still felt familiar, so I built Shark. It's native Swift and SwiftUI. It has tabs, split panes (F3), a terminal drawer that follows your folder (F4), hover previews, cascading subfolder menus, and an optional Explorer-style folder tree in the sidebar.

It's free, open source under Apache 2.0, and still alpha, so expect rough edges. I'd like to hear what's missing.

### Taglines (60 characters max)

- A Finder alternative with Windows Explorer's familiar power (59)
- Tabs, split panes and a terminal for your Mac's files (53)

### One-liner (about 140 characters)

Shark is a free, open source Mac file manager with tabs, split panes, a built-in terminal and hover previews. Built for people who left Windows Explorer behind.

### Short description (about 400 characters)

Shark is a native macOS file manager for people who live in their folders. It keeps Finder's look and adds what Windows File Explorer, QTTabBar and Dolphin users expect: tabs, side-by-side panes, an editable path bar, cut and paste, a status bar, a command palette, and a terminal drawer that follows the folder you're in. Free, open source (Apache 2.0), macOS 14+. Currently alpha.

### Tags and keywords

file manager, finder alternative, dual pane, tabs, terminal, quick look, swift, swiftui, open source, macOS

---

## 1. AlternativeTo (needs account, submit via the "Add application" form)

Account note: I can't create an account. If your Google sign-in is already linked to AlternativeTo, I'll use it. If it would create a new account, you need to do that step.

I could not load the live form while writing this (the fetch was declined), so field names below follow AlternativeTo's usual form and I'll check each one when I open it.

| Field | Value |
|---|---|
| Name | Shark - Better Finder |
| Tagline | A Finder alternative with Windows Explorer's familiar power |
| Platforms | Mac |
| License | Open Source (Apache 2.0) |
| Price | Free |
| Website | https://shark.andronasef.com |
| Source / download | https://github.com/andronasef/shark |
| Tags | file manager, finder alternative, dual pane, tabs, terminal, open source |
| Icon | `Resources/AppIcon.png` |
| Screenshots | `docs/screenshots/tabs-and-split.png`, `terminal.png`, `hover-preview.png`, `subfolder-menu.png` |

Description:

I used Windows for years. When I moved to a Mac, the thing I missed most was File Explorer: typing a path into the address bar, cutting and pasting files, a folder tree on the left, an item count in a status bar. Finder hides most of that or doesn't have it.

So I built Shark, a Finder with superpowers that still feels familiar to me. It's native Swift and SwiftUI and keeps Finder's look, then adds the things I missed from File Explorer, QTTabBar on Windows and Dolphin on KDE.

Features:
- Tabs: open folders in tabs, pin or lock the ones you use daily, and reopen closed tabs.
- Split panes: press F3 for a second pane and drag files between the two.
- Terminal drawer: press F4 for a terminal that follows the folder you're in.
- Hover previews: preview images, text, video or audio without opening another app.
- Location bar: type a path to jump straight to a folder.
- Cut and paste: real cut, copy and paste for files.
- Folder tree: switch the sidebar to an Explorer-style tree.
- Command palette: Command-K opens actions and recent folders.

Shark is free, open source under Apache 2.0, and needs macOS 14 or later. It's still in alpha, so expect rough edges, and tell me what's missing.

"Alternative to" links to add after the listing is live (each is a separate "Suggest as alternative" click on that app's page):

1. Finder (Apple)
2. Path Finder
3. ForkLift
4. Marta
5. Commander One
6. QTTabBar (Windows, shows why it exists)
7. Dolphin (KDE)

Order matters: Finder first, since that's the search people actually type.

---

## 2. MacUpdate

No self-serve submit page. The developer page lists a "Suggest an app / Report a problem" link in the footer and a contact form. Draft message:

> Subject: Please list Shark, a free open source Finder alternative
>
> Hi MacUpdate team,
>
> I'm the developer of Shark, a free, open source (Apache 2.0) file manager for macOS 14+. It adds tabs, split panes, a built-in terminal and hover previews to a Finder-style interface.
>
> Latest release (1.0.0-alpha.2, signed and notarized): https://github.com/andronasef/shark/releases
> Website: https://shark.andronasef.com
> Source: https://github.com/andronasef/shark
> Homebrew: `brew install --cask andronasef/shark/shark`
>
> It is alpha, so I'd be glad to take any compatibility notes. Screenshots and the icon are in the repo under `docs/screenshots` and `Resources/AppIcon.png`.
>
> Thanks,
> Andrew Nasef

---

## 3. macapps.link

The site has a "Request an app & say hello!" form (name, email, message). Draft message:

> Hi, I'm the developer of Shark, a free open source Finder alternative for macOS 14+ (tabs, split panes, terminal drawer, hover previews). It's Apache 2.0, built in Swift, and in alpha.
> Site: https://shark.andronasef.com
> Repo: https://github.com/andronasef/shark
> Would you consider adding it? Happy to send icons or screenshots.

---

## 4. awesome-mac (PR to jaywcjlove/awesome-mac)

Rules from its CONTRIBUTING: one PR per suggestion, alphabetical order inside the category, title casing, one-sentence description, useful PR title.

Section: `### Finder Tools` (README.md line ~1687). Shark goes between `RClick` and `Strata Files`.

Line to add to `README.md`:

```md
* [Shark - Better Finder](https://shark.andronasef.com) - Native file manager with tabs, split panes, a built-in terminal, and hover previews. [![Open-Source Software][OSS Icon]](https://github.com/andronasef/shark) ![Freeware][Freeware Icon] ![Native App][Native Icon]
```

The repo keeps `README-zh.md`, `README-ja.md` and `README-ko.md` in sync. Same position, translated description (please check these, I'm less sure of them than the English):

```md
* [Shark - Better Finder](https://shark.andronasef.com) - 原生 macOS 文件管理器，支持标签页、分屏、内置终端和悬停预览。 [![Open-Source Software][OSS Icon]](https://github.com/andronasef/shark) ![Freeware][Freeware Icon] ![Native App][Native Icon]
* [Shark - Better Finder](https://shark.andronasef.com) - タブ、分割ペイン、内蔵ターミナル、ホバープレビューを備えたネイティブのファイルマネージャ。 [![Open-Source Software][OSS Icon]](https://github.com/andronasef/shark) ![Freeware][Freeware Icon] ![Native App][Native Icon]
* [Shark - Better Finder](https://shark.andronasef.com) - 탭, 분할 창, 내장 터미널, 호버 미리보기를 지원하는 네이티브 파일 관리자. [![Open-Source Software][OSS Icon]](https://github.com/andronasef/shark) ![Freeware][Freeware Icon] ![Native App][Native Icon]
```

PR title: `Add Shark - Better Finder to Finder Tools`

PR body:

> Adds Shark, a free open source (Apache 2.0) native macOS file manager with tabs, split panes, a terminal drawer and hover previews. Placed alphabetically in Finder Tools, between RClick and Strata Files, using the same icon style as neighbouring entries. Also added to the zh, ja and ko READMEs.

Process: I fork the repo with `gh`, edit the four files, and open the PR only after you say go. Opening a PR is public, so it stays a draft until you approve.

---

## 5. open-source-mac-os-apps (PR to serhii-londar/open-source-mac-os-apps)

Rules: edit `applications.json` only (not the README), one PR per app, description ends with a period, repo needs a recent commit and an English README. Shark qualifies. Category id `finder` exists; `utilities` is the fallback.

Entry:

```json
{
    "short_description": "Native file manager with tabs, split panes, a built-in terminal, and hover previews.",
    "categories": [
        "finder"
    ],
    "repo_url": "https://github.com/andronasef/shark",
    "title": "Shark",
    "icon_url": "https://raw.githubusercontent.com/andronasef/shark/main/Resources/AppIcon.png",
    "screenshots": [
        "https://raw.githubusercontent.com/andronasef/shark/main/docs/screenshots/tabs-and-split.png",
        "https://raw.githubusercontent.com/andronasef/shark/main/docs/screenshots/terminal.png"
    ],
    "official_site": "https://shark.andronasef.com",
    "languages": [
        "swift"
    ]
}
```

PR title: `Add Shark - Better Finder`

PR body (the repo has a PR template, I'll fill it in when I open the PR):

> Shark is a free, Apache 2.0 native file manager for macOS 14+, written in Swift and SwiftUI. Added to `applications.json` under the Finder category.

I still need to confirm the default branch name is `main` before the raw URLs are final.

---

## 6. Smaller directories (each needs an account or a form, same copy)

Use the tagline, one-liner and short description from section 0.

| Site | What it asks for | Notes |
|---|---|---|
| SaaSHub | Name, URL, tagline, description, category | Category: File Management. Lists "alternatives to", so reuse the AlternativeTo list. |
| Uneed | Name, URL, tagline, description, logo, screenshots | Free launch queue. |
| Peerlist (Launchpad) | Project name, tagline, description, links | Needs a profile. A weekly launch slot. |
| Fazier | Name, URL, tagline, description | Free listing. |
| BetaList | Name, URL, pitch | Aimed at pre-launch products. An alpha fits, but they may decline it as already launched. |
| DevHunt | Name, URL, tagline, description | Dev tool angle: terminal drawer, command palette, Homebrew install. |

I haven't opened these forms yet, so the field lists are expectations, not verified.

---

## Suggested extra (your call, not done)

The repo has no GitHub topics set. Adding `macos`, `file-manager`, `finder-alternative`, `swift`, `swiftui`, `dual-pane`, `terminal` helps GitHub search and the awesome-list maintainers. I haven't changed it because it edits the public repo page.
