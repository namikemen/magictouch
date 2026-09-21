import Foundation
import CoreGraphics

/// Internal simplified touch point model
public struct TouchPoint: Identifiable, Equatable {
    public let id: Int
    public var x: Float
    public var y: Float
    public var totalSize: Float
    public var timestamp: Double

    public init(id: Int, x: Float, y: Float, totalSize: Float = 0.0, timestamp: Double = 0.0) {
        self.id = id
        self.x = x
        self.y = y
        self.totalSize = totalSize
        self.timestamp = timestamp
    }
}

public protocol GestureRecognizerDelegate: AnyObject {
    func gestureRecognizerDidDetect(gesture: GestureType)
    func gestureRecognizerDidUpdateTouches(touches: [TouchPoint])
}

/// Gesture recognition state machine
public final class GestureRecognizer {
    public weak var delegate: GestureRecognizerDelegate?

    // Tracking active touch paths
    private var initialTouches: [Int: TouchPoint] = [:]
    private var currentTouches: [Int: TouchPoint] = [:]
    private var touchDownTimes: [Int: Double] = [:]
    private var touchPositionsAtTapDown: [Int: TouchPoint] = [:]
    private var suppressedTouchIds: Set<Int> = []
    private var touchStartTime: Double = 0
    private var maxSimultaneousFingers: Int = 0

    private struct PendingTipTap {
        let gesture: GestureType
        let restingId: Int
        let liftedId: Int
        let detectedTime: Double
    }
    private var pendingTipTap: PendingTipTap?

    // Pinch tracking
    private var initialSpread: Float?
    private var minSpreadDelta: Float = 0
    private var maxSpreadDelta: Float = 0
    private var hasTriggeredPinch: Bool = false
    private let pinchMinDelta: Float = 0.05

    // Thresholds tuned for Magic Mouse surface dimensions
    private let tapMaxDuration: Double = 0.50       // seconds
    private let tapMaxMovement: Float = 0.14        // normalized distance (mouse surface is compact)
    private let swipeMinDistance: Float = 0.10      // normalized distance

    // Multi-tap tracker
    private var lastTapTime: Double = 0
    private var lastTapFingerCount: Int = 0
    private var consecutiveTapCount: Int = 0

    public init() {}

    private func calculateSpread(touches: [TouchPoint]) -> Float {
        guard touches.count >= 2 else { return 0 }
        var totalDist: Float = 0
        var pairCount: Float = 0
        for i in 0..<touches.count {
            for j in (i + 1)..<touches.count {
                let dx = touches[i].x - touches[j].x
                let dy = touches[i].y - touches[j].y
                totalDist += sqrt(dx * dx + dy * dy)
                pairCount += 1
            }
        }
        return pairCount > 0 ? (totalDist / pairCount) : 0
    }

