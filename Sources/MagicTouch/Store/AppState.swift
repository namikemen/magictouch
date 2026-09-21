import Foundation
import Combine

public final class AppState: ObservableObject {
    public static let shared = AppState()

    @Published public var touches: [TouchPoint] = []
    @Published public var lastGesture: String = ""
    @Published public var isConnected: Bool = false
    @Published public var deviceName: String = "Magic Mouse"
    @Published public var showingAddSheet: Bool = false

    private init() {}
}
