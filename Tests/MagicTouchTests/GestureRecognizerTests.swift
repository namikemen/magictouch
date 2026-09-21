import XCTest
@testable import MagicTouch

final class GestureRecognizerTests: XCTestCase, GestureRecognizerDelegate {
    private var lastDetectedGesture: GestureType?
    private var updatedTouches: [TouchPoint] = []

    func gestureRecognizerDidDetect(gesture: GestureType) {
        self.lastDetectedGesture = gesture
    }

    func gestureRecognizerDidUpdateTouches(touches: [TouchPoint]) {
        self.updatedTouches = touches
    }

    func testThreeFingerTapDetection() {
        let recognizer = GestureRecognizer()
        recognizer.delegate = self

        // Simulate 3 fingers landing on mouse surface
        let touchesDown = [
            TouchPoint(id: 1, x: 0.3, y: 0.7),
            TouchPoint(id: 2, x: 0.5, y: 0.7),
            TouchPoint(id: 3, x: 0.7, y: 0.7)
        ]
        recognizer.processFrame(touches: touchesDown, timestamp: 1.0)

        // Simulate small movement during tap
        let touchesHold = [
            TouchPoint(id: 1, x: 0.31, y: 0.7),
            TouchPoint(id: 2, x: 0.51, y: 0.7),
            TouchPoint(id: 3, x: 0.71, y: 0.7)
        ]
        recognizer.processFrame(touches: touchesHold, timestamp: 1.1)

        // All fingers lifted within 200ms
        recognizer.processFrame(touches: [], timestamp: 1.2)

        XCTAssertEqual(lastDetectedGesture, .threeFingerTap)
    }

    func testTwoFingerSwipeRightDetection() {
        let recognizer = GestureRecognizer()
        recognizer.delegate = self

        // 2 fingers land
        let startTouches = [
            TouchPoint(id: 1, x: 0.3, y: 0.5),
            TouchPoint(id: 2, x: 0.5, y: 0.5)
        ]
        recognizer.processFrame(touches: startTouches, timestamp: 2.0)

        // Move significantly to the right (> swipeMinDistance)
        let moveTouches = [
            TouchPoint(id: 1, x: 0.65, y: 0.51),
            TouchPoint(id: 2, x: 0.85, y: 0.51)
        ]
        recognizer.processFrame(touches: moveTouches, timestamp: 2.15)

        // Release fingers
        recognizer.processFrame(touches: [], timestamp: 2.2)

        XCTAssertEqual(lastDetectedGesture, .twoFingerSwipeRight)
    }

    func testPhysicalClickSimulation() {
        let recognizer = GestureRecognizer()
        recognizer.delegate = self

        // 3 fingers resting when click happens
        let restingTouches = [
            TouchPoint(id: 1, x: 0.3, y: 0.5),
            TouchPoint(id: 2, x: 0.5, y: 0.5),
            TouchPoint(id: 3, x: 0.7, y: 0.5)
        ]
        recognizer.processFrame(touches: restingTouches, timestamp: 3.0)
        recognizer.processPhysicalClick()

        XCTAssertEqual(lastDetectedGesture, .threeFingerClick)
    }
}
