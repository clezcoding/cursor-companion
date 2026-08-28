import WidgetKit
import SwiftUI
import CursorCompanionCore

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), cursorPercent: 50.0)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), cursorPercent: 65.0)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        // Find the active account's ID and fetch the latest snapshot
        // Note: For a real app with WidgetKit, UserDefaults (App Group) should store the selected account.
        // For our MVP, we just get the latest snapshot of the first account found in the DB.
        var percent = 0.0
        
        let fileManager = FileManager.default
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = appSupport.appendingPathComponent("CursorCompanion")
        let accountsFile = appDir.appendingPathComponent("accounts.json")
        
        if let data = try? Data(contentsOf: accountsFile),
           let accounts = try? JSONDecoder().decode([CursorAccount].self, from: data),
           let first = accounts.first {
            
            let history = AnalyticsDatabase.shared.fetchHistory(for: first.id, limit: 1)
            if let latest = history.first {
                percent = latest.cursorPercent
            } else {
                percent = first.snapshot?.cursorModelsPercent ?? 0.0
            }
        }
        
        let entries = [
            SimpleEntry(date: Date(), cursorPercent: percent)
        ]
        
        let timeline = Timeline(entries: entries, policy: .after(Date().addingTimeInterval(15 * 60)))
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let cursorPercent: Double
}

struct CursorCompanionWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Cursor Models")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.2))
                        .frame(height: 12)
                    
                    Capsule()
                        .fill(Color.green)
                        .frame(width: max(0, min(geo.size.width, geo.size.width * CGFloat(entry.cursorPercent / 100.0))), height: 12)
                }
            }
            .frame(height: 12)
            
            Text("\(Int(entry.cursorPercent))% used")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
        }
        .padding()
    }
}

@main
struct CursorCompanionWidget: Widget {
    let kind: String = "CursorCompanionWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(macOS 14.0, *) {
                CursorCompanionWidgetEntryView(entry: entry)
                    .containerBackground(Color.black.gradient, for: .widget)
            } else {
                CursorCompanionWidgetEntryView(entry: entry)
                    .background(Color.black.gradient)
            }
        }
        .configurationDisplayName("Cursor Usage")
        .description("Track your Cursor AI token usage directly from your desktop.")
    }
}
