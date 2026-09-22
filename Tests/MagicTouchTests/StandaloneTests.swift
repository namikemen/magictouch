import Foundation

final class GestureRecognizerTestsRunner: GestureRecognizerDelegate {
    private var lastDetectedGesture: GestureType?
    private var detectedGestures: [GestureType] = []
    private var updatedTouches: [TouchPoint] = []

    func gestureRecognizerDidDetect(gesture: GestureType) {
        self.lastDetectedGesture = gesture
        self.detectedGestures.append(gesture)
    }

    func gestureRecognizerDidUpdateTouches(touches: [TouchPoint]) {
        self.updatedTouches = touches
    }

    func assertEqual<T: Equatable>(_ actual: T?, _ expected: T, _ message: String) {
        if actual == expected {
            print("  ✅ PASS: \(message)")
        } else {
            print("  ❌ FAIL: \(message) - Expected \(expected), got \(String(describing: actual))")
            exit(1)
        }
    }

    func testThreeFingerTapDetection() {
        print("Running: Three Finger Tap Detection...")
        let recognizer = GestureRecognizer()
        recognizer.delegate = self

        let touchesDown = [
            TouchPoint(id: 1, x: 0.3, y: 0.7),
            TouchPoint(id: 2, x: 0.5, y: 0.7),
            TouchPoint(id: 3, x: 0.7, y: 0.7)
        ]
        recognizer.processFrame(touches: touchesDown, timestamp: 1.0)

        let touchesHold = [
            TouchPoint(id: 1, x: 0.31, y: 0.7),
            TouchPoint(id: 2, x: 0.51, y: 0.7),
            TouchPoint(id: 3, x: 0.71, y: 0.7)
        ]
        recognizer.processFrame(touches: touchesHold, timestamp: 1.1)
        recognizer.processFrame(touches: [], timestamp: 1.2)

        assertEqual(lastDetectedGesture, .threeFingerTap, "Detected 3-finger tap")
    }

    func testTwoFingerSwipeRightDetection() {
        print("Running: Two Finger Swipe Right Detection...")
        let recognizer = GestureRecognizer()
        recognizer.delegate = self

        let startTouches = [
            TouchPoint(id: 1, x: 0.3, y: 0.5),
            TouchPoint(id: 2, x: 0.5, y: 0.5)
        ]
        recognizer.processFrame(touches: startTouches, timestamp: 2.0)

        let moveTouches = [
            TouchPoint(id: 1, x: 0.65, y: 0.51),
            TouchPoint(id: 2, x: 0.85, y: 0.51)
        ]
        recognizer.processFrame(touches: moveTouches, timestamp: 2.15)
        recognizer.processFrame(touches: [], timestamp: 2.2)

        assertEqual(lastDetectedGesture, .twoFingerSwipeRight, "Detected 2-finger swipe right")
    }

    func testTwoFingerSwipeLeftWithNaturalCompressionNotPinchIn() {
        print("Running: Two Finger Swipe Left with Natural Finger Compression (not Pinch In)...")
        let recognizer = GestureRecognizer()
        recognizer.delegate = self
        lastDetectedGesture = nil

        // User places 2 fingers on right side: spread = 0.20
        let startTouches = [
            TouchPoint(id: 1, x: 0.70, y: 0.50),
            TouchPoint(id: 2, x: 0.50, y: 0.50)
        ]
        recognizer.processFrame(touches: startTouches, timestamp: 2.5)

        // Hand swipes left across curved surface, fingers naturally compress to spread = 0.13 (delta = -0.07)
        let moveTouches = [
            TouchPoint(id: 1, x: 0.45, y: 0.51),
            TouchPoint(id: 2, x: 0.32, y: 0.51)
        ]
        recognizer.processFrame(touches: moveTouches, timestamp: 2.65)
        recognizer.processFrame(touches: [], timestamp: 2.70)

        assertEqual(lastDetectedGesture, .twoFingerSwipeLeft, "Detected 2-finger swipe left rather than false pinch in")
    }

