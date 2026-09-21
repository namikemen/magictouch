import SwiftUI
import AppKit

/// Branded MagicTouch logo view with intelligent resource resolution
public struct AppLogoView: View {
    public var size: CGFloat

    public init(size: CGFloat = 30) {
        self.size = size
    }

    public var body: some View {
        if let image = loadLogoImage() {
            Image(nsImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size, height: size)
                .clipShape(RoundedRectangle(cornerRadius: size * 0.22, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                        .stroke(Color.primary.opacity(0.10), lineWidth: 0.5)
                )
                .shadow(color: Color.black.opacity(0.18), radius: 2.5, x: 0, y: 1.5)
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                    .fill(Color.accentColor.opacity(0.15))
                Image(systemName: "magicmouse.fill")
                    .font(.system(size: size * 0.52))
                    .foregroundColor(.accentColor)
            }
            .frame(width: size, height: size)
        }
    }

    private func loadLogoImage() -> NSImage? {
        // 1. Bundle resource (standard .app packaging)
        if let url = Bundle.main.url(forResource: "logo", withExtension: "png"),
           let img = NSImage(contentsOf: url) {
            return img
        }
        if let resURL = Bundle.main.resourceURL?.appendingPathComponent("logo.png"),
           let img = NSImage(contentsOf: resURL) {
            return img
        }

        // 2. Directory adjacent to the running binary
        let binDir = Bundle.main.bundleURL.deletingLastPathComponent()
        let adjLogo = binDir.appendingPathComponent("logo.png")
        if let img = NSImage(contentsOf: adjLogo) {
            return img
        }

        // 3. Known relative paths (during local dev/testing)
        let searchPaths = [
            "Resources/logo.png",
            "logo.png",
            "../logo.png"
        ]
        for path in searchPaths {
            let fileURL = URL(fileURLWithPath: path)
            if FileManager.default.fileExists(atPath: fileURL.path),
               let img = NSImage(contentsOf: fileURL) {
                return img
            }
        }

        return nil
    }
}
