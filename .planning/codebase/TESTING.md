# Testing Patterns

**Analysis Date:** 2026-09-21

## Test Framework

**Runners:**
- **Standalone CLI Test Runner:** Compiled with `swiftc` via `./run_tests.sh` (`Tests/MagicTouchTests/StandaloneTests.swift`). Does not require Xcode IDE; executes directly in terminal or headless CI environments with immediate terminal feedback.
- **XCTest Runner:** Standard Apple testing target in `Package.swift` (`Tests/MagicTouchTests/GestureRecognizerTests.swift`).

**Run Commands:**
```bash
./run_tests.sh                           # Run all 25 standalone unit tests (fast, ~1-2 seconds)
swift test                               # Run XCTest suite via Swift Package Manager
```

## Test File Organization

**Location:**
- Dedicated `Tests/` directory at the repository root.
- `Tests/MagicTouchTests/`:
  - `GestureRecognizerTests.swift`: Standard XCTest assertions (`XCTAssertEqual`).
  - `StandaloneTests.swift`: Self-executing runner with custom assertion helpers and complete test suite coverage.

## Test Structure

**Delegate Mocking Pattern:**
To test gesture recognition without firing real macOS synthetic clicks or requiring physical Magic Mouse hardware, tests implement `GestureRecognizerDelegate`:

```swift
final class GestureRecognizerTestsRunner: GestureRecognizerDelegate {
    private var lastDetectedGesture: GestureType?
    private var updatedTouches: [TouchPoint] = []

    func gestureRecognizerDidDetect(gesture: GestureType) {
        self.lastDetectedGesture = gesture
    }

    func gestureRecognizerDidUpdateTouches(touches: [TouchPoint]) {
        self.updatedTouches = touches
    }
}
```

**Simulation Frame Sequences:**
Tests simulate the passage of time and physical finger motions by feeding synthetic arrays of `TouchPoint` with increasing timestamps into `recognizer.processFrame(touches:timestamp:)`:

```swift
// 1. Touchdown
recognizer.processFrame(touches: [TouchPoint(id: 1, x: 0.3, y: 0.5), TouchPoint(id: 2, x: 0.5, y: 0.5)], timestamp: 2.0)

// 2. Motion / Displacement
recognizer.processFrame(touches: [TouchPoint(id: 1, x: 0.65, y: 0.51), TouchPoint(id: 2, x: 0.85, y: 0.51)], timestamp: 2.15)

// 3. Finger Lift / Release
recognizer.processFrame(touches: [], timestamp: 2.2)

// 4. Verification
assertEqual(lastDetectedGesture, .twoFingerSwipeRight, "Detected 2-finger swipe right")
```

## Test Suites & Coverage (25 Test Suites)

1. **Semantic Versioning (`SemVer`):** Compares versions, prefixes (`v1.0.0`), and pre-release tags.
2. **Update Manifest & GitHub Release JSON:** Verifies decoding of `latest.json` and GitHub API release objects.
3. **1-Finger Zone Separation:** Verifies Left vs Right half tap discrimination (`x < 0.5` vs `x >= 0.5`).
4. **Triple Tap Detection:** Validates consecutive multi-tap sequences for 1 and 2 fingers within timing limits.
5. **Config Fallback Resolution:** Ensures specific sub-zone gestures fall back gracefully to parent gesture definitions.
6. **Legacy JSON Deserialization:** Guarantees backward compatibility with older configuration files.
7. **Multi-Finger Taps:** 2-finger and 3-finger tap recognition.
8. **Directional Swipes:** Left, right, up, down directional classification.
9. **Natural Compression Immunity:** Verifies that fingers naturally curving during horizontal swipes are not misclassified as pinch-in gestures.
10. **Resting Finger Suppression:** Confirms that resting an index finger while moving the mouse does not cause accidental taps.
11. **Hand Drift Suppression:** Confirms pointer movement jitter does not cause accidental taps.
12. **Pinch In & Out:** Two-finger and three-finger spread expansion and contraction.
13. **Asymmetric Pinch:** Handles cases where one finger anchors and another moves inward.
14. **Physical Surface Click with Fingers Resting:** Tests 3-finger physical click mapping to Middle Click.
15. **Tip-Tap Gestures:** Rest-and-tap recognition for left and right fingers, including consecutive tip-taps.
16. **Staggered Lift Differentiation:** Distinguishes simultaneous 2-finger tap lifts from tip-tap releases.
17. **Action Target Mappings:** Validates storage, retrieval, and string representations of mouse button simulations.
18. **Configuration Persistence:** Tests save and reload mechanics of `ConfigurationStore`.

---

*Testing analysis: 2026-09-21*
*Update when adding new test suites*
