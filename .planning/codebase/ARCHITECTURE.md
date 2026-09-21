# Architecture

**Analysis Date:** 2026-09-21

## Pattern Overview

**Overall:** Event-Driven Reactive macOS Menu Bar Utility (Bridge → State Machine Engine → Action Dispatcher & Reactive UI).

**Key Characteristics:**
- **Zero-Latency Touch Interception:** Intercepts hardware capacitive touches at C level from `MultitouchSupport.framework` without poll overhead.
- **State Machine Recognition:** Robust custom gesture recognizer (`Sources/MagicTouch/Engine/GestureRecognizer.swift`) evaluating spatial spreads, velocities, contact durations, and lift timings.
- **Accessory App Lifecycle:** Headless menu bar accessory (`NSStatusItem`) with an interactive SwiftUI `NSPopover` containing live sensor visualizers and hotkey recorders.
- **Thread Segregation:** High-frequency touch callbacks process on background driver threads; recognized gestures and UI state updates dispatch synchronously or asynchronously to the Main Dispatch Queue.

## Layers

**1. Hardware & Multitouch Bridge Layer:**
- Purpose: Interfaces with Apple's private C APIs to discover connected multi-touch devices and stream contact frames.
- Contains: `Sources/MultitouchBridge/MultitouchBridge.m`, `Sources/MultitouchBridge/include/MultitouchBridge.h`.
- Depends on: macOS `/System/Library/PrivateFrameworks/MultitouchSupport.framework`.
- Used by: `Sources/MagicTouch/Engine/MultitouchManager.swift`.

**2. Engine & Gesture Recognition Layer:**
- Purpose: Normalizes raw touch frames, tracks active touch paths, filters jitter and unintentional palm contact, and detects gesture types.
- Contains:
  - `Sources/MagicTouch/Engine/MultitouchManager.swift`: Manages device lifecycle and delegates callbacks.
  - `Sources/MagicTouch/Engine/GestureRecognizer.swift`: State machine distinguishing taps, double/triple taps, directional swipes, pairwise pinches, and tip-taps.
  - `Sources/MagicTouch/Engine/ActionDispatcher.swift`: Synthesizes mouse buttons (Button 1, 2, 3, double-click, triple-click), hotkeys, AppleScript, and shell scripts.
  - `Sources/MagicTouch/Engine/PermissionManager.swift`: Manages Accessibility and Input Monitoring permissions.
  - `Sources/MagicTouch/Engine/UpdateChecker.swift`: Downloads and parses GitHub release manifests and DMGs.
- Depends on: `MultitouchBridge`, `CoreGraphics`, `AppKit`, `Foundation`.
- Used by: `AppDelegate`, SwiftUI Views.

**3. State & Configuration Store Layer:**
- Purpose: Maintains transient UI state (live touch points, detected gestures, mouse connection status) and persistent user mappings.
- Contains:
  - `Sources/MagicTouch/Store/AppState.swift`: In-memory reactive state (`@Published` touches, connection status, last gesture).
  - `Sources/MagicTouch/Store/ConfigurationStore.swift`: Manages persistence of `GestureMapping` records to `~/Library/Application Support/MagicTouch/gestures.json`.
- Depends on: `Sources/MagicTouch/Models/GestureModel.swift`.
- Used by: `AppDelegate`, `ActionDispatcher`, and all SwiftUI views.

**4. UI & Presentation Layer:**
- Purpose: Displays menu bar icon, status popover, live capacitive touch grid, gesture mapping editor, and update notification banners.
- Contains:
  - `Sources/MagicTouch/Views/MainPopoverView.swift`: Root view in `NSPopover`.
  - `Sources/MagicTouch/Views/TouchVisualizerView.swift`: Canvas/Shape rendering live Magic Mouse capacitive touches in real-time.
  - `Sources/MagicTouch/Views/GestureEditorSheet.swift`: Modal sheet to assign actions to gestures.
  - `Sources/MagicTouch/Views/HotkeyRecorderView.swift`: Physical keystroke recorder for custom shortcuts.
  - `Sources/MagicTouch/Views/PermissionBannerView.swift`: Warning banner if permissions are missing.
  - `Sources/MagicTouch/Views/UpdateBannerView.swift`: In-app notification and download progress bar for software updates.
- Depends on: `SwiftUI`, `AppState`, `ConfigurationStore`, `UpdateChecker`, `PermissionManager`.
- Used by: `AppDelegate.togglePopover()`.

## Data Flow

**1. Touch Event Processing & Action Dispatch Flow:**
```
[Physical Touch on Magic Mouse]
       │
       ▼
[MultitouchSupport Private Framework]
       │
       ▼
[MultitouchBridge (C callback in MultitouchBridge.m)]
       │
       ▼
[MultitouchManager (Swift)]
       │
       ▼
[GestureRecognizer.processFrame()]
       │
       ├─► updates AppState.touches (Main Queue) ──► TouchVisualizerView updates
       │
       ▼ (upon gesture detection criteria met)
[GestureRecognizerDelegate.gestureRecognizerDidDetect(gesture)]
       │
       ├─► updates AppState.lastGesture (Main Queue)
       │
       ▼
[ConfigurationStore.actionForGesture(gesture)]
       │ (if matching mapping exists)
       ▼
[ActionDispatcher.execute(action)]
       │
       ├─► CGEvent / CoreGraphics (Mouse Button / Keystroke)
       ├─► NSAppleScript (AppleScript execution)
       ├─► Process (Background Shell script)
       └─► NSWorkspace / AppKit (System Action)
```

**2. State Management:**
- Transient State: Handled via `AppState.shared` (`ObservableObject`). Touch updates update at 60–120Hz without hitting disk.
- Persistent State: Handled via `ConfigurationStore.shared` (`ObservableObject`), serialized to JSON on changes.

## Key Abstractions

- `GestureType`: Enum identifying all 30+ supported gesture variants categorized by finger count (1 to 4 fingers) and type (tap, swipe, pinch, tip-tap, physical click).
- `ActionTarget`: Enum modeling all possible action outputs (`mouseButton`, `keyboardShortcut`, `appleScript`, `shellCommand`, `systemAction`).
- `GestureMapping`: Identifiable struct combining a `GestureType` with an `ActionTarget` and enabled flag.
- `TouchPoint`: Lightweight struct representing a single normalized touch point on the mouse surface (x, y coordinates [0.0...1.0], contact size, timestamp).
- `GestureRecognizerDelegate`: Protocol allowing decouple of gesture parsing from UI notification and action dispatch.

## Entry Points

- `Sources/MagicTouch/main.swift`: Application entry point (`@main struct MagicTouchApp: App`).
  - Initializes `AppDelegate` via `@NSApplicationDelegateAdaptor`.
  - Sets activation policy to accessory mode.
  - Instantiates `MultitouchManager`, starts touch listener, checks permissions, registers status bar item, and checks for updates.

## Error Handling

- **Missing Permissions:** `PermissionManager` monitors Accessibility and Input Monitoring. Missing permissions display interactive banners directing users to System Settings rather than crashing.
- **Hardware Disconnection:** `MultitouchManager` detects device detachment/attachment and updates `AppState.isConnected` without throwing.
- **Corrupted Config:** `ConfigurationStore.load()` falls back to factory default gesture mappings if `gestures.json` is missing or unparseable.
- **Script Failures:** `ActionDispatcher` captures AppleScript and Shell errors safely and logs them without crashing the host process.

---

*Architecture analysis: 2026-09-21*
*Update after major architectural changes*
