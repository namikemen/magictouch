# Feature Research

**Domain:** Modern macOS Utility Landing Page & Interactive Hardware Simulator  
**Researched:** 2026-09-21  
**Confidence:** HIGH  

## Feature Landscape

### Table Stakes (Users Expect These)

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Hero Section with One-Click Download | Users visit landing pages primarily to understand the tool and get the installer | LOW | Prominent Universal DMG button + direct GitHub release link, version tag, macOS 13+ badge |
| Dynamic GitHub Release Info | Visitors want to know the current version and verify that the project is actively maintained | LOW | Fetch `latest.json` or GitHub API with graceful static fallback (`v0.1.0`) |
| Interactive Feature Breakdown | Technical power users need to know why this app is superior to built-in macOS gestures | MEDIUM | Highlights private framework interception, sub-ms latency, 100% local privacy, Universal binary |
| Complete Gesture Matrix | Users must see exactly what gestures are possible before installing | MEDIUM | Tabbed or categorized grid for 1, 2, 3, and 4-finger gestures with descriptions |
| Action Dispatcher Showcase | Explains what can be triggered (Middle Click, Triple Click, Hotkeys, AppleScript, Shell) | LOW | Visual cards showing mouse simulation and custom scripting flexibility |
| Step-by-Step Permission Guide | macOS apps using Accessibility and Input Monitoring often face user setup confusion | MEDIUM | Visual instructions with macOS System Settings guidance to ensure seamless onboarding |
| Responsive Mobile & Desktop Layout | Users frequently browse links from mobile or iPads before downloading on their Mac | MEDIUM | Touch-friendly controls, responsive glassmorphic cards, collapsible navigation |

### Differentiators (Competitive Advantage)

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Interactive Magic Mouse Simulator | Lets prospective users physically try or watch gestures in action directly on the webpage | HIGH | 2D/3D mouse surface rendering live capacitive touch circles, trails, and state transitions |
| Gesture Tour / Auto-Play Demo | Users can click any gesture (e.g. "Tip-Tap Right", "3-Finger Middle Click", "2-Finger Pinch In") to watch automated fingertip animations | MEDIUM | Demonstrates complex gestures visually so users instantly understand how to perform them |
| Web Audio Synthesized Haptics | Gives satisfying acoustic click/pop feedback when gestures trigger on the simulator | LOW | Zero-asset Web Audio API oscillator; includes a quick mute/unmute toggle |
| Live macOS Menu Bar Popover Preview | Recreates the exact native SwiftUI `MainPopoverView` UI inside a browser window mockup | MEDIUM | Shows users exactly what the app looks like in daily use on macOS |
| Copy-Paste CLI Install (Homebrew / Curl) | Power users and developers prefer one-line terminal installation options | LOW | Terminal snippet block with one-click copy button |

### Anti-Features (Avoid)

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Heavy 3D WebGL (Three.js 5MB+) | Looks flashy in demos | Slow initial load, high GPU battery drain on laptops, broken on older mobile browsers | Lightweight CSS3 3D perspective transforms and Canvas 2D renderers |
| Mandatory Newsletter / Email Gate | Marketing capture | Creates friction and turns away open-source enthusiasts | Direct download links with optional star button on GitHub |
| Multi-page SPA with Client-Side Routing | Feels "modern" | Breaks GitHub Pages direct URLs, introduces routing complexity and hydration bugs | High-speed single-page layout with smooth anchor scrolling |

## Feature Dependencies

```
[GitHub Pages Static Structure]
    └──requires──> [Hero & DMG Download Integration]
    └──requires──> [Gesture Matrix Showcase]
    └──requires──> [Interactive Magic Mouse Canvas Visualizer]
                       └──requires──> [Touch Coordinate State Machine]
                       └──enhances──> [Audio Feedback Engine]
                       └──enhances──> [Gesture Tour Preset Player]
```

---

*Feature research verified for high-conversion utility product showcase.*
