# Codebase Structure

**Analysis Date:** 2026-09-21

## Directory Layout

```
magictouch/
├── .github/
│   └── workflows/
│       └── release.yml                 # Automated release, packaging, and update manifest workflow
├── Sources/
│   ├── MagicTouch/
│   │   ├── Engine/                     # Core recognition algorithms and system service managers
│   │   │   ├── ActionDispatcher.swift   # Simulates mouse buttons, clicks, keystrokes, scripts
│   │   │   ├── GestureRecognizer.swift  # Gesture recognition state machine & touch trajectory tracking
│   │   │   ├── MultitouchManager.swift  # Device discovery, C callback bridge handler, hardware listener
│   │   │   ├── PermissionManager.swift  # macOS Accessibility and Input Monitoring permission checks
│   │   │   └── UpdateChecker.swift      # In-app update checker and DMG download coordinator
│   │   ├── Models/                     # Core data types and contracts
│   │   │   ├── GestureModel.swift       # Enums for GestureType, ActionTarget, MouseButtonType, KeyModifier
│   │   │   └── UpdateInfo.swift        # Data structures for update manifest JSON and GitHub release parsing
│   │   ├── Store/                      # Application state and persistent preferences
│   │   │   ├── AppState.swift          # Observable transient UI state (active touches, connection status)
│   │   │   └── ConfigurationStore.swift # JSON file persistence for user gesture mappings
│   │   ├── Views/                      # SwiftUI user interface components
│   │   │   ├── GestureEditorSheet.swift # Modal sheet for configuring and binding actions to gestures
│   │   │   ├── HotkeyRecorderView.swift # Interactive view recording physical keyboard shortcuts
│   │   │   ├── MainPopoverView.swift    # Top-level window hosting visualizer, mappings list, status
│   │   │   ├── PermissionBannerView.swift # Warning banner for missing system permissions
│   │   │   ├── TouchVisualizerView.swift # Live capacitive mouse touch surface visualization
│   │   │   └── UpdateBannerView.swift   # Banner alerting users when software updates are available
│   │   └── main.swift                  # App entry point, NSApplicationDelegate, status item setup
│   └── MultitouchBridge/               # Objective-C bridge to private MultitouchSupport.framework
│       ├── MultitouchBridge.m          # C wrapper implementations for MTDevice* functions
│       └── include/
│           ├── MultitouchBridge.h      # C header declaring MTTouch structs and callback prototypes
│           └── module.modulemap        # Clang modulemap exposing MultitouchBridge to Swift
├── Tests/
│   └── MagicTouchTests/
│       ├── GestureRecognizerTests.swift # XCTest test cases for tap, swipe, and pinch detection
│       └── StandaloneTests.swift       # Self-contained executable test runner (25 test suites)
├── Package.swift                       # Swift Package Manager manifest
├── README.md                           # Documentation, feature overview, gesture matrix, build instructions
├── build.sh                            # Development compilation script for native architecture
├── package_app.sh                      # Universal binary compilation, bundle layout, and DMG creator
└── run_tests.sh                        # Headless test runner compilation and execution script
```

## Directory Purposes

**`Sources/MagicTouch/Engine/`:**
- Purpose: Contains low-level driver event routing, hardware abstraction, gesture recognition state tracking, and synthetic input generation.
- Key files:
  - `GestureRecognizer.swift`: The mathematical core measuring finger spreads, durations, and movement deltas.
  - `ActionDispatcher.swift`: Quartz event synthesizer.

**`Sources/MagicTouch/Models/`:**
- Purpose: Immutable value types and enums used across engine, stores, and views.
- Key files:
  - `GestureModel.swift`: Complete inventory of supported gestures and assignable actions.

**`Sources/MagicTouch/Store/`:**
- Purpose: Application state management and persistence.
- Key files:
  - `ConfigurationStore.swift`: Reads and writes `gestures.json`.
  - `AppState.swift`: Drives SwiftUI view updates for real-time sensor feedback.

**`Sources/MagicTouch/Views/`:**
- Purpose: SwiftUI presentation layer.
- Key files:
  - `MainPopoverView.swift`: Main UI container.
  - `TouchVisualizerView.swift`: Custom graphics rendering of the Magic Mouse touch surface.

**`Sources/MultitouchBridge/`:**
- Purpose: Interfaces with `/System/Library/PrivateFrameworks/MultitouchSupport.framework`.
- Key files:
  - `MultitouchBridge.h`: C struct definitions for low-level multi-touch frames.
  - `MultitouchBridge.m`: Device enumeration and callback dispatch wrappers.

**`Tests/MagicTouchTests/`:**
- Purpose: Unit testing suite verifying gesture recognition logic, serialization, and version comparison.
- Key files:
  - `StandaloneTests.swift`: Comprehensive headless test runner.

## Key File Locations

**Entry Points:**
- `Sources/MagicTouch/main.swift`: Application lifecycle and NSStatusItem setup.
- `Tests/MagicTouchTests/StandaloneTests.swift`: CLI test runner entry point.

**Configuration:**
- `Package.swift`: SPM target dependencies and compiler flags.
- `package_app.sh`: Distribution build flags, Info.plist generation, DMG layout.
- `~/Library/Application Support/MagicTouch/gestures.json`: Runtime user configurations.

**Documentation:**
- `README.md`: Public GitHub repository documentation and user guide.

## Naming Conventions

**Files:**
- Swift Source: `PascalCase.swift` (e.g. `GestureRecognizer.swift`, `MainPopoverView.swift`).
- Objective-C / C: `PascalCase.m`, `PascalCase.h`.
- Shell Scripts: `snake_case.sh` (e.g. `package_app.sh`, `run_tests.sh`).

**Types & Protocols:**
- Classes, Structs, Enums, Protocols: `PascalCase` (e.g. `GestureRecognizer`, `ActionDispatcher`, `TouchPoint`).
- Enum cases: `camelCase` (e.g. `.threeFingerClick`, `.oneFingerTapLeft`, `.keyboardShortcut`).

**Variables & Functions:**
- Properties and Methods: `camelCase` (e.g. `processFrame`, `actionForGesture`).

## Where to Add New Code

**Adding a New Gesture:**
1. Declare enum case in `Sources/MagicTouch/Models/GestureModel.swift` under `GestureType`.
2. Implement recognition heuristic in `Sources/MagicTouch/Engine/GestureRecognizer.swift`.
3. Add simulated test cases in `Tests/MagicTouchTests/StandaloneTests.swift` and `Tests/MagicTouchTests/GestureRecognizerTests.swift`.

**Adding a New Action Type:**
1. Add case to `ActionTarget` in `Sources/MagicTouch/Models/GestureModel.swift`.
2. Implement execution branch in `Sources/MagicTouch/Engine/ActionDispatcher.swift`.
3. Add configuration UI controls in `Sources/MagicTouch/Views/GestureEditorSheet.swift`.

**Adding Website or Documentation:**
- Public landing page / documentation files belong in repository root (e.g., `docs/` or `website/` or root `index.html` for GitHub Pages).

---

*Structure analysis: 2026-09-21*
*Update after directory structure changes*
