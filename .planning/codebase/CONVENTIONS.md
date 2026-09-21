# Coding Conventions

**Analysis Date:** 2026-09-21

## Naming Patterns

**Files:**
- Source files use `PascalCase.swift` corresponding exactly to the primary type declared within (e.g., `GestureRecognizer.swift`, `ConfigurationStore.swift`).
- Test files suffix type names with `Tests.swift` (e.g., `GestureRecognizerTests.swift`, `StandaloneTests.swift`).
- Automation scripts use lowercase `snake_case.sh` (e.g., `package_app.sh`, `run_tests.sh`).

**Types & Protocols:**
- Structs, Classes, and Enums: `PascalCase` (e.g., `GestureRecognizer`, `ActionDispatcher`, `TouchPoint`).
- Protocols: Suffix with `Delegate` or capability descriptor (e.g., `GestureRecognizerDelegate`, `MultitouchManagerDelegate`).
- Enum cases: `camelCase` (e.g., `.oneFingerTapLeft`, `.twoFingerPinchIn`, `.keyboardShortcut`).

**Variables & Methods:**
- Properties, local variables, and methods: `camelCase` (e.g., `processFrame`, `lastDetectedGesture`, `hasAccessibility`).
- Boolean flags and getters: Prefix with `is`, `has`, or descriptive predicate (e.g., `isConnected`, `isEnabled`, `isChecking`, `hasTriggeredPinch`).
- Private properties: CamelCase without underscores (e.g., `touchDownTimes`, `lastTapTime`).

## Code Style

**Formatting:**
- Indentation: 4 spaces (standard Swift convention).
- Bracing: 1TBS (One True Brace Style) — opening brace on the same line as declaration, closing brace aligned with statement.
- Line Length: Generally kept within 120 characters for readability.
- Imports: Grouped at the top of each file, starting with system frameworks (`Foundation`, `CoreGraphics`, `AppKit`, `SwiftUI`) followed by project modules.

**Architecture Patterns:**
- **Singletons for Engine and Stores:** Core controllers and stores expose a shared instance: `public static let shared = ClassName()`.
- **Value Semantics for Data Models:** Touch frames, mappings, and configuration records are implemented as `struct` or `enum` adopting `Codable`, `Identifiable`, and `Equatable`.
- **Reference Semantics for Controllers:** Engines and state stores that hold persistent observers or run loops are implemented as `final class`.
- **Explicit Thread Dispatching:** Any callback from `MultitouchBridge` or background network sessions (`URLSession`) updates UI-bound state strictly via `DispatchQueue.main.async`.

## Error Handling

**Strategies:**
- **Non-Fatal Fallbacks:** Configuration loading and decoding errors in `ConfigurationStore` do not crash the app; they log and restore default gesture presets.
- **Nil Safety:** Use `guard let` and `if let` unwrapping rather than forced unwrapping (`!`), with isolated exceptions for known constant URLs in tests or initializers.
- **System Service Protection:** In `ActionDispatcher.swift`, external process executions (like AppleScript and shell scripts) execute within isolated `Process()` blocks and catch errors without crashing the main application.

## State Management & SwiftUI

**Observability:**
- Application state classes inherit from `ObservableObject`.
- State bound to UI controls is marked `@Published` (e.g., `@Published public var isEnabled: Bool = true`).
- Views access state via `@ObservedObject var store: ConfigurationStore = ConfigurationStore.shared` or `@State`.

## Documentation & Comments

**Conventions:**
- Standard Markdown docstrings (`/// ...`) on all public types, protocols, and critical methods.
- Section dividers marked with `// MARK: - Section Name` to organize delegate implementations, event handlers, and helper methods.
- Heuristic reasoning: Comments explain the mathematical rationale behind timing windows and spatial thresholds in `GestureRecognizer.swift` (e.g. why 450ms rest filters unintentional taps).

---

*Conventions analysis: 2026-09-21*
*Update when conventions evolve*
