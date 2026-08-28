import SwiftUI
import Charts
import CursorCompanionCore

public struct SparklineView: View {
    let history: [UsageSnapshot]
    
    public init(history: [UsageSnapshot]) {
        self.history = history
    }
    
    public var body: some View {
        if history.isEmpty {
            Rectangle()
                .fill(Color.gray.opacity(0.1))
                .frame(height: 20)
                .cornerRadius(4)
        } else {
            Chart(Array(history.enumerated()), id: \.offset) { index, snapshot in
                let total = (snapshot.cursorModelsPercent ?? 0) + (snapshot.otherModelsPercent ?? 0)
                LineMark(
                    x: .value("Time", index),
                    y: .value("Usage", total)
                )
                .foregroundStyle(DesignSystem.accentSuccess.gradient)
                .interpolationMethod(.monotone)
                
                AreaMark(
                    x: .value("Time", index),
                    y: .value("Usage", total)
                )
                .foregroundStyle(LinearGradient(colors: [DesignSystem.accentSuccess.opacity(0.3), Color.clear], startPoint: .top, endPoint: .bottom))
                .interpolationMethod(.monotone)
            }
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .frame(height: 30)
        }
    }
}

public struct SparklineWrapperView: View {
    @ObservedObject var appState: AppState
    let accountID: String
    @State private var history: [UsageSnapshot] = []
    
    public init(appState: AppState, accountID: String) {
        self.appState = appState
        self.accountID = accountID
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Activity (Last 7 Days)")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(DesignSystem.textSecondary)
            
            SparklineView(history: history)
        }
        .task(id: accountID) {
            history = await appState.historyStore.fetchHistory(for: accountID, limit: 50)
            history.reverse()
        }
    }
}
