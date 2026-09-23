import Foundation
import MultitouchBridge
import CoreGraphics
import AppKit

/// Callback passed to MultitouchSupport C-API
private func multitouchCallback(device: MTDeviceRef?, touches: UnsafeMutablePointer<MTTouch>?, numTouches: Int32, timestamp: Double, frame: Int32) -> Int32 {
    guard let manager = MultitouchManager.activeInstance else { return 0 }
    guard let touches = touches else { return 0 }

    var touchPoints: [TouchPoint] = []
    touchPoints.reserveCapacity(Int(numTouches))

    for i in 0..<Int(numTouches) {
        let touch = touches[i]
        // Magic Mouse reports touches across states (MakeTouch=3, Touching=4, HoverInRange=2, BreakTouch=5)
        // Accept all non-zero states except OutOfRange (7) and NotTracking (0)
        if touch.state != MTTouchStateNotTracking && touch.state != MTTouchStateOutOfRange {
            let point = TouchPoint(
                id: Int(touch.identifier),
                x: touch.normalizedPosition.position.x,
                y: touch.normalizedPosition.position.y,
                totalSize: touch.totalSize,
                timestamp: timestamp
            )
            touchPoints.append(point)
        }
    }

    manager.handleTouchFrame(touches: touchPoints, timestamp: timestamp)
    return 0
}

/// Callback triggered by IOHIDManager when devices connect or disconnect
private func deviceListChangedCallback() {
    DispatchQueue.main.async {
        MultitouchManager.activeInstance?.handleDeviceListChanged()
    }
}

public protocol MultitouchManagerDelegate: AnyObject {
    func multitouchManagerDidDetect(gesture: GestureType)
    func multitouchManagerDidUpdateTouches(touches: [TouchPoint])
    func multitouchManagerDeviceStatusChanged(connected: Bool, deviceName: String)
    func multitouchManagerDidStartDrag()
    func multitouchManagerDidEndDrag()
}

public extension MultitouchManagerDelegate {
    func multitouchManagerDidStartDrag() {}
    func multitouchManagerDidEndDrag() {}
}

public final class MultitouchManager: GestureRecognizerDelegate {
    public static var activeInstance: MultitouchManager?

    public weak var delegate: MultitouchManagerDelegate?
    public let recognizer: GestureRecognizer
    private var isRunning = false
    private var activeDevice: MTDeviceRef?
    private var isExternalDeviceActive = false
    private var clickEventTap: CFMachPort?
    private var watchdogTimer: Timer?
    private var reconnectWorkItem: DispatchWorkItem?

    public init() {
        self.recognizer = GestureRecognizer()
        self.recognizer.delegate = self
        MultitouchManager.activeInstance = self
    }

    public func start() {
        guard !isRunning else { return }
        isRunning = true
        registerSystemNotifications()
        MTBridgeRegisterDeviceListChangedCallback(deviceListChangedCallback)
        startMultitouchDevice()
        startClickInterceptor()
        startWatchdog()
    }

    public func stop() {
        guard isRunning else { return }
        isRunning = false
        stopWatchdog()
        unregisterSystemNotifications()
        stopMultitouchDevice()
        stopClickInterceptor()
    }

