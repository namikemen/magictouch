# Pitfalls Research

**Domain:** Modern macOS Utility Landing Page & Interactive Hardware Simulator  
**Researched:** 2026-09-21  
**Confidence:** HIGH  

## Critical Pitfalls & Gotchas

### 1. Canvas Blurriness on Apple Retina Displays

- **Issue:** HTML5 Canvas elements set with CSS width/height without scaling the internal drawing buffer appear pixelated and blurry on Retina MacBooks, 4K/5K displays, and mobile devices.
- **Warning Signs:** Glowing touch dots and boundary lines on the mouse surface look fuzzy compared to surrounding CSS text.
- **Prevention Strategy:** Explicitly query `window.devicePixelRatio` and scale the canvas buffer:
  ```javascript
  const dpr = window.devicePixelRatio || 1;
  canvas.width = rect.width * dpr;
  canvas.height = rect.height * dpr;
  ctx.scale(dpr, dpr);
  ```
- **Phase Mapping:** Addressed in Phase 2 (Interactive Simulator).

### 2. Browser Web Audio Autoplay Policy Violations

- **Issue:** Instantiating and running `AudioContext` automatically on page load triggers `The AudioContext was not allowed to start` errors in Safari, Chrome, and Firefox.
- **Warning Signs:** Console errors on page load; sound effects fail to play when interacting with the mouse simulator.
- **Prevention Strategy:** Construct the `AudioContext` lazily on the first user interaction (e.g., clicking on the simulator or toggling the sound button) and resume suspended contexts via `ctx.resume()`. Keep sound muted by default with an obvious sound toggle badge.
- **Phase Mapping:** Addressed in Phase 2 (Audio Feedback).

### 3. Glassmorphism Stutter & Mobile GPU Overload

- **Issue:** Stacking multiple layers of `backdrop-filter: blur(24px)` on deeply nested elements causes frame drops during page scrolling, particularly in mobile Safari and integrated Intel GPUs.
- **Warning Signs:** Scroll lag or high fan spin on laptops when scrolling through feature cards.
- **Prevention Strategy:** Use `backdrop-filter` only on primary foreground panels (navigation bar and modal cards). Use performant semi-transparent CSS color blends (`background: rgba(255, 255, 255, 0.04)`) with subtle 1px translucent borders (`border: 1px solid rgba(255, 255, 255, 0.08)`) to achieve the frosted look without expensive GPU passes.
- **Phase Mapping:** Addressed in Phase 1 (Core Glassmorphic Styling).

### 4. GitHub API 403 Rate Limiting

- **Issue:** If GitHub's unauthenticated API rate limit (60 requests/hr per IP) is reached, `fetch('https://api.github.com/repos/namikemen/magictouch/releases/latest')` returns 403 Forbidden.
- **Warning Signs:** Download button shows "Loading..." or breaks when viewed from shared networks.
- **Prevention Strategy:** Always implement immediate static defaults:
  - Default download URL: `https://github.com/namikemen/magictouch/releases/latest/download/MagicTouch.dmg`
  - Default version tag: `v0.1.0`
  - Fetch API asynchronously to enhance the UI with release notes or asset sizes, but never block the download button on API success.
- **Phase Mapping:** Addressed in Phase 1 (Hero & Download CTA).

### 5. Mobile Touch Conflicts on Virtual Mouse Surface

- **Issue:** Trying to drag or swipe on the interactive mouse canvas on mobile phones triggers browser viewport scrolling or pull-to-refresh instead of virtual mouse gestures.
- **Warning Signs:** Inability to perform swipe or pinch demos on mobile touchscreens.
- **Prevention Strategy:** Apply `touch-action: none` in CSS to the canvas container and use modern Pointer Events (`pointerdown`, `pointermove`, `pointerup`) with `preventDefault()` when dragging on the mouse surface.
- **Phase Mapping:** Addressed in Phase 2 (Simulator Interaction).

---

*Pitfalls research verified to prevent rendering, audio, and performance regressions.*