    func testTwoFingerSwipeLeftWithAsynchronousFingerLiftNotPinchIn() {
        print("Running: Two Finger Swipe Left with Asynchronous Finger Lift (not Pinch In)...")
        let recognizer = GestureRecognizer()
        recognizer.delegate = self
        lastDetectedGesture = nil

        // User starts swipe with 2 fingers
        recognizer.processFrame(touches: [
            TouchPoint(id: 1, x: 0.45, y: 0.50),
            TouchPoint(id: 2, x: 0.75, y: 0.50)
        ], timestamp: 2.0)

        // Mid-swipe: both fingers moving left
        recognizer.processFrame(touches: [
            TouchPoint(id: 1, x: 0.22, y: 0.50),
            TouchPoint(id: 2, x: 0.46, y: 0.50)
        ], timestamp: 2.15)

        // Asynchronous release: index finger (touch 1) lifts 20ms before middle finger (touch 2)
        recognizer.processFrame(touches: [
            TouchPoint(id: 2, x: 0.43, y: 0.50)
        ], timestamp: 2.17)

        // Trailing finger lifts
        recognizer.processFrame(touches: [], timestamp: 2.20)

        assertEqual(lastDetectedGesture, .twoFingerSwipeLeft, "Asynchronous finger lift correctly evaluated as swipe left, not pinch in")
    }

    func testTwoFingerSwipeLeftNearLeftEdgeNotPinchIn() {
        print("Running: Two Finger Swipe Left Starting Near Left Edge (not Pinch In)...")
        let recognizer = GestureRecognizer()
        recognizer.delegate = self
        lastDetectedGesture = nil

        // Leading finger starts near left curved edge
        recognizer.processFrame(touches: [
            TouchPoint(id: 1, x: 0.18, y: 0.50),
            TouchPoint(id: 2, x: 0.52, y: 0.50)
        ], timestamp: 3.0)

        // Leading finger reaches physical edge (dx = -0.05), trailing finger sweeps (dx = -0.26)
        // Spread compresses drastically from 0.34 to 0.13 (delta = -0.21)
        recognizer.processFrame(touches: [
            TouchPoint(id: 1, x: 0.13, y: 0.50),
            TouchPoint(id: 2, x: 0.26, y: 0.50)
        ], timestamp: 3.15)
        recognizer.processFrame(touches: [], timestamp: 3.20)

        assertEqual(lastDetectedGesture, .twoFingerSwipeLeft, "Heavy finger compression near edge recognized as swipe left, not pinch in")
    }

    func testOneFingerLongRestNotTap() {
        print("Running: 1-Finger Long Resting Finger Lift (must NOT trigger tap)...")
        let recognizer = GestureRecognizer()
        recognizer.delegate = self
        lastDetectedGesture = nil

        // User rests index finger on mouse for 450ms while moving/reading
        recognizer.processFrame(touches: [TouchPoint(id: 1, x: 0.30, y: 0.50)], timestamp: 10.0)
        recognizer.processFrame(touches: [TouchPoint(id: 1, x: 0.30, y: 0.50)], timestamp: 10.45)
        recognizer.processFrame(touches: [], timestamp: 10.46)

        assertEqual(lastDetectedGesture, nil, "Resting finger for 450ms does NOT trigger accidental tap")
    }

    func testOneFingerDriftNotTap() {
        print("Running: 1-Finger Hand Movement / Drift (must NOT trigger tap)...")
        let recognizer = GestureRecognizer()
        recognizer.delegate = self
        lastDetectedGesture = nil

        // User's finger drifts across 8.5% of surface while moving mouse
        recognizer.processFrame(touches: [TouchPoint(id: 1, x: 0.30, y: 0.50)], timestamp: 11.0)
        recognizer.processFrame(touches: [TouchPoint(id: 1, x: 0.385, y: 0.50)], timestamp: 11.15)
        recognizer.processFrame(touches: [], timestamp: 11.16)

        assertEqual(lastDetectedGesture, nil, "Finger drifting by 8.5% does NOT trigger accidental tap")
    }

