# Requirements: MagicTouch Website

**Defined:** 2026-09-21  
**Core Value:** Deliver a visually stunning, responsive showcase with an interactive on-page mouse simulator that lets visitors experience MagicTouch's gesture power firsthand before downloading the app.  

## v1 Requirements

### Design & Glassmorphism (DSGN)

- [ ] **DSGN-01**: User experiences a cohesive dark-mode glassmorphic interface with frosted glass panels, translucent borders, and subtle glow accents matching macOS aesthetics.
- [ ] **DSGN-02**: User can navigate smoothly between page sections using a sticky glassmorphic navigation bar with blurred backdrop and responsive mobile drawer.
- [ ] **DSGN-03**: Layout adapts responsively across mobile, tablet, and high-DPI desktop viewports without overflow or clipping.

### Hero & Downloads (HERO)

- [ ] **HERO-01**: User sees a high-impact headline, product summary badge, and platform specifications (Apple Silicon & Intel Universal, macOS 13+ Ventura/Sonoma/Sequoia).
- [ ] **HERO-02**: User can click the primary "Download for macOS" CTA to download the latest `MagicTouch.dmg` installer directly from GitHub Releases.
- [ ] **HERO-03**: Page asynchronously queries GitHub Releases to display the latest release tag (e.g. `v0.1.0`) and asset details with instant static fallback.
- [ ] **HERO-04**: User can copy a terminal command snippet for one-click installation or repository cloning.

### Interactive Magic Mouse Simulator (SIM)

- [ ] **SIM-01**: User can view a sleek virtual mockup of the Apple Magic Mouse capacitive surface rendered with crisp Retina scaling.
- [ ] **SIM-02**: User can interact directly with the virtual mouse surface via mouse or touch to see live glowing capacitive contact points matching the app's `TouchPoint` model.
- [ ] **SIM-03**: User can click preset gesture tour buttons (3-Finger Click, Tip-Tap Right, Pinch In, 2-Finger Swipe) to watch automated fingertip playback.
- [ ] **SIM-04**: Simulator displays real-time "Recognized Gesture" and "Simulated Action" feedback badges upon gesture detection.
- [ ] **SIM-05**: User can toggle synthesized procedural audio haptics (mechanical clicks and taps via Web Audio API) on and off.

### Gesture Matrix & Actions (MTRX)

- [ ] **MTRX-01**: User can browse the complete matrix of 30+ supported gestures filterable by finger count (1, 2, 3, and 4 fingers).
- [ ] **MTRX-02**: Each gesture card displays gesture name, category, description, and available action bindings.
- [ ] **MTRX-03**: Action target cards highlight mouse button simulations (Left, Right, Middle, Double, Triple Click), Hotkey recording, AppleScript, and Shell commands.

### Architecture & Installation Guide (GUIDE)

- [ ] **GUIDE-01**: User can review technical architecture highlights (sub-millisecond private framework interception, zero background telemetry, native Swift/AppKit).
- [ ] **GUIDE-02**: User can follow a visual step-by-step walkthrough for granting macOS Accessibility and Input Monitoring permissions.
- [ ] **GUIDE-03**: User can view an interactive preview recreating the native SwiftUI menu bar popover interface.

### Deployment & GitHub Pages (DPLY)

- [ ] **DPLY-01**: Website is packaged in `docs/` with zero build dependencies, enabling immediate activation on GitHub Pages.
- [ ] **DPLY-02**: Site includes SEO metadata, OpenGraph tags, Apple touch icons, and clean repository documentation links.

## v2 Requirements

### Community & Extensions

- **V2-COMM-01**: User-submitted gesture presets gallery and community sharing.
- **V2-COMM-02**: Interactive configuration exporter allowing visitors to download custom `gestures.json` directly from the website.

## Out of Scope

| Feature | Reason |
|---------|--------|
| Server-side backend / Database | Unnecessary for static product showcase; site is 100% hosted on GitHub Pages CDN |
| Payment processing & License keys | MagicTouch is a free and open-source utility distributed under the MIT license |
| Mac App Store links | MagicTouch uses private `MultitouchSupport.framework` and is distributed via direct signed DMG |
| Heavy Three.js 3D WebGL scenes | 2D/CSS3 canvas maintains instant load times and 60fps performance on all mobile/laptop devices |

## Traceability

Which phases cover which requirements. (Populated during roadmap creation).

| Requirement | Phase | Status |
|-------------|-------|--------|
| DSGN-01 | Phase 1 | Pending |
| DSGN-02 | Phase 1 | Pending |
| DSGN-03 | Phase 1 | Pending |
| HERO-01 | Phase 1 | Pending |
| HERO-02 | Phase 1 | Pending |
| HERO-03 | Phase 1 | Pending |
| HERO-04 | Phase 1 | Pending |
| SIM-01  | Phase 2 | Pending |
| SIM-02  | Phase 2 | Pending |
| SIM-03  | Phase 2 | Pending |
| SIM-04  | Phase 2 | Pending |
| SIM-05  | Phase 2 | Pending |
| MTRX-01 | Phase 3 | Pending |
| MTRX-02 | Phase 3 | Pending |
| MTRX-03 | Phase 3 | Pending |
| GUIDE-01 | Phase 3 | Pending |
| GUIDE-02 | Phase 3 | Pending |
| GUIDE-03 | Phase 3 | Pending |
| DPLY-01 | Phase 3 | Pending |
| DPLY-02 | Phase 3 | Pending |

**Coverage:**
- v1 requirements: 20 total
- Mapped to phases: 20
- Unmapped: 0 ✓

---

*Requirements defined: 2026-09-21*
*Last updated: 2026-09-21 after initial definition*
