# Phase 2: Interactive Magic Mouse Canvas Simulator - Context

**Gathered:** 2026-09-21
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver a photorealistic, high-performance HTML5 Canvas simulation of the Apple Magic Mouse with live capacitive multi-touch tracking, animated gesture playback tours, and procedural Web Audio haptics. Scope includes `docs/js/simulator.js` and `docs/js/audio.js` integrated into `#simulator` section of `docs/index.html`. Full gesture matrix and permissions guide belong in Phase 3.

</domain>

<decisions>
## Implementation Decisions

### Surface Visual Style & Canvas Rendering
- Top-down photorealistic white acrylic glass body with subtle specular gradient reflection and matte aluminum rim.
- Apple-inspired design matching real Magic Mouse 2/3 profile with smooth rounded rectangular aspect ratio (~1:2 ratio).
- Subtle coordinate grid markings and live capacitive contact rings indicating normalized `(x, y)` and pressure/size glow matching `TouchPoint` model.
- Crisp Retina rendering using `window.devicePixelRatio` scaling to eliminate blurry canvas lines on high-DPI Mac/mobile screens.

### Interaction Modes & Tour Presets
- Interactive preset bar featuring core MagicTouch gestures:
  1. Middle Click (3-finger tap / click)
  2. Tip-Tap Right (index down, middle tap)
  3. 2-Finger Pinch In/Out (smart zoom)
  4. 2-Finger Swipe Left/Right (Spaces navigation)
  5. 4-Finger Tap (Mission Control / App Exposé)
- "Auto-tour" button to cycle through all gesture demonstrations automatically.
- Direct interactive sandbox: Mouse click/drag creates a virtual finger contact point with trailing glow; touch events support multi-touch on mobile/trackpad screens.

### Live Recognition & Feedback HUD
- Floating frosted glass HUD overlay above or beside the canvas.
- Displays:
  - Real-time "Recognized Gesture" badge with icon.
  - "Simulated Action" badge (e.g., `Middle Click (Button 3)`, `Smart Zoom 2x`, `Switch Space`).
  - Active contact count and normalized `(x, y)` coordinates.
  - Interactive "Simulate" pulse effect on detection.

### Web Audio Procedural Haptics
- Procedural Apple Taptic-style sound synthesis via Web Audio API (sine oscillator frequency sweep + bandpass noise transient) for crisp, subtle mechanical clicks without external audio files.
- Audio defaults to **Muted** with a visible frosted glass Sound toggle button to comply with browser autoplay policies.
- Audio context initialized lazily on first user interaction.

### Claude's Discretion
- Exact easing functions and bezier paths for automated finger playback animations.
- Canvas dimensions and responsive layout adjustments across mobile/desktop viewports.
- Micro-interaction particle/ripple effects upon gesture trigger.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Codebase Multitouch Model
- `Sources/MagicTouch/TouchPoint.swift` — Native touch point structure (`id`, `normalizedX`, `normalizedY`, `size`, `phase`)
- `Sources/MagicTouch/GestureRecognizer.swift` — Gesture definitions, timing thresholds, and recognition logic
- `Sources/MagicTouch/ConfigurationStore.swift` — Default gesture bindings and action categories

### Project Specs
- `.planning/REQUIREMENTS.md` §SIM — SIM-01 through SIM-05 requirements
- `.planning/ROADMAP.md` §Phase 2 — Success criteria and plan breakdown

</canonical_refs>

<specifics>
## Specific Ideas

- "Top-down photorealistic white acrylic glass body with subtle specular reflection, aluminum rim, and live coordinate/force glow rings"
- "Interactive preset bar + Auto-tour button to cycle through gestures"
- "Subtle Apple Taptic-style sound (procedural oscillator click), defaulting to Muted with ambient sound toggle"

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `docs/css/style.css`: `.glass-panel`, `.glass-pill`, glow radial backgrounds, and typography tokens established in Phase 1.
- `docs/index.html`: `#simulator` placeholder container ready for simulator canvas, preset buttons, and HUD badges.

### Established Patterns
- Pure static zero-build deployment inside `docs/` for GitHub Pages.
- Dark obsidian theme (`#070709`) with Apple Blue (`#0071e3`) and Cyan (`#38bdf8`) accents.

### Integration Points
- `docs/index.html` section `<section id="simulator">`: host canvas container, control pills, and HUD.
- `docs/js/simulator.js`: Canvas drawing engine, coordinate tracking, gesture tour runner.
- `docs/js/audio.js`: Procedural Web Audio haptic click generator.
- `docs/js/main.js`: Wire initialization and audio mute toggle.

</code_context>

<deferred>
## Deferred Ideas

- Full 30+ gesture matrix and filtering table — Phase 3
- macOS permissions setup guide (Accessibility & Input Monitoring) — Phase 3
- User-customizable gesture configuration generator (`gestures.json` export) — v2 backlog

</deferred>

---

*Phase: 02-interactive-magic-mouse-canvas-simulator*
*Context gathered: 2026-09-21*
