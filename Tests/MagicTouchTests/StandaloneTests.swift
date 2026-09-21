import Foundation

final class GestureRecognizerTestsRunner: GestureRecognizerDelegate {
    private var lastDetectedGesture: GestureType?
    private var updatedTouches: [TouchPoint] = []

    func gestureRecognizerDidDetect(gesture: GestureType) {
        self.lastDetectedGesture = gesture
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

    func testThreeFingerPinchInDetection() {
        print("Running: Three Finger Pinch In Detection...")
        let recognizer = GestureRecognizer()
        recognizer.delegate = self
        lastDetectedGesture = nil

        let startTouches = [
            TouchPoint(id: 1, x: 0.2, y: 0.5),
            TouchPoint(id: 2, x: 0.5, y: 0.5),
            TouchPoint(id: 3, x: 0.8, y: 0.5)
        ]
        recognizer.processFrame(touches: startTouches, timestamp: 5.0)

        let pinchedTouches = [
            TouchPoint(id: 1, x: 0.4, y: 0.5),
            TouchPoint(id: 2, x: 0.5, y: 0.5),
            TouchPoint(id: 3, x: 0.6, y: 0.5)
        ]
        recognizer.processFrame(touches: pinchedTouches, timestamp: 5.2)
        recognizer.processFrame(touches: [], timestamp: 5.3)

        assertEqual(lastDetectedGesture, .threeFingerPinchIn, "Detected 3-finger pinch in")
    }

    func testThreeFingerPinchOutDetection() {
        print("Running: Three Finger Pinch Out Detection...")
        let recognizer = GestureRecognizer()
        recognizer.delegate = self
        lastDetectedGesture = nil

        let startTouches = [
            TouchPoint(id: 1, x: 0.4, y: 0.5),
            TouchPoint(id: 2, x: 0.5, y: 0.5),
            TouchPoint(id: 3, x: 0.6, y: 0.5)
        ]
        recognizer.processFrame(touches: startTouches, timestamp: 6.0)

        let spreadTouches = [
            TouchPoint(id: 1, x: 0.2, y: 0.5),
            TouchPoint(id: 2, x: 0.5, y: 0.5),
            TouchPoint(id: 3, x: 0.8, y: 0.5)
        ]
        recognizer.processFrame(touches: spreadTouches, timestamp: 6.2)
        recognizer.processFrame(touches: [], timestamp: 6.3)

        assertEqual(lastDetectedGesture, .threeFingerPinchOut, "Detected 3-finger pinch out")
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
        let legacyJSON = "\"1-Finger Tap\"".data(using: .utf8)!
        let decoded = try? JSONDecoder().decode(GestureType.self, from: legacyJSON)
        assertEqual(decoded, .oneFingerTapLeft, "Decoded legacy '1-Finger Tap' to .oneFingerTapLeft")
    }

    func testOneFingerTripleTapDetection() {
        print("Running: 1-Finger Triple Tap Detection...")
        let recognizer = GestureRecognizer()
        recognizer.delegate = self
        lastDetectedGesture = nil

        // Tap 1
        recognizer.processFrame(touches: [TouchPoint(id: 1, x: 0.25, y: 0.50)], timestamp: 30.0)
        recognizer.processFrame(touches: [], timestamp: 30.1)

        // Tap 2
        recognizer.processFrame(touches: [TouchPoint(id: 1, x: 0.25, y: 0.50)], timestamp: 30.2)
        recognizer.processFrame(touches: [], timestamp: 30.3)

        // Tap 3
        recognizer.processFrame(touches: [TouchPoint(id: 1, x: 0.25, y: 0.50)], timestamp: 30.4)
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

    func testConfigurationStoreTripleTapFallback() {
        print("Running: Configuration Store Triple Tap Fallback...")
        let store = ConfigurationStore.shared
        let mapping = GestureMapping(gesture: .oneFingerTripleTap, action: .mouseButton(button: .tripleClick))
        store.mappings.removeAll(where: { $0.gesture == .oneFingerTripleTap || $0.gesture == .oneFingerTripleTapLeft })
        store.addMapping(mapping)

        // Querying for oneFingerTripleTapLeft should fall back to general oneFingerTripleTap mapping
        assertEqual(store.actionForGesture(.oneFingerTripleTapLeft), .mouseButton(button: .tripleClick), "Resolves sub-zone triple tap to general mapping")

        store.deleteMapping(id: mapping.id)
    }

    func testConfigurationStorePersistence() {
        print("Running: Configuration Store Mapping & Query...")
        let store = ConfigurationStore.shared
        XCTAssertDefault(store.isEnabled, "Store is enabled by default")
        let action = store.actionForGesture(.threeFingerClick)
        assertEqual(action, .mouseButton(button: .middleClick), "Default 3-finger click resolves to Middle Click")
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
        runner.testConfigurationStoreTripleTapFallback()
        runner.testGestureTypeLegacyDecoding()
        runner.testThreeFingerTapDetection()
        runner.testTwoFingerSwipeRightDetection()
        runner.testTwoFingerPinchInDetection()
        runner.testTwoFingerPinchOutDetection()
        runner.testThreeFingerPinchInDetection()
        runner.testThreeFingerPinchOutDetection()
        runner.testAsymmetricalPinchInNotSwipe()
        runner.testPhysicalClickSimulation()
        runner.testTipTapRightDetection()
        runner.testTipTapLeftDetection()
        runner.testDoubleTipTapRight()
        runner.testTwoFingerTapNotTipTap()
        runner.testMouseButtonMappings()
        runner.testConfigurationStorePersistence()
        print("🎉 All 22 MagicTouch test suites passed successfully!")
    }
}