    /// Process a new contact frame from the mouse surface
    public func processFrame(touches: [TouchPoint], timestamp: Double) {
        let activeFingers = touches.count
        delegate?.gestureRecognizerDidUpdateTouches(touches: touches)

        // Check if there was a pending tip-tap from near-simultaneous touchdown
        if let pending = pendingTipTap {
            if activeFingers == 1 && touches.first?.id == pending.restingId {
                if timestamp - pending.detectedTime >= 0.10 {
                    // Resting finger stayed down: confirmed Tip-Tap!
                    delegate?.gestureRecognizerDidDetect(gesture: pending.gesture)
                    suppressedTouchIds.insert(pending.restingId)
                    initialTouches.removeValue(forKey: pending.liftedId)
                    touchDownTimes.removeValue(forKey: pending.liftedId)
                    touchPositionsAtTapDown.removeValue(forKey: pending.liftedId)
                    maxSimultaneousFingers = 1
                    pendingTipTap = nil
                }
            } else if activeFingers == 0 {
                // Both fingers lifted within 100ms: was a 2-finger tap, cancel pending tip-tap
                pendingTipTap = nil
            }
        }

        if activeFingers > 0 {
            if initialTouches.isEmpty {
                // New gesture session began
                touchStartTime = timestamp
                maxSimultaneousFingers = activeFingers
                for t in touches {
                    initialTouches[t.id] = t
                    touchDownTimes[t.id] = timestamp
                }
            } else {
                if activeFingers > maxSimultaneousFingers {
                    maxSimultaneousFingers = activeFingers
                }
                for t in touches {
                    if initialTouches[t.id] == nil {
                        initialTouches[t.id] = t
                        touchDownTimes[t.id] = timestamp
                    }
                }

                // If a second finger just landed, snapshot resting finger position
                let previousIds = Set(currentTouches.keys)
                if activeFingers == 2 && previousIds.count == 1 {
                    for t in touches {
                        touchPositionsAtTapDown[t.id] = t
                    }
                }
            }

            // Live Pinch Detection across 2 or 3 active fingers
            if activeFingers >= 2 {
                let spread = calculateSpread(touches: touches)
                if initialSpread == nil {
                    initialSpread = spread
                }
                if let base = initialSpread {
                    let delta = spread - base
                    if delta < minSpreadDelta { minSpreadDelta = delta }
                    if delta > maxSpreadDelta { maxSpreadDelta = delta }

                    if !hasTriggeredPinch {
                        if delta <= -pinchMinDelta {
                            hasTriggeredPinch = true
                            if activeFingers == 2 {
                                delegate?.gestureRecognizerDidDetect(gesture: .twoFingerPinchIn)
                            } else if activeFingers == 3 {
                                delegate?.gestureRecognizerDidDetect(gesture: .threeFingerPinchIn)
                            }
                            suppressedTouchIds.formUnion(touches.map { $0.id })
                        } else if delta >= pinchMinDelta {
                            hasTriggeredPinch = true
                            if activeFingers == 2 {
                                delegate?.gestureRecognizerDidDetect(gesture: .twoFingerPinchOut)
                            } else if activeFingers == 3 {
                                delegate?.gestureRecognizerDidDetect(gesture: .threeFingerPinchOut)
                            }
                            suppressedTouchIds.formUnion(touches.map { $0.id })
                        }
                    }
                }
            }

            // Check for Tip-Tap: 2 fingers were touching, now 1 finger lifted while other remains resting
            let activeIds = Set(touches.map { $0.id })
            let previousIds = Set(currentTouches.keys)
            let liftedIds = previousIds.subtracting(activeIds)

            if maxSimultaneousFingers == 2 && activeFingers == 1 && liftedIds.count == 1 && !hasTriggeredPinch {
                if let liftedId = liftedIds.first,
                   let liftedInitial = initialTouches[liftedId],
                   let restingTouch = touches.first,
                   let restingInitial = initialTouches[restingTouch.id] {
                    
                    let liftedStartTime = touchDownTimes[liftedId] ?? touchStartTime
                    let restingStartTime = touchDownTimes[restingTouch.id] ?? touchStartTime
                    let tapDuration = timestamp - liftedStartTime
                    
                    let restingRef = touchPositionsAtTapDown[restingTouch.id] ?? restingInitial
                    let restingMoved = hypot(restingTouch.x - restingRef.x, restingTouch.y - restingRef.y)
                    let liftedMoved = hypot((currentTouches[liftedId]?.x ?? liftedInitial.x) - liftedInitial.x,
                                            (currentTouches[liftedId]?.y ?? liftedInitial.y) - liftedInitial.y)

                    if tapDuration <= 0.65 && restingMoved < 0.14 && liftedMoved < 0.14 {
                        let gesture: GestureType = (liftedInitial.x < restingInitial.x) ? .tipTapLeft : .tipTapRight
                        let gap = liftedStartTime - restingStartTime

                        if gap > 0.08 {
                            // Resting finger was already resting when tap began: trigger immediately
                            delegate?.gestureRecognizerDidDetect(gesture: gesture)
                            suppressedTouchIds.insert(restingTouch.id)
                            initialTouches.removeValue(forKey: liftedId)
                            touchDownTimes.removeValue(forKey: liftedId)
                            touchPositionsAtTapDown.removeValue(forKey: liftedId)
                            maxSimultaneousFingers = 1
                            initialSpread = nil
                            minSpreadDelta = 0
                            maxSpreadDelta = 0
                        } else {
                            // Both touched down almost together: pend to confirm resting finger stays down
                            pendingTipTap = PendingTipTap(gesture: gesture, restingId: restingTouch.id, liftedId: liftedId, detectedTime: timestamp)
                        }
                    }
                }
            }

            currentTouches.removeAll()
            for t in touches {
                currentTouches[t.id] = t
            }
        } else {
            // All fingers lifted: evaluate gesture session
            if let pending = pendingTipTap {
                if timestamp - pending.detectedTime >= 0.10 {
                    delegate?.gestureRecognizerDidDetect(gesture: pending.gesture)
                    suppressedTouchIds.insert(pending.restingId)
                }
                pendingTipTap = nil
            }

            if !initialTouches.isEmpty {
                if !hasTriggeredPinch {
                    let nonSuppressedTouches = initialTouches.keys.filter { !suppressedTouchIds.contains($0) }
                    if !nonSuppressedTouches.isEmpty {
                        let duration = timestamp - touchStartTime
                        evaluateCompletedGesture(duration: duration, timestamp: timestamp)
                    }
                }
                initialTouches.removeAll()
                currentTouches.removeAll()
                touchDownTimes.removeAll()
                touchPositionsAtTapDown.removeAll()
                suppressedTouchIds.removeAll()
                pendingTipTap = nil
                initialSpread = nil
                minSpreadDelta = 0
                maxSpreadDelta = 0
                hasTriggeredPinch = false
                maxSimultaneousFingers = 0
            }
        }
    }

