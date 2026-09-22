import Foundation
import CoreGraphics
import AppKit

/// Dispatches synthesized actions when a gesture is recognized
public final class ActionDispatcher {
    public static let shared = ActionDispatcher()

    private var isDragging = false

    public static let magicEventSignature: Int64 = 0x4D41474943 // "MAGIC"
    public static var isSynthesizingEvent: Bool = false

    private init() {}

    public func execute(action: ActionTarget, clickState: Int = 1) {
        DispatchQueue.main.async {
            switch action {
            case .mouseButton(let button):
                self.triggerMouseButton(button, clickState: clickState)
            case .keyboardShortcut(let modifiers, let keyCode, _):
                self.triggerKeystroke(modifiers: modifiers, keyCode: keyCode)
            case .appleScript(let script):
                self.runAppleScript(script)
            case .shellCommand(let command):
                self.runShellCommand(command)
            case .systemAction(let systemAction):
                self.triggerSystemAction(systemAction)
            }
        }
    }

    // MARK: - Drag Simulation
    public func startLeftDrag() {
        guard !isDragging else { return }
        guard let location = CGEvent(source: nil)?.location else { return }
        if let downEvent = CGEvent(mouseEventSource: nil, mouseType: .leftMouseDown, mouseCursorPosition: location, mouseButton: .left) {
            downEvent.setIntegerValueField(.eventSourceUserData, value: ActionDispatcher.magicEventSignature)
            ActionDispatcher.isSynthesizingEvent = true
            downEvent.post(tap: .cghidEventTap)
            ActionDispatcher.isSynthesizingEvent = false
            isDragging = true
        }
    }

    public func endLeftDrag() {
        guard isDragging else { return }
        guard let location = CGEvent(source: nil)?.location else { return }
        if let upEvent = CGEvent(mouseEventSource: nil, mouseType: .leftMouseUp, mouseCursorPosition: location, mouseButton: .left) {
            upEvent.setIntegerValueField(.eventSourceUserData, value: ActionDispatcher.magicEventSignature)
            ActionDispatcher.isSynthesizingEvent = true
            upEvent.post(tap: .cghidEventTap)
            ActionDispatcher.isSynthesizingEvent = false
            isDragging = false
        }
    }

    // MARK: - Mouse Simulation
    private func triggerMouseButton(_ button: MouseButtonType, clickState: Int = 1) {
        guard let location = CGEvent(source: nil)?.location else { return }

        switch button {
        case .doubleClick:
            if clickState >= 2 {
                triggerSingleClick(typeDown: .leftMouseDown, typeUp: .leftMouseUp, button: .left, location: location, clickState: 2)
            } else {
                triggerMultiClick(count: 2, location: location)
            }
            return
        case .tripleClick:
            if clickState >= 3 {
                triggerSingleClick(typeDown: .leftMouseDown, typeUp: .leftMouseUp, button: .left, location: location, clickState: 3)
            } else {
                triggerMultiClick(count: 3, location: location)
            }
            return
        case .leftDrag:
            if isDragging {
                endLeftDrag()
            } else {
                startLeftDrag()
            }
            return
        default:
            break
        }

        let mouseTypeDown: CGEventType
        let mouseTypeUp: CGEventType
        let mouseButton: CGMouseButton

        switch button {
        case .leftClick:
            mouseTypeDown = .leftMouseDown
            mouseTypeUp = .leftMouseUp
            mouseButton = .left
        case .rightClick:
            mouseTypeDown = .rightMouseDown
            mouseTypeUp = .rightMouseUp
            mouseButton = .right
        case .middleClick:
            mouseTypeDown = .otherMouseDown
            mouseTypeUp = .otherMouseUp
            mouseButton = .center
        case .back:
            mouseTypeDown = .otherMouseDown
            mouseTypeUp = .otherMouseUp
            mouseButton = CGMouseButton(rawValue: 3)!
        case .forward:
            mouseTypeDown = .otherMouseDown
            mouseTypeUp = .otherMouseUp
            mouseButton = CGMouseButton(rawValue: 4)!
        case .doubleClick, .tripleClick, .leftDrag:
            return
        }

        triggerSingleClick(typeDown: mouseTypeDown, typeUp: mouseTypeUp, button: mouseButton, location: location, clickState: clickState)
    }

