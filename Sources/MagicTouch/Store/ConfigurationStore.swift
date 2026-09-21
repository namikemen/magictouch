import Foundation
import Combine
import SwiftUI

/// Manages loading, saving, and updating user gesture configurations
public final class ConfigurationStore: ObservableObject {
    public static let shared = ConfigurationStore()

    @Published public var mappings: [GestureMapping] = []
    @Published public var isEnabled: Bool = true

    private let saveURL: URL

    public init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = appSupport.appendingPathComponent("MagicTouch", isDirectory: true)

        try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)
        self.saveURL = appDir.appendingPathComponent("gestures.json")

        load()
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

        // Exact match first
        if let direct = mappings.first(where: { $0.isEnabled && $0.gesture == gesture })?.action {
            return direct
        }

        // Fallback for left/right sub-zone taps if general gesture is configured
        switch gesture {
        case .oneFingerDoubleTapLeft, .oneFingerDoubleTapRight:
            return mappings.first(where: { $0.isEnabled && $0.gesture == .oneFingerDoubleTap })?.action
        case .oneFingerTripleTapLeft, .oneFingerTripleTapRight:
            return mappings.first(where: { $0.isEnabled && $0.gesture == .oneFingerTripleTap })?.action
        default:
            return nil
        }
    }
}
