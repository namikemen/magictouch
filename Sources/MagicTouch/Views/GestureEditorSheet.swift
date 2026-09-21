import SwiftUI

final class GestureEditorViewModel: ObservableObject {
    @Published var selectedGesture: GestureType = .threeFingerTap
    @Published var selectedActionCategory: ActionCategory = .mouse
    @Published var selectedMouseButton: MouseButtonType = .middleClick
    @Published var selectedSystemAction: SystemActionType = .missionControl
    @Published var shellCommandText: String = "say 'Gesture executed'"
    @Published var appleScriptText: String = "display notification \"MagicTouch gesture triggered!\" with title \"MagicTouch\""

    // Recorded Hotkey state
    @Published var recordedModifiers: [KeyModifier] = [.command, .shift]
    @Published var recordedKeyCode: UInt16 = 21 // '4'
    @Published var recordedDescription: String = "⌘ + ⇧ + 4"

    enum ActionCategory: String, CaseIterable, Identifiable {
        case mouse = "Mouse"
        case shortcut = "Keyboard"
        case system = "System"
        case shell = "Shell"
        case appleScript = "AppleScript"

        var id: String { rawValue }
    }
}

/// Modal sheet to configure or add a gesture mapping
public struct GestureEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = GestureEditorViewModel()

    var onSave: (GestureMapping) -> Void

    public init(onSave: @escaping (GestureMapping) -> Void) {
        self.onSave = onSave
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Title Header
            HStack {
                Text("Assign Custom Gesture")
                    .font(.system(size: 14, weight: .bold))
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }

            Divider()

            // Step 1: Select Gesture
            VStack(alignment: .leading, spacing: 4) {
                Text("Magic Mouse Gesture:")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)

                Picker("", selection: $vm.selectedGesture) {
                    ForEach(GestureType.allCases) { gesture in
                        Text(gesture.rawValue).tag(gesture)
                    }
                }
                .labelsHidden()
            }

            // Step 2: Action Category Picker
            VStack(alignment: .leading, spacing: 6) {
                Text("Trigger Action:")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)

                Picker("", selection: $vm.selectedActionCategory) {
                    ForEach(GestureEditorViewModel.ActionCategory.allCases) { cat in
                        Text(cat.rawValue).tag(cat)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()

                // Category Detail Form
                VStack(alignment: .leading, spacing: 6) {
                    switch vm.selectedActionCategory {
                    case .mouse:
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Mouse Button to simulate:")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                            Picker("", selection: $vm.selectedMouseButton) {
                                ForEach(MouseButtonType.allCases, id: \.self) { btn in
                                    Text(btn.rawValue).tag(btn)
                                }
                            }
                            .labelsHidden()
                        }

                    case .shortcut:
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Press the desired key combination on your keyboard:")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)

                            HotkeyRecorderView(
                                modifiers: $vm.recordedModifiers,
                                keyCode: $vm.recordedKeyCode,
                                description: $vm.recordedDescription
                            )
                        }

                    case .system:
                        VStack(alignment: .leading, spacing: 4) {
                            Text("System Action to perform:")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                            Picker("", selection: $vm.selectedSystemAction) {
                                ForEach(SystemActionType.allCases, id: \.self) { act in
                                    Text(act.rawValue).tag(act)
                                }
                            }
                            .labelsHidden()
                        }

                    case .shell:
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Shell Script / Terminal command:")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                            TextEditor(text: $vm.shellCommandText)
                                .font(.system(size: 11, design: .monospaced))
                                .frame(height: 55)
                                .cornerRadius(6)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                                )
                        }

                    case .appleScript:
                        VStack(alignment: .leading, spacing: 4) {
                            Text("AppleScript code:")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                            TextEditor(text: $vm.appleScriptText)
                                .font(.system(size: 11, design: .monospaced))
                                .frame(height: 55)
                                .cornerRadius(6)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                                )
                        }
                    }
                }
                .padding(.top, 4)
            }

            Spacer(minLength: 8)

            Divider()

            // Footer buttons
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Spacer()

                Button("Save Assignment") {
                    saveMapping()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        }
        .padding(16)
        .frame(minWidth: 460, maxWidth: 500)
    }

    private func saveMapping() {
        let action: ActionTarget
        switch vm.selectedActionCategory {
        case .mouse:
            action = .mouseButton(button: vm.selectedMouseButton)
        case .system:
            action = .systemAction(action: vm.selectedSystemAction)
        case .shortcut:
            action = .keyboardShortcut(
                modifiers: vm.recordedModifiers,
                keyCode: vm.recordedKeyCode,
                description: vm.recordedDescription.isEmpty ? "Shortcut" : vm.recordedDescription
            )
        case .shell:
            action = .shellCommand(command: vm.shellCommandText)
        case .appleScript:
            action = .appleScript(script: vm.appleScriptText)
        }

        let newMapping = GestureMapping(gesture: vm.selectedGesture, action: action)
        onSave(newMapping)
    }
}
