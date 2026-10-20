# Shark Website Implementation Plan

**Goal:** Build the approved free-download landing page inside `website/`.

**Architecture:** Static Astro site with reusable layout, icon and download components; plain CSS and native HTML interactions. Existing real app screenshots supply the visual proof. No client framework or animation library.

**Tech stack:** Astro 7, TypeScript, CSS, optimized WebP screenshots.

**Spec:** User-approved plan in this thread; website design rules in `website/DESIGN.md`.

## Constraints

- Bright, professional macOS identity with restrained liquid glass.
- Download is the primary action; Shark is free and requires macOS 14+.
- Source and releases point to `andronasef/shark`, which the owner will publish later.
- Keep native application source unchanged. No invented adoption, performance, or testimonial claims.

## Tasks

- [x] Build Astro configuration, accessible shared components, hero, four feature stories, tool list, FAQ, download close and footer.
- [x] Optimize and attribute existing images; document website tokens and publishing instructions.
- [x] Run production build and design detector. Inspect desktop and mobile renders, check overflow, image loading, navigation, FAQ, focus, and reduced motion.
- [x] Review the final page independently, address material findings, update the changelog, and commit this feature.

## Review focus

- Small screens: no horizontal overflow; primary action remains visible and usable.
- No JavaScript: navigation, download, and FAQ remain functional.
- Reduced motion/transparency and forced colors: content remains readable.
- GitHub Pages subpath: every image and internal link resolves under `/shark/`.
- Unpublished release: clearly document that the release URL becomes live after the owner publishes.

## Verification record

- Production Astro build passed; generated page contains zero client script imports.
- Headless Chromium: 1440, 768, 390, and 320px widths; zero horizontal overflow, all images loaded.
- FAQ mouse and keyboard operation, no-JavaScript behavior, reduced motion and forced colors passed.
- Design detector reported no findings. White primary-action text contrast is 5.29:1.
- Existing native suite: 114 tests passed, zero failures.
- Independent Impeccable finish review: `ship`, no material fixes. Review used the shipped reviewer procedure through a fresh general agent because the specialized role was unavailable.
- Download/source/issue destinations use the owner-supplied repository. Publication has not been performed.
