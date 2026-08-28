import SwiftUI

public struct MetricBlockView: View {
    public let title: String
    public let subtitle: String?
    public let percentUsed: Double?

    public init(title: String, subtitle: String? = nil, percentUsed: Double?) {
        self.title = title
        self.subtitle = subtitle
        self.percentUsed = percentUsed
    }

    private var statusColor: Color {
        guard let used = percentUsed else { return DesignSystem.textSecondary }
        if used >= 85.0 {
            return DesignSystem.accentError
        } else if used >= 70.0 {
            return DesignSystem.accentWarning
        } else {
            return DesignSystem.accentInfo // primary blue
        }
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(DesignSystem.textPrimary)
                    if let sub = subtitle {
                        Text(sub)
                            .font(.system(size: 11))
                            .foregroundColor(DesignSystem.textMuted)
                    }
                }
                
                Spacer()

                if let used = percentUsed {
                    Text(String(format: "%.0f%%", used))
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundColor(DesignSystem.textPrimary)
                } else {
                    Text("---")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundColor(DesignSystem.textMuted)
                }
            }

            SlimProgressBar(percentUsed: percentUsed, color: statusColor)
        }
        .padding(.vertical, 4)
    }
}