    func testTwoFingerPinchInDetection() {
        print("Running: Two Finger Pinch In Detection...")
        let recognizer = GestureRecognizer()
        recognizer.delegate = self

        // 2 fingers wide apart
        let startTouches = [
            TouchPoint(id: 1, x: 0.2, y: 0.5),
            TouchPoint(id: 2, x: 0.8, y: 0.5)
        ]
        recognizer.processFrame(touches: startTouches, timestamp: 3.0)

        // Fingers come closer together
        let pinchedTouches = [
            TouchPoint(id: 1, x: 0.45, y: 0.5),
            TouchPoint(id: 2, x: 0.55, y: 0.5)
        ]
        recognizer.processFrame(touches: pinchedTouches, timestamp: 3.2)
        recognizer.processFrame(touches: [], timestamp: 3.3)

        assertEqual(lastDetectedGesture, .twoFingerPinchIn, "Detected 2-finger pinch in")
    }

    func testTwoFingerPinchOutDetection() {
        print("Running: Two Finger Pinch Out Detection...")
        let recognizer = GestureRecognizer()
        recognizer.delegate = self
        lastDetectedGesture = nil

        // Fingers start close together
        let startTouches = [
            TouchPoint(id: 1, x: 0.45, y: 0.5),
            TouchPoint(id: 2, x: 0.55, y: 0.5)
        ]
        recognizer.processFrame(touches: startTouches, timestamp: 4.0)

        // Fingers spread outward
        let spreadTouches = [
            TouchPoint(id: 1, x: 0.20, y: 0.5),
            TouchPoint(id: 2, x: 0.80, y: 0.5)
        ]
        recognizer.processFrame(touches: spreadTouches, timestamp: 4.2)
        recognizer.processFrame(touches: [], timestamp: 4.3)

        assertEqual(lastDetectedGesture, .twoFingerPinchOut, "Detected 2-finger pinch out")
    }

    func testHoldToDragDetection() {
        print("Running: Hold to Drag (Tap & Hold) Detection...")
        let recognizer = GestureRecognizer()
        recognizer.delegate = self
        lastDetectedGesture = nil

        // Step 1: Initial quick tap
        recognizer.processFrame(touches: [TouchPoint(id: 1, x: 0.5, y: 0.5, totalSize: 0.2)], timestamp: 10.0)
        recognizer.processFrame(touches: [], timestamp: 10.08)

        // Step 2: Touch down again within 200ms and hold for >= 220ms
        recognizer.processFrame(touches: [TouchPoint(id: 1, x: 0.5, y: 0.5, totalSize: 0.25)], timestamp: 10.20)
        recognizer.processFrame(touches: [TouchPoint(id: 1, x: 0.52, y: 0.51, totalSize: 0.25)], timestamp: 10.43)

        assertEqual(lastDetectedGesture, .holdToDrag, "Detected Hold to Drag on tap-and-hold")

        // Step 3: Release finger ends drag
        recognizer.processFrame(touches: [], timestamp: 10.50)
    }

    func testAsymmetricalPinchInNotSwipe() {
        print("Running: Asymmetrical Pinch In Distinction from Swipe...")
        let recognizer = GestureRecognizer()
        recognizer.delegate = self
        lastDetectedGesture = nil

        // Finger 1 stays relatively still while finger 2 moves inward significantly
        let startTouches = [
            TouchPoint(id: 1, x: 0.30, y: 0.5),
            TouchPoint(id: 2, x: 0.70, y: 0.5)
        ]
        recognizer.processFrame(touches: startTouches, timestamp: 7.0)

        let movedTouches = [
            TouchPoint(id: 1, x: 0.31, y: 0.5),
            TouchPoint(id: 2, x: 0.45, y: 0.5)
        ]
        recognizer.processFrame(touches: movedTouches, timestamp: 7.2)
        recognizer.processFrame(touches: [], timestamp: 7.3)

        assertEqual(lastDetectedGesture, .twoFingerPinchIn, "Asymmetrical finger closure recognized as pinch in rather than swipe")
    }

    func testPhysicalClickSimulation() {
        print("Running: Physical Click Simulation...")
        let recognizer = GestureRecognizer()
        recognizer.delegate = self

        let restingTouches = [
            TouchPoint(id: 1, x: 0.3, y: 0.5),
            TouchPoint(id: 2, x: 0.5, y: 0.5),
            TouchPoint(id: 3, x: 0.7, y: 0.5)
        ]
        recognizer.processFrame(touches: restingTouches, timestamp: 4.0)
        recognizer.processPhysicalClick()

        assertEqual(lastDetectedGesture, .threeFingerClick, "Detected 3-finger physical surface click")
    }