    private func triggerSingleClick(typeDown: CGEventType, typeUp: CGEventType, button: CGMouseButton, location: CGPoint, clickState: Int) {
        guard let downEvent = CGEvent(mouseEventSource: nil, mouseType: typeDown, mouseCursorPosition: location, mouseButton: button),
              let upEvent = CGEvent(mouseEventSource: nil, mouseType: typeUp, mouseCursorPosition: location, mouseButton: button) else {
            return
        }

        downEvent.setIntegerValueField(.mouseEventClickState, value: Int64(clickState))
        upEvent.setIntegerValueField(.mouseEventClickState, value: Int64(clickState))
        downEvent.setIntegerValueField(.eventSourceUserData, value: ActionDispatcher.magicEventSignature)
        upEvent.setIntegerValueField(.eventSourceUserData, value: ActionDispatcher.magicEventSignature)

        ActionDispatcher.isSynthesizingEvent = true
        downEvent.post(tap: .cghidEventTap)
        usleep(10000) // 10ms hold
        upEvent.post(tap: .cghidEventTap)
        ActionDispatcher.isSynthesizingEvent = false
    }

    private func triggerMultiClick(count: Int, location: CGPoint) {
        ActionDispatcher.isSynthesizingEvent = true
        defer { ActionDispatcher.isSynthesizingEvent = false }
        for i in 1...count {
            if let downEvent = CGEvent(mouseEventSource: nil, mouseType: .leftMouseDown, mouseCursorPosition: location, mouseButton: .left),
               let upEvent = CGEvent(mouseEventSource: nil, mouseType: .leftMouseUp, mouseCursorPosition: location, mouseButton: .left) {
                downEvent.setIntegerValueField(.mouseEventClickState, value: Int64(i))
                upEvent.setIntegerValueField(.mouseEventClickState, value: Int64(i))
                downEvent.setIntegerValueField(.eventSourceUserData, value: ActionDispatcher.magicEventSignature)
                upEvent.setIntegerValueField(.eventSourceUserData, value: ActionDispatcher.magicEventSignature)
                downEvent.post(tap: .cghidEventTap)
                usleep(10000) // 10ms hold
                upEvent.post(tap: .cghidEventTap)
                if i < count {
                    usleep(30000) // 30ms inter-click interval
                }
            }
        }
    }

    // MARK: - Keyboard Shortcut Simulation
    private func triggerKeystroke(modifiers: [KeyModifier], keyCode: UInt16) {
        var flags: CGEventFlags = []
        for mod in modifiers {
            switch mod {
            case .command: flags.insert(.maskCommand)
            case .option: flags.insert(.maskAlternate)
            case .control: flags.insert(.maskControl)
            case .shift: flags.insert(.maskShift)
            }
        }

        let source = CGEventSource(stateID: .combinedSessionState)
        if let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true),
           let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false) {
            keyDown.flags = flags
            keyUp.flags = flags
            // Post to HID event tap (system-level routing to active application)
            keyDown.post(tap: .cghidEventTap)
            usleep(25000) // 25ms hold for app event loop capture
            keyUp.post(tap: .cghidEventTap)
        }
    }

    // MARK: - AppleScript Execution
    private func runAppleScript(_ scriptText: String) {
        DispatchQueue.global(qos: .userInitiated).async {
            var error: NSDictionary?
            if let scriptObject = NSAppleScript(source: scriptText) {
                scriptObject.executeAndReturnError(&error)
                if let err = error {
                    print("[MagicTouch] AppleScript error: \(err)")
                }
            }
        }
    }

    // MARK: - Shell Command Execution
    private func runShellCommand(_ command: String) {
        DispatchQueue.global(qos: .userInitiated).async {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/zsh")
            process.arguments = ["-c", command]

            do {
                try process.run()
            } catch {
                print("[MagicTouch] Failed to run shell command: \(error)")
            }
        }
    }

    // MARK: - System Actions
    private func triggerSystemAction(_ action: SystemActionType) {
        switch action {
        case .missionControl:
            runShellCommand("open -b com.apple.exposelauncher 2>/dev/null || open -a 'Mission Control' 2>/dev/null")
        case .appExpose:
            // Simulate Ctrl + Down
            triggerKeystroke(modifiers: [.control], keyCode: 125)
        case .showDesktop:
            // Simulate F11
            triggerKeystroke(modifiers: [], keyCode: 103)
        case .launchpad:
            // Supports modern macOS Sequoia/Tahoe (com.apple.apps.launcher) and legacy (com.apple.launchpad.launcher)
            runShellCommand("open -b com.apple.apps.launcher 2>/dev/null || open -b com.apple.launchpad.launcher 2>/dev/null || open -a Apps 2>/dev/null || open -a Launchpad 2>/dev/null")
        case .volumeUp:
            runAppleScript("set volume output volume ((output volume of (get volume settings)) + 6)")
        case .volumeDown:
            runAppleScript("set volume output volume ((output volume of (get volume settings)) - 6)")
        case .mute:
            runAppleScript("set volume output muted (not (output muted of (get volume settings)))")
        }
    }
}
