# Technology Stack

**Analysis Date:** 2026-09-21

## Languages

**Primary:**
- Swift 5.9 (`swift-tools-version: 5.9`) - Used for all core application code, SwiftUI views, state stores, and gesture recognition engine (`Sources/MagicTouch/`).

**Secondary:**
- Objective-C - Low-level bridge layer interfacing with macOS's private Multitouch framework (`Sources/MultitouchBridge/MultitouchBridge.m`, `Sources/MultitouchBridge/include/MultitouchBridge.h`).
- Zsh Shell Scripting (`/bin/zsh`) - Build, packaging, DMG creation, and test runner automation (`build.sh`, `package_app.sh`, `run_tests.sh`).
- YAML - Continuous integration and release automation (`.github/workflows/release.yml`).

## Runtime

**Environment:**
- macOS 13.0+ (Ventura, Sonoma, Sequoia) target deployment platform.
- Native compiled Darwin Mach-O binary (Universal: `arm64` Apple Silicon and `x86_64` Intel architectures).
- Background menu bar accessory application (`NSApp.setActivationPolicy(.accessory)` with no Dock icon).

**Package Manager:**
- Swift Package Manager (SPM) with `Package.swift`.
- Direct compiler driver invocations via `swiftc` and `clang` in shell scripts for headless universal binary compilation and DMG packaging without requiring Xcode IDE.

## Frameworks

**Core:**
- SwiftUI (`import SwiftUI`) - Declarative user interface for status popover, live touch visualizer, hotkey recorder, and gesture editor sheets.
- AppKit (`import AppKit`) - Status bar item (`NSStatusItem`, `NSStatusBar`), floating popover window (`NSPopover`, `NSHostingController`), system event hooks, and application lifecycle (`NSApplicationDelegate`).
- CoreGraphics (`import CoreGraphics`) - Synthesized mouse event injection (`CGEvent`, `CGMouseButton`, `cghidEventTap`) and coordinate handling.
- MultitouchSupport (macOS Private Framework located at `/System/Library/PrivateFrameworks/MultitouchSupport.framework`) - Low-level multi-touch contact frames, finger IDs, absolute/normalized coordinates, and device registration.
- Combine (`import Combine`) - Observable state tracking and reactive UI binding (`ObservableObject`, `@Published`).

**Testing:**
- XCTest - Unit testing target (`Tests/MagicTouchTests/GestureRecognizerTests.swift`).
- Custom Standalone Swift Test Runner - Headless test executable compiled with `swiftc` (`Tests/MagicTouchTests/StandaloneTests.swift` via `run_tests.sh`) allowing rapid execution in headless environments.

**Build/Dev:**
- `swiftc` - Native Swift compiler with `-target arm64-apple-macos13.0` and `-target x86_64-apple-macos13.0`.
- `clang` - C/Objective-C compiler for `MultitouchBridge.m`.
- `lipo` - macOS Universal binary stitcher creating multi-architecture binaries.
- `hdiutil` - macOS disk image utility creating distribution `.dmg` files.

## Key Dependencies

**Critical:**
- `MultitouchSupport.framework` (System Private Framework) - Provides C-level hooks `MTRegisterContactFrameCallback`, `MTDeviceStart`, `MTDeviceCreateList` to intercept raw touch sensor data on Apple Magic Mouse.
- `CoreGraphics` (macOS System Framework) - Generates synthesized mouse clicks (left, right, middle, double-click, triple-click) and keystrokes.
- `AppKit` (macOS System Framework) - Menu bar management, window hosting, accessibility permission queries.

**Infrastructure:**
- `Foundation` - JSON serialization/deserialization for gesture configuration persistence and update checking.
- `Security` / `ApplicationServices` - Accessibility (`AXIsProcessTrustedWithOptions`) and Input Monitoring permission verification.

## Configuration

**Environment:**
- No environment variables required for standard application execution.
- GitHub Actions CI uses `GITHUB_TOKEN` for publishing releases.

**Build:**
- `Package.swift` - Swift Package Manager manifest specifying platform macOS v13+, library target `MultitouchBridge`, and executable target `MagicTouch` linked against `/System/Library/PrivateFrameworks/MultitouchSupport.framework`.
- `package_app.sh` - Universal binary build script, Info.plist generator, and `.dmg` / `.tar.gz` / `.zip` packager.
- `run_tests.sh` - Standalone test compiler and test runner.

## Platform Requirements

**Development:**
- macOS 13.0 or higher.
- Xcode Command Line Tools (`xcrun`, `swiftc`, `clang`, `lipo`, `hdiutil`).

**Production:**
- macOS 13.0+ (Ventura, Sonoma, Sequoia).
- Hardware: Physical Apple Magic Mouse (Magic Mouse 1, 2, or USB-C edition).
- macOS Permissions: Accessibility (`AXIsProcessTrusted`) and Input Monitoring.

---

*Stack analysis: 2026-09-21*
*Update after major dependency changes*
