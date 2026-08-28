import SwiftUI
import CursorCompanionCore

/// Re-Authentifizierungs-Hinweis für abgelaufene Sessions
public struct ReauthBannerView: View {
    public let accountLabel: String
    public let onRetry: () -> Void

    public init(accountLabel: String, onRetry: @escaping () -> Void) {
        self.accountLabel = accountLabel
        self.onRetry = onRetry
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Session für **\(accountLabel)** abgelaufen. Bitte in Cursor neu anmelden.")
                .font(.system(size: 11.5))
                .foregroundColor(Color(white: 0.7))
                .lineSpacing(2)

            Button(action: onRetry) {
                Text("→ Erneut prüfen")
                    .font(.system(size: 11.5, weight: .medium))
                    .foregroundColor(DesignSystem.accentSuccess)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .contentShape(Rectangle())
                    .background(DesignSystem.bgTertiary)
                    .cornerRadius(4)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
}

/// Erststart-Ansicht, wenn noch kein aktiver Cursor-Login gefunden wurde
public struct EmptyAccountsView: View {
    public let onSync: () -> Void

    public init(onSync: @escaping () -> Void) {
        self.onSync = onSync
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Kein Cursor-Login gefunden. Bitte in Cursor anmelden.")
                .font(.system(size: 11.5))
                .foregroundColor(Color(white: 0.7))
                .lineSpacing(2)

            Button(action: onSync) {
                Text("→ Anmeldedaten einlesen")
                    .font(.system(size: 11.5, weight: .medium))
                    .foregroundColor(DesignSystem.accentSuccess)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .contentShape(Rectangle())
                    .background(DesignSystem.bgTertiary)
                    .cornerRadius(4)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
}
