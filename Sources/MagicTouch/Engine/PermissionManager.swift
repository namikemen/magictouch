import Foundation
import AppKit
import CoreGraphics

public final class PermissionManager: ObservableObject {
    public static let shared = PermissionManager()

    @Published public var hasAccessibility: Bool = false
    @Published public var hasInputMonitoring: Bool = false

    private var timer: Timer?

    private init() {
        checkAll()
        startPolling()
    }

    deinit {
        timer?.invalidate()
    }

    public var allGranted: Bool {
        hasAccessibility && hasInputMonitoring
    }

    public func checkAll() {
        self.hasAccessibility = checkAccessibility(prompt: false)
        self.hasInputMonitoring = checkInputMonitoring()
    }

    private func startPolling() {
        // Poll every 2 seconds so UI dynamically updates when user grants permissions in System Settings
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let acc = self.checkAccessibility(prompt: false)
            let inp = self.checkInputMonitoring()
            if acc != self.hasAccessibility || inp != self.hasInputMonitoring {
                DispatchQueue.main.async {
                    self.hasAccessibility = acc
                    self.hasInputMonitoring = inp
                    if acc {
                        // Dynamically re-hook CGEventTap if accessibility was just granted
                        MultitouchManager.activeInstance?.restartClickInterceptorIfNeeded()
                    }
                }
            }
        }
    }

    public func restartApp() {
        let bundleURL = Bundle.main.bundleURL
        let config = NSWorkspace.OpenConfiguration()
        config.createsNewApplicationInstance = true
        NSWorkspace.shared.openApplication(at: bundleURL, configuration: config) { _, _ in
            DispatchQueue.main.async {
                NSApp.terminate(nil)
            }
        }
    }

    // MARK: - Accessibility Check & Request
    public func checkAccessibility(prompt: Bool = false) -> Bool {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: prompt]
        return AXIsProcessTrustedWithOptions(options)
    }

    public func requestAccessibility() {
        _ = checkAccessibility(prompt: true)
        openSystemSettings(pane: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")
    }

    // MARK: - Input Monitoring Check & Request
    public func checkInputMonitoring() -> Bool {
        // IOHIDCheckAccess checks for kIOHIDRequestTypeListenEvent permissions
        if #available(macOS 10.15, *) {
            let access = IOHIDCheckAccess(kIOHIDRequestTypeListenEvent)
            return access == kIOHIDAccessTypeGranted
        }
        return true
    }

    public func requestInputMonitoring() {
        if #available(macOS 10.15, *) {
            IOHIDRequestAccess(kIOHIDRequestTypeListenEvent)
        }
        openSystemSettings(pane: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent")
    }

    // MARK: - Helper to open specific Privacy tab
    public func openSystemSettings(pane: String) {
        if let url = URL(string: pane) {
            NSWorkspace.shared.open(url)
        }
    }
}