    func testTipTapRightDetection() {
        print("Running: Tip-Tap Right (Rest Left, Tap Right) Detection...")
        let recognizer = GestureRecognizer()
        recognizer.delegate = self
        lastDetectedGesture = nil

        // Left finger (id 1) rests on mouse for 1.0 second
        recognizer.processFrame(touches: [TouchPoint(id: 1, x: 0.30, y: 0.50)], timestamp: 10.0)
        recognizer.processFrame(touches: [TouchPoint(id: 1, x: 0.30, y: 0.50)], timestamp: 10.5)

        // Right finger (id 2) taps down
        recognizer.processFrame(touches: [
            TouchPoint(id: 1, x: 0.30, y: 0.50),
            TouchPoint(id: 2, x: 0.70, y: 0.50)
        ], timestamp: 11.0)

        // Right finger (id 2) lifts 150ms later while left finger (id 1) stays resting
        recognizer.processFrame(touches: [TouchPoint(id: 1, x: 0.30, y: 0.50)], timestamp: 11.15)

        assertEqual(lastDetectedGesture, .tipTapRight, "Detected Tip-Tap Right when tapping right finger while left finger rests")

        // Reset tracking to verify resting finger lift does NOT produce a false 1-finger tap
        lastDetectedGesture = nil
        recognizer.processFrame(touches: [], timestamp: 11.5)
        assertEqual(lastDetectedGesture, nil, "Resting finger lift does NOT trigger spurious 1-finger tap")
    }

    func testTipTapLeftDetection() {
        print("Running: Tip-Tap Left (Rest Right, Tap Left) Detection...")
        let recognizer = GestureRecognizer()
        recognizer.delegate = self
        lastDetectedGesture = nil

        // Right finger (id 2) rests on mouse
        recognizer.processFrame(touches: [TouchPoint(id: 2, x: 0.70, y: 0.50)], timestamp: 12.0)
        recognizer.processFrame(touches: [TouchPoint(id: 2, x: 0.70, y: 0.50)], timestamp: 12.5)

        // Left finger (id 1) taps down
        recognizer.processFrame(touches: [
            TouchPoint(id: 1, x: 0.30, y: 0.50),
            TouchPoint(id: 2, x: 0.70, y: 0.50)
        ], timestamp: 13.0)

        // Left finger (id 1) lifts 150ms later while right finger (id 2) stays resting
        recognizer.processFrame(touches: [TouchPoint(id: 2, x: 0.70, y: 0.50)], timestamp: 13.15)

        assertEqual(lastDetectedGesture, .tipTapLeft, "Detected Tip-Tap Left when tapping left finger while right finger rests")

        // Reset tracking to verify resting finger lift does NOT produce a false 1-finger tap
        lastDetectedGesture = nil
        recognizer.processFrame(touches: [], timestamp: 13.5)
        assertEqual(lastDetectedGesture, nil, "Resting finger lift does NOT trigger spurious 1-finger tap")
    }

    func testDoubleTipTapRight() {
        print("Running: Consecutive Double Tip-Tap Right Detection...")
        let recognizer = GestureRecognizer()
        recognizer.delegate = self
        lastDetectedGesture = nil

        // Finger 1 rests
        recognizer.processFrame(touches: [TouchPoint(id: 1, x: 0.30, y: 0.50)], timestamp: 14.0)

        // First tap with finger 2
        recognizer.processFrame(touches: [TouchPoint(id: 1, x: 0.30, y: 0.50), TouchPoint(id: 2, x: 0.70, y: 0.50)], timestamp: 14.3)
        recognizer.processFrame(touches: [TouchPoint(id: 1, x: 0.30, y: 0.50)], timestamp: 14.45)
        assertEqual(lastDetectedGesture, .tipTapRight, "First Tip-Tap Right detected")

        lastDetectedGesture = nil

        // Second tap with finger 2 while finger 1 still resting
        recognizer.processFrame(touches: [TouchPoint(id: 1, x: 0.30, y: 0.50), TouchPoint(id: 2, x: 0.70, y: 0.50)], timestamp: 14.7)
        recognizer.processFrame(touches: [TouchPoint(id: 1, x: 0.30, y: 0.50)], timestamp: 14.85)
        assertEqual(lastDetectedGesture, .tipTapRight, "Second consecutive Tip-Tap Right detected")

        // Lift resting finger
        lastDetectedGesture = nil
        recognizer.processFrame(touches: [], timestamp: 15.0)
        assertEqual(lastDetectedGesture, nil, "No spurious tap after multiple tip-taps")
    }

