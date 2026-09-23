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
    public let recognizerQueue = DispatchQueue(label: "com.namikemen.magictouch.recognizer", qos: .userInteractive)
    private var isRunning = false
    private var activeDevice: MTDeviceRef?
    private var isExternalDeviceActive = false
    private var lastKnownExternalDeviceCount = -1
    private var lastKnownTotalDeviceCount = -1
    private var clickEventTap: CFMachPort?
    private var watchdogTimer: Timer?

    public init() {
        self.recognizer = GestureRecognizer()
        self.recognizer.delegate = self
        MultitouchManager.activeInstance = self
    }

    public func start() {
        guard !isRunning else { return }
        isRunning = true
        registerSystemNotifications()
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

    // MARK: - Device Scanning
    private struct DeviceScanResult {
        let externalDevice: MTDeviceRef?
        let builtInDevice: MTDeviceRef?
        let externalCount: Int
        let totalCount: Int
    }

    private func scanDevices() -> DeviceScanResult {
        MTBridgeRefreshDevices()
        let count = MTBridgeGetDeviceCount()
        var extDev: MTDeviceRef?
        var builtInDev: MTDeviceRef?
        var extCount = 0

        for i in 0..<count {
            if let dev = MTBridgeGetDeviceAtIndex(i) {
                if MTBridgeDeviceIsBuiltIn(dev) {
                    if builtInDev == nil { builtInDev = dev }
                } else {
                    extCount += 1
                    if extDev == nil { extDev = dev }
                }
            }
        }
        return DeviceScanResult(
            externalDevice: extDev,
            builtInDevice: builtInDev,
            externalCount: extCount,
            totalCount: count
        )
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
        print("[MagicTouch] Mac going to sleep. Stopping multitouch...")
        fflush(stdout)
        lastKnownExternalDeviceCount = -1
        lastKnownTotalDeviceCount = -1
        stopMultitouchDevice()
        delegate?.multitouchManagerDeviceStatusChanged(connected: false, deviceName: "Mac Sleeping")
    }

    @objc private func systemDidWake() {
        print("[MagicTouch] Mac woke up. Re-enabling click interceptor & scheduling reconnection...")
        fflush(stdout)
        reEnableClickInterceptor()
        lastKnownExternalDeviceCount = -1
        lastKnownTotalDeviceCount = -1

        // Bluetooth devices often take 1 - 3 seconds after wake to re-establish connection.
        // Stagger reconnect attempts:
        for delay in [0.8, 2.0, 3.5] {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                guard let self = self, self.isRunning else { return }
                self.reEnableClickInterceptor()
                self.checkDeviceStatus()
            }
        }
    }

    // MARK: - Multitouch Device Lifecycle
    private func startMultitouchDevice() {
        let scan = scanDevices()
        self.lastKnownExternalDeviceCount = scan.externalCount
        self.lastKnownTotalDeviceCount = scan.totalCount

        print("[MagicTouch] Total multitouch devices found: \(scan.totalCount) (External: \(scan.externalCount))")
        fflush(stdout)

        if let ext = scan.externalDevice {
            self.activeDevice = ext
            self.isExternalDeviceActive = true
            MTBridgeStartDevice(ext, multitouchCallback)
            let devName = "Apple Magic Mouse (Connected)"
            print("[MagicTouch] Successfully bound to: \(devName)")
            fflush(stdout)
            delegate?.multitouchManagerDeviceStatusChanged(connected: true, deviceName: devName)
        } else if let builtIn = scan.builtInDevice {
            self.activeDevice = builtIn
            self.isExternalDeviceActive = false
            MTBridgeStartDevice(builtIn, multitouchCallback)
            let devName = "Internal Trackpad"
            print("[MagicTouch] Bound to fallback: \(devName)")
            fflush(stdout)
            delegate?.multitouchManagerDeviceStatusChanged(connected: true, deviceName: devName)
        } else {
            self.activeDevice = nil
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
        watchdogTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.checkDeviceStatus()
        }
    }

    private func stopWatchdog() {
        watchdogTimer?.invalidate()
        watchdogTimer = nil
    }

    private func checkDeviceStatus() {
        guard isRunning else { return }
        reEnableClickInterceptor()

        let scan = scanDevices()

        // 1. Has the count of external devices changed?
        // (e.g. Magic Mouse was switched off: extCount 1 -> 0, or switched on: extCount 0 -> 1)
        if scan.externalCount != lastKnownExternalDeviceCount {
            print("[MagicTouch] External device change detected (\(lastKnownExternalDeviceCount) -> \(scan.externalCount)). Updating connection...")
            fflush(stdout)
            stopMultitouchDevice()
            startMultitouchDevice()
            return
        }

        // 2. If we are currently not bound to any device, but devices exist, bind!
        if activeDevice == nil && scan.totalCount > 0 {
            print("[MagicTouch] Multitouch device available. Binding...")
            fflush(stdout)
            startMultitouchDevice()
            return
        }
    }

    // MARK: - Frame Dispatch
    fileprivate func handleTouchFrame(touches: [TouchPoint], timestamp: Double) {
        recognizerQueue.async { [weak self] in
            self?.recognizer.processFrame(touches: touches, timestamp: timestamp)
        }
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
                // Handle system-disabled taps (e.g. timeout during sleep or high load)
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
                    mgr.recognizerQueue.async {
                        mgr.recognizer.processPhysicalClick()
                    }
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
