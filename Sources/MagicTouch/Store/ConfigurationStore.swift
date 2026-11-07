import Foundation
import Combine
import SwiftUI

/// Posted by ConfigurationStore whenever the master-toggle hotkey configuration changes,
/// so the hotkey manager can re-register the system-wide shortcut.
public extension Notification.Name {
    static let magicTouchToggleHotkeyChanged = Notification.Name("MagicTouchToggleHotkeyChanged")
}

/// Manages loading, saving, and updating user gesture configurations
public final class ConfigurationStore: ObservableObject {
    public static let shared = ConfigurationStore()

    // MARK: Master-toggle hotkey configuration

    public static let defaultToggleHotkeyModifiers: [KeyModifier] = [.control, .option]
    public static let defaultToggleHotkeyKeyCode: UInt16 = 46 // 'M'
    public static let defaultToggleHotkeyDescription: String = "⌃ + ⌥ + M"

    private static let hotkeyModifiersKey = "MagicTouch_ToggleHotkeyModifiers"
    private static let hotkeyKeyCodeKey = "MagicTouch_ToggleHotkeyKeyCode"
    private static let hotkeyDescriptionKey = "MagicTouch_ToggleHotkeyDescription"

    @Published public var mappings: [GestureMapping] = []
    @Published public var isEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: "MagicTouch_IsEnabled")
        }
    }
    @Published public var touchAreaMinY: Double {
        didSet {
            UserDefaults.standard.set(touchAreaMinY, forKey: "MagicTouch_TouchAreaMinY")
        }
    }
    @Published public var toggleHotkeyModifiers: [KeyModifier] = ConfigurationStore.defaultToggleHotkeyModifiers {
        didSet {
            UserDefaults.standard.set(toggleHotkeyModifiers.map(\.rawValue), forKey: ConfigurationStore.hotkeyModifiersKey)
        }
    }
    @Published public var toggleHotkeyKeyCode: UInt16 = ConfigurationStore.defaultToggleHotkeyKeyCode {
        didSet {
            UserDefaults.standard.set(Int(toggleHotkeyKeyCode), forKey: ConfigurationStore.hotkeyKeyCodeKey)
        }
    }
    @Published public var toggleHotkeyDescription: String = ConfigurationStore.defaultToggleHotkeyDescription {
        didSet {
            UserDefaults.standard.set(toggleHotkeyDescription, forKey: ConfigurationStore.hotkeyDescriptionKey)
        }
    }

    /// Whether the master-toggle shortcut is configured (a key code and at least one modifier).
    public var hasToggleHotkey: Bool {
        toggleHotkeyKeyCode != 0 && !toggleHotkeyModifiers.isEmpty
    }

    /// Human-readable label for the master-toggle shortcut, or "None" when disabled.
    public var toggleHotkeyDisplay: String {
        hasToggleHotkey ? toggleHotkeyDescription : "None"
    }

    /// Updates the master-toggle shortcut, persists it, and notifies the hotkey manager to re-register.
    public func setToggleHotkey(modifiers: [KeyModifier], keyCode: UInt16, description: String) {
        toggleHotkeyModifiers = modifiers
        toggleHotkeyKeyCode = keyCode
        toggleHotkeyDescription = description
        NotificationCenter.default.post(name: .magicTouchToggleHotkeyChanged, object: nil)
    }

    /// Restores the default master-toggle shortcut and notifies the hotkey manager.
    public func resetToggleHotkey() {
        setToggleHotkey(
            modifiers: ConfigurationStore.defaultToggleHotkeyModifiers,
            keyCode: ConfigurationStore.defaultToggleHotkeyKeyCode,
            description: ConfigurationStore.defaultToggleHotkeyDescription
        )
    }

    private let saveURL: URL

    public init(saveURL: URL? = nil) {
        if let customURL = saveURL {
            self.saveURL = customURL
            self.isEnabled = true
            self.touchAreaMinY = 0.0
        } else {
            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            let appDir = appSupport.appendingPathComponent("MagicTouch", isDirectory: true)

            try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)
            self.saveURL = appDir.appendingPathComponent("gestures.json")
            self.isEnabled = UserDefaults.standard.object(forKey: "MagicTouch_IsEnabled") as? Bool ?? true
            self.touchAreaMinY = UserDefaults.standard.object(forKey: "MagicTouch_TouchAreaMinY") as? Double ?? 0.0

            // Master-toggle hotkey: the @Published initializers already hold the defaults,
            // so only override values that were persisted by a previous session.
            if let storedModifiers = UserDefaults.standard.stringArray(forKey: ConfigurationStore.hotkeyModifiersKey) {
                self.toggleHotkeyModifiers = storedModifiers.compactMap { KeyModifier(rawValue: $0) }
            }
            if let storedKeyCode = UserDefaults.standard.object(forKey: ConfigurationStore.hotkeyKeyCodeKey) as? Int {
                self.toggleHotkeyKeyCode = UInt16(clamping: storedKeyCode)
            }
            if let storedDescription = UserDefaults.standard.string(forKey: ConfigurationStore.hotkeyDescriptionKey) {
                self.toggleHotkeyDescription = storedDescription
            }
        }

        load()
    }

    public func setTouchAreaMinY(_ minY: Double) {
        self.touchAreaMinY = min(max(minY, 0.0), 0.70)
    }

    public func load() {
        if let data = try? Data(contentsOf: saveURL),
           let decoded = try? JSONDecoder().decode([GestureMapping].self, from: data) {
            self.mappings = decoded
        } else {
            // Setup sensible defaults
            self.mappings = [
                GestureMapping(gesture: .threeFingerClick, action: .mouseButton(button: .middleClick)),
                GestureMapping(gesture: .twoFingerSwipeLeft, action: .keyboardShortcut(modifiers: [.control], keyCode: 123, description: "Ctrl + Left (Previous Space)")),
                GestureMapping(gesture: .twoFingerSwipeRight, action: .keyboardShortcut(modifiers: [.control], keyCode: 124, description: "Ctrl + Right (Next Space)")),
                GestureMapping(gesture: .twoFingerSwipeUp, action: .systemAction(action: .missionControl)),
                GestureMapping(gesture: .twoFingerSwipeDown, action: .systemAction(action: .appExpose)),
                GestureMapping(gesture: .threeFingerTap, action: .mouseButton(button: .middleClick))
            ]
            save()
        }
    }

    public func save() {
        if let data = try? JSONEncoder().encode(mappings) {
            try? data.write(to: saveURL)
        }
    }

    public func addMapping(_ mapping: GestureMapping) {
        mappings.append(mapping)
        save()
    }

    public func deleteMapping(at offsets: IndexSet) {
        for index in offsets.sorted(by: >) {
            if index < mappings.count {
                mappings.remove(at: index)
            }
        }
        save()
    }

    public func deleteMapping(id: UUID) {
        mappings.removeAll(where: { $0.id == id })
        save()
    }

    public func toggleMapping(id: UUID) {
        if let idx = mappings.firstIndex(where: { $0.id == id }) {
            mappings[idx].isEnabled.toggle()
            save()
        }
    }

    public func updateMapping(_ mapping: GestureMapping) {
        if let idx = mappings.firstIndex(where: { $0.id == mapping.id }) {
            mappings[idx] = mapping
            save()
        }
    }

    public func actionForGesture(_ gesture: GestureType) -> ActionTarget? {
        guard isEnabled else { return nil }
        return mappings.first(where: { $0.isEnabled && $0.gesture == gesture })?.action
    }
}
