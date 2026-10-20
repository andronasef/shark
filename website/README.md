# Shark website

Static Astro landing page for the free native macOS file manager.

## Run locally

Requires Node.js 22.22+.

```sh
cd website
npm ci
npm run dev
```

Open `http://localhost:4321/shark/`. Build with `npm run build`, then use `npm run preview` to inspect the production output.

## Publish

The site is configured for `https://andronasef.github.io/shark/` in `astro.config.mjs`. Upload the contents of `website/dist/` to your static host, or configure GitHub Pages to deploy that directory through Actions. For a custom domain, update `site` and set `base` to `/` before building. No deployment has been performed.

Download buttons point to `https://github.com/andronasef/shark/releases/latest`; source and issue links use the same repository. The owner will publish that repository later. Publish a release containing a ZIP of the app before promoting the download page. The website intentionally makes no claims about a currently available version, signing status, or download count.

## Editing

- `src/pages/index.astro`: sections, feature copy, FAQ, and project links.
- `src/pages/features.astro`: complete feature page; its maintained catalog is `src/data/features.ts` (`featureGroups`). Add or revise entries in the same change as app features, as required by the root `AGENTS.md`.
- `src/components/SiteHeader.astro` and `SiteFooter.astro`: shared navigation for both pages.
- `src/components/DownloadLink.astro`: shared download destination.
- `src/styles/global.css`: responsive layout, materials, motion and accessibility.
- `src/assets/`: optimized screenshots of the real app.
- `DESIGN.md`: website-specific design rules; the root design guide continues to own the native app.

No React runtime, external fonts, analytics, cookies, or third-party asset requests are used. Navigation, FAQs and download links work with JavaScript disabled.

## Assets and reference

Screenshots derive from `../docs/screenshots/`; the icon derives from `../Resources/AppIcon.png`. These are existing Shark project assets, not generated product mockups. See `ASSETS.md` for provenance.

The material treatment is original CSS informed by [LiquidGlass-UI](https://github.com/hwyuanzi/LiquidGlass-UI): restrained sheen, backdrop blur, and progressive fallbacks. No library code is copied or installed. This implementation does not claim optical refraction.
