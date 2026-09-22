import SwiftUI
import AppKit

@main
struct MagicTouchApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate, MultitouchManagerDelegate {
    var statusItem: NSStatusItem?
    var popover: NSPopover?

    let multitouchManager = MultitouchManager()
    let configStore = ConfigurationStore.shared
    let actionDispatcher = ActionDispatcher.shared
    let appState = AppState.shared
    private var lastDispatchedGesture: GestureType?
    private var lastDispatchedTime: Double = 0
    private var lastSingleTapGesture: GestureType = .oneFingerTapLeft

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory) // Menu bar only app (no dock icon)

        // Setup status item in macOS menu bar
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "magicmouse.fill", accessibilityDescription: "MagicTouch")
            button.action = #selector(togglePopover)
            button.target = self
        }

        // Setup Popover
        let popoverView = MainPopoverView()

        let popover = NSPopover()
        popover.contentSize = NSSize(width: 560, height: 440)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: popoverView)
        self.popover = popover

        // Connect Multitouch
        multitouchManager.delegate = self
        multitouchManager.start()

        PermissionManager.shared.checkAll()
        if !PermissionManager.shared.hasAccessibility {
            _ = PermissionManager.shared.checkAccessibility(prompt: true)
        }
        if !PermissionManager.shared.hasInputMonitoring {
            PermissionManager.shared.requestInputMonitoring()
        }

        // Check for updates in background after startup
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            UpdateChecker.shared.checkForUpdates(manual: false)
        }
    }

    @objc func togglePopover() {
        guard let button = statusItem?.button, let popover = popover else { return }

        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }

    // MARK: - MultitouchManagerDelegate
    func multitouchManagerDidDetect(gesture: GestureType) {
        let now = ProcessInfo.processInfo.systemUptime
        // Debounce only micro-bounces (< 50ms) so rapid deliberate taps are never dropped
        if gesture == lastDispatchedGesture && (now - lastDispatchedTime) < 0.05 {
            return
        }
        lastDispatchedGesture = gesture
        lastDispatchedTime = now

        if gesture == .oneFingerTapLeft || gesture == .oneFingerTapRight {
            lastSingleTapGesture = gesture
        }

        DispatchQueue.main.async {
            self.appState.lastGesture = gesture.rawValue
        }

        // Check if user has an assigned action for this gesture
        if let action = configStore.actionForGesture(gesture) {
            let clickState = (gesture == .oneFingerDoubleTap) ? 2 : ((gesture == .oneFingerTripleTap) ? 3 : 1)
            actionDispatcher.execute(action: action, clickState: clickState)
        } else if gesture == .oneFingerDoubleTap {
            // User did not map 1-Finger Double Tap: fall back to single tap action with clickState = 2
            // so standard double-clicking/tapping functions naturally as a native double click!
            if let fallbackAction = configStore.actionForGesture(lastSingleTapGesture) {
                actionDispatcher.execute(action: fallbackAction, clickState: 2)
            }
        } else if gesture == .oneFingerTripleTap {
            // User did not map 1-Finger Triple Tap: fall back to single tap action with clickState = 3
            if let fallbackAction = configStore.actionForGesture(lastSingleTapGesture) {
                actionDispatcher.execute(action: fallbackAction, clickState: 3)
            }
        }
    }

    func multitouchManagerDidUpdateTouches(touches: [TouchPoint]) {
        DispatchQueue.main.async {
            self.appState.touches = touches
        }
    }

    func multitouchManagerDeviceStatusChanged(connected: Bool, deviceName: String) {
        DispatchQueue.main.async {
            self.appState.isConnected = connected
            self.appState.deviceName = deviceName
        }
    }

    func multitouchManagerDidStartDrag() {
        // If the user has a custom action mapped to holdToDrag, that gets triggered in didDetect;
        // otherwise, startLeftDrag natively initiates macOS left click drag.
        if configStore.actionForGesture(.holdToDrag) == nil {
            actionDispatcher.startLeftDrag()
        }
    }

    func multitouchManagerDidEndDrag() {
        actionDispatcher.endLeftDrag()
    }
}
