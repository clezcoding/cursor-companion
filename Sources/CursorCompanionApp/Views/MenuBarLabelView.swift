import SwiftUI
import CursorCompanionCore

/// Vektor-Icon für die macOS-Menüleiste (Sleeker Cursor Arrow)
struct MenuBarIconShape: View {
    var body: some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height
            
            // Sleeker, modern cursor arrow
            var path = Path()
            path.move(to: CGPoint(x: w * 0.2, y: h * 0.9))
            path.addLine(to: CGPoint(x: w * 0.2, y: h * 0.1))
            path.addLine(to: CGPoint(x: w * 0.85, y: h * 0.45))
            path.addLine(to: CGPoint(x: w * 0.55, y: h * 0.55))
            path.addLine(to: CGPoint(x: w * 0.7, y: h * 0.9))
            path.addLine(to: CGPoint(x: w * 0.5, y: h * 0.95))
            path.addLine(to: CGPoint(x: w * 0.35, y: h * 0.6))
            path.closeSubpath()
            
            context.fill(path, with: .color(.primary))
            
            // Subtiler status dot
            let orbitDot = Path(ellipseIn: CGRect(x: w * 0.7, y: h * 0.7, width: w * 0.25, height: h * 0.25))
            context.fill(orbitDot, with: .color(DesignSystem.accentSuccess))
        }
        .frame(width: 12, height: 12)
    }
}

struct MenuBarProgressRing: View {
    var percent: Double
    var color: Color
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: 2)
            
            Circle()
                .trim(from: 0, to: CGFloat(percent / 100.0))
                .stroke(color, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .frame(width: 12, height: 12)
    }
}

/// Menüleisten-Anzeige mit Icon und dynamischen Prozentwerten ("⌘ 63% · 41%")
public struct MenuBarLabelView: View {
    @ObservedObject var appState: AppState

    public init(appState: AppState) {
        self.appState = appState
    }

    private func colorForUsage(_ used: Double?) -> Color {
        guard let used = used else { return .secondary }
        if used >= 95.0 {
            return DesignSystem.accentError
        } else if used >= 80.0 {
            return DesignSystem.accentWarning
        } else {
            return DesignSystem.accentSuccess
        }
    }

    public var body: some View {
        HStack(spacing: 5) {
            // Sleek Icon
            MenuBarIconShape()
                .opacity(appState.isSyncing ? 0.3 : 0.8)
                .animation(appState.isSyncing ? Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true) : .default, value: appState.isSyncing)

            if let account = appState.activeAccount ?? appState.selectedAccount,
               let snapshot = account.snapshot {
                
                // Cursor Models
                if let cursorPct = snapshot.cursorModelsPercent {
                    HStack(spacing: 3) {
                        MenuBarProgressRing(percent: cursorPct, color: colorForUsage(cursorPct))
                        Text(String(format: "%.0f%%", cursorPct))
                            .foregroundColor(.primary)
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                    }
                }

                // Other Models
                if let otherPct = snapshot.otherModelsPercent {
                    HStack(spacing: 3) {
                        MenuBarProgressRing(percent: otherPct, color: colorForUsage(otherPct))
                        Text(String(format: "%.0f%%", otherPct))
                            .foregroundColor(.secondary)
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                    }
                }
            } else {
                Text("Cursor")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.primary)
            }
        }
        .padding(.horizontal, 4)
    }
}
