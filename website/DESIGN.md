---
name: Shark website
description: A bright, familiar Mac setting for real Shark workflows.
colors:
  ground: "#f7f9fc"
  ink: "#18232e"
  secondary: "#586674"
  accent: "#0069d4"
  accent-hover: "#0067cf"
  line: "#dde3e9"
  white: "#ffffff"
  blue: "#e3edf8"
  mint: "#e3eeea"
  peach: "#f4e9e2"
  lavender: "#ece8f4"
typography:
  display:
    fontFamily: "-apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif"
    fontSize: "clamp(54px, 6.5vw, 88px)"
    fontWeight: 600
    lineHeight: 1.04
    letterSpacing: "-0.035em"
  headline:
    fontFamily: "-apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif"
    fontSize: "clamp(34px, 4.2vw, 50px)"
    fontWeight: 600
    lineHeight: 1.08
    letterSpacing: "-0.035em"
  title:
    fontFamily: "-apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif"
    fontSize: "clamp(27px, 3vw, 36px)"
    fontWeight: 600
    lineHeight: 1.08
    letterSpacing: "-0.035em"
  body:
    fontFamily: "-apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif"
    fontSize: "16px"
    lineHeight: 1.6
  label:
    fontFamily: "-apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif"
    fontSize: "15px"
    fontWeight: 600
    lineHeight: 1.4
  catalog-display:
    fontFamily: "-apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif"
    fontSize: "clamp(44px, 4.6vw, 64px)"
    fontWeight: 600
    lineHeight: 1.06
    letterSpacing: "-0.035em"
  catalog-heading:
    fontFamily: "-apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif"
    fontSize: "clamp(28px, 3vw, 38px)"
    fontWeight: 600
    lineHeight: 1.08
    letterSpacing: "-0.035em"
  catalog-entry-title:
    fontFamily: "-apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif"
    fontSize: "15px"
    fontWeight: 600
    lineHeight: 1.5
  catalog-entry-body:
    fontFamily: "-apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif"
    fontSize: "14px"
    lineHeight: 1.8
rounded:
  key: "5px"
  screenshot: "7px"
  screenshot-hero: "13px"
  panel: "16px"
  floating: "20px"
  navigation: "24px"
  capsule: "999px"
spacing:
  small: "9px"
  control: "13px"
  gutter-mobile: "20px"
  gutter-tablet: "32px"
  gutter-desktop: "48px"
components:
  button-primary:
    backgroundColor: "{colors.accent}"
    textColor: "{colors.white}"
    typography: "{typography.label}"
    rounded: "{rounded.capsule}"
    padding: "13px 23px"
  button-primary-hover:
    backgroundColor: "{colors.accent-hover}"
    textColor: "{colors.white}"
    rounded: "{rounded.capsule}"
  button-compact:
    backgroundColor: "{colors.accent}"
    textColor: "{colors.white}"
    rounded: "{rounded.capsule}"
    padding: "10px 17px"
  feature-panel:
    rounded: "{rounded.panel}"
    padding: "43px 27px"
  catalog-entry:
    textColor: "{colors.ink}"
    padding: "22px 0 26px"
---

# Design System: Shark website

## Overview

**Creative North Star: "A familiar Mac window"**

This guide owns the marketing website only. It extends Shark’s familiar macOS identity without changing the native app’s root design system. The cool, bright ground and system typography create an airy setting for real app screenshots; familiar blue controls and restrained translucent surfaces connect the website to the Mac.

The website gives product imagery room to explain the interface. Quiet copy, visible keyboard shortcuts, and native disclosure controls keep the presentation approachable and practical. The approved page sequence and conversion purpose remain in `.impeccable/surfaces/website-src-pages-index-astro.md`.

**Key Characteristics:**
- Familiar system typography and blue actions.
- Real app imagery on light, softly tinted grounds.
- Structural glass for floating navigation.
- Responsive spacing and accessible native behavior.