    func testTwoFingerTapNotTipTap() {
        print("Running: Two Finger Tap distinction from Tip-Tap...")
        let recognizer = GestureRecognizer()
        recognizer.delegate = self
        lastDetectedGesture = nil

        // Both fingers touch down at same time
        recognizer.processFrame(touches: [
            TouchPoint(id: 1, x: 0.30, y: 0.50),
            TouchPoint(id: 2, x: 0.70, y: 0.50)
        ], timestamp: 16.0)

        // Finger 1 lifts slightly earlier (20ms) than finger 2
        recognizer.processFrame(touches: [TouchPoint(id: 2, x: 0.70, y: 0.50)], timestamp: 16.15)
        // Finger 2 lifts immediately after (16.17)
        recognizer.processFrame(touches: [], timestamp: 16.17)

        assertEqual(lastDetectedGesture, .twoFingerTap, "Simultaneous touchdown with staggered lift recognized as 2-finger tap")
    }

    func testMouseButtonMappings() {
        print("Running: Left Click, Right Click, Double Click & Triple Click Mouse Button Mappings...")
        let testGestureLeft = GestureType.oneFingerDoubleTap
        let testGestureRight = GestureType.oneFingerSwipeUp
        let testGestureDouble = GestureType.fourFingerSwipeUp
        let testGestureTriple = GestureType.fourFingerSwipeDown

        let leftMapping = GestureMapping(gesture: testGestureLeft, action: .mouseButton(button: .leftClick))
        let rightMapping = GestureMapping(gesture: testGestureRight, action: .mouseButton(button: .rightClick))
        let doubleMapping = GestureMapping(gesture: testGestureDouble, action: .mouseButton(button: .doubleClick))
        let tripleMapping = GestureMapping(gesture: testGestureTriple, action: .mouseButton(button: .tripleClick))

        assertEqual(leftMapping.action.displayName, "Mouse: Left Click (Button 1)", "Left click display name format")
        assertEqual(rightMapping.action.displayName, "Mouse: Right Click (Button 2 / Secondary)", "Right click display name format")
        assertEqual(doubleMapping.action.displayName, "Mouse: Double Click", "Double click display name format")
        assertEqual(tripleMapping.action.displayName, "Mouse: Triple Click (Select Line)", "Triple click display name format")

        let store = ConfigurationStore.shared
        store.mappings.removeAll(where: {
            $0.gesture == testGestureLeft || $0.gesture == testGestureRight ||
            $0.gesture == testGestureDouble || $0.gesture == testGestureTriple
        })
        store.addMapping(leftMapping)
        store.addMapping(rightMapping)
        store.addMapping(doubleMapping)
        store.addMapping(tripleMapping)

        assertEqual(store.actionForGesture(testGestureLeft), .mouseButton(button: .leftClick), "Store resolves left click mapping")
        assertEqual(store.actionForGesture(testGestureRight), .mouseButton(button: .rightClick), "Store resolves right click mapping")
        assertEqual(store.actionForGesture(testGestureDouble), .mouseButton(button: .doubleClick), "Store resolves double click mapping")
        assertEqual(store.actionForGesture(testGestureTriple), .mouseButton(button: .tripleClick), "Store resolves triple click mapping")

        // Test safe deletion by ID
        store.deleteMapping(id: leftMapping.id)
        store.deleteMapping(id: rightMapping.id)
        store.deleteMapping(id: doubleMapping.id)
        store.deleteMapping(id: tripleMapping.id)
        assertEqual(store.actionForGesture(testGestureDouble), nil, "Double click mapping deleted safely")
    }