    /// Evaluate what gesture was made when fingers lift
    private func evaluateCompletedGesture(duration: Double, timestamp: Double) {
        let fingerCount = maxSimultaneousFingers

        // Check for 2-finger or 3-finger pinch/spread (if not already triggered live)
        if !hasTriggeredPinch && fingerCount >= 2 {
            if minSpreadDelta <= -pinchMinDelta {
                hasTriggeredPinch = true
                if fingerCount == 2 {
                    delegate?.gestureRecognizerDidDetect(gesture: .twoFingerPinchIn)
                    return
                } else if fingerCount == 3 {
                    delegate?.gestureRecognizerDidDetect(gesture: .threeFingerPinchIn)
                    return
                }
            } else if maxSpreadDelta >= pinchMinDelta {
                hasTriggeredPinch = true
                if fingerCount == 2 {
                    delegate?.gestureRecognizerDidDetect(gesture: .twoFingerPinchOut)
                    return
                } else if fingerCount == 3 {
                    delegate?.gestureRecognizerDidDetect(gesture: .threeFingerPinchOut)
                    return
                }
            }
        }

        // Calculate average displacement across fingers
        var totalDx: Float = 0
        var totalDy: Float = 0
        var count: Float = 0

        for (id, initial) in initialTouches {
            if let final = currentTouches[id] ?? initialTouches[id] {
                totalDx += (final.x - initial.x)
                totalDy += (final.y - initial.y)
                count += 1
            }
        }

        let avgDx = count > 0 ? (totalDx / count) : 0
        let avgDy = count > 0 ? (totalDy / count) : 0
        let distance = sqrt(avgDx * avgDx + avgDy * avgDy)

        // Check for Swipes
        if distance >= swipeMinDistance {
            if abs(avgDx) > abs(avgDy) {
                // Horizontal Swipe
                if avgDx > 0 {
                    dispatchSwipe(fingerCount: fingerCount, direction: .right)
                } else {
                    dispatchSwipe(fingerCount: fingerCount, direction: .left)
                }
            } else {
                // Vertical Swipe
                if avgDy > 0 {
                    dispatchSwipe(fingerCount: fingerCount, direction: .up)
                } else {
                    dispatchSwipe(fingerCount: fingerCount, direction: .down)
                }
            }
            return
        }

        // Check for Taps
        if duration <= tapMaxDuration && distance < tapMaxMovement {
            if (timestamp - lastTapTime) < 0.38 && lastTapFingerCount == fingerCount {
                consecutiveTapCount += 1
            } else {
                consecutiveTapCount = 1
            }

            lastTapTime = timestamp
            lastTapFingerCount = fingerCount

            switch consecutiveTapCount {
            case 1:
                dispatchTap(fingerCount: fingerCount)
            case 2:
                dispatchDoubleTap(fingerCount: fingerCount)
            case 3:
                dispatchTripleTap(fingerCount: fingerCount)
                consecutiveTapCount = 0
                lastTapTime = 0
            default:
                consecutiveTapCount = 0
                lastTapTime = 0
            }
            return
        }
    }

    private enum Direction {
        case left, right, up, down
    }

