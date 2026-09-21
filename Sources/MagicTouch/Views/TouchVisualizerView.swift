import SwiftUI

/// Real-time visual feedback of fingers touching the Magic Mouse surface
public struct TouchVisualizerView: View {
    public var touches: [TouchPoint]

    public init(touches: [TouchPoint]) {
        self.touches = touches
    }

    public var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let cornerRadius = w * 0.22
            let touchSize = max(16.0, w * 0.17)

            ZStack {
                // Mouse Body Silhouette
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(Color.secondary.opacity(0.35), lineWidth: 1.5)
                    .background(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(Color(nsColor: .windowBackgroundColor))
                    )

                // Dividing notch
                VStack {
                    Capsule()
                        .fill(Color.secondary.opacity(0.25))
                        .frame(width: max(3.0, w * 0.03), height: max(14.0, h * 0.12))
                        .padding(.top, 10)
                    Spacer()
                    Text("Magic Mouse")
                        .font(.system(size: max(8.0, w * 0.07), weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(.bottom, 12)
                }

                // Active Finger Touches
                ForEach(touches) { touch in
                    let posX = min(max(CGFloat(touch.x) * w, 12.0), w - 12.0)
                    let posY = min(max((1.0 - CGFloat(touch.y)) * h, 12.0), h - 12.0)

                    Circle()
                        .fill(Color.accentColor.opacity(0.85))
                        .frame(width: touchSize, height: touchSize)
                        .shadow(color: Color.accentColor.opacity(0.5), radius: 4)
                        .overlay(
                            Text("\(touch.id)")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.white)
                        )
                        .position(x: posX, y: posY)
                }
            }
        }
        .aspectRatio(140.0 / 230.0, contentMode: .fit)
    }
}
