# Phase 3: Gesture Matrix, Installation Guide & GitHub Pages Readiness - Context

**Gathered:** 2026-09-21
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver the complete filterable 30+ gesture matrix, action target breakdown, technical architecture cards, step-by-step macOS permissions walkthrough, SEO metadata/favicon, and verify zero-dependency deployment for GitHub Pages.

</domain>

<decisions>
## Implementation Decisions

### 30+ Gesture Matrix & Filter Bar
- Category filter pills: "All Gestures (30+)", "1 Finger", "2 Fingers", "3 Fingers", "4 Fingers", "Clicks & Taps", "Swipes & Pinches".
- Live instant search input field allowing visitors to search gestures by keyword (e.g. "middle", "tab", "zoom", "swipe").
- Gesture cards styled with `.glass-panel`, featuring:
  - Gesture name and icon.
  - Finger count pill badge.
  - Plain-English trigger description.
  - Default action assignment badge.
  - Available action type indicators (Mouse, Hotkey, System, Script).

### Action Targets Showcase
- 4 dedicated action target cards explaining configuration flexibility:
  1. Mouse Clicks & Triggers (Left, Right, Middle Click / Button 3, Double Click, Triple Click).
  2. Keyboard Shortcuts (Arbitrary key combinations with ⌘, ⌥, ⌃, ⇧).
  3. macOS System Features (Mission Control, App Exposé, Spaces Navigation, Smart Zoom).
  4. Advanced Scripts (Arbitrary AppleScript commands and Terminal shell executions).

### Technical Architecture Highlights
- 3 core glassmorphic highlight cards:
  - Private C-API Hook: Direct `MultitouchSupport.framework` event tap with sub-millisecond recognition.
  - Privacy First & Zero Telemetry: 100% offline, no cloud analytics or tracking.
  - Ultra-Lightweight Native App: Pure Swift & AppKit menu bar agent (<25MB RAM, ~0% idle CPU).

### Visual macOS Permissions Guide
- Visual 3-step cards with native macOS Sonoma/Sequoia UI mockups:
  - Step 1: Drag `MagicTouch.app` into Applications folder.
  - Step 2: Enable in `System Settings → Privacy & Security → Accessibility` (enables simulated mouse clicks and keypresses).
  - Step 3: Enable in `System Settings → Privacy & Security → Input Monitoring` (enables reading raw capacitive touch coordinates).
- Visual toggle switches with animated interactive state.

### GitHub Pages & SEO Readiness
- Zero build requirement: pure static HTML/CSS/JS inside `docs/`.
- Embedded SVG favicon (`docs/favicon.svg`) with Magic Mouse & wand motif.
- Comprehensive OpenGraph and Twitter card metadata for sharing.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Codebase Gestures & Architecture
- `Sources/MagicTouch/GestureRecognizer.swift` — Full list of recognized gesture types and thresholds
- `Sources/MagicTouch/ConfigurationStore.swift` — Default gesture bindings and action definitions
- `Sources/MagicTouch/MultitouchBridge.h` — Multitouch private framework headers and event callbacks

### Project Specs
- `.planning/REQUIREMENTS.md` §MTRX, §GUIDE, §DPLY
- `.planning/ROADMAP.md` §Phase 3

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `docs/css/style.css`: `.glass-panel`, `.glass-pill`, `.specular-rim`, and glow utility classes.
- `docs/index.html`: `#features`, `#gestures`, `#installation` sections ready for content replacement.
- `docs/js/main.js`: Established DOM hydration and event handling patterns.

### Integration Points
- `docs/index.html`: Replace placeholder sections `#features`, `#gestures`, `#installation`.
- `docs/js/gestures.js` or `docs/js/main.js`: Gesture search and filter logic.
- `docs/favicon.svg`: Brand icon for site tab and bookmarks.

</code_context>

<deferred>
## Deferred Ideas

- User preset configuration exporter (`gestures.json`) — v2
- Community presets upload portal — v2

</deferred>

---

*Phase: 03-gesture-matrix-installation-guide-github-pages-readiness*
*Context gathered: 2026-09-21*
