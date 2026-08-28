import SwiftUI
import CursorCompanionCore

/// Kompakte Menüleisten-Anzeige ("63% · 41%")
public struct MenuBarLabelView: View {
    @ObservedObject var appState: AppState

    public init(appState: AppState) {
        self.appState = appState
    }

    public var body: some View {
        HStack(spacing: 5) {
            if let account = appState.activeAccount ?? appState.selectedAccount,
               let snapshot = account.snapshot {
                
                if let cursorPct = snapshot.cursorModelsPercent {
                    Text(String(format: "%.0f%%", cursorPct))
                        .foregroundColor(Color(red: 0.06, green: 0.73, blue: 0.51)) // #10B981
                        .font(.system(size: 11.5, weight: .semibold, design: .monospaced))
                } else {
                    Text("—")
                        .foregroundColor(.secondary)
                        .font(.system(size: 11.5, weight: .semibold, design: .monospaced))
                }

                Text("·")
                    .foregroundColor(Color(white: 0.4))
                    .font(.system(size: 11))

                if let otherPct = snapshot.otherModelsPercent {
                    Text(String(format: "%.0f%%", otherPct))
                        .foregroundColor(Color(red: 0.96, green: 0.62, blue: 0.04)) // #F59E0B
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
