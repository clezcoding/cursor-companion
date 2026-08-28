import SwiftUI

/// 2px Hairline Progress Metric Row mit eindeutiger Verbrauchs- vs. Verbleibend-Anzeige
public struct MetricBlockView: View {
    public let title: String
    public let subtitle: String?
    public let percentUsed: Double?

    public init(title: String, subtitle: String? = nil, percentUsed: Double?) {
        self.title = title
        self.subtitle = subtitle
        self.percentUsed = percentUsed
    }

    /// Dynamische Signalfarbe basierend auf dem Verbrauchsgrad
    private var statusColor: Color {
        guard let used = percentUsed else { return Color(white: 0.4) }
        if used >= 85.0 {
            return Color(red: 0.96, green: 0.25, blue: 0.37) // #F43F5E (Kritisch verbraucht)
        } else if used >= 70.0 {
            return Color(red: 0.96, green: 0.62, blue: 0.04) // #F59E0B (Warnung)
        } else {
            return Color(red: 0.06, green: 0.73, blue: 0.51) // #10B981 (Entspannt)
        }
    }

    private var remainingText: String? {
        guard let used = percentUsed else { return nil }
        let rem = max(0.0, 100.0 - used)
        return String(format: "%.0f%% frei", rem)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            // Header Row: Titel & Prozentangabe "verbraucht"
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(Color(white: 0.7))
                
                Spacer()

                if let used = percentUsed {
                    HStack(spacing: 4) {
                        Text(String(format: "%.0f%%", used))
                            .font(.system(size: 13, weight: .semibold, design: .monospaced))
                            .foregroundColor(statusColor)
                        
                        Text("verbraucht")
                            .font(.system(size: 10.5, weight: .regular))
                            .foregroundColor(Color(white: 0.5))
                    }
                } else {
                    Text("Keine Daten")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(Color(white: 0.4))
                }
            }

            // 2px Hairline Verbrauchs-Balken
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Hintergrund: Dunkle unverbrauchte Schiene
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color(white: 0.15))
                        .frame(height: 2)

                    // Vordergrund: Bereits verbrauchter Anteil
                    if let used = percentUsed {
                        let clamped = max(0.0, min(100.0, used))
                        let width = geo.size.width * CGFloat(clamped / 100.0)
                        RoundedRectangle(cornerRadius: 1)
                            .fill(statusColor)
                            .frame(width: width, height: 2)
                            .animation(.easeOut(duration: 0.25), value: used)
                    }
                }
            }
            .frame(height: 2)

            // Subtitle Row: Modell-Typ & Verbleibend-Hinweis
            HStack {
                if let sub = subtitle {
                    Text(sub)
                        .font(.system(size: 10))
                        .foregroundColor(Color(white: 0.4))
                }
                Spacer()
                if let rem = remainingText {
                    Text(rem)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(Color(white: 0.45))
                }
            }
            .padding(.top, 1)
        }
    }
}
