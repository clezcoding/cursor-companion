import SwiftUI
import Charts
import CursorCompanionCore

public struct HistoryChartView: View {
    let accountID: String
    @State private var history: [AnalyticsSnapshot] = []
    
    public init(accountID: String) {
        self.accountID = accountID
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Activity (Last 7 Days)")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(DesignSystem.textSecondary)
                .padding(.horizontal, 4)
            
            if history.isEmpty {
                Text("No data available yet")
                    .font(.system(size: 11))
                    .foregroundColor(DesignSystem.textMuted)
                    .frame(height: 100)
                    .frame(maxWidth: .infinity)
                    .background(DesignSystem.bgSecondary)
                    .cornerRadius(8)
            } else {
                Chart {
                    ForEach(history) { snapshot in
                        // BarChart stacked for Cursor vs Other
                        BarMark(
                            x: .value("Time", snapshot.timestamp),
                            y: .value("Cursor", snapshot.cursorPercent)
                        )
                        .foregroundStyle(DesignSystem.accentSuccess.gradient)
                        
                        BarMark(
                            x: .value("Time", snapshot.timestamp),
                            y: .value("Other", snapshot.otherPercent)
                        )
                        .foregroundStyle(DesignSystem.accentWarning.gradient)
                    }
                }
                .chartXAxis {
                    AxisMarks(preset: .aligned, values: .stride(by: .day)) { value in
                        if let date = value.as(Date.self) {
                            AxisValueLabel {
                                Text(date, format: .dateTime.weekday(.abbreviated))
                                    .font(.system(size: 9))
                                    .foregroundColor(DesignSystem.textMuted)
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading, values: .automatic(desiredCount: 3)) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 2]))
                            .foregroundStyle(DesignSystem.borderDefault)
                        if let percent = value.as(Double.self) {
                            AxisValueLabel {
                                Text("\(Int(percent))%")
                                    .font(.system(size: 9))
                                    .foregroundColor(DesignSystem.textMuted)
                            }
                        }
                    }
                }
                .frame(height: 100)
                .padding(8)
                .background(DesignSystem.bgSecondary)
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(DesignSystem.borderHighlight, lineWidth: 0.5))
            }
        }
        .onAppear {
            loadHistory()
        }
    }
    
    private func loadHistory() {
        // Fetch up to 50 snapshots
        let data = AnalyticsDatabase.shared.fetchHistory(for: accountID, limit: 50)
        
        // Group by day to prevent too many bars
        var grouped: [Date: AnalyticsSnapshot] = [:]
        let calendar = Calendar.current
        
        for snap in data {
            let day = calendar.startOfDay(for: snap.timestamp)
            if let existing = grouped[day] {
                // Keep the max percentage for that day
                if snap.cursorPercent > existing.cursorPercent {
                    grouped[day] = snap
                }
            } else {
                grouped[day] = snap
            }
        }
        
        self.history = grouped.values.sorted(by: { $0.timestamp < $1.timestamp })
    }
}