    private func dispatchSwipe(fingerCount: Int, direction: Direction) {
        switch (fingerCount, direction) {
        case (1, .left): delegate?.gestureRecognizerDidDetect(gesture: .oneFingerSwipeLeft)
        case (1, .right): delegate?.gestureRecognizerDidDetect(gesture: .oneFingerSwipeRight)
        case (1, .up): delegate?.gestureRecognizerDidDetect(gesture: .oneFingerSwipeUp)
        case (1, .down): delegate?.gestureRecognizerDidDetect(gesture: .oneFingerSwipeDown)

        case (2, .left): delegate?.gestureRecognizerDidDetect(gesture: .twoFingerSwipeLeft)
        case (2, .right): delegate?.gestureRecognizerDidDetect(gesture: .twoFingerSwipeRight)
        case (2, .up): delegate?.gestureRecognizerDidDetect(gesture: .twoFingerSwipeUp)
        case (2, .down): delegate?.gestureRecognizerDidDetect(gesture: .twoFingerSwipeDown)

        case (3, .left): delegate?.gestureRecognizerDidDetect(gesture: .threeFingerSwipeLeft)
        case (3, .right): delegate?.gestureRecognizerDidDetect(gesture: .threeFingerSwipeRight)
        case (3, .up): delegate?.gestureRecognizerDidDetect(gesture: .threeFingerSwipeUp)
        case (3, .down): delegate?.gestureRecognizerDidDetect(gesture: .threeFingerSwipeDown)

        case (4, .left): delegate?.gestureRecognizerDidDetect(gesture: .fourFingerSwipeLeft)
        case (4, .right): delegate?.gestureRecognizerDidDetect(gesture: .fourFingerSwipeRight)
        case (4, .up): delegate?.gestureRecognizerDidDetect(gesture: .fourFingerSwipeUp)
        case (4, .down): delegate?.gestureRecognizerDidDetect(gesture: .fourFingerSwipeDown)
        default: break
        }
    }

    private func dispatchTap(fingerCount: Int) {
        switch fingerCount {
        case 1:
            let tapX = initialTouches.values.first?.x ?? (currentTouches.values.first?.x ?? 0.5)
            if tapX < 0.50 {
                delegate?.gestureRecognizerDidDetect(gesture: .oneFingerTapLeft)
            } else {
                delegate?.gestureRecognizerDidDetect(gesture: .oneFingerTapRight)
            }
        case 2: delegate?.gestureRecognizerDidDetect(gesture: .twoFingerTap)
        case 3: delegate?.gestureRecognizerDidDetect(gesture: .threeFingerTap)
        case 4: delegate?.gestureRecognizerDidDetect(gesture: .fourFingerTap)
        default: break
        }
    }

    private func dispatchDoubleTap(fingerCount: Int) {
        switch fingerCount {
        case 1:
            let tapX = initialTouches.values.first?.x ?? (currentTouches.values.first?.x ?? 0.5)
            if tapX < 0.50 {
                delegate?.gestureRecognizerDidDetect(gesture: .oneFingerDoubleTapLeft)
            } else {
                delegate?.gestureRecognizerDidDetect(gesture: .oneFingerDoubleTapRight)
            }
            delegate?.gestureRecognizerDidDetect(gesture: .oneFingerDoubleTap)
        case 2:
            delegate?.gestureRecognizerDidDetect(gesture: .twoFingerDoubleTap)
        case 3:
            delegate?.gestureRecognizerDidDetect(gesture: .threeFingerDoubleTap)
        default:
            break
        }
    }

    private func dispatchTripleTap(fingerCount: Int) {
        switch fingerCount {
        case 1:
            let tapX = initialTouches.values.first?.x ?? (currentTouches.values.first?.x ?? 0.5)
            if tapX < 0.50 {
                delegate?.gestureRecognizerDidDetect(gesture: .oneFingerTripleTapLeft)
            } else {
                delegate?.gestureRecognizerDidDetect(gesture: .oneFingerTripleTapRight)
            }
            delegate?.gestureRecognizerDidDetect(gesture: .oneFingerTripleTap)
        case 2:
            delegate?.gestureRecognizerDidDetect(gesture: .twoFingerTripleTap)
        case 3:
            delegate?.gestureRecognizerDidDetect(gesture: .threeFingerTripleTap)
        default:
            break
        }
    }

    /// Process a physical mouse click intercepted via CGEventTap or mouse hook
    public func processPhysicalClick() {
        let fingers = currentTouches.count > 0 ? currentTouches.count : maxSimultaneousFingers
        switch fingers {
        case 1:
            delegate?.gestureRecognizerDidDetect(gesture: .oneFingerClick)
        case 2:
            delegate?.gestureRecognizerDidDetect(gesture: .twoFingerClick)
        case 3:
            delegate?.gestureRecognizerDidDetect(gesture: .threeFingerClick)
        case 4:
            delegate?.gestureRecognizerDidDetect(gesture: .fourFingerClick)
        default:
            break
        }
    }
}
