# Roadmap: MagicTouch Website

## Overview

Build a modern, responsive, dark-mode glassmorphic showcase website and interactive hardware simulator for **MagicTouch**, deployed to GitHub Pages with zero build dependencies. The journey advances across three coarse phases: establishing the visual foundation and download pipeline, creating the interactive virtual Magic Mouse simulator with procedural audio haptics, and delivering the complete gesture matrix and macOS permissions onboarding guide.

## Phases

- [x] **Phase 1: Design System, Layout & Hero Showcase** - Zero-build `docs/` foundation, glassmorphic styling, responsive layout, and GitHub Releases download CTA.
- [ ] **Phase 2: Interactive Magic Mouse Canvas Simulator** - Virtual mouse surface, real-time capacitive touch visualization, gesture tour playback, and Web Audio haptic feedback.
- [ ] **Phase 3: Gesture Matrix, Installation Guide & GitHub Pages Readiness** - 30+ gesture matrix, action targets, macOS permission walkthrough, and GitHub Pages deployment verification.

## Phase Details

### Phase 1: Design System, Layout & Hero Showcase
**Goal**: Establish the zero-build static site structure in `docs/`, modern dark glassmorphic styling system, responsive navigation, high-impact hero presentation, and live GitHub Releases download integration.  
**Depends on**: Nothing (first phase)  
**Requirements**: DSGN-01, DSGN-02, DSGN-03, HERO-01, HERO-02, HERO-03, HERO-04  
**Success Criteria** (what must be TRUE):
  1. Visitors see a cohesive dark glassmorphic UI with frosted panels, subtle neon glows, and responsive navigation across mobile and desktop.
  2. The primary "Download for macOS" button links to the universal `MagicTouch.dmg` release and dynamically displays the current version tag (with static fallback).
  3. One-click copyable terminal command block lets developers quickly clone or install.
**Plans**: 2 plans

Plans:
- [x] 01-01: Setup `docs/` structure, Tailwind utility classes, glassmorphic CSS, responsive header, and hero section.
- [x] 01-02: Implement GitHub Releases API integration (`main.js`) with version tag badges and copy-to-clipboard terminal snippet.

---

### Phase 2: Interactive Magic Mouse Canvas Simulator
**Goal**: Deliver a photorealistic, high-performance HTML5 Canvas simulation of the Apple Magic Mouse with live capacitive multi-touch tracking, animated gesture playback tours, and procedural Web Audio haptics.  
**Depends on**: Phase 1  
**Requirements**: SIM-01, SIM-02, SIM-03, SIM-04, SIM-05  
**Success Criteria** (what must be TRUE):
  1. Virtual Magic Mouse renders with crisp Retina display scaling (`window.devicePixelRatio`) without blurriness.
  2. Visitors can touch or drag on the mouse surface to produce glowing capacitive contact circles at 60fps without lag.
  3. Clicking preset tour buttons (3-Finger Click, Tip-Tap Right, 2-Finger Pinch, Spaces Swipe) plays automated finger trajectories and displays live recognition badges.
  4. Web Audio API synthesizes subtle mechanical clicks and pops with an interactive mute/unmute toggle.
**Plans**: 2 plans

Plans:
- [ ] 02-01: Build the Canvas-based virtual mouse surface (`simulator.js`), Retina scaling, touch coordinate tracking, and gesture state machine.
- [ ] 02-02: Build the procedural Web Audio feedback engine (`audio.js`), tour preset player, and real-time recognition badges.

---

### Phase 3: Gesture Matrix, Installation Guide & GitHub Pages Readiness
**Goal**: Implement the complete 30+ gesture matrix categorized by finger counts, action target breakdown, visual macOS permissions walkthrough, and verify zero-dependency deployment for GitHub Pages.  
**Depends on**: Phase 2  
**Requirements**: MTRX-01, MTRX-02, MTRX-03, GUIDE-01, GUIDE-02, GUIDE-03, DPLY-01, DPLY-02  
**Success Criteria** (what must be TRUE):
  1. Visitors can filter and browse all 30+ gestures across 1, 2, 3, and 4 fingers with default action bindings.
  2. Visual macOS permissions guide explains granting Accessibility and Input Monitoring in System Settings with clear steps.
  3. Entire site in `docs/` runs cleanly without build errors, external 404s, or console warnings on GitHub Pages.
**Plans**: 2 plans

Plans:
- [ ] 03-01: Build the filterable 30+ gesture matrix, action targets grid, and native popover mockup.
- [ ] 03-02: Build the macOS permissions walkthrough guide, SEO/OpenGraph metadata, and verify GitHub Pages local serving.

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Design System, Layout & Hero Showcase | 2/2 | Complete | 2026-09-21 |
| 2. Interactive Magic Mouse Canvas Simulator | 0/2 | Not started | - |
| 3. Gesture Matrix, Installation Guide & GitHub Pages Readiness | 0/2 | Not started | - |

---

*Roadmap generated: 2026-09-21*
