import Foundation
import CoreGraphics
import AppKit

/// Dispatches synthesized actions when a gesture is recognized
public final class ActionDispatcher {
    public static let shared = ActionDispatcher()

    private init() {}

    public func execute(action: ActionTarget) {
        DispatchQueue.main.async {
            switch action {
            case .mouseButton(let button):
                self.triggerMouseButton(button)
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

    // MARK: - Mouse Simulation
    private func triggerMouseButton(_ button: MouseButtonType) {
        guard let location = CGEvent(source: nil)?.location else { return }

        switch button {
        case .doubleClick:
            triggerMultiClick(count: 2, location: location)
            return
        case .tripleClick:
            triggerMultiClick(count: 3, location: location)
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
        case .doubleClick, .tripleClick:
            return
        }

        if let downEvent = CGEvent(mouseEventSource: nil, mouseType: mouseTypeDown, mouseCursorPosition: location, mouseButton: mouseButton),
           let upEvent = CGEvent(mouseEventSource: nil, mouseType: mouseTypeUp, mouseCursorPosition: location, mouseButton: mouseButton) {
            downEvent.post(tap: .cghidEventTap)
            usleep(10000) // 10ms hold
            upEvent.post(tap: .cghidEventTap)
        }
    }

    private func triggerMultiClick(count: Int, location: CGPoint) {
        for i in 1...count {
            if let downEvent = CGEvent(mouseEventSource: nil, mouseType: .leftMouseDown, mouseCursorPosition: location, mouseButton: .left),
               let upEvent = CGEvent(mouseEventSource: nil, mouseType: .leftMouseUp, mouseCursorPosition: location, mouseButton: .left) {
                downEvent.setIntegerValueField(.mouseEventClickState, value: Int64(i))
                upEvent.setIntegerValueField(.mouseEventClickState, value: Int64(i))
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
            keyDown.post(tap: .cghidEventTap)
            usleep(15000)
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
            // Open Mission Control via open command
            runShellCommand("open -b com.apple.exposelauncher")
        case .appExpose:
            // Simulate Ctrl + Down
            triggerKeystroke(modifiers: [.control], keyCode: 125)
        case .showDesktop:
            // Simulate F11
            triggerKeystroke(modifiers: [], keyCode: 103)
        case .launchpad:
            runShellCommand("open -b com.apple.launchpad.launcher")
        case .volumeUp:
            runAppleScript("set volume output volume ((output volume of (get volume settings)) + 6)")
        case .volumeDown:
            runAppleScript("set volume output volume ((output volume of (get volume settings)) - 6)")
        case .mute:
            runAppleScript("set volume output muted (not (output muted of (get volume settings)))")
        }
    }
}