    func testOneFingerTapLeftDetection() {
        print("Running: 1-Finger Tap Left Detection...")
        let recognizer = GestureRecognizer()
        recognizer.delegate = self
        lastDetectedGesture = nil

        let touchDown = [TouchPoint(id: 1, x: 0.25, y: 0.50)]
        recognizer.processFrame(touches: touchDown, timestamp: 20.0)
        recognizer.processFrame(touches: [TouchPoint(id: 1, x: 0.26, y: 0.50)], timestamp: 20.10)
        recognizer.processFrame(touches: [], timestamp: 20.15)

        assertEqual(lastDetectedGesture, .oneFingerTapLeft, "Detected 1-Finger Tap Left for touch at x = 0.25")
    }

    func testOneFingerTapRightDetection() {
        print("Running: 1-Finger Tap Right Detection...")
        let recognizer = GestureRecognizer()
        recognizer.delegate = self
        lastDetectedGesture = nil

        let touchDown = [TouchPoint(id: 1, x: 0.75, y: 0.50)]
        recognizer.processFrame(touches: touchDown, timestamp: 21.0)
        recognizer.processFrame(touches: [TouchPoint(id: 1, x: 0.74, y: 0.50)], timestamp: 21.10)
        recognizer.processFrame(touches: [], timestamp: 21.15)

        assertEqual(lastDetectedGesture, .oneFingerTapRight, "Detected 1-Finger Tap Right for touch at x = 0.75")
    }

    func testGestureTypeLegacyDecoding() {
        print("Running: Legacy GestureType JSON Decoding...")
        let legacyJSON = "[\"1-Finger Tap\", \"1-Finger Double Tap Left\", \"3-Finger Pinch In\"]".data(using: .utf8)!
        let decoded = try? JSONDecoder().decode([GestureType].self, from: legacyJSON)
        assertEqual(decoded?[0], .oneFingerTapLeft, "Decoded legacy '1-Finger Tap' to .oneFingerTapLeft")
        assertEqual(decoded?[1], .oneFingerDoubleTap, "Decoded legacy '1-Finger Double Tap Left' to .oneFingerDoubleTap")
        assertEqual(decoded?[2], .twoFingerPinchIn, "Decoded legacy '3-Finger Pinch In' to .twoFingerPinchIn")
    }

    func testOneFingerTripleTapDetection() {
        print("Running: 1-Finger Triple Tap Detection...")
        let recognizer = GestureRecognizer()
        recognizer.delegate = self
        lastDetectedGesture = nil

        // Tap 1
        recognizer.processFrame(touches: [TouchPoint(id: 1, x: 0.25, y: 0.50, totalSize: 0.2)], timestamp: 30.0)
        recognizer.processFrame(touches: [], timestamp: 30.1)

        // Tap 2
        recognizer.processFrame(touches: [TouchPoint(id: 1, x: 0.25, y: 0.50, totalSize: 0.2)], timestamp: 30.2)
        recognizer.processFrame(touches: [], timestamp: 30.3)

        // Tap 3
        recognizer.processFrame(touches: [TouchPoint(id: 1, x: 0.25, y: 0.50, totalSize: 0.2)], timestamp: 30.4)
        recognizer.processFrame(touches: [], timestamp: 30.5)

        assertEqual(lastDetectedGesture, .oneFingerTripleTap, "Detected 1-Finger Triple Tap")
    }

    func testTwoFingerTripleTapDetection() {
        print("Running: 2-Finger Triple Tap Detection...")
        let recognizer = GestureRecognizer()
        recognizer.delegate = self
        lastDetectedGesture = nil

        // Tap 1
        recognizer.processFrame(touches: [TouchPoint(id: 1, x: 0.3, y: 0.5), TouchPoint(id: 2, x: 0.7, y: 0.5)], timestamp: 40.0)
        recognizer.processFrame(touches: [], timestamp: 40.1)

        // Tap 2
        recognizer.processFrame(touches: [TouchPoint(id: 1, x: 0.3, y: 0.5), TouchPoint(id: 2, x: 0.7, y: 0.5)], timestamp: 40.2)
        recognizer.processFrame(touches: [], timestamp: 40.3)

        // Tap 3
        recognizer.processFrame(touches: [TouchPoint(id: 1, x: 0.3, y: 0.5), TouchPoint(id: 2, x: 0.7, y: 0.5)], timestamp: 40.4)
        recognizer.processFrame(touches: [], timestamp: 40.5)

        assertEqual(lastDetectedGesture, .twoFingerTripleTap, "Detected 2-Finger Triple Tap")
    }

