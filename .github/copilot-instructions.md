# MagicTouch Copilot Instructions

MagicTouch is a native macOS menu bar utility for the Apple Magic Mouse. It intercepts low-level capacitive touch frames directly from Apple's private `MultitouchSupport.framework`, processes them through a custom gesture recognition state machine, and synthesizes actions (mouse buttons, keystrokes, AppleScript, shell commands) with sub-millisecond latency.

---

## 1. Build, Test, and Packaging Commands

### Native Compilation
- **Quick Build**: `./build.sh` (compiles `MultitouchBridge.m` with `clang` and Swift sources with `swiftc` into `.build/bin/MagicTouch`)
- **SwiftPM Build**: `swift build` (compiles debug binary at `.build/debug/MagicTouch`)
- **Run Locally**: `./.build/bin/MagicTouch` (starts the menu bar accessory process)

### Testing
- **Run All Tests (Standalone)**: `./run_tests.sh`
  - Uses `Tests/MagicTouchTests/StandaloneTests.swift` compiled directly via `swiftc`.
  - Runs 36 test suites in ~1-2 seconds without requiring full Xcode.app or `XCTest` (ideal for Command Line Tools environments and headless CI).
- **Run a Single Test**:
  - *Standalone runner*: Isolate the desired test by commenting/uncommenting the target runner call in `RunnerApp.main()` within `Tests/MagicTouchTests/StandaloneTests.swift`, then run `./run_tests.sh`.
  - *SwiftPM / XCTest runner*: `swift test --filter GestureRecognizerTests/<testMethodName>` (e.g. `swift test --filter GestureRecognizerTests/testThreeFingerTapDetection`). Requires full Xcode.app selected via `xcode-select -s /Applications/Xcode.app` since Apple's Command Line Tools SDK does not include `XCTest.framework`.

### Packaging & Release
- **Package Universal App & DMG**: `./package_app.sh <version>` (e.g. `./package_app.sh 1.0.0`)
  - Compiles dual architectures (`arm64` Apple Silicon + `x86_64` Intel), merges via `lipo`, applies ad-hoc codesigning, generates `Info.plist`, builds `MagicTouch.dmg`, archives `.tar.gz` and `.zip`, and generates `latest.json` with SHA256 checksums in `.build/dist/`.
- **Automated Release**: `./release.sh [patch|minor|major|<version>]`
  - Validates working tree, runs test suites, updates version in `Sources/MagicTouch/Engine/UpdateChecker.swift`, creates git tag, and pushes to origin to trigger GitHub Actions release CI.

---

## 2. High-Level Architecture

The application operates as an event-driven pipeline from private C kernel callbacks down to CoreGraphics event synthesis and SwiftUI presentation:

```
[Magic Mouse Physical Surface]
       │
       ▼
[MultitouchSupport.framework] (macOS Private Framework)
       │
       ▼
[MultitouchBridge (C/Obj-C)] (Sources/MultitouchBridge/)
       │  • MTRegisterContactFrameCallback, MTBridgeStartDevice
       ▼
[MultitouchManager (Swift)] (Sources/MagicTouch/Engine/MultitouchManager.swift)
       │  • Filters out hover/proximity states via MTBridgeIsPhysicalContact
       │  • Restricts binding strictly to external Magic Mouse (!MTBridgeDeviceIsBuiltIn)
       │  • Filters touch points against configurable touchAreaMinY threshold
       │  • Watchdog timer (2s) auto-recovers disconnects/sleep
       │  • CGEvent.tapCreate on .cghidEventTap intercepts physical left clicks
       ▼
[GestureRecognizer] (Sources/MagicTouch/Engine/GestureRecognizer.swift)
       │  • State machine running on dedicated recognizerQueue (qos: .userInteractive)
       │  • Distinguishes 1-4 finger taps, double/triple taps, directional swipes, pinches, tip-taps, hold-to-drag
       │  • Applies directional ratio scroll suppression and resting finger filters
       ▼
[AppDelegate & ConfigurationStore] (Sources/MagicTouch/main.swift, Store/ConfigurationStore.swift)
       │  • Resolves GestureType to ActionTarget from ~/Library/Application Support/MagicTouch/gestures.json
       │  • Falls back unmapped 1-finger double/triple taps to single tap action with clickState = 2 or 3
       ▼
[ActionDispatcher] (Sources/MagicTouch/Engine/ActionDispatcher.swift)
       │  • Synthesizes CGEvent clicks, keystrokes, NSAppleScript, or Process (/bin/zsh)
       │  • Tags events with magicEventSignature to prevent CGEventTap infinite loops
       ▼
[SwiftUI UI Layer] (Sources/MagicTouch/Views/)
          • MainPopoverView: Menu bar NSPopover interface
          • TouchVisualizerView: Real-time capacitive contact visualizer
          • HotkeyRecorderView & GestureEditorSheet: Configuration modals
```

