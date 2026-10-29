# Marketing

Listing name from 29 Oct 2026: **Shark – File Manager** (matches the App Store after Apple rejected "Finder" in the name). Listings made before that use "Shark - Better Finder" and stay as they are. Prose can say "Shark".

SEO keywords, guides and the Search Console steps: [seo.md](seo.md).

Last updated 27 Oct 2026. Copy for every listing lives in [phase1-drafts.md](phase1-drafts.md).

## Facts to reuse

- Site: https://shark.andronasef.com
- Repo: https://github.com/andronasef/shark (Apache 2.0)
- Trailer: https://youtu.be/SoQqCcbbE1c
- Install: `brew install --cask andronasef/shark/shark`
- Mac App Store: https://apps.apple.com/us/app/shark-better-finder/id6825086341 (in review, link not live yet)
- Version: 1.0.0-alpha.2, macOS 14+, 8 languages
- Story: used Windows, missed File Explorer, built a Finder with superpowers that feels familiar. Also borrows from QTTabBar (Windows) and Dolphin (KDE).
- Images: App Store screenshots only. Copies in the session scratchpad `shots/` (JPEG, about 500 KB each).

## Done

| Platform | Status | Notes |
| --- | --- | --- |
| Product Hunt | Launched | Done before this plan. |
| AlternativeTo | Submitted 27 Oct | Normal review queue. Paid priority ($5) and "we finish it" ($15) not bought. |
| MacUpdate | Submitted 27 Oct (by you) | In their review queue. Check the email linked to the Google account for approval or questions. |
| awesome-mac | PR opened 27 Oct | https://github.com/jaywcjlove/awesome-mac/pull/3930 |
| open-source-mac-os-apps | PR opened 27 Oct | https://github.com/serhii-londar/open-source-mac-os-apps/pull/1812 |
| awesome-swift-macos-apps | Merged | https://github.com/jaywcjlove/awesome-swift-macos-apps/pull/176 |
| README | Updated | Trailer link added to the top row. Not committed. |

## Remaining in Phase 1 (directories)

Copy is drafted for all of these. None of the forms are opened yet. Each needs its own login.

| Platform | Notes |
| --- | --- |
| SaaSHub | Category File Management. Reuse the AlternativeTo "alternative to" list. |
| Uneed | Free launch queue. Needs logo and screenshots. |
| Peerlist | Project launch page. |
| Fazier | Free listing. |
| BetaList | Aimed at pre-launch products. May decline an alpha that is already public. |
| DevHunt | Dev angle: terminal drawer, command palette, Homebrew install. |
| macapps.link | Skipped. Last updated in 2022 and the form wants an email. |

## After the AlternativeTo approval

Add "alternative to" links: Finder, Path Finder, ForkLift, Marta, Commander One, QTTabBar, Dolphin. This is only possible once the listing is approved.

## Content: one article at a time

Publish one article at a time, and make each one the most useful page on the web for its question. Quality over volume: one great guide beats five thin ones.

For each article:

1. Pick one real question people search (check volume and difficulty in Semrush; see [seo.md](seo.md)).
2. Answer it in the first two sentences, then go deeper than the pages that rank today: steps, shortcuts, screenshots, edge cases, and an FAQ.
3. Check every fact. Shark claims against the app; competitor claims against the developer's own site.
4. Mention Shark only where it actually solves the problem.
5. Publish under `website/src/content/guides/`, request indexing in Search Console, and share it where the question gets asked (Reddit, forums, social).
6. Only start the next one when this one is done.

Published so far: Finder alternatives comparison, File Explorer for Mac, Finder split screen, cut and paste files, open Terminal in a folder. Next candidates are in [seo.md](seo.md).

## Later phases (not started)

You only authorised Phase 1. Each of these needs a draft and your review first.

| Platform | Angle |
| --- | --- |
| Show HN | "Show HN: Shark – File Manager, a native Mac file manager with tabs, split panes and a terminal". Post on a weekday morning US time. Be ready to answer comments for a few hours. |
| r/macapps | Allowed to self-promote with disclosure. Lead with the story and a screenshot. |
| r/macOS, r/MacOSApps, r/swift, r/opensource | Check each sidebar for self-promotion rules before posting. |
| Indie Hackers | Product page plus a build story post. |
| dev.to or Hashnode | "Why I built a Finder with the things I missed from Windows Explorer." Embed the trailer. |
| X, Bluesky, Mastodon, LinkedIn | Short post with the trailer. |
| Newsletters and press | MacStories, 9to5Mac, The Sweet Setup, Mac Power Users, Setapp-style roundups. Pitch only after the App Store link is live. |

## Housekeeping

- Commit `README.md` and `docs/launch/` when you want them in git. Nothing here is committed.
- GitHub topics are empty. Suggested: `file-manager`, `finder-alternative`, `macos`, `swift`, `swiftui`, `terminal`. This changes the public repo page, so I have not touched it.
- After the Mac App Store approval: replace the "in review" badge in the README and add the store link to every listing.
- Some listings may need a fresh screenshot set once the alpha changes visually.

## Risks and open questions

- AlternativeTo may reject the Homebrew cask because it is in a personal tap and not the main cask repository.
- MacUpdate sign-in via Google may have created a new account (androamazing). I could not tell.
- The App Store link is dead until Apple approves the app. Listings that require a working link should wait.
- Alpha status: some directories prefer stable releases, so expect a few to decline or delay.