    func testConfigurationStoreEnableToggle() {
        print("Running: Configuration Store Enable/Disable Toggle...")
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".json")
        let store = ConfigurationStore(saveURL: tempURL)
        XCTAssertDefault(store.isEnabled, "Store is enabled by default")
        store.isEnabled = false
        XCTAssertDefault(!store.isEnabled, "Store can be disabled")
        assertEqual(store.actionForGesture(.threeFingerClick), nil, "No action returned when store is disabled")
        store.isEnabled = true
        assertEqual(store.actionForGesture(.threeFingerClick), .mouseButton(button: .middleClick), "Action returned when store is enabled")
        try? FileManager.default.removeItem(at: tempURL)
    }

    func testConfigurationStorePersistence() {
        print("Running: Configuration Store Mapping & Query...")
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".json")
        let store = ConfigurationStore(saveURL: tempURL)
        XCTAssertDefault(store.isEnabled, "Store is enabled by default")
        let action = store.actionForGesture(.threeFingerClick)
        assertEqual(action, .mouseButton(button: .middleClick), "Default 3-finger click resolves to Middle Click")
        try? FileManager.default.removeItem(at: tempURL)
    }

    func testSemVerComparison() {
        print("Running: Semantic Version (SemVer) Comparison...")
        let v1_0_0 = SemVer("1.0.0")
        let v1_0_1 = SemVer("v1.0.1")
        let v1_2_0 = SemVer("1.2")
        let v2_0_0 = SemVer("v2.0.0-beta")

        XCTAssertDefault(v1_0_1 > v1_0_0, "v1.0.1 is newer than 1.0.0")
        XCTAssertDefault(v1_2_0 > v1_0_1, "1.2.0 is newer than v1.0.1")
        XCTAssertDefault(v2_0_0 > v1_2_0, "v2.0.0-beta is newer than 1.2.0")
        XCTAssertDefault(SemVer("1.0.0") == SemVer("v1.0.0"), "1.0.0 equals v1.0.0")
        XCTAssertDefault(!(v1_0_0 > v1_0_1), "1.0.0 is not newer than v1.0.1")
    }

    func testUpdateManifestDecoding() {
        print("Running: UpdateManifest & GitHubRelease JSON Decoding...")
        let manifestJSON = """
        {
          "version": "1.1.0",
          "notes": "Added update checker and release automation",
          "pub_date": "2026-09-21T15:00:00Z",
          "platforms": {
            "darwin-universal": {
              "url": "https://github.com/namikemen/magictouch/releases/download/v1.1.0/MagicTouch.app.tar.gz",
              "signature": "sha256abc"
            },
            "dmg": {
              "url": "https://github.com/namikemen/magictouch/releases/download/v1.1.0/MagicTouch.dmg",
              "signature": "sha256dmg"
            }
          }
        }
        """.data(using: .utf8)!

        let manifest = try? JSONDecoder().decode(UpdateManifest.self, from: manifestJSON)
        XCTAssertDefault(manifest != nil, "Successfully decoded UpdateManifest")
        assertEqual(manifest?.version, "1.1.0", "Decoded version matches 1.1.0")
        assertEqual(manifest?.platforms?["dmg"]?.url, "https://github.com/namikemen/magictouch/releases/download/v1.1.0/MagicTouch.dmg", "Decoded dmg URL")

        let githubJSON = """
        {
          "tag_name": "v1.2.0",
          "name": "MagicTouch v1.2.0",
          "body": "Release notes here",
          "html_url": "https://github.com/namikemen/magictouch/releases/tag/v1.2.0",
          "assets": [
            {
              "name": "MagicTouch.dmg",
              "browser_download_url": "https://github.com/namikemen/magictouch/releases/download/v1.2.0/MagicTouch.dmg"
            }
          ]
        }
        """.data(using: .utf8)!

        let release = try? JSONDecoder().decode(GitHubRelease.self, from: githubJSON)
        XCTAssertDefault(release != nil, "Successfully decoded GitHubRelease fallback")
        assertEqual(release?.tagName, "v1.2.0", "Decoded tagName")
        assertEqual(release?.assets.first?.name, "MagicTouch.dmg", "Decoded asset name")
    }

    private func XCTAssertDefault(_ condition: Bool, _ msg: String) {
        if condition {
            print("  ✅ PASS: \(msg)")
        } else {
            print("  ❌ FAIL: \(msg)")
            exit(1)
        }
    }

    func testPhysicalClickSuppressesTapOnRelease() {
        print("Running: Physical Click Suppresses Tap on Release...")
        let recognizer = GestureRecognizer()
        recognizer.delegate = self
        lastDetectedGesture = nil
        detectedGestures.removeAll()

        let touches = [
            TouchPoint(id: 1, x: 0.3, y: 0.7),
            TouchPoint(id: 2, x: 0.5, y: 0.7),
            TouchPoint(id: 3, x: 0.7, y: 0.7)
        ]
        recognizer.processFrame(touches: touches, timestamp: 50.0)
        // User physically depresses the mouse button
        recognizer.processPhysicalClick()
        assertEqual(lastDetectedGesture, .threeFingerClick, "Physical 3-finger click detected")

        // User releases physical click and lifts fingers
        recognizer.processFrame(touches: [], timestamp: 50.15)

        // Must still be .threeFingerClick and NOT have triggered .threeFingerTap!
        assertEqual(lastDetectedGesture, .threeFingerClick, "Finger release does NOT trigger false tap after click")
        assertEqual(detectedGestures.count, 1, "Only 1 gesture dispatched during click session")
    }

    func testThreeFingerTapBounceDebounce() {
        print("Running: Three Finger Tap Bounce Debounce...")
        let recognizer = GestureRecognizer()
        recognizer.delegate = self
        lastDetectedGesture = nil
        detectedGestures.removeAll()

        let touches = [
            TouchPoint(id: 1, x: 0.3, y: 0.7),
            TouchPoint(id: 2, x: 0.5, y: 0.7),
            TouchPoint(id: 3, x: 0.7, y: 0.7)
        ]
        // Clean 3-finger tap
        recognizer.processFrame(touches: touches, timestamp: 60.0)
        recognizer.processFrame(touches: [], timestamp: 60.08)
        assertEqual(detectedGestures.count, 1, "First 3-finger tap detected")
        assertEqual(detectedGestures.first, .threeFingerTap, "Gesture is threeFingerTap")

        // Hardware contact bounce: fingers graze glass 40ms later for 20ms
        recognizer.processFrame(touches: touches, timestamp: 60.12)
        recognizer.processFrame(touches: [], timestamp: 60.14)

        assertEqual(detectedGestures.count, 1, "Contact bounce within 120ms does NOT trigger second tap")
    }
}

