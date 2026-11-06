# Phase 12: Honest Sidebar and System Boundaries - Context

**Gathered:** 2026-11-06
**Status:** Ready for planning

<domain>
## Phase Boundary
Remove fake Finder tag navigation and explain the system Open/Save boundary. HON-01 and HON-02 only; actual tags belong to Phase 19.
</domain>

<decisions>
## Implementation Decisions
### Sidebar
- Remove the Tags section, color-name filters and inert All Tags action, including keyboard traversal entries.
- Preserve Favorites, Locations, tree, mounted-volume eject and collapse behavior.
### System boundary
- Help, onboarding and the website FAQ explain that other apps retain system Open/Save dialogs, even when Shark is the default folder app.
- Correct catalog references to absent Tags without adding future feature claims.
### Implementation discretion
- Use existing native text styles and layout, no new controls or dependencies. Approved decisions in EVERYDAY-MAC-MILESTONE.md supersede repeated grilling.
</decisions>

<code_context>
## Existing Code Insights
- PlacesSidebarView contains tagItems, a Tags section and an independent keyboard-order projection; remove all three together.
- HelpView and OnboardingView already explain feature discovery and folder integration.
- website/src/data/features.ts is the public inventory; index.astro owns the home FAQ.
</code_context>

<specifics>
## Specific Ideas
Keep the Finder visual direction; no placeholder Tags heading or disabled replacement.
</specifics>

<deferred>
## Deferred Ideas
Actual Finder tags remain scheduled for Phase 19, not deferred from the milestone.
</deferred>
