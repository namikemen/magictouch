# Stack Research

**Domain:** Modern macOS Utility Landing Page & Interactive Hardware Simulator (GitHub Pages)  
**Researched:** 2026-09-21  
**Confidence:** HIGH  

## Recommended Stack

### Core Technologies

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| HTML5 (Semantic) | Latest | Document structure, accessibility, SEO | Universal, accessible, zero runtime overhead, instant parse |
| Tailwind CSS | 3.4.x (via CDN / Play or static bundle) | Utility-first styling, glassmorphism, responsive grid | Rapid UI development, native dark mode utilities, backdrop-blur support |
| Modern Vanilla JavaScript (ES2022+) | Native | Simulator state machine, gesture demo animation, audio synthesis, GitHub API fetching | Zero build pipeline, zero bundle bloat, maximum execution speed |
| HTML5 2D Canvas API | Native | High-frequency (60fps) multi-touch coordinate visualizer and gesture trail particle rendering | Renders smooth capacitive touch points and trails with sub-millisecond overhead without DOM thrashing |
| Web Audio API (`AudioContext`) | Native | Synthesized haptic audio feedback (clicks, pops, subtle mechanical ticks) | No external audio files to load, zero latency audio feedback on user gestures |

### Supporting Libraries & Assets

| Library / Asset | Version | Purpose | When to Use |
|-----------------|---------|---------|-------------|
| Lucide Icons | Latest (via SVG / CDN) | Sleek modern icons for macOS buttons, keyboard symbols (⌘, ⌥, ⌃, ⇧), and download links | Clean iconography matching Apple SF Symbols aesthetic |
| Inter / -apple-system Font Stack | Native | Typography matching native macOS San Francisco aesthetic | Instant font rendering without remote Google Fonts layout shifts |

### Hosting & Deployment

| Tool | Purpose | Notes |
|------|---------|-------|
| GitHub Pages | Public CDN hosting at `https://namikemen.github.io/magictouch/` | Deploys directly from `/docs` directory or root branch on git push with zero CI runners needed |
| GitHub Releases Direct Linking | Instant DMG installer downloads | Points to `https://github.com/namikemen/magictouch/releases/latest/download/MagicTouch.dmg` |

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| Pure Static (HTML + Tailwind + Vanilla JS) | React / Next.js / Astro | When building complex multi-page web applications with authentication and CMS backends; overkill for a high-impact single-page product showcase |
| Web Audio API Synthesis | External MP3 / WAV audio files | When recorded realistic studio sound effects are mandatory; synthetic oscillator pops are zero-latency, <1KB of JS code, and never fail due to CORS |
| HTML5 Canvas for Touch Visualizer | SVG / DOM elements for touches | When touches are static; for 60fps dynamic multi-touch finger tracking and fading gesture trails, Canvas is significantly more performant |

## What NOT to Use

- Heavy frameworks (Angular, complex Next.js SSR): Adds unnecessary compilation layers and breaks simple GitHub Pages static hosting.
- Bulky CSS frameworks with fixed non-macOS styling (Bootstrap, Material UI): Clashes with the sleek dark glassmorphic Apple macOS aesthetic.
- Remote audio assets or unoptimized large video files: Increases initial page weight and delays first meaningful paint.

---

*Stack research verified for zero-dependency GitHub Pages deployment.*