@main
struct RunnerApp {
    static func main() {
        let runner = GestureRecognizerTestsRunner()
        runner.testSemVerComparison()
        runner.testUpdateManifestDecoding()
        runner.testOneFingerTapLeftDetection()
        runner.testOneFingerTapRightDetection()
        runner.testOneFingerTripleTapDetection()
        runner.testTwoFingerTripleTapDetection()
        runner.testConfigurationStoreEnableToggle()
        runner.testGestureTypeLegacyDecoding()
        runner.testThreeFingerTapDetection()
        runner.testPhysicalClickSuppressesTapOnRelease()
        runner.testThreeFingerTapBounceDebounce()
        runner.testTwoFingerSwipeRightDetection()
        runner.testTwoFingerSwipeLeftWithNaturalCompressionNotPinchIn()
        runner.testTwoFingerSwipeLeftWithAsynchronousFingerLiftNotPinchIn()
        runner.testTwoFingerSwipeLeftNearLeftEdgeNotPinchIn()
        runner.testOneFingerLongRestNotTap()
        runner.testOneFingerDriftNotTap()
        runner.testTwoFingerPinchInDetection()
        runner.testTwoFingerPinchOutDetection()
        runner.testHoldToDragDetection()
        runner.testAsymmetricalPinchInNotSwipe()
        runner.testPhysicalClickSimulation()
        runner.testTipTapRightDetection()
        runner.testTipTapLeftDetection()
        runner.testDoubleTipTapRight()
        runner.testTwoFingerTapNotTipTap()
        runner.testMouseButtonMappings()
        runner.testConfigurationStorePersistence()
        print("🎉 All 28 MagicTouch test suites passed successfully!")
    }
}
