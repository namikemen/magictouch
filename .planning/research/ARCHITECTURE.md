# Architecture Research

**Domain:** Modern macOS Utility Landing Page & Interactive Hardware Simulator  
**Researched:** 2026-09-21  
**Confidence:** HIGH  

## Architecture Overview

**Pattern:** Static Client-Side Modular Web Architecture deployed via GitHub Pages (`docs/` directory).

**Key Principles:**
- **Zero Build Friction:** No `node_modules`, bundling step, or CI compile needed; edits are immediately testable in any browser and deployable on git push.
- **High-Performance Canvas Rendering:** The interactive Magic Mouse simulator uses a dedicated HTML5 `<canvas>` coupled to `requestAnimationFrame` to ensure zero-lag 60fps animations.
- **Modular Component Segregation:** JavaScript logic is organized into clean, focused ES modules for readability and testability.

## Component Architecture

```
docs/
├── index.html                  # Core markup, SEO metadata, OpenGraph tags, semantic layout
├── css/
│   └── style.css               # Glassmorphic classes, keyframe animations, responsive grid rules
├── js/
│   ├── main.js                 # App initialization, mobile nav, release fetcher, UI event listeners
│   ├── simulator.js            # Interactive Magic Mouse canvas engine & gesture animation sequencer
│   ├── audio.js                # Web Audio API procedural sound synthesizer (clicks, pops)
│   └── data/
│       └── gestures.js         # Structured data for 30+ gestures, categories, and actions
└── assets/                     # Favicons, Apple Magic Mouse SVG silhouettes, screenshot assets
```

## Module Responsibilities

**1. `index.html` (Structure & Layout):**
- Navigation Header: Brand logo, status dot ("v0.1.0 Ready"), navigation links, and GitHub Star link.
- Hero Section: High-impact typography, quick value prop, primary "Download .DMG" button, secondary "Try Simulator" anchor.
- Interactive Simulator Section: Virtual Magic Mouse canvas, gesture tour buttons, live recognition badge, audio toggle.
- Gesture Matrix Section: Interactive filterable tabs (1, 2, 3, 4 fingers) displaying all 30+ gestures with descriptions and mapped actions.
- Features & Architecture Grid: 4-column glass cards detailing sub-millisecond latency, private framework integration, native Swift performance, and 100% local privacy.
- Setup & Permissions Walkthrough: Step-by-step visual cards for macOS Accessibility and Input Monitoring.
- Footer: Copyright, MIT license, GitHub links, and author attribution.

**2. `simulator.js` (Virtual Mouse Engine):**
- Renders the smooth capacitive surface of the Apple Magic Mouse with subtle specular reflection and boundary lines.
- Captures mouse hover/drag or finger touch coordinates and renders live glowing contact points matching `TouchPoint`.
- State Machine Player: Implements keyframe tweening for automated gesture demonstrations (swipes, taps, pinches, tip-taps).
- Event Emitter: Dispatches `gestureDetected` events to update on-page badges and trigger `audio.js`.

**3. `audio.js` (Web Audio Synthesizer):**
- Uses `AudioContext` with exponential gain ramps and short oscillator bursts (800Hz - 200Hz) to simulate realistic tactile clicks and haptic taps.
- Fully respects user muting and initializes on first user gesture to satisfy browser autoplay policies.

**4. `main.js` (Release Integration & UI):**
- Asynchronously queries `https://api.github.com/repos/namikemen/magictouch/releases/latest` (with fallback to `latest.json` or cached `v0.1.0`).
- Updates download CTA buttons with exact release version tag and download file size.
- Handles smooth section scrolling and mobile menu toggling.

## Data Flow

```
[User Interaction (Click / Drag on Simulator or Gesture Tour button)]
                        │
                        ▼
            [simulator.js Engine]
            ├── updates Canvas Touch Points (60fps requestAnimationFrame)
            ├── triggers Gesture State Machine
            │
            ├─► emits gesture event ──► updates DOM UI Badges ("Recognized: 3-Finger Tap")
            └─► calls audio.playClick() ──► Web Audio API plays subtle mechanical pop
```

## Suggested Build Order

1. **Phase 1: Foundation & Static Showcase:**
   - Setup `docs/` structure, glassmorphic CSS styling, responsive Hero, feature cards, and download buttons linked to GitHub Releases.
2. **Phase 2: Interactive Magic Mouse Simulator:**
   - Build the interactive Canvas mouse surface, capacitive touch visualizer, procedural Web Audio effects, and gesture tour player.
3. **Phase 3: Gesture Matrix & Setup Walkthrough:**
   - Render the complete filterable 30+ gesture matrix, action dispatcher cards, macOS permissions onboarding guide, and polish for GitHub Pages.

---

*Architecture research verified for modularity, speed, and GitHub Pages deployment.*