    // MARK: - System Sleep & Wake Lifecycle
    private func registerSystemNotifications() {
        let ws = NSWorkspace.shared.notificationCenter
        ws.addObserver(self, selector: #selector(systemWillSleep), name: NSWorkspace.willSleepNotification, object: nil)
        ws.addObserver(self, selector: #selector(systemDidWake), name: NSWorkspace.didWakeNotification, object: nil)
        ws.addObserver(self, selector: #selector(systemDidWake), name: NSWorkspace.screensDidWakeNotification, object: nil)
    }

    private func unregisterSystemNotifications() {
        let ws = NSWorkspace.shared.notificationCenter
        ws.removeObserver(self, name: NSWorkspace.willSleepNotification, object: nil)
        ws.removeObserver(self, name: NSWorkspace.didWakeNotification, object: nil)
        ws.removeObserver(self, name: NSWorkspace.screensDidWakeNotification, object: nil)
    }

    @objc private func systemWillSleep() {
        print("[MagicTouch] Mac going to sleep. Stopping multitouch device...")
        fflush(stdout)
        stopMultitouchDevice()
        delegate?.multitouchManagerDeviceStatusChanged(connected: false, deviceName: "Mac Sleeping")
    }

    @objc private func systemDidWake() {
        print("[MagicTouch] Mac woke up. Re-enabling click interceptor & reconnecting...")
        fflush(stdout)
        reEnableClickInterceptor()

        // Bluetooth devices often take 1 - 3 seconds after wake to re-establish connection.
        // Stagger reconnect attempts:
        for delay in [0.5, 1.5, 3.0, 5.0] {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                guard let self = self, self.isRunning else { return }
                self.reEnableClickInterceptor()
                self.refreshDeviceConnection()
            }
        }
    }

    // MARK: - Device Hotplug Handling
    fileprivate func handleDeviceListChanged() {
        reconnectWorkItem?.cancel()
        let work = DispatchWorkItem { [weak self] in
            guard let self = self, self.isRunning else { return }
            self.refreshDeviceConnection()
        }
        reconnectWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: work)
    }

    public func refreshDeviceConnection() {
        guard isRunning else { return }
        MTBridgeRefreshDevices()
        let count = MTBridgeGetDeviceCount()

        var externalDev: MTDeviceRef?
        for i in 0..<count {
            if let dev = MTBridgeGetDeviceAtIndex(i), !MTBridgeDeviceIsBuiltIn(dev) {
                externalDev = dev
                break
            }
        }

        // If we already hold an external device, verify it's still alive & running
        if let current = activeDevice, isExternalDeviceActive {
            let isAlive = MTBridgeDeviceIsAlive(current)
            let isRunning = MTBridgeDeviceIsRunning(current)
            if let ext = externalDev, ext == current, isAlive, isRunning {
                // Device is still active and healthy, no reconnect needed
                return
            }
        }

        print("[MagicTouch] Device configuration changed (found \(count) devices). Re-binding...")
        fflush(stdout)
        stopMultitouchDevice()
        startMultitouchDevice()
    }

    // MARK: - Multitouch Device Lifecycle
    private func startMultitouchDevice() {
        MTBridgeRefreshDevices()
        let count = MTBridgeGetDeviceCount()
        print("[MagicTouch] Total multitouch devices found: \(count)")
        fflush(stdout)

        if count == 0 {
            delegate?.multitouchManagerDeviceStatusChanged(connected: false, deviceName: "No devices found")
            return
        }

        var targetDevice: MTDeviceRef?
        var isExternal = false

        // First pass: find external device (Magic Mouse or external Trackpad)
        for i in 0..<count {
            if let dev = MTBridgeGetDeviceAtIndex(i) {
                let builtIn = MTBridgeDeviceIsBuiltIn(dev)
                print("[MagicTouch] Device \(i): \(dev), builtIn: \(builtIn)")
                fflush(stdout)
                if !builtIn {
                    targetDevice = dev
                    isExternal = true
                    break
                }
            }
        }

        // Fallback: use first device if no external is found
        if targetDevice == nil {
            targetDevice = MTBridgeGetDeviceAtIndex(0)
            isExternal = false
        }

        if let device = targetDevice {
            self.activeDevice = device
            self.isExternalDeviceActive = isExternal
            MTBridgeStartDevice(device, multitouchCallback)
            let devName = isExternal ? "Apple Magic Mouse (Connected)" : "Internal Trackpad"
            print("[MagicTouch] Successfully bound to: \(devName)")
            fflush(stdout)
            delegate?.multitouchManagerDeviceStatusChanged(connected: true, deviceName: devName)
        } else {
            self.isExternalDeviceActive = false
            print("[MagicTouch] No multitouch device found")
            fflush(stdout)
            delegate?.multitouchManagerDeviceStatusChanged(connected: false, deviceName: "No Multitouch Device Found")
        }
    }

    private func stopMultitouchDevice() {
        if let device = activeDevice {
            activeDevice = nil
            isExternalDeviceActive = false
            MTBridgeStopDevice(device, multitouchCallback)
        }
    }

    // MARK: - Watchdog Timer
    private func startWatchdog() {
        stopWatchdog()
        watchdogTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            self?.watchdogTick()
        }
    }

