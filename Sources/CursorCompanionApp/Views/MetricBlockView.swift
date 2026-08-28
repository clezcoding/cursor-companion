import SwiftUI

/// 2px Hairline Progress Metric Row im Emil Kowalski Minimalist Stil
public struct MetricBlockView: View {
    public let title: String
    public let percent: Double?
    public let tintColor: Color

    public init(title: String, percent: Double?, tintColor: Color) {
        self.title = title
        self.percent = percent
        self.tintColor = tintColor
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(Color(white: 0.6))
                
                Spacer()

                if let pct = percent {
                    Text(String(format: "%.0f%%", pct))
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .foregroundColor(Color(white: 0.95))
                } else {
                    Text("Keine Daten")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(Color(white: 0.4))
                }
            }

            // 2px Pure Hairline Track
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color(white: 0.15))
                        .frame(height: 2)

                    if let pct = percent {
                        let width = max(0, min(geo.size.width, geo.size.width * CGFloat(pct / 100.0)))
                        RoundedRectangle(cornerRadius: 1)
                            .fill(tintColor)
                            .frame(width: width, height: 2)
                            .animation(.easeOut(duration: 0.25), value: pct)
                    }
                }
            }
            .frame(height: 2)
        }
    }
}