## Colors

The palette combines a cool near-white ground, slate text, familiar blue actions, and soft contextual tints. Frontmatter records the reusable values extracted from `src/styles/global.css`, which remains the implementation source of truth.

### Primary

- **Mac action blue:** primary buttons, focus outlines, links in FAQ answers, and navigation hover feedback. White primary labels have a 5.29:1 contrast ratio.
- **Hover blue:** the primary action’s slightly deeper hover state.

### Neutral

- **Cool ground:** the page canvas.
- **Slate ink:** headings and primary text.
- **Secondary slate:** descriptions, captions, and supporting labels.
- **Divider gray:** FAQ and footer separators.
- **White:** action labels, opaque glass fallbacks, and shortcut surfaces.

The blue, mint, peach, and lavender grounds distinguish feature imagery and its matching symbol. These are contextual tints rather than additional action colors. Higher contrast and reduced transparency preferences darken secondary text and replace glass with an opaque white surface. Forced colors retain visible boundaries and semantic system colors.

## Typography

**Display and body font:** the system stack in frontmatter, preserving the established Mac identity. System typography is an explicit product requirement.

### Hierarchy

- **Display:** the two-line hero uses the display role; on small screens it changes to `clamp(44px, 10.7vw, 57px)` with tracking at −0.04em.
- **Headline:** section headings use the headline role; the closing heading scales from 40px to 60px.
- **Title:** feature headings use the title role.
- **Body:** supporting copy ranges from 14px to 18px with line-height between 1.6 and 1.8. Feature descriptions measure up to 42ch on desktop and 60ch in the stacked layout.
- **Label:** primary actions use the label role; compact actions use 13px type. Keyboard hints use 11px system text.

**Catalog hierarchy:** the catalog-display role uses a more compact hero, changing to `clamp(40px, 9.5vw, 52px)` at 540px and below. Catalog category headings use catalog-heading. Entry titles and descriptions use catalog-entry-title and catalog-entry-body; shortcut keys keep their existing small system type.

Headings balance their lines; prose uses pretty wrapping. Heading tracking stays at or above −0.04em.

## Layout

Content has a maximum width of 1180px, with desktop gutters from the spacing scale. At 1000px and below, gutters reduce to the tablet value; at 540px and below, they use the mobile value. The hero screenshot stage can extend to 1320px. Navigation is limited to 1000px.

The header sticks 20px from the top, reducing to 12px on mobile; anchor targets clear it through scroll padding. Feature stories alternate copy and imagery in a two-column grid, with 64px gaps on desktop. At 800px and below, feature stories, the everyday-tools section, and FAQ become single-column; screenshots follow their copy. At 540px and below, hero actions stack, the GitHub header item is hidden while footer links remain, and the dock omits shortcut labels.

Section spacing gives screenshots room: feature stories are separated by 94px on desktop and 70px in the stacked layout. Images keep their full aspect ratios.

The complete Features page uses a split introductory hero, followed by a 235px category index and a flexible catalog column with a 70px gap. The index sticks below the site header at 120px; below 800px it becomes an in-flow two-column list. Catalog entries form two open columns with hairline separators, collapsing to one at 540px. At 1000px and below, the index narrows to 200px and the column gap reduces to 40px. Category headings and the hero retain the established system font and palette with the compact catalog scales recorded above. Footer links wrap as needed on both pages.

## Elevation & Depth

Navigation and the feature dock float above page content with an 82% white fill, 22px backdrop blur, 145% saturation, an upper white highlight, and a soft downward shadow. The blue download button uses a slight inset highlight. Screenshot shadows establish app windows above tinted grounds. No optical refraction is implemented.

**The Structural Glass Rule.** Use glass for floating navigation and the feature dock; keep content sections on open or softly tinted grounds.

Unsupported backdrop filters, reduced transparency, and increased contrast use opaque white surfaces. Exact shadows and transitions are recorded in the sidecar.

## Shapes

