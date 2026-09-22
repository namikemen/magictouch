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
        if gesture == lastDispatchedGesture && (now - lastDispatchedTime) < 0.15 {
            return
        }
        lastDispatchedGesture = gesture
        lastDispatchedTime = now

        DispatchQueue.main.async {
            self.appState.lastGesture = gesture.rawValue
        }

        // Check if user has an assigned action for this gesture
        if let action = configStore.actionForGesture(gesture) {
            actionDispatcher.execute(action: action)
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
