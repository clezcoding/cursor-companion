import SwiftUI
import CursorCompanionCore

/// Vektor-Icon für die macOS-Menüleiste (Cursor Chevron mit Orbit-Punkt)
struct MenuBarIconShape: View {
    var body: some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height
            
            // Cursor Arrowhead Pfad
            var path = Path()
            path.move(to: CGPoint(x: w * 0.15, y: h * 0.90))
            path.addLine(to: CGPoint(x: w * 0.15, y: h * 0.10))
            path.addLine(to: CGPoint(x: w * 0.90, y: h * 0.50))
            path.addLine(to: CGPoint(x: w * 0.52, y: h * 0.58))
            path.closeSubpath()
            
            context.fill(path, with: .color(.white))
            
            // Subtiler mintfarbener Status-Orbit
            let orbitDot = Path(ellipseIn: CGRect(x: w * 0.65, y: h * 0.70, width: w * 0.28, height: h * 0.28))
            context.fill(orbitDot, with: .color(Color(red: 0.06, green: 0.73, blue: 0.51)))
        }
        .frame(width: 13, height: 13)
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
        if used >= 85.0 {
            return Color(red: 0.96, green: 0.25, blue: 0.37) // #F43F5E (Kritisch)
        } else if used >= 70.0 {
            return Color(red: 0.96, green: 0.62, blue: 0.04) // #F59E0B (Warnung)
        } else {
            return Color(red: 0.06, green: 0.73, blue: 0.51) // #10B981 (Normal)
        }
    }

    public var body: some View {
        HStack(spacing: 5) {
            // App Icon in der Menüleiste
            MenuBarIconShape()

            if let account = appState.activeAccount ?? appState.selectedAccount,
               let snapshot = account.snapshot {
                
                // Cursor Models %
                if let cursorPct = snapshot.cursorModelsPercent {
                    Text(String(format: "%.0f%%", cursorPct))
                        .foregroundColor(colorForUsage(cursorPct))
                        .font(.system(size: 11.5, weight: .semibold, design: .monospaced))
                } else {
                    Text("—")
                        .foregroundColor(.secondary)
                        .font(.system(size: 11.5, weight: .semibold, design: .monospaced))
                }

                Text("·")
                    .foregroundColor(Color(white: 0.4))
                    .font(.system(size: 11))

                // Other Models %
                if let otherPct = snapshot.otherModelsPercent {
                    Text(String(format: "%.0f%%", otherPct))
                        .foregroundColor(colorForUsage(otherPct))
                        .font(.system(size: 11.5, weight: .semibold, design: .monospaced))
                } else {
                    Text("—")
                        .foregroundColor(.secondary)
                        .font(.system(size: 11.5, weight: .semibold, design: .monospaced))
                }
            } else {
                Text("Cursor")
                    .font(.system(size: 11.5, weight: .semibold))
                    .foregroundColor(.primary)
            }
        }
        .padding(.horizontal, 3)
    }
}
