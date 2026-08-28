import SwiftUI

public struct SlimProgressBar: View {
    public let percentUsed: Double?
    public let color: Color
    @State private var animatedPercent: Double = 0.0

    public init(percentUsed: Double?, color: Color = DesignSystem.accentInfo) {
        self.percentUsed = percentUsed
        self.color = color
    }

    public var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Track
                Capsule()
                    .fill(Color.black.opacity(0.2))
                    .frame(height: 4)

                // Indicator
                if percentUsed != nil {
                    let clamped = max(0.0, min(100.0, animatedPercent))
                    let width = geo.size.width * CGFloat(clamped / 100.0)
                    
                    Capsule()
                        .fill(color)
                        .frame(width: width, height: 4)
                }
            }
        }
        .frame(height: 4)
        .onAppear {
            if let target = percentUsed {
                withAnimation(DesignSystem.Animations.physicalSpring.delay(0.1)) {
                    animatedPercent = target
                }
            }
        }
        .onChange(of: percentUsed) { newValue in
            if let target = newValue {
                withAnimation(DesignSystem.Animations.physicalSpring) {
                    animatedPercent = target
                }
            }
        }
    }
}
