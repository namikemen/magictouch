import AppKit
import Carbon.HIToolbox
import Foundation

/// Registers and manages the system-wide keyboard shortcut that toggles the app's
/// master enable switch. The shortcut configuration is read from ConfigurationStore
/// and is re-registered automatically whenever it changes.
public final class GlobalHotkeyManager {
    public static let shared = GlobalHotkeyManager()

    /// Stable four-character signature for our hot keys ("MTog").
    fileprivate static let hotKeySignature: FourCharCode = 0x4D546F67
    fileprivate static let hotKeyID: UInt32 = 1

    fileprivate var onToggle: (() -> Void)?
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerInstalled = false

    private init() {}

    deinit {
        NotificationCenter.default.removeObserver(self)
        unregister()
    }

    /// Installs the Carbon event handler (once) and registers the shortcut from
    /// ConfigurationStore. Must be called after the app finishes launching.
    public func start(onToggle: @escaping () -> Void) {
        self.onToggle = onToggle

        installEventHandlerIfNeeded()
        register()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(toggleHotkeyConfigDidChange),
            name: .magicTouchToggleHotkeyChanged,
            object: nil
        )
    }

    /// Unregisters and re-registers the shortcut using the latest configuration.
    public func reload() {
        register()
    }

    // MARK: - Notification handling

    @objc private func toggleHotkeyConfigDidChange() {
        register()
    }

    // MARK: - Registration

    private func register() {
        unregister()

        let store = ConfigurationStore.shared
        // No key code or no modifiers: the shortcut is intentionally disabled.
        guard store.hasToggleHotkey else { return }

        var carbonModifiers: UInt32 = 0
        for modifier in store.toggleHotkeyModifiers {
            switch modifier {
            case .command: carbonModifiers |= UInt32(cmdKey)
            case .option: carbonModifiers |= UInt32(optionKey)
            case .control: carbonModifiers |= UInt32(controlKey)
            case .shift: carbonModifiers |= UInt32(shiftKey)
            }
        }

        let hotKeyID = EventHotKeyID(signature: Self.hotKeySignature, id: Self.hotKeyID)
        let status = RegisterEventHotKey(
            UInt32(store.toggleHotkeyKeyCode),
            carbonModifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        if status != noErr {
            NSLog("MagicTouch: Failed to register toggle hotkey (status %d)", status)
        }
    }

    private func unregister() {
        if let hotKeyRef = hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
    }

    // MARK: - Carbon event plumbing

    private func installEventHandlerIfNeeded() {
        guard !eventHandlerInstalled else { return }

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let userData = Unmanaged.passUnretained(self).toOpaque()
        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            magicTouchHotkeyEventHandler,
            1,
            &eventType,
            userData,
            nil
        )
        eventHandlerInstalled = (status == noErr)

        if status != noErr {
            NSLog("MagicTouch: Failed to install hotkey event handler (status %d)", status)
        }
    }
}

/// Non-capturing C-compatible event handler; the manager instance is recovered from
/// the userData pointer supplied to InstallEventHandler. Top-level functions (unlike
/// static methods) can be converted to a C function pointer.
private func magicTouchHotkeyEventHandler(
    _ handlerRef: EventHandlerCallRef?,
    _ event: EventRef?,
    _ userData: UnsafeMutableRawPointer?
) -> OSStatus {
    guard let event = event, let userData = userData else { return noErr }

    var hotKeyID = EventHotKeyID()
    let status = GetEventParameter(
        event,
        EventParamName(kEventParamDirectObject),
        EventParamType(typeEventHotKeyID),
        nil,
        MemoryLayout<EventHotKeyID>.size,
        nil,
        &hotKeyID
    )

    if status == noErr,
       hotKeyID.signature == GlobalHotkeyManager.hotKeySignature,
       hotKeyID.id == GlobalHotkeyManager.hotKeyID {
        let manager = Unmanaged<GlobalHotkeyManager>.fromOpaque(userData).takeUnretainedValue()
        DispatchQueue.main.async {
            manager.onToggle?()
        }
    }

    return noErr
}
