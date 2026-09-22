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
    func gestureRecognizerDidStartDrag()
    func gestureRecognizerDidEndDrag()
}

public extension GestureRecognizerDelegate {
    func gestureRecognizerDidStartDrag() {}
    func gestureRecognizerDidEndDrag() {}
}

/// Gesture recognition state machine
public final class GestureRecognizer {
    public weak var delegate: GestureRecognizerDelegate?

    // Tracking active touch paths
    private var initialTouches: [Int: TouchPoint] = [:]
    private var currentTouches: [Int: TouchPoint] = [:]
    private var lastKnownTouches: [Int: TouchPoint] = [:]
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
    private let pinchMinDelta: Float = 0.08

    // Hold-to-drag tracking (Tap and hold 1 finger)
    private var isDragging: Bool = false
    private var isPotentialDragHold: Bool = false
    private var potentialDragHoldStartTime: Double = 0

    // Thresholds tuned for Magic Mouse surface dimensions
    private let oneFingerTapMinDuration: Double = 0.04   // seconds (filters micro-contact jitter)
    private let oneFingerTapMaxDuration: Double = 0.30   // seconds
    private let oneFingerTapMaxMovement: Float = 0.065   // normalized distance

    // Multi-finger tap thresholds
    private let multiFingerTapMinDuration: Double = 0.035
    private let multiFingerTapMaxDuration: Double = 0.35
    private let multiFingerTapMaxMovement: Float = 0.10

    // Swipe threshold
    private let swipeMinDistance: Float = 0.09          // normalized distance

    // Multi-tap tracker
    private var lastTapTime: Double = 0
    private var lastTapFingerCount: Int = 0
    private var consecutiveTapCount: Int = 0
    private var hasPhysicalClickedInCurrentSession = false

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
                    lastKnownTouches.removeValue(forKey: pending.liftedId)
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
            // Keep persistent record of the most recent coordinate of every touch in this session
            for t in touches {
                lastKnownTouches[t.id] = t
            }

