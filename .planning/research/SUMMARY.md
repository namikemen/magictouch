# Project Research Summary

**Project:** MagicTouch Website  
**Domain:** Modern macOS Utility Landing Page & Interactive Hardware Simulator (GitHub Pages)  
**Researched:** 2026-09-21  
**Confidence:** HIGH  

## Executive Summary

MagicTouch is a native macOS utility that unlocks ultra-low-latency custom multitouch gestures for the Apple Magic Mouse. To support and showcase the project, we are creating a dedicated, high-impact product landing page hosted directly on GitHub Pages (`docs/`). The website bridges the gap between the GitHub repository and end users by delivering an Apple-inspired dark glassmorphic design, a one-click Universal DMG download workflow, and a standout interactive Magic Mouse simulator.

The recommended stack is a pure static implementation using HTML5, modern Tailwind CSS utilities, and modular vanilla JavaScript. This architecture eliminates Node.js build pipelines and server maintenance while guaranteeing instant page loads, 60fps canvas animations, and zero-friction hosting on GitHub Pages. The primary differentiator is an interactive on-page Magic Mouse playground that lets visitors test and visually understand gesture mechanics (middle clicks, tip-taps, pinches, space switches) with synthetic haptic audio feedback.

Key risks—including Retina display canvas blurriness, Web Audio autoplay restrictions, and GitHub API rate limits—are completely mitigated by explicit device pixel ratio scaling, user-initiated audio context resumption, and static fallback download links.

## Key Findings

### Recommended Stack

A zero-build static architecture hosted in `docs/` for GitHub Pages.
- **HTML5 & Tailwind CSS**: Semantic markup with frosted glass cards, subtle neon/cyan accent glows, and responsive typography matching Apple's San Francisco system font.
- **Vanilla JavaScript (ES2022+) & HTML5 Canvas API**: Drives the 60fps virtual Magic Mouse surface, capacitive contact dots, and automated gesture tour playback.
- **Web Audio API**: Synthesizes tactile click and pop sounds without external audio asset downloads.

### Expected Features

**Must Have (Table Stakes):**
- High-impact Hero with macOS badges, feature summaries, and direct Universal DMG download CTA.
- Dynamic GitHub release tag and asset size integration (fetching `latest.json` with fallback).
- Complete 30+ Gesture Matrix categorized by finger counts (1, 2, 3, 4 fingers).
- Feature & Architecture cards (sub-millisecond latency, private framework, native Swift, zero telemetry).
- Step-by-step macOS Accessibility and Input Monitoring permission setup guide.

**Should Have (Differentiators):**
- Interactive Magic Mouse Canvas Simulator with live capacitive touch points matching `TouchPoint`.
- Automated Gesture Tour allowing visitors to click any gesture to watch animated fingertip paths.
- Procedural Web Audio haptic feedback toggle.
- macOS menu bar popover preview replicating the native SwiftUI interface.

### Architecture Approach

Static modular structure located in `docs/`:
1. `docs/index.html`: Main semantic layout and hero presentation.
2. `docs/css/style.css`: Custom glassmorphism, responsive styles, and glow utilities.
3. `docs/js/simulator.js`: Canvas multi-touch engine and gesture player.
4. `docs/js/audio.js`: Web Audio oscillator for tactile haptics.
5. `docs/js/main.js`: Release API fetcher, navigation, and gesture matrix interactivity.

### Critical Pitfalls

1. **Retina Canvas Blur**: Scale canvas dimensions by `window.devicePixelRatio`.
2. **Audio Autoplay Block**: Instantiate `AudioContext` only after user interaction; mute by default.
3. **Glassmorphic GPU Lag**: Use subtle semi-transparent background gradients with 1px translucent borders rather than deep nested `backdrop-filter` passes.
4. **GitHub API 403 Rate Limit**: Always provide static fallbacks (`v0.1.0`, direct DMG URL) so the download CTA never fails.

## Roadmap Implications

The research suggests dividing this initiative into 3 coarse, well-scoped phases:
- **Phase 1: Foundation, Glassmorphic Design & Hero Showcase** (Repository setup, `docs/` structure, styling system, Hero section, dynamic GitHub release CTA, and feature highlights).
- **Phase 2: Interactive Magic Mouse Canvas Simulator** (Virtual mouse 2D canvas, touch coordinate visualizer, automated gesture demo player, and procedural audio haptics).
- **Phase 3: Gesture Matrix, Permissions Guide & Deployment** (Complete 30+ gesture matrix, action targets, setup instructions, GitHub Pages readiness validation).

---

*Research summary verified to inform requirements and roadmap creation.*
