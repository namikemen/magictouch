import SwiftUI

/// Main popover window shown when user clicks the menu bar icon
public struct MainPopoverView: View {
    @ObservedObject var appState: AppState = AppState.shared
    @ObservedObject var configStore: ConfigurationStore = ConfigurationStore.shared
    @ObservedObject var permissionManager: PermissionManager = PermissionManager.shared
    @ObservedObject var updateChecker: UpdateChecker = UpdateChecker.shared

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            HStack(alignment: .center, spacing: 10) {
                AppLogoView(size: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text("MagicTouch")
                        .font(.system(size: 15, weight: .bold))

                    HStack(spacing: 6) {
                        Circle()
                            .fill(appState.isConnected ? Color.green : Color.orange)
                            .frame(width: 7, height: 7)
                        Text(appState.isConnected ? appState.deviceName : "Searching for Magic Mouse...")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                HStack(spacing: 8) {
                    Text(configStore.isEnabled ? "Active" : "Disabled")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(configStore.isEnabled ? .primary : .secondary)

                    Toggle("", isOn: $configStore.isEnabled)
                        .toggleStyle(.switch)
                        .labelsHidden()
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(Color(nsColor: .windowBackgroundColor))

            // Permission Banner
            PermissionBannerView(permissionManager: permissionManager)

            // Update Banner
            UpdateBannerView()

            Divider()

            // Main Content Area (Visualizer + Mappings)
            HStack(alignment: .top, spacing: 16) {
                // Left Column: Live Visualizer (Relative sizing)
                VStack(spacing: 10) {
                    TouchVisualizerView(touches: appState.touches)
                        .frame(maxWidth: 130, maxHeight: 210)
                        .padding(.top, 4)

                    if !appState.lastGesture.isEmpty {
                        VStack(spacing: 2) {
                            Text("Detected Gesture")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(.secondary)
                            Text(appState.lastGesture)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.accentColor)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .frame(maxWidth: .infinity)
                        .background(Color.accentColor.opacity(0.12))
                        .cornerRadius(6)
                    } else {
                        Text("Touch surface to test")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }

                    Spacer(minLength: 0)
                }
                .frame(width: 135)

                // Right Column: Assigned Gestures List
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Assigned Gestures (\(configStore.mappings.count))")
                            .font(.system(size: 12, weight: .semibold))

                        Spacer()

                        Button(action: { appState.showingAddSheet = true }) {
                            HStack(spacing: 4) {
                                Image(systemName: "plus")
                                Text("Add Gesture")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }

                    // Safe, crash-free list iteration using IDs
                    ScrollView {
                        LazyVStack(spacing: 6) {
                            ForEach(configStore.mappings) { mapping in
                                HStack(spacing: 10) {
                                    Toggle("", isOn: Binding(
                                        get: { mapping.isEnabled },
                                        set: { _ in
                                            configStore.toggleMapping(id: mapping.id)
                                        }
                                    ))
                                    .labelsHidden()
                                    .toggleStyle(.checkbox)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(mapping.gesture.rawValue)
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(mapping.isEnabled ? .primary : .secondary)

                                        Text(mapping.action.displayName)
                                            .font(.system(size: 11))
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                    }

                                    Spacer()

                                    Button(action: {
                                        configStore.deleteMapping(id: mapping.id)
                                    }) {
                                        Image(systemName: "trash")
                                            .foregroundColor(.secondary)
                                    }
                                    .buttonStyle(.plain)
                                    .padding(.trailing, 4)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 7)
                                .background(Color(nsColor: .controlBackgroundColor))
                                .cornerRadius(6)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                    .frame(maxHeight: .infinity)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding(14)
            .background(Color(nsColor: .underPageBackgroundColor).opacity(0.35))

            Divider()

            // Footer Bar
            HStack(spacing: 12) {
                Button("Quit MagicTouch") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
                .font(.system(size: 11))

                Button(action: {
                    updateChecker.checkForUpdates(manual: true)
                }) {
                    HStack(spacing: 4) {
                        if updateChecker.isChecking {
                            ProgressView()
                                .controlSize(.mini)
                        } else {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 9))
                        }
                        Text(updateChecker.isChecking ? "Checking..." : "Check for Updates")
                    }
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
                .font(.system(size: 11))

                if let status = updateChecker.statusMessage, !updateChecker.isUpdateAvailable {
                    Text(status)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                Text("v\(updateChecker.currentVersion)")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary.opacity(0.8))
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 8)
            .background(Color(nsColor: .windowBackgroundColor))
        }
        .frame(minWidth: 560, minHeight: 440)
        .sheet(isPresented: $appState.showingAddSheet) {
            GestureEditorSheet { newMapping in
                configStore.addMapping(newMapping)
            }
        }
    }
}
