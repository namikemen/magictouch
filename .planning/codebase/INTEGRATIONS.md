# External Integrations

**Analysis Date:** 2026-09-21

## APIs & External Services

**GitHub Releases & Updates:**
- GitHub Releases API & Direct Asset Downloads:
  - Purpose: Automated in-app update checks, release notes retrieval, and binary DMG downloads.
  - Manifest URL: `https://github.com/namikemen/magictouch/releases/latest/download/latest.json`
  - Fallback REST API: `https://api.github.com/repos/namikemen/magictouch/releases/latest`
  - Client: Native `URLSession` in `Sources/MagicTouch/Engine/UpdateChecker.swift` (implements `URLSessionDownloadDelegate` for live download progress tracking).
  - Auth: Public unauthenticated requests (rate limit: standard GitHub IP rate limits).

**macOS Private Framework Integration:**
- Apple MultitouchSupport Private Framework:
  - Framework Path: `/System/Library/PrivateFrameworks/MultitouchSupport.framework`
  - Bridge Module: `Sources/MultitouchBridge/MultitouchBridge.m` and `Sources/MultitouchBridge/include/MultitouchBridge.h`
  - Functions Hooked: `MTDeviceCreateList`, `MTRegisterContactFrameCallback`, `MTUnregisterContactFrameCallback`, `MTDeviceStart`, `MTDeviceStop`, `MTDeviceIsBuiltIn`, `MTDeviceGetFamilyID`.
  - Purpose: Intercepts raw multi-touch capacitive contact frames directly from the Magic Mouse hardware before macOS system gesture recognition consumes or suppresses them.

## Data Storage

**Local File Storage:**
- Directory: `~/Library/Application Support/MagicTouch/`
- File: `gestures.json` (`Sources/MagicTouch/Store/ConfigurationStore.swift`)
  - Format: JSON array of `GestureMapping` objects containing `gesture` and `action` definitions.
  - Persistence Mechanism: Decoded on launch; auto-saved on mapping changes via `JSONEncoder`.

## Operating System & Subsystem Integrations

**macOS Accessibility Subsystem:**
- API: `ApplicationServices` / `AXIsProcessTrustedWithOptions`
- Purpose: Verifies whether MagicTouch has permissions to simulate system-wide mouse events (`CGEvent`) and keystrokes.
- Managed by: `Sources/MagicTouch/Engine/PermissionManager.swift`.

**macOS Input Monitoring Subsystem:**
- API: `IOHIDCheckAccess(kIOHIDRequestTypeListenEvent)` and `IOHIDRequestAccess(kIOHIDRequestTypeListenEvent)`
- Purpose: Required by macOS Catalina+ to monitor physical hardware input events and clicks.
- Managed by: `Sources/MagicTouch/Engine/PermissionManager.swift`.

**macOS Scripting & Shell Subsystem:**
- AppleScript: Executed via `NSAppleScript(source: script).executeAndReturnError(&errorInfo)` in `Sources/MagicTouch/Engine/ActionDispatcher.swift`.
- Shell Commands: Executed asynchronously via `Process()` launching `/bin/zsh -c <command>` in `Sources/MagicTouch/Engine/ActionDispatcher.swift`.

**macOS Window Server & Quartz Event Services:**
- API: `CoreGraphics` / `CGEvent(mouseEventSource: nil, mouseType: ..., mouseCursorPosition: ..., mouseButton: ...)` posted to `.cghidEventTap`.
- Purpose: Dispatches synthesized clicks (left, right, middle, double, triple) and keyboard shortcuts to active windows.

## CI/CD & Deployment

**Hosting:**
- GitHub Repository: `namikemen/magictouch` (`https://github.com/namikemen/magictouch`)
- Release Artifacts: Hosted directly on GitHub Releases (DMG, universal zip, tarball, `latest.json`, `checksums.txt`).

**CI Pipeline:**
- Service: GitHub Actions (`.github/workflows/release.yml`)
- Triggers: Tag push (`v*.*.*`) or manual `workflow_dispatch`.
- Steps:
  1. Compiles universal app and produces `.dmg` via `package_app.sh` on `macos-14` runner.
  2. Generates `latest.json` auto-update manifest with SHA256 checksums on `ubuntu-latest`.
  3. Publishes GitHub Release using `softprops/action-gh-release@v2`.

## Environment Configuration

**Development:**
- No API keys or credentials needed for local compilation or running tests.
- Requires macOS with developer accessibility permissions granted in System Settings.

**Production:**
- Standard macOS end-user permissions (prompts user for Accessibility and Input Monitoring on first launch).

---

*Integration analysis: 2026-09-21*
*Update after major dependency changes*