---

## 3. Key Conventions & Implementation Rules

### Private Framework Encapsulation
- All direct calls to `/System/Library/PrivateFrameworks/MultitouchSupport.framework` must remain strictly inside `Sources/MultitouchBridge/`.
- Never attempt to import `MultitouchSupport` directly into Swift files; always access hardware devices through `MultitouchBridge.h` and `MultitouchManager.swift`.

### Dual-Test Synchronization
- `Tests/MagicTouchTests/StandaloneTests.swift` is the authoritative test suite for CI and developer CLI runs.
- When adding or modifying gesture recognition logic or store behavior, **always** add corresponding test cases to `StandaloneTests.swift` so `./run_tests.sh` verifies them without Xcode IDE dependencies.

### Threading & Concurrency Discipline
- **Driver Callbacks**: Raw frames arrive on low-level OS threads via `multitouchCallback`.
- **Recognition Queue**: Frames are immediately forwarded to `MultitouchManager.recognizerQueue` (`qos: .userInteractive`) to keep parsing off the main thread.
- **Main Queue Rule**: All UI updates, `@Published` property changes (`AppState`, `ConfigurationStore`, `UpdateChecker`), and `ActionDispatcher.execute` calls must be performed on `DispatchQueue.main`.
- **Script Isolation**: Shell scripts and AppleScripts in `ActionDispatcher` must execute asynchronously in isolated `Process()` tasks with `catch` blocks so script errors never crash the host menu bar app.

### Synthetic Event Loop Prevention
- `ActionDispatcher` marks all synthetic mouse events with `.eventSourceUserData = ActionDispatcher.magicEventSignature` (`0x4D41474943`, `"MAGIC"`) and sets `ActionDispatcher.isSynthesizingEvent = true`.
- `MultitouchManager`'s physical click interceptor (`CGEventTap`) checks both conditions and ignores matched events, preventing recursive click loops.

### Physical Magic Mouse Surface Dynamics & Filtering
- The Magic Mouse has a narrow, curved glass surface where users frequently rest palms, recoil during scrolling, or hover fingers above the glass.
- **Physical Contact vs Hover**: `MTBridgeIsPhysicalContact` only accepts physical touchdown states (`MakeTouch=3`, `Touching=4`, `BreakTouch=5`). Proximity/hover states (`StartInRange=1`, `HoverInRange=2`, `LingerInRange=6`) are rejected to avoid phantom touches.
- **Scroll vs Tap Differentiation**: Circular excursion thresholds alone fail to distinguish small vertical scrolls from taps. The recognizer compares vertical displacement against lateral spread (`abs(avgDy) > 0.032 && abs(avgDy) > abs(avgDx) * 1.25`) to accurately reject scroll flicks without compromising tap responsiveness.
- **Configurable Touchable Area**: `touchAreaMinY` filters out touches on the lower/palm area of the mouse (normalized Y runs from 0.0 at the palm rest to 1.0 at the front edge).
- **Trackpad Isolation**: `MTBridgeDeviceIsBuiltIn(dev)` is used to strictly reject built-in Mac trackpads; MagicTouch only operates on external Magic Mice.
- **Resting Finger Suppression**: Touch contacts persisting > 450ms are marked as resting; their subsequent lift will not trigger accidental taps.
- **Natural Finger Compression**: During horizontal multi-finger swipes, fingers naturally converge on the curved surface. The recognizer accounts for this so swipes are not misclassified as pinch-in gestures.
- Always run `./run_tests.sh` to verify these boundary conditions before adjusting timing or distance thresholds.

### Architectural Patterns & State Management
- **Singletons**: Core controllers and stores use `public static let shared = ClassName()`.
- **Value Semantics**: Models (`GestureType`, `ActionTarget`, `GestureMapping`, `TouchPoint`) are immutable structs or enums conforming to `Codable`, `Identifiable`, and `Equatable`.
- **Controllers**: Engine classes holding run loops or event taps are `final class`.
- **Graceful Persistence**: `ConfigurationStore` safely falls back to built-in default mappings if `gestures.json` is missing or corrupted.

### Versioning Single Source of Truth
- The canonical app version is defined in `Sources/MagicTouch/Engine/UpdateChecker.swift`:
  `@Published public var currentVersion: String = "..."`
- `release.sh` reads and updates this field automatically during release cycles.
