# SEO and AI search

Last updated 29 Oct 2026. Keyword data: Semrush, US database, pulled 29 Oct 2026.

## Target keywords

Main cluster, all easy (KD under 30). Together about 2K US searches a month.

| Keyword | US volume | KD % |
| --- | --- | --- |
| finder alternative | 210 (1.1K global) | 27 |
| macos finder alternative | 210 | 21 |
| mac finder replacement | 210 | 25 |
| mac finder alternative | 170 | 29 |
| finder alternatives for mac | 170 | 20 |
| mac os x finder alternative | 170 | 16 |
| os x finder alternative | 170 | 16 |
| mac os finder alternative | 110 | 24 |
| alternative finder mac | 110 | 22 |
| macbook finder alternative | 110 | 23 |
| finder alternative mac | 90 | 25 |

Wider file manager terms (harder, but worth a page each over time):

| Keyword | US volume | KD % |
| --- | --- | --- |
| mac file explorer | 390 | 53 |
| macos file manager | 260 | 33 |
| mac os x file manager | 260 | 37 |
| mac os file manager | 210 | 52 |
| best file manager for mac | 110 | 21 |
| best file browser for mac | 110 | 28 |
| better file manager for mac | 70 | 21 |
| best file manager for macos | 70 | 19 |
| dual pane file manager mac | 30 | n/a |
| mac total commander alternative | 20 | n/a |

## Pages that target them

| Page | Main keywords |
| --- | --- |
| `/guides/finder-alternatives-mac/` | finder alternative cluster, best file manager for mac |
| `/guides/windows-file-explorer-on-mac/` | mac file explorer, windows explorer for mac |
| `/guides/dual-pane-file-manager-mac/` | dual pane file manager mac, finder split screen |
| `/guides/cut-and-paste-files-mac/` | how to cut files in mac finder |
| `/guides/open-terminal-in-folder-mac/` | open terminal in folder mac |

Competitor facts in the roundup (prices, features) were taken from each developer's site on 29 Oct 2026. Recheck them every few months and bump `updated` in the guide's frontmatter.

Next guide ideas: show hidden files on Mac, batch rename files on Mac, Total Commander for Mac, ForkLift vs Finder.

## Technical setup (done)

- Sitemap (`/sitemap-index.xml`) and `robots.txt` allow every crawler, AI crawlers included.
- Structured data: `SoftwareApplication` on every page, `FAQPage` on the home page, `Article` plus `BreadcrumbList` on guides.
- `/llms.txt` lists the product, pages, guides and every feature. It is generated at build time, so it never goes stale.

## Google Search Console (you do this)

1. Open https://search.google.com/search-console and add a **Domain** property for `shark.andronasef.com` (or `andronasef.com` to cover every subdomain).
2. Add the TXT record Google gives you at your DNS provider, then click Verify. DNS verification needs no change to the site.
3. In **Sitemaps**, submit `https://shark.andronasef.com/sitemap-index.xml`.
4. In **URL Inspection**, request indexing for `/guides/finder-alternatives-mac/` and the other guides.
5. Do the same at Bing Webmaster Tools (it can import from Search Console). Bing's index feeds ChatGPT search and Copilot.

## AI search

- AI answers quote pages that answer the question in the first lines, with lists and tables. The guides are written that way.
- They also lean on third-party mentions: AlternativeTo, Reddit threads, awesome lists, Product Hunt. The directory work in `marketing.md` helps here as much as the site does.
- Keep facts in the guides true. A wrong claim about a competitor gets repeated by every AI tool that reads the page.

## Images

Guides use Shark's own screenshots plus three freely licensed photos from Wikimedia Commons, each credited under the image as its license requires:

- `website/src/assets/guides/norton-commander.png`: Yuri Samoilov, CC BY 2.0
- `website/src/assets/guides/magic-keyboard.jpg`: Fletcher, CC BY 4.0
- `website/src/assets/guides/macbook-air-keyboard.jpg`: TheumasNL, CC BY-SA 4.0

The Finder alternatives roundup also uses one official product screenshot per competitor, credited and linked to its site: ForkLift (BinaryNights), Commander One (Electronic Team), Marta, Nimble Commander (Magnumbytes) and QSpace. These are in `website/src/assets/guides/alternatives/`. Path Finder has none yet, because its site has no image files to pull. If a developer asks for an image to come down, remove it.

Only add other outside images with a free license (Commons, Unsplash, Pexels) and keep the credit line. Don't use competitors' screenshots or images from Google Images.
