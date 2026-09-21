# Codebase Concerns

**Analysis Date:** 2026-09-21

## Tech Debt

**`package_app.sh` Ad-Hoc Code Signing:**
- Issue: The build script signs binaries using ad-hoc signature (`codesign --force --deep -s -`).
- Why: Enables immediate local builds without requiring a paid Apple Developer ID certificate in developer environments.
- Impact: On modern macOS (Sonoma, Sequoia), Gatekeeper may warn about unnotarized apps unless opened via Control-click > Open or allowed in Privacy & Security.
- Fix approach: Integrate optional Apple Developer certificate signing (`codesign -s "Developer ID Application: ..."`) and `xcrun notarytool` submission when credentials are present in CI secrets.

**Swift Package Manager vs Custom Build Scripts:**
- Issue: SPM is configured in `Package.swift`, but packaging and release builds use `package_app.sh` and direct `swiftc`/`clang` compiler invocations.
- Why: Private framework linking (`-F/System/Library/PrivateFrameworks -framework MultitouchSupport`) requires unsafe flags in SPM which prevents easy binary distribution or archive workflows within standard Xcode GUI builds.
- Impact: Dual maintenance: changes to compiler flags or module dependencies must be reflected in both `Package.swift` and `package_app.sh`.
- Fix approach: Keep build scripts synchronized with `Package.swift` targets; consider SPM plugins or Makefiles for unified entry points.

## Known Fragile Areas

**Apple Private Framework (`MultitouchSupport.framework`):**
- Why fragile: Apple does not provide official public headers or SDK documentation for `MultitouchSupport`. C struct definitions (`MTTouch`, `MTPoint`, `MTVector`) in `Sources/MultitouchBridge/include/MultitouchBridge.h` are reverse-engineered.
- Common failures: While stable across macOS 10.6 through macOS 15, future macOS kernel or driver refactors could alter struct layouts or callback signatures.
- Safe modification: Encapsulate all raw C pointers and structs strictly within `MultitouchBridge`. Ensure fallback checks prevent crashes if `MTDeviceCreateList` returns `NULL`.
- Test coverage: Tested via synthetic `TouchPoint` feeds in `StandaloneTests.swift`. Live hardware callbacks are isolated behind `MultitouchManager`.

**Gesture Recognition Sensitivity & Surface Dynamics:**
- Why fragile: The physical surface of the Magic Mouse is curved and much narrower than a MacBook trackpad. Users frequently rest fingers on the mouse while moving it.
- Common failures: Misclassification between horizontal swipes and pinch-in gestures when fingers compress naturally, or false taps when resting fingers lift.
- Safe modification: Maintain strict bounds on tap duration (`oneFingerTapMaxDuration = 0.28s`) and movement distance (`oneFingerTapMaxMovement = 0.065`). Always verify against `testTwoFingerSwipeLeftWithNaturalCompressionNotPinchIn` and `testOneFingerLongRestNotTap` before tuning recognizer parameters.

## Security Considerations

**macOS System Permissions (Accessibility & Input Monitoring):**
- Risk: MagicTouch has the ability to intercept multi-touch coordinates and inject synthetic keystrokes and mouse events via `CoreGraphics`.
- Current mitigation: The application does not log keystrokes or send telemetry. All touch coordinates remain in local memory and are only used for gesture classification.
- Recommendations: Maintain clear privacy declarations on the website/documentation reassuring users that MagicTouch operates 100% locally with zero analytics or remote data collection.

**Arbitrary Shell & AppleScript Execution:**
- Risk: Users can configure custom shell commands or AppleScripts to trigger on gestures.
- Current mitigation: Commands only originate from the user's locally stored `~/Library/Application Support/MagicTouch/gestures.json`.
- Recommendations: Prevent executing unverified external scripts from downloaded configuration files without explicit user review.

## Dependencies at Risk

**GitHub Releases API Rate Limiting:**
- Risk: Public GitHub API calls have a limit of 60 requests/hour per IP for unauthenticated users.
- Impact: If an office network has multiple users or automated update checks fire frequently, GitHub API queries could receive HTTP 403.
- Current mitigation: `UpdateChecker.swift` prioritizes downloading the static release asset `latest.json` directly from `github.com/.../releases/latest/download/latest.json` (which is not subject to the 60 req/hr API rate limit) and only falls back to the REST API if `latest.json` fails.

## Missing Project Needs (Website & Web Presence)

**Dedicated Project Website:**
- Problem: MagicTouch currently only exists as a raw GitHub repository with a `README.md`.
- Impact: Potential users looking for a Magic Mouse customization tool have no web landing page to see visual demonstrations of gestures, view interactive documentation, check system requirements, or download the latest `.dmg` installer.
- Solution: Design and build a modern, high-conversion, responsive static landing page (with interactive touch visualizer preview, gesture showcase, download buttons hooked to GitHub Releases, and quick start guide).

---

*Concerns analysis: 2026-09-21*
*Update when discovering new bugs, risks, or tech debt*
