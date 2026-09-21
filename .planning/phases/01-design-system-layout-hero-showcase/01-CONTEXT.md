# Phase 01: Design System, Layout & Hero Showcase - Context

**Gathered:** 2026-09-21  
**Status:** Ready for planning  

<domain>
## Phase Boundary

Establish the zero-build static site structure in `docs/` for GitHub Pages, implement the dark glassmorphic styling system (frosted glass panels, translucent borders, electric Apple blue/cyan accents), build the floating glass navigation bar, craft the centered spotlight Hero section, and integrate the live GitHub Releases download pipeline for `MagicTouch.dmg`.
</domain>

<decisions>
## Implementation Decisions

### Visual Styling & Glassmorphism
- **Background Palette**: Deep Obsidian Dark (`#070709`) with dark frosted cards (`#121217/60`) and 1px translucent borders (`border-white/10`).
- **Accent Lighting**: Electric macOS Blue & Cyan glow (`#0071e3` and `#38bdf8`) with subtle radial background ambient lights matching native macOS Sonoma/Sequoia wallpapers.
- **Glass Panel Treatment**: Frosted glass panels with a subtle top-edge specular highlight simulating native macOS window chrome without heavy multiple `backdrop-filter` passes.
- **Typography & Density**: Apple-style spacious layout using the native `-apple-system, BlinkMacSystemFont, "SF Pro Display", "Inter"` font stack with generous padding and tracked badge labels.

### Hero Section Layout
- **Composition**: Centered Spotlight layout with bold centered typography, platform capability badges, primary and secondary CTA buttons, and a floating native macOS popover mockup below.
- **Headline & Hook**: 
  - Headline: *"Unleash Your Magic Mouse"*
  - Subtitle: *"Ultra-responsive multi-touch gestures, middle click, pinches, and custom hotkeys for macOS."*
- **Platform Badges**: Row of glass pill badges sitting above the headline:
  - "⚡ Universal Binary (Apple Silicon & Intel)"
  - "🖥️ macOS 13+ Ventura / Sonoma / Sequoia"
  - "🔒 Zero Telemetry • 100% Local"
  - "✨ v0.1.1 Released"
- **Hero Preview Element**: Floating Native macOS Popover Mockup recreating the look of `MainPopoverView` (menu bar status item, live mouse sensor visualizer outline, and active gesture badge).

### Download CTA & Quick Install
- **Primary CTA**: Glowing macOS Blue Pill button (`#0071e3`) with Apple icon, "Download for macOS", dynamic "v0.1.1 (Universal DMG)" subtext, and subtle hover pulse effect.
- **Secondary Actions**: 
  - "Try Interactive Simulator" (smooth anchor scroll jumping down to the simulator section).
  - "GitHub Repo" (with star icon linking to `https://github.com/namikemen/magictouch`).
- **Terminal Install Snippet**: Sleek dark terminal card with one-click copy button, displaying:
  `git clone https://github.com/namikemen/magictouch.git && cd magictouch && ./package_app.sh`
  (includes animated "Copied!" feedback).
- **Metadata Footnote**: Trust & Compatibility caption under the buttons: *"Free & Open Source under MIT • Universal Binary • Verified SHA-256"*.

### Navigation Bar Structure
- **Layout Format**: Floating Frosted Glass Pill centered at the top of the viewport (`sticky top-4 z-50 mx-auto max-w-5xl backdrop-blur-md`).
- **Navigation Links**: Anchor jump links to page sections: "Features", "Simulator", "Gesture Matrix", "Install Guide".
- **Navbar Quick Actions**: Right-aligned group featuring a GitHub Star button and a compact "Download .DMG" pill button.
- **Mobile Menu**: Responsive hamburger toggle that smoothly animates a frosted glass slide-down drawer with tap-to-dismiss backdrop.

### Claude's Discretion
- Exact Tailwind utility combinations and CSS keyframe animations for gradient shimmer and button hover states.
- Error fallback handling in `main.js` if the GitHub API is unavailable or rate-limited.
- Exact SVG path icons for Apple logo, GitHub logo, terminal prompt, and download arrows.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing:**

- `.planning/PROJECT.md` — Project core value, vision, and requirements
- `.planning/REQUIREMENTS.md` — Active requirements `DSGN-01`, `DSGN-02`, `DSGN-03`, `HERO-01`, `HERO-02`, `HERO-03`, `HERO-04`
- `.planning/research/STACK.md` — Zero-build static architecture (HTML5 + Tailwind CSS + Vanilla JS)
- `.planning/research/ARCHITECTURE.md` — Directory structure (`docs/`), module boundaries, and build order
- `.planning/research/PITFALLS.md` — Glassmorphism GPU performance rules and GitHub API rate-limit mitigations
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets & References
- `Sources/MagicTouch/Views/MainPopoverView.swift`: The native SwiftUI popover UI layout (header, connection indicator, visualizer frame, mappings table) to recreate in the Hero preview mockup.
- `README.md`: Contains verified feature descriptions, gesture matrix tables, and project metadata.
- `.github/workflows/release.yml`: Defines the release asset naming convention (`MagicTouch.dmg`, `latest.json`).
- Current release tag: `v0.1.1` in git tag history.

### Established Patterns
- Direct download URL pattern: `https://github.com/namikemen/magictouch/releases/latest/download/MagicTouch.dmg`
- GitHub Releases API: `https://api.github.com/repos/namikemen/magictouch/releases/latest`
- Fallback manifest: `https://github.com/namikemen/magictouch/releases/latest/download/latest.json`

### Integration Points
- Files will be placed in `docs/` at repository root so GitHub Pages can serve them directly without build tools.
</code_context>

<specifics>
## Specific Ideas

- Floating glass capsule navigation bar inspired by modern Apple and Linear website aesthetics.
- Dynamic version tag update via `main.js` that checks GitHub API and automatically updates the CTA button text and badge from `v0.1.0` to the latest tag (e.g. `v0.1.1`).
- Interactive terminal snippet with one-click copy to clipboard and toast feedback.
</specifics>

<deferred>
## Deferred Ideas

- Interactive Canvas multi-touch Magic Mouse simulator (deferred to Phase 2).
- Procedural Web Audio haptic feedback engine (deferred to Phase 2).
- Full 30+ gesture matrix interactive tabs and macOS permission visual cards (deferred to Phase 3).
</deferred>

---

*Phase: 01-design-system-layout-hero-showcase*  
*Context gathered: 2026-09-21*  
