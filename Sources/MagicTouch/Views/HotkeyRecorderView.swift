import SwiftUI
import AppKit

final class HotkeyRecorderModel: ObservableObject {
    @Published var isRecording: Bool = false
    var monitor: Any?

    deinit {
        stopRecording()
    }

    func startRecording(onKey: @escaping ([KeyModifier], UInt16, String) -> Void) {
        isRecording = true
        monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
            guard let self = self else { return event }

            // Handle escape to cancel
            if event.keyCode == 53 {
                self.stopRecording()
                return nil
            }

            var mods: [KeyModifier] = []
            var descParts: [String] = []

            if event.modifierFlags.contains(.command) {
                mods.append(.command)
                descParts.append("⌘")
            }
            if event.modifierFlags.contains(.control) {
                mods.append(.control)
                descParts.append("⌃")
            }
            if event.modifierFlags.contains(.option) {
                mods.append(.option)
                descParts.append("⌥")
            }
            if event.modifierFlags.contains(.shift) {
                mods.append(.shift)
                descParts.append("⇧")
            }

            let keyChar = self.readableKeyString(for: event)
            descParts.append(keyChar)

            onKey(mods, event.keyCode, descParts.joined(separator: " + "))
            self.stopRecording()
            return nil
        }
    }

    func stopRecording() {
        isRecording = false
        if let mon = monitor {
            NSEvent.removeMonitor(mon)
            monitor = nil
        }
    }

    private func readableKeyString(for event: NSEvent) -> String {
        switch event.keyCode {
        case 36: return "Return"
        case 48: return "Tab"
        case 49: return "Space"
        case 51: return "Delete"
        case 123: return "←"
        case 124: return "→"
        case 125: return "↓"
        case 126: return "↑"
        case 122: return "F1"
        case 120: return "F2"
        case 99: return "F3"
        case 118: return "F4"
        case 96: return "F5"
        case 97: return "F6"
        case 98: return "F7"
        case 100: return "F8"
        case 101: return "F9"
        case 109: return "F10"
        case 103: return "F11"
        case 111: return "F12"
        default:
            if let chars = event.charactersIgnoringModifiers, !chars.isEmpty {
                return chars.uppercased()
            }
            return "Key(\(event.keyCode))"
        }
    }
}

/// An interactive hotkey recorder that captures key presses and modifier keys directly from the keyboard
public struct HotkeyRecorderView: View {
    @Binding var modifiers: [KeyModifier]
    @Binding var keyCode: UInt16
    @Binding var description: String

    @StateObject private var model = HotkeyRecorderModel()

    public init(modifiers: Binding<[KeyModifier]>, keyCode: Binding<UInt16>, description: Binding<String>) {
        self._modifiers = modifiers
        self._keyCode = keyCode
        self._description = description
    }

    public var body: some View {
        HStack(spacing: 10) {
            Button(action: {
                if model.isRecording {
                    model.stopRecording()
                } else {
                    model.startRecording { newMods, newCode, newDesc in
                        self.modifiers = newMods
                        self.keyCode = newCode
                        self.description = newDesc
                    }
                }
            }) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(model.isRecording ? Color.red : Color.secondary)
                        .frame(width: 8, height: 8)
                    Text(model.isRecording ? "Press Keys on Keyboard..." : (description.isEmpty ? "Click to Record Hotkey" : description))
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundColor(model.isRecording ? .accentColor : .primary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .frame(maxWidth: .infinity)
                .background(model.isRecording ? Color.accentColor.opacity(0.15) : Color(nsColor: .controlBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(model.isRecording ? Color.accentColor : Color.secondary.opacity(0.3), lineWidth: 1)
                )
                .cornerRadius(6)
            }
            .buttonStyle(.plain)

            if !description.isEmpty {
                Button(action: {
                    self.modifiers = []
                    self.keyCode = 0
                    self.description = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .onDisappear {
            model.stopRecording()
        }
    }
}
