import SwiftUI

/// Real-time visual feedback of fingers touching the Magic Mouse surface
public struct TouchVisualizerView: View {
    public var touches: [TouchPoint]
    public var touchAreaMinY: Double

    public init(touches: [TouchPoint], touchAreaMinY: Double = 0.0) {
        self.touches = touches
        self.touchAreaMinY = touchAreaMinY
    }

    public var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let cornerRadius = w * 0.22
            let touchSize = max(16.0, w * 0.17)
            let splitY = (touchAreaMinY > 0.0) ? (1.0 - CGFloat(touchAreaMinY)) * h : h

            ZStack {
                // Mouse Body Silhouette
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(Color.secondary.opacity(0.35), lineWidth: 1.5)
                    .background(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(Color(nsColor: .windowBackgroundColor))
                    )

                // Ignored lower zone shading if touchAreaMinY > 0
                if touchAreaMinY > 0.0 {
                    VStack(spacing: 0) {
                        Spacer()
                            .frame(height: splitY)
                        ZStack {
                            Rectangle()
                                .fill(Color.secondary.opacity(0.08))
                            Text("Ignored Zone")
                                .font(.system(size: max(7.0, w * 0.06), weight: .semibold))
                                .foregroundColor(.secondary.opacity(0.6))
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))

                    // Boundary dashed line
                    Path { p in
                        p.move(to: CGPoint(x: 10, y: splitY))
                        p.addLine(to: CGPoint(x: w - 10, y: splitY))
                    }
                    .stroke(style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                    .foregroundColor(Color.secondary.opacity(0.45))
                }

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

                // Active & Ignored Finger Touches
                ForEach(touches) { touch in
                    let posX = min(max(CGFloat(touch.x) * w, 12.0), w - 12.0)
                    let posY = min(max((1.0 - CGFloat(touch.y)) * h, 12.0), h - 12.0)
                    let isIgnored = touchAreaMinY > 0.0 && Double(touch.y) < touchAreaMinY

                    Circle()
                        .fill(isIgnored ? Color.secondary.opacity(0.35) : Color.accentColor.opacity(0.85))
                        .frame(width: touchSize, height: touchSize)
                        .shadow(color: isIgnored ? Color.clear : Color.accentColor.opacity(0.5), radius: 4)
                        .overlay(
                            Text("\(touch.id)")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(isIgnored ? Color.secondary : Color.white)
                        )
                        .position(x: posX, y: posY)
                }
            }
        }
        .aspectRatio(140.0 / 230.0, contentMode: .fit)
    }
}
