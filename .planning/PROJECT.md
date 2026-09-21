# MagicTouch Website

## What This Is

A modern, high-impact glassmorphic product showcase and landing page for **MagicTouch**, the native macOS menu bar utility for the Apple Magic Mouse. Hosted on GitHub Pages with zero build dependencies, the site features an interactive virtual Magic Mouse simulator, an animated gesture matrix, installation walkthroughs, and direct universal DMG download integration with GitHub Releases.

## Core Value

Deliver a visually stunning, responsive showcase with an interactive on-page mouse simulator that lets visitors experience MagicTouch's gesture power firsthand before downloading the app.

## Requirements

### Validated

<!-- Shipped and confirmed capabilities from existing macOS codebase -->

- ✓ Low-level multi-touch interception via private `MultitouchSupport.framework` — existing
- ✓ 30+ gesture recognition engine (taps, swipes, pinches, tip-taps, surface clicks) — existing
- ✓ Action dispatcher with synthetic mouse buttons (Button 1, 2, 3, double, triple), hotkeys, AppleScript, shell commands — existing
- ✓ Native SwiftUI menu bar popover with live capacitive touch visualizer — existing
- ✓ In-app update checker querying GitHub Releases and `latest.json` — existing
- ✓ Universal binary packaging (`arm64` + `x86_64`) and automated DMG release workflow — existing

### Active

<!-- Scope for the website initiative -->

- [ ] Responsive glassmorphic dark-mode aesthetic inspired by native macOS design (frosted glass panels, subtle borders, accent glows, system typography)
- [ ] Hero section with headline, app badge, quick feature callouts, and primary "Download for macOS" CTA
- [ ] Interactive Magic Mouse simulator: 2D/3D visualizer with interactive surface allowing users to click/drag/trigger gestures, with live capacitive touch points and gesture trails
- [ ] Sound / haptic toggle offering subtle audio feedback on gesture triggers in the simulator
- [ ] Complete Gesture Matrix showcase highlighting 1-to-4 finger gestures (Middle Click, Tip-Taps, Pinch Zoom, Spaces Navigation)
- [ ] Architecture & Feature highlights (sub-millisecond latency, 100% local privacy, native Swift/AppKit, battery efficient)
- [ ] Installation & Permissions guide detailing macOS Accessibility and Input Monitoring setup
- [ ] Live GitHub Releases integration fetching latest tag version, download stats, and release notes with static fallback to `namikemen/magictouch`
- [ ] Zero-build static architecture ready for GitHub Pages hosting (e.g. `docs/` or root)

### Out of Scope

<!-- Explicit boundaries with rationale -->

- Server-side backend or database — Pure static site suited for GitHub Pages CDN
- Payment processing or licensing paywall — MagicTouch is an open-source utility
- Full blog or CMS platform — Focused product landing page and documentation guide
- Mac App Store links — MagicTouch utilizes private frameworks and is distributed via direct DMG download

## Context

- Existing macOS app repository: `namikemen/magictouch`
- Latest release workflow publishes `MagicTouch.dmg`, universal zip, and `latest.json` to GitHub Releases
- Visual styling should harmonize with the native macOS SwiftUI app (clean dark background, SF-style typography, accent blues/purples, green connection status badge)

## Constraints

- **Hosting**: GitHub Pages compatible (pure static HTML, modern CSS / Tailwind, Vanilla JS, no mandatory build pipeline).
- **Performance**: High frame rate (60fps) animations for the interactive mouse simulator using Canvas or hardware-accelerated CSS.
- **Responsiveness**: Smooth experience across mobile touchscreens and desktop mice.
- **Dependencies**: Zero runtime server dependencies; all assets self-contained or loaded from reliable CDNs.

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Pure Static Stack (HTML5 + Tailwind + Vanilla JS) | Enables instant deployment on GitHub Pages without node build steps or CI pipeline friction | — Pending |
| Interactive Mouse Simulator | Lets users visually test and understand gestures (tip-taps, pinches, middle click) before installing | — Pending |
| Glassmorphic Dark-Mode Design | Matches modern macOS Ventura/Sonoma/Sequoia aesthetic and the native popover look | — Pending |
| GitHub Releases API Integration | Dynamically pulls the latest version number and DMG link so the website never becomes stale | — Pending |

---

*Last updated: 2026-09-21 after initialization*
