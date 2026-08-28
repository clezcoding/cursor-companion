import SwiftUI

/// Zentrale Design System Definitionen für CursorCompanion V2
/// Komplettes Redesign: Modern, Glassmorphism, Micro-Interactions (Emil Kowalski)

public struct DesignSystem {
    // Semantic Colors (Vibrant Dark Theme)
    public static let bgPrimary = Color(red: 0.05, green: 0.05, blue: 0.06) // Very deep blue/gray
    public static let bgSecondary = Color(white: 0.12).opacity(0.8)
    public static let bgTertiary = Color(white: 0.18).opacity(0.8)
    
    public static let textPrimary = Color.white
    public static let textSecondary = Color(white: 0.7)
    public static let textMuted = Color(white: 0.5)
    
    // Vibrant Accents
    public static let accentSuccess = Color(red: 0.1, green: 0.85, blue: 0.55) // Vibrant Green
    public static let accentWarning = Color(red: 1.0, green: 0.65, blue: 0.1) // Vibrant Orange
    public static let accentError = Color(red: 1.0, green: 0.3, blue: 0.4) // Vibrant Red
    public static let accentInfo = Color(red: 0.2, green: 0.6, blue: 1.0) // Vibrant Blue
    
    // Gradients for progress bars
    public static let successGradient = LinearGradient(colors: [Color(red: 0.0, green: 0.7, blue: 0.5), accentSuccess], startPoint: .leading, endPoint: .trailing)
    public static let warningGradient = LinearGradient(colors: [Color(red: 0.9, green: 0.5, blue: 0.0), accentWarning], startPoint: .leading, endPoint: .trailing)
    public static let errorGradient = LinearGradient(colors: [Color(red: 0.9, green: 0.1, blue: 0.2), accentError], startPoint: .leading, endPoint: .trailing)
    
    public static let borderDefault = Color.white.opacity(0.1)
    public static let borderHighlight = Color.white.opacity(0.2)
    
    // Custom Animations
    public struct Animations {
        /// Snappy ease-out curve for fast UI interactions (e.g. popovers entering)
        public static let snappyEaseOut = Animation.timingCurve(0.23, 1, 0.32, 1, duration: 0.25)
        
        /// Elastic spring for physical interactions (bouncy but controlled)
        public static let physicalSpring = Animation.spring(response: 0.35, dampingFraction: 0.65, blendDuration: 0.1)
        
        /// Very fast interaction spring (for button presses)
        public static let fastSpring = Animation.spring(response: 0.2, dampingFraction: 0.6)
        
        /// Smooth transition for states
        public static let smoothTransition = Animation.easeInOut(duration: 0.3)
    }
}

/// A modern button style that scales down on press with a snappy fast spring animation.
/// Uses 0.96 scale for that perfect tactile feel.
public struct ModernButtonStyle: ButtonStyle {
    public var scaleAmount: CGFloat = 0.96
    public var animation: Animation = DesignSystem.Animations.fastSpring
    public var baseOpacity: Double = 1.0
    public var pressedOpacity: Double = 0.7
    
    public init(scaleAmount: CGFloat = 0.96, animation: Animation = DesignSystem.Animations.fastSpring, baseOpacity: Double = 1.0, pressedOpacity: Double = 0.7) {
        self.scaleAmount = scaleAmount
        self.animation = animation
        self.baseOpacity = baseOpacity
        self.pressedOpacity = pressedOpacity
    }
    
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .contentShape(Rectangle()) // Explicit content shape fixes empty space clicks
            .opacity(configuration.isPressed ? pressedOpacity : baseOpacity)
            .scaleEffect(configuration.isPressed ? scaleAmount : 1.0)
            .animation(animation, value: configuration.isPressed)
    }
}

public extension ButtonStyle where Self == ModernButtonStyle {
    static var modern: ModernButtonStyle {
        ModernButtonStyle()
    }
    static var springy: ModernButtonStyle {
        ModernButtonStyle(animation: DesignSystem.Animations.fastSpring)
    }
}

/// A modifier that applies a subtle background color change on hover with a snappy curve.
public struct HoverEffectModifier: ViewModifier {
    let hoverColor: Color
    let defaultColor: Color
    let cornerRadius: CGFloat
    
    @State private var isHovered = false
    
    public init(hoverColor: Color = DesignSystem.bgTertiary, defaultColor: Color = Color.clear, cornerRadius: CGFloat = 6) {
        self.hoverColor = hoverColor
        self.defaultColor = defaultColor
        self.cornerRadius = cornerRadius
    }
    
    public func body(content: Content) -> some View {
        content
            .background(isHovered ? hoverColor : defaultColor)
            .cornerRadius(cornerRadius)
            .onHover { hovering in
                withAnimation(DesignSystem.Animations.snappyEaseOut) {
                    isHovered = hovering
                }
            }
    }
}

/// A modifier for 3D tilt effect based on mouse movement (emulating physical objects)
public struct TiltEffectModifier: ViewModifier {
    @State private var hoverLocation: CGPoint = .zero
    @State private var isHovering = false
    
    public func body(content: Content) -> some View {
        GeometryReader { geo in
            content
                .rotation3DEffect(
                    .degrees(isHovering ? 4 : 0),
                    axis: (
                        x: (geo.size.height / 2 - hoverLocation.y) / geo.size.height,
                        y: -(geo.size.width / 2 - hoverLocation.x) / geo.size.width,
                        z: 0
                    )
                )
                .animation(DesignSystem.Animations.physicalSpring, value: isHovering)
                .animation(DesignSystem.Animations.fastSpring, value: hoverLocation)
                .onContinuousHover { phase in
                    switch phase {
                    case .active(let location):
                        isHovering = true
                        hoverLocation = location
                    case .ended:
                        isHovering = false
                        hoverLocation = CGPoint(x: geo.size.width/2, y: geo.size.height/2)
                    }
                }
        }
    }
}

// Visual Effect Blur for Glassmorphism
public struct VisualEffectView: NSViewRepresentable {
    public var material: NSVisualEffectView.Material
    public var blendingMode: NSVisualEffectView.BlendingMode
    public var state: NSVisualEffectView.State

    public init(
        material: NSVisualEffectView.Material = .popover,
        blendingMode: NSVisualEffectView.BlendingMode = .behindWindow,
        state: NSVisualEffectView.State = .active
    ) {
        self.material = material
        self.blendingMode = blendingMode
        self.state = state
    }

    public func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = state
        return view
    }

    public func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
        nsView.state = state
    }
}

public extension View {
    func modernHoverEffect(hoverColor: Color = DesignSystem.bgTertiary, defaultColor: Color = Color.clear, cornerRadius: CGFloat = 8) -> some View {
        self.modifier(HoverEffectModifier(hoverColor: hoverColor, defaultColor: defaultColor, cornerRadius: cornerRadius))
    }
    
    func interactiveTilt() -> some View {
        self.modifier(TiltEffectModifier())
    }
    
    func glassBackground(cornerRadius: CGFloat = 12) -> some View {
        self.background(
            VisualEffectView(material: .hudWindow, blendingMode: .behindWindow, state: .active)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        )
    }
}