            if initialTouches.isEmpty {
                // New gesture session began
                touchStartTime = timestamp
                maxSimultaneousFingers = activeFingers
                for t in touches {
                    initialTouches[t.id] = t
                    touchDownTimes[t.id] = timestamp
                }

                // Check for Tap-and-Hold Drag: previous single tap lifted recently, now 1 finger down again
                if activeFingers == 1 && (timestamp - lastTapTime) <= 0.32 && lastTapFingerCount == 1 {
                    isPotentialDragHold = true
                    potentialDragHoldStartTime = timestamp
                } else {
                    isPotentialDragHold = false
                }
            } else {
                if activeFingers > maxSimultaneousFingers {
                    maxSimultaneousFingers = activeFingers
                }
                if activeFingers != 1 {
                    isPotentialDragHold = false
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

            // Track spread changes across 2 or 3 active fingers
            if activeFingers >= 2 {
                let spread = calculateSpread(touches: touches)
                if initialSpread == nil {
                    initialSpread = spread
                }
                if let base = initialSpread {
                    let delta = spread - base
                    if delta < minSpreadDelta { minSpreadDelta = delta }
                    if delta > maxSpreadDelta { maxSpreadDelta = delta }
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
                            lastKnownTouches.removeValue(forKey: liftedId)
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

            // If held down for >= 220ms during tap-and-hold, engage drag!
            if isPotentialDragHold && !isDragging && activeFingers == 1 {
                if (timestamp - potentialDragHoldStartTime) >= 0.22 {
                    isDragging = true
                    delegate?.gestureRecognizerDidStartDrag()
                    delegate?.gestureRecognizerDidDetect(gesture: .holdToDrag)
                }
            }

            currentTouches.removeAll()
            for t in touches {
                currentTouches[t.id] = t
            }
        } else {
            // All fingers lifted: evaluate gesture session
            if isDragging {
                isDragging = false
                isPotentialDragHold = false
                delegate?.gestureRecognizerDidEndDrag()
                consecutiveTapCount = 0
                lastTapTime = 0
                initialTouches.removeAll()
                currentTouches.removeAll()
                lastKnownTouches.removeAll()
                touchDownTimes.removeAll()
                touchPositionsAtTapDown.removeAll()
                suppressedTouchIds.removeAll()
                pendingTipTap = nil
                initialSpread = nil
                minSpreadDelta = 0
                maxSpreadDelta = 0
                hasTriggeredPinch = false
                maxSimultaneousFingers = 0
                return
            }
            isPotentialDragHold = false
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
                lastKnownTouches.removeAll()
                touchDownTimes.removeAll()
                touchPositionsAtTapDown.removeAll()
                suppressedTouchIds.removeAll()
                pendingTipTap = nil
                initialSpread = nil
                minSpreadDelta = 0
                maxSpreadDelta = 0
                hasTriggeredPinch = false
                maxSimultaneousFingers = 0
                hasPhysicalClickedInCurrentSession = false
            }
        }
    }

    /// Evaluate what gesture was made when fingers lift
    private func evaluateCompletedGesture(duration: Double, timestamp: Double) {
        if hasPhysicalClickedInCurrentSession {
            return
        }
        let fingerCount = maxSimultaneousFingers

        // Calculate average displacement across fingers, using lastKnownTouches for lifted fingers
        var totalDx: Float = 0
        var totalDy: Float = 0
        var count: Float = 0

        for (id, initial) in initialTouches {
            if let final = lastKnownTouches[id] ?? currentTouches[id] ?? initialTouches[id] {
                let dx = (final.x - initial.x)
                let dy = (final.y - initial.y)
                totalDx += dx
                totalDy += dy
                count += 1
            }
        }

        let avgDx = count > 0 ? (totalDx / count) : 0
        let avgDy = count > 0 ? (totalDy / count) : 0
        let distance = sqrt(avgDx * avgDx + avgDy * avgDy)

        // 1. 2-Finger Gestures (Accurately distinguish Swipe Left/Right/Up/Down vs Pinch In/Out)
        if fingerCount == 2 {
            let sorted = initialTouches.values.sorted { $0.x < $1.x }
            if sorted.count == 2 {
                let leftInit = sorted[0]
                let rightInit = sorted[1]
                let leftFinal = lastKnownTouches[leftInit.id] ?? currentTouches[leftInit.id] ?? leftInit
                let rightFinal = lastKnownTouches[rightInit.id] ?? currentTouches[rightInit.id] ?? rightInit

                let leftDx = leftFinal.x - leftInit.x
                let rightDx = rightFinal.x - rightInit.x
                let leftDy = leftFinal.y - leftInit.y
                let rightDy = rightFinal.y - rightInit.y

                let avgDx = (leftDx + rightDx) / 2.0
                let avgDy = (leftDy + rightDy) / 2.0
                let centroidTranslation = hypot(avgDx, avgDy)
                let spreadDelta = minSpreadDelta

                // --- 2-FINGER PINCH IN ---
                // Convergence requirements:
                // 1. Symmetric pinch: both fingers move toward each other (left moves right, right moves left).
                let isSymmetricPinchIn = (leftDx >= 0.020 && rightDx <= -0.020)
                
                // 2. Left finger anchored: left finger remains still while right finger sweeps inward.
                let isLeftAnchoredPinchIn = (leftDx >= -0.015) &&
                                           (hypot(leftDx, leftDy) <= 0.028) &&
                                           (rightDx <= -0.065) &&
                                           (abs(spreadDelta) >= centroidTranslation * 1.35)
                
                // 3. Right finger anchored: right finger remains still while left finger sweeps inward.
                let isRightAnchoredPinchIn = (rightDx <= 0.015) &&
                                            (hypot(rightDx, rightDy) <= 0.028) &&
                                            (leftDx >= 0.065) &&
                                            (abs(spreadDelta) >= centroidTranslation * 1.35)
                
                if spreadDelta <= -pinchMinDelta && (isSymmetricPinchIn || isLeftAnchoredPinchIn || isRightAnchoredPinchIn) {
                    delegate?.gestureRecognizerDidDetect(gesture: .twoFingerPinchIn)
                    return
                }

                // --- 2-FINGER PINCH OUT ---
                // Spreading requirements:
                let isSymmetricPinchOut = (leftDx <= -0.020 && rightDx >= 0.020)
                let isLeftAnchoredPinchOut = (leftDx <= 0.015) &&
                                            (hypot(leftDx, leftDy) <= 0.028) &&
                                            (rightDx >= 0.065) &&
                                            (abs(maxSpreadDelta) >= centroidTranslation * 1.35)
                let isRightAnchoredPinchOut = (rightDx >= -0.015) &&
                                             (hypot(rightDx, rightDy) <= 0.028) &&
                                             (leftDx <= -0.065) &&
                                             (abs(maxSpreadDelta) >= centroidTranslation * 1.35)

                if maxSpreadDelta >= pinchMinDelta && (isSymmetricPinchOut || isLeftAnchoredPinchOut || isRightAnchoredPinchOut) {
                    delegate?.gestureRecognizerDidDetect(gesture: .twoFingerPinchOut)
                    return
                }

                // --- 2-FINGER SWIPE LEFT ---
                // Parallel translation to the left:
                // 1. Leading finger (left) moved left (or stayed at left edge if started at x <= 0.22)
                let isLeftFingerMovingLeft = (leftDx <= -0.025) || (leftInit.x <= 0.22 && leftDx <= 0.005)
                // 2. Trailing finger (right) moved left
                let isRightFingerMovingLeft = (rightDx <= -0.045)
                // 3. Overall motion is leftward and predominantly horizontal
                let isOverallSwipeLeft = (avgDx <= -0.055) && (abs(avgDx) > abs(avgDy))

                if isLeftFingerMovingLeft && isRightFingerMovingLeft && isOverallSwipeLeft {
                    dispatchSwipe(fingerCount: 2, direction: .left)
                    return
                }

                // --- 2-FINGER SWIPE RIGHT ---
                let isRightFingerMovingRight = (rightDx >= 0.025) || (rightInit.x >= 0.78 && rightDx >= -0.005)
                let isLeftFingerMovingRight = (leftDx >= 0.045)
                let isOverallSwipeRight = (avgDx >= 0.055) && (abs(avgDx) > abs(avgDy))

                if isLeftFingerMovingRight && isRightFingerMovingRight && isOverallSwipeRight {
                    dispatchSwipe(fingerCount: 2, direction: .right)
                    return
                }

                // --- 2-FINGER SWIPE UP ---
                if avgDy >= 0.060 && leftDy >= 0.025 && rightDy >= 0.025 && abs(avgDy) >= abs(avgDx) {
                    dispatchSwipe(fingerCount: 2, direction: .up)
                    return
                }

                // --- 2-FINGER SWIPE DOWN ---
                if avgDy <= -0.060 && leftDy <= -0.025 && rightDy <= -0.025 && abs(avgDy) >= abs(avgDx) {
                    dispatchSwipe(fingerCount: 2, direction: .down)
                    return
                }
            }
        } else if fingerCount >= 3 && distance >= swipeMinDistance {
            // General 3 or 4-finger swipe
            if abs(avgDx) > abs(avgDy) {
                if avgDx > 0 { dispatchSwipe(fingerCount: fingerCount, direction: .right) }
                else { dispatchSwipe(fingerCount: fingerCount, direction: .left) }
            } else {
                if avgDy > 0 { dispatchSwipe(fingerCount: fingerCount, direction: .up) }
                else { dispatchSwipe(fingerCount: fingerCount, direction: .down) }
            }
            return
        } else if fingerCount == 1 && distance >= swipeMinDistance {
            // 1-finger swipe
            if abs(avgDx) > abs(avgDy) {
                if avgDx > 0 { dispatchSwipe(fingerCount: 1, direction: .right) }
                else { dispatchSwipe(fingerCount: 1, direction: .left) }
            } else {
                if avgDy > 0 { dispatchSwipe(fingerCount: 1, direction: .up) }
                else { dispatchSwipe(fingerCount: 1, direction: .down) }
            }
            return
        }

        // 2. Check for Taps
        let isTap: Bool
        if fingerCount == 1 {
            isTap = duration >= oneFingerTapMinDuration &&
                    duration <= oneFingerTapMaxDuration &&
                    distance < oneFingerTapMaxMovement
        } else {
            // Multi-finger tap: 35ms - 350ms and movement < 0.10
            isTap = duration >= multiFingerTapMinDuration &&
                    duration <= multiFingerTapMaxDuration &&
                    distance < multiFingerTapMaxMovement
        }

        if isTap {
            if (timestamp - lastTapTime) < 0.35 && lastTapFingerCount == fingerCount {
                // Reject rapid capacitive contact bounce (< 120ms) for multi-finger taps
                if (timestamp - lastTapTime) < 0.12 && fingerCount >= 2 {
                    return
                }
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
        hasPhysicalClickedInCurrentSession = true
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
