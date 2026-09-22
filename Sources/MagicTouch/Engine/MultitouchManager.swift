import Foundation
import MultitouchBridge
import CoreGraphics

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
    private var isRunning = false
    private var activeDevice: MTDeviceRef?
    private var clickEventTap: CFMachPort?

    public init() {
        self.recognizer = GestureRecognizer()
        self.recognizer.delegate = self
        MultitouchManager.activeInstance = self
    }

    public func start() {
        guard !isRunning else { return }
        isRunning = true
        startMultitouchDevice()
        startClickInterceptor()
    }

    public func stop() {
        guard isRunning else { return }
        isRunning = false
        stopMultitouchDevice()
        stopClickInterceptor()
    }

    // MARK: - Multitouch Device Lifecycle
    private func startMultitouchDevice() {
        let count = MTBridgeGetDeviceCount()
        print("[MagicTouch] Total multitouch devices found: \(count)")

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
            MTBridgeStartDevice(device, multitouchCallback)
            let devName = isExternal ? "Apple Magic Mouse (Connected)" : "Internal Trackpad"
            print("[MagicTouch] Successfully bound to: \(devName)")
            fflush(stdout)
            delegate?.multitouchManagerDeviceStatusChanged(connected: true, deviceName: devName)
        } else {
            print("[MagicTouch] No multitouch device found")
            fflush(stdout)
            delegate?.multitouchManagerDeviceStatusChanged(connected: false, deviceName: "No Multitouch Device Found")
        }
    }

    private func stopMultitouchDevice() {
        if let device = activeDevice {
            MTBridgeStopDevice(device, multitouchCallback)
            activeDevice = nil
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

    public func restartClickInterceptorIfNeeded() {
        if clickEventTap == nil && isRunning {
            startClickInterceptor()
        }
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
