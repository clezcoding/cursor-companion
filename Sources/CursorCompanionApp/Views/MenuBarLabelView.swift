import SwiftUI
import CursorCompanionCore

/// Kompakte Menüleisten-Anzeige mit dynamischer Signal-Farbe ("63% · 41%")
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
        HStack(spacing: 4) {
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
        .padding(.horizontal, 2)
    }
}