Feature panels have gently curved corners using the panel radius, reducing to 12px on mobile. Screenshots use the screenshot radius; the hero uses the larger screenshot-hero radius, reducing to 6px on mobile. Primary controls are capsules. Navigation uses the navigation radius on desktop and floating radius on mobile. Shortcut keys have compact rounded corners and a fine border.

## Components

### Buttons and links

Primary actions are blue capsules with white labels, 52px minimum height, and the primary padding in frontmatter. Compact actions have a 40px minimum height and 13px type. Hover lifts buttons 2px with a 240ms decelerating transition; active resets the lift. Focus uses a 3px blue outline offset 5px. Text links use a restrained blue with an underline on hover.

Download links lead to GitHub’s latest release page. Avoid an unverified version, file size, or immediate binary-download promise.

### Navigation and feature dock

The sticky navigation combines the supplied app icon, wordmark, plain links, and a compact download action. The glass dock contains feature anchors, inline SVG symbols, and shortcut hints where space permits. Its hover state adds a subtle blue fill.

`SiteHeader` and `SiteFooter` are shared across routes. The Features link opens the complete catalog and marks the current page with `aria-current="page"`; FAQ returns to the home-page section. Both routes honor the configured deployment base path. The catalog uses semantic section headings and definition lists, with stable category and feature anchors. Keep content in `src/data/features.ts` current alongside app implementation, as required by the root `AGENTS.md`.

### Catalog entries

Open definition-list entries use a fine top separator and the catalog-entry padding, reducing to 20px above and 24px below on mobile. Titles wrap alongside optional shortcut keys; descriptions sit 10px below. The two-column grid uses a 35px gap, reducing to 25px at 1000px and below. Category index links use secondary text, turning blue and underlined on hover; the current Features route uses the same blue in shared navigation.

### Feature panels and imagery

Feature imagery sits on blue, mint, peach, or lavender panels with matching symbol tiles. Use only real app screenshots and the supplied Shark icon. Keep full screenshots intact and preserve aspect ratios. Raster origins are recorded in `ASSETS.md`; Astro generates responsive screenshot sizes. Do not recreate app UI as a fake screenshot.

### Guide cards

The Guides index is a two-column grid of cards (one column at 640px and below) with a 28px gap, 40px on mobile. Each card is one link: a tinted feature panel holding a full Shark screenshot (16:10, 28px by 24px padding), then a 25px title, a 15px description and a blue text link. The first guide is a featured card spanning both columns, image left and copy right with a 56px gap, stacking at 800px and below. Hovering lifts the panel 3px and deepens the screenshot shadow over 280ms; Reduce Motion removes both. Cards reuse the blue, mint, peach and lavender panel tints and their dark variants. Set a guide's card with `image`, `imageAlt`, `tint` and `order` in its frontmatter, using only Shark screenshots.

### Keyboard hints

Shortcut labels use small bordered white keys with a subtle bottom shadow. Feature-story hints have a 25px minimum height and 28px minimum width; the denser dock hints use lighter fills.

### FAQ disclosures

Native `details`/`summary` controls support keyboard interaction and remain usable without JavaScript. Fine separators distinguish rows; opening rotates the decorative plus sign 45 degrees. Answers use secondary text and underlined links.

### Motion

The single entrance moment is the already-visible hero screenshot settling 15px over 1.1s. Reduced motion disables animation, transitions, and smooth scrolling.

## Do's and Don'ts

### Do:

- **Do** preserve the native Mac identity with system fonts and familiar blue actions.
- **Do** show real, uncropped app screenshots at their original aspect ratios.
- **Do** retain keyboard focus visibility and preference-based glass and motion fallbacks.
- **Do** keep page structure and screenshot provenance in their dedicated surface and asset documents.

### Don't:

- **Don't** invent adoption statistics, reviews, prices, or performance benchmarks.
- **Don't** recreate app UI as a fake screenshot.
- **Don't** imply an immediate binary download when the destination is the release page.