    private func stopWatchdog() {
        watchdogTimer?.invalidate()
        watchdogTimer = nil
    }

    private func watchdogTick() {
        guard isRunning else { return }
        reEnableClickInterceptor()

        if let device = activeDevice {
            let alive = MTBridgeDeviceIsAlive(device)
            let running = MTBridgeDeviceIsRunning(device)
            if !alive || !running {
                print("[MagicTouch] Active device became unresponsive (alive: \(alive), running: \(running)). Reconnecting...")
                fflush(stdout)
                refreshDeviceConnection()
                return
            }

            // If currently on fallback built-in trackpad, check if external mouse has appeared
            if !isExternalDeviceActive {
                let count = MTBridgeGetDeviceCount()
                for i in 0..<count {
                    if let dev = MTBridgeGetDeviceAtIndex(i), !MTBridgeDeviceIsBuiltIn(dev) {
                        print("[MagicTouch] External mouse detected while on fallback. Switching to Magic Mouse...")
                        fflush(stdout)
                        refreshDeviceConnection()
                        return
                    }
                }
            }
        } else {
            refreshDeviceConnection()
        }
    }

    // MARK: - Frame Dispatch
    fileprivate func handleTouchFrame(touches: [TouchPoint], timestamp: Double) {
        recognizer.processFrame(touches: touches, timestamp: timestamp)
    }

    // MARK: - Click Event Tap
    private func startClickInterceptor() {
        let mask = (1 << CGEventType.leftMouseDown.rawValue)
        guard let tap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(mask),
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                // Handle system-disabled taps (e.g. timeout or high load during sleep/wake)
                if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
                    if let refcon = refcon {
                        let mgr = Unmanaged<MultitouchManager>.fromOpaque(refcon).takeUnretainedValue()
                        mgr.reEnableClickInterceptor()
                    }
                    return Unmanaged.passRetained(event)
                }

                // Filter out MagicTouch's own synthesized clicks
                if event.getIntegerValueField(.eventSourceUserData) == ActionDispatcher.magicEventSignature {
                    return Unmanaged.passRetained(event)
                }
                if ActionDispatcher.isSynthesizingEvent {
                    return Unmanaged.passRetained(event)
                }
                if let refcon = refcon {
                    let mgr = Unmanaged<MultitouchManager>.fromOpaque(refcon).takeUnretainedValue()
                    mgr.recognizer.processPhysicalClick()
                }
                return Unmanaged.passRetained(event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            print("[MagicTouch] Note: CGEvent tap requires Accessibility Permissions to intercept physical clicks.")
            fflush(stdout)
            return
        }

        self.clickEventTap = tap
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
    }

    public func reEnableClickInterceptor() {
        guard isRunning else { return }
        if let tap = clickEventTap {
            if !CGEvent.tapIsEnabled(tap: tap) {
                CGEvent.tapEnable(tap: tap, enable: true)
                print("[MagicTouch] Re-enabled CGEventTap after timeout/sleep.")
                fflush(stdout)
            }
        } else {
            startClickInterceptor()
        }
    }

    public func restartClickInterceptorIfNeeded() {
        reEnableClickInterceptor()
    }

    private func stopClickInterceptor() {
        if let tap = clickEventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            clickEventTap = nil
        }
    }

    // MARK: - GestureRecognizerDelegate
    public func gestureRecognizerDidDetect(gesture: GestureType) {
        delegate?.multitouchManagerDidDetect(gesture: gesture)
    }

    public func gestureRecognizerDidUpdateTouches(touches: [TouchPoint]) {
        delegate?.multitouchManagerDidUpdateTouches(touches: touches)
    }

    public func gestureRecognizerDidStartDrag() {
        delegate?.multitouchManagerDidStartDrag()
    }

    public func gestureRecognizerDidEndDrag() {
        delegate?.multitouchManagerDidEndDrag()
    }
}
