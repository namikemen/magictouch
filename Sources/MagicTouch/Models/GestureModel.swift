import Foundation

/// Defines all gesture combinations that can be performed on the Magic Mouse
public enum GestureType: String, Codable, CaseIterable, Identifiable {
    // 1-Finger Gestures
    case oneFingerTapLeft = "1-Finger Tap Left"
    case oneFingerTapRight = "1-Finger Tap Right"
    case oneFingerDoubleTap = "1-Finger Double Tap"
    case oneFingerTripleTap = "1-Finger Triple Tap"
    case holdToDrag = "Hold to Drag (Tap & Hold)"
    case oneFingerClick = "1-Finger Click"
    case oneFingerSwipeLeft = "1-Finger Swipe Left"
    case oneFingerSwipeRight = "1-Finger Swipe Right"
    case oneFingerSwipeUp = "1-Finger Swipe Up"
    case oneFingerSwipeDown = "1-Finger Swipe Down"

    // 2-Finger Gestures
    case twoFingerTap = "2-Finger Tap"
    case twoFingerDoubleTap = "2-Finger Double Tap"
    case twoFingerTripleTap = "2-Finger Triple Tap"
    case twoFingerClick = "2-Finger Click"
    case twoFingerSwipeLeft = "2-Finger Swipe Left"
    case twoFingerSwipeRight = "2-Finger Swipe Right"
    case twoFingerSwipeUp = "2-Finger Swipe Up"
    case twoFingerSwipeDown = "2-Finger Swipe Down"
    case twoFingerPinchIn = "2-Finger Pinch In"
    case twoFingerPinchOut = "2-Finger Pinch Out"
    case tipTapLeft = "Tip-Tap Left (Rest Right, Tap Left)"
    case tipTapRight = "Tip-Tap Right (Rest Left, Tap Right)"

    // 3-Finger Gestures
    case threeFingerTap = "3-Finger Tap"
    case threeFingerDoubleTap = "3-Finger Double Tap"
    case threeFingerTripleTap = "3-Finger Triple Tap"
    case threeFingerClick = "3-Finger Click (Middle Click standard)"
    case threeFingerSwipeLeft = "3-Finger Swipe Left"
    case threeFingerSwipeRight = "3-Finger Swipe Right"
    case threeFingerSwipeUp = "3-Finger Swipe Up"
    case threeFingerSwipeDown = "3-Finger Swipe Down"

    // 4-Finger Gestures
    case fourFingerTap = "4-Finger Tap"
    case fourFingerClick = "4-Finger Click"
    case fourFingerSwipeLeft = "4-Finger Swipe Left"
    case fourFingerSwipeRight = "4-Finger Swipe Right"
    case fourFingerSwipeUp = "4-Finger Swipe Up"
    case fourFingerSwipeDown = "4-Finger Swipe Down"

    public var id: String { rawValue }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
        switch raw {
        case "1-Finger Tap":
            self = .oneFingerTapLeft
        case "1-Finger Double Tap Left", "1-Finger Double Tap Right":
            self = .oneFingerDoubleTap
        case "1-Finger Triple Tap Left", "1-Finger Triple Tap Right":
            self = .oneFingerTripleTap
        case "3-Finger Pinch In":
            self = .twoFingerPinchIn
        case "3-Finger Pinch Out":
            self = .twoFingerPinchOut
        default:
            if let val = GestureType(rawValue: raw) {
                self = val
            } else {
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unknown gesture: \(raw)")
            }
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.rawValue)
    }

    public var fingerCount: Int {
        switch self {
        case .oneFingerTapLeft, .oneFingerTapRight, .oneFingerDoubleTap,
             .oneFingerTripleTap, .holdToDrag, .oneFingerClick,
             .oneFingerSwipeLeft, .oneFingerSwipeRight, .oneFingerSwipeUp, .oneFingerSwipeDown:
            return 1
        case .twoFingerTap, .twoFingerDoubleTap, .twoFingerTripleTap, .twoFingerClick,
             .twoFingerSwipeLeft, .twoFingerSwipeRight, .twoFingerSwipeUp, .twoFingerSwipeDown,
             .twoFingerPinchIn, .twoFingerPinchOut, .tipTapLeft, .tipTapRight:
            return 2
        case .threeFingerTap, .threeFingerDoubleTap, .threeFingerTripleTap, .threeFingerClick,
             .threeFingerSwipeLeft, .threeFingerSwipeRight, .threeFingerSwipeUp, .threeFingerSwipeDown:
            return 3
        case .fourFingerTap, .fourFingerClick,
             .fourFingerSwipeLeft, .fourFingerSwipeRight, .fourFingerSwipeUp, .fourFingerSwipeDown:
            return 4
        }
    }
}

/// Defines what action will execute when a gesture is triggered
public enum ActionTarget: Codable, Equatable {
    case mouseButton(button: MouseButtonType)
    case keyboardShortcut(modifiers: [KeyModifier], keyCode: UInt16, description: String)
    case appleScript(script: String)
    case shellCommand(command: String)
    case systemAction(action: SystemActionType)

    public var displayName: String {
        switch self {
        case .mouseButton(let btn):
            return "Mouse: \(btn.rawValue)"
        case .keyboardShortcut(_, _, let desc):
            return "Key: \(desc)"
        case .appleScript:
            return "AppleScript"
        case .shellCommand(let cmd):
            return "Shell: \(cmd)"
        case .systemAction(let act):
            return "System: \(act.rawValue)"
        }
    }
}

public enum MouseButtonType: String, Codable, CaseIterable {
    case leftClick = "Left Click (Button 1)"
    case rightClick = "Right Click (Button 2 / Secondary)"
    case middleClick = "Middle Click (Button 3)"
    case doubleClick = "Double Click"
    case tripleClick = "Triple Click (Select Line)"
    case leftDrag = "Left Mouse Drag (Hold to Drag)"
    case back = "Back (Button 4)"
    case forward = "Forward (Button 5)"
}

public enum KeyModifier: String, Codable {
    case command = "Cmd"
    case option = "Option"
    case control = "Ctrl"
    case shift = "Shift"
}

public enum SystemActionType: String, Codable, CaseIterable {
    case missionControl = "Mission Control"
    case appExpose = "Application Expose"
    case showDesktop = "Show Desktop"
    case launchpad = "Launchpad"
    case volumeUp = "Volume Up"
    case volumeDown = "Volume Down"
    case mute = "Mute"
}

/// A mapping between a gesture and an action
public struct GestureMapping: Codable, Identifiable, Equatable {
    public var id: UUID
    public var isEnabled: Bool
    public var gesture: GestureType
    public var action: ActionTarget

    public init(id: UUID = UUID(), isEnabled: Bool = true, gesture: GestureType, action: ActionTarget) {
        self.id = id
        self.isEnabled = isEnabled
        self.gesture = gesture
        self.action = action
    }
}
