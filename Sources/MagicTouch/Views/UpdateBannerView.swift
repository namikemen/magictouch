import SwiftUI

/// Banner displayed at the top of the popover when a newer version is available.
public struct UpdateBannerView: View {
    @ObservedObject var updateChecker: UpdateChecker = UpdateChecker.shared

    public init() {}

    public var body: some View {
        if updateChecker.isUpdateAvailable && !updateChecker.isDismissed {
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .center) {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.accentColor)

                    Text("Update Available: v\(updateChecker.latestVersion)")
                        .font(.system(size: 12, weight: .bold))

                    Spacer()

                    Button(action: {
                        updateChecker.dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }

                if !updateChecker.releaseNotes.isEmpty {
                    Text(updateChecker.releaseNotes)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                if updateChecker.isDownloading {
                    VStack(alignment: .leading, spacing: 3) {
                        ProgressView(value: updateChecker.downloadProgress, total: 1.0)
                            .progressViewStyle(.linear)

                        Text(updateChecker.statusMessage ?? "Downloading...")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 2)
                } else {
                    HStack(spacing: 8) {
                        Button(action: {
                            updateChecker.startDownload()
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.down")
                                Text("Download DMG")
                            }
                            .font(.system(size: 10, weight: .semibold))
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)

                        if let pageURL = updateChecker.releasePageURL {
                            Button(action: {
                                NSWorkspace.shared.open(pageURL)
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "link")
                                    Text("Changelog")
                                }
                                .font(.system(size: 10))
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }

                        if let status = updateChecker.statusMessage, !updateChecker.statusMessage!.contains("Checking") {
                            Text(status)
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                    .padding(.top, 2)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color.accentColor.opacity(0.1))
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color.accentColor.opacity(0.3)),
                alignment: .bottom
            )
        }
    }
}
