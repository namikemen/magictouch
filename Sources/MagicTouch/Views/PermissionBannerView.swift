import SwiftUI

/// Banner prompting user to grant missing macOS permissions
public struct PermissionBannerView: View {
    @ObservedObject var permissionManager: PermissionManager

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: permissionManager.allGranted ? "checkmark.shield.fill" : "exclamationmark.triangle.fill")
                    .foregroundColor(permissionManager.allGranted ? .green : .yellow)
                    .imageScale(.medium)
                Text(permissionManager.allGranted ? "Permissions Active" : "Permissions Required")
                    .font(.system(size: 11, weight: .bold))
                Spacer()
            }

            if !permissionManager.allGranted {
                Text("Enable Accessibility & Input Monitoring. Note: macOS requires restarting MagicTouch after granting Input Monitoring.")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 8) {
                Button(action: {
                    permissionManager.requestAccessibility()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: permissionManager.hasAccessibility ? "checkmark.circle.fill" : "hand.raised.fill")
                            .foregroundColor(permissionManager.hasAccessibility ? .green : .yellow)
                        Text(permissionManager.hasAccessibility ? "Accessibility: OK" : "Grant Accessibility")
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.mini)

                Button(action: {
                    permissionManager.requestInputMonitoring()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: permissionManager.hasInputMonitoring ? "checkmark.circle.fill" : "keyboard.fill")
                            .foregroundColor(permissionManager.hasInputMonitoring ? .green : .yellow)
                        Text(permissionManager.hasInputMonitoring ? "Input: OK" : "Grant Input Monitoring")
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.mini)

                if !permissionManager.allGranted {
                    Button(action: {
                        permissionManager.restartApp()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.clockwise.circle.fill")
                            Text("Relaunch App")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.mini)
                }
            }
            .padding(.top, 2)
        }
        .padding(10)
        .background(permissionManager.allGranted ? Color.green.opacity(0.08) : Color.yellow.opacity(0.12))
        .cornerRadius(8)
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
}
