# Reddit posts

Drafted 8 Nov 2026 for Shark 1.0.0-alpha.4. Nothing here is posted. Post from your own account, and rewrite the text in your own voice first: r/macapps mods are more likely to remove posts that read as AI-written.

## Before you post on r/macapps

The rules below come from community posts and megathreads from March to June 2026. Read the current sidebar and pinned posts first, because they change.

- **Eligibility for the main feed:** a Mac App Store presence (Shark now has one), a recognized-developer flair, or 10+ karma in r/macapps. If you don't qualify, post in the monthly megathread instead.
- **One app post per developer every 30 days.** The clock starts at your last app post, even if it was removed. A megathread post counts too.
- **Disclose that you're the developer**, in the post and in every comment that mentions Shark.
- **Required format, "PCP":** app name, the **P**roblem it solves, a **C**omparison with one or two competitors, and **P**ricing with a link. Posts without it may be removed.
- **Identity:** mods want a real developer identity. Link andronasef.com and the GitHub repo, and post from your main account.
- Use the developer/self-promotion flair if the sub offers one.

## Where to post (researched 8 Nov 2026)

Rules come from third-party rule trackers and community posts, not each sub's own pages. Read the sidebar before every post.

| Subreddit | Self-promotion | How to post Shark |
| --- | --- | --- |
| r/macapps | Allowed, limited: one dev post per 30 days, PCP format, disclose; otherwise the monthly megathread | Main post below |
| r/SideProject | Allowed; don't repost the same project often | "I built a Finder alternative because I missed Windows Explorer" |
| r/coolgithubprojects | Allowed for GitHub-hosted projects; repost only after ~6 months with new features | Repo link plus a screenshot |
| r/opensource | Restricted: Promotional flair, OSI license required (Apache 2.0 qualifies) | Drafted below |
| r/AlphaAndBetaUsers | Allowed; meant for early feedback | Ask for alpha testers |
| r/IMadeThis | Allowed | Short story plus screenshot |
| r/indiehackers | One post with the Self Promotion flair | Build story |
| r/MacOS, r/macbookpro | Product posts get removed; ask the mods first | Answer file-management questions without links |
| r/swift | Product posts restricted | Only a technical write-up, and ask mods first |
| r/appdevelopers | Banned | Skip |

## r/macapps

Keep their required parts: problem, comparison, pricing. Disclose you're the developer.

**Title:** Shark – File Manager: a free Finder alternative with cut and paste, ⌘K and a built-in terminal [Developer]

**Body:**

I'm the developer. I switched from Windows and missed File Explorer, so I built Shark. It looks like Finder and adds:

- Jump anywhere in the folder tree with cascading subfolder menus
- ⌘K command palette for every action
- Cut and paste files with ⌘X / ⌘V (and ⌘Z to undo)
- Two folders in one window (F3)
- A terminal right under your files (F4)

**Vs.** ForkLift and Commander One if you need SFTP or cloud; Shark is local files only, Finder-style.

**Price:** free, open source, macOS 14+. Still alpha.

- App Store: https://apps.apple.com/us/app/shark-file-manager/id6825086341
- GitHub: https://github.com/andronasef/shark

**Attach:** the App Store screenshots in `docs/appstore-screenshots/`.

## Posting schedule

One subreddit every few days, never two on the same day, each with its own text. Post on a weekday morning US Eastern time and stay to answer comments for 2–3 hours.

| Date | Subreddit | Angle |
| --- | --- | --- |
| Tue 10 Nov | r/macapps | The app, in their PCP format |
| Fri 13 Nov | r/SideProject | Why I built it, ask for feedback |
| Tue 17 Nov | r/coolgithubprojects | The repo |
| Fri 20 Nov | r/opensource | Open source angle, ask for contributors |
| Tue 24 Nov | r/IMadeThis | Short and visual |
| Fri 27 Nov | r/indiehackers | Build and launch story |

If r/macapps removes the post, wait for the mods' reason before posting anywhere else.

## r/SideProject

**Title:** I missed Windows File Explorer on my Mac, so I built my own file manager

**Body:**

Shark looks like Finder but adds cascading subfolder menus, a ⌘K command palette, real cut and paste, two folders in one window and a terminal under your files. Free, open source, alpha. What would make you leave Finder?

https://shark.andronasef.com

## r/coolgithubprojects

**Title:** Shark: open source macOS file manager with ⌘K, cut and paste, split panes and a terminal (Swift/SwiftUI)

**Link:** https://github.com/andronasef/shark

**First comment:** Finder-style look, five additions: subfolder menus, ⌘K palette, ⌘X/⌘V, F3 split, F4 terminal. Apache 2.0. `brew install --cask andronasef/shark/shark`

## r/opensource

Use the Promotional flair.

**Title:** Shark: a free, open source Finder alternative for macOS (Apache 2.0)

**Body:**

Native Swift/SwiftUI file manager: subfolder menus, ⌘K command palette, cut and paste, split panes and a built-in terminal. It's alpha. Bug reports, translations and PRs welcome.

https://github.com/andronasef/shark

## r/IMadeThis

**Title:** I made a Mac file manager that looks like Finder but works like Windows Explorer

**Attach:** the trailer (https://youtu.be/SoQqCcbbE1c) or one App Store screenshot.

**Body:** Shark. Free and open source. https://shark.andronasef.com

## r/indiehackers

Use the Self Promotion flair.

**Title:** Shipped a free Mac app in a month. Apple rejected it for one word in the name

**Body:**

I built Shark, a Finder alternative, in four weeks. Apple rejected it because the name had "Finder" in it (their trademark). Renamed to "Shark – File Manager" and it passed. Lesson: keep Apple's product names out of your name, subtitle and keywords.

It's free and open source. Shipping on the App Store and Homebrew. What brought users to your free app?

https://shark.andronasef.com

## r/swift or r/SwiftUI (optional, build story)

Only post here if you write about the code, not the product. Something like:

**Title:** What I learned building a Finder alternative in SwiftUI: keeping a 10,000-file folder smooth

Write it from what actually happened in the alpha.4 scrolling work (thumbnails loading only after scrolling settles, fewer redraws per cell). Link the repo at the end, not the App Store.

## Don't

- Don't post the same text to several subs on the same day. It reads as spam and can get the account flagged.
- Don't ask friends to upvote. Reddit detects vote manipulation.
- Don't call it "Better Finder" in titles; use "Shark – File Manager".
