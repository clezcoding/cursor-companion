import SwiftUI
import CursorCompanionCore

/// Haupt-Popover im Emil Kowalski Minimalist Stil (270px Breite)
public struct PopoverView: View {
    @ObservedObject var appState: AppState
    public var onOpenSettings: (() -> Void)?

    public init(appState: AppState, onOpenSettings: (() -> Void)? = nil) {
        self.appState = appState
        self.onOpenSettings = onOpenSettings
    }

    private var countdownString: String? {
        guard let account = appState.selectedAccount,
              let cycleEnd = account.snapshot?.cycleEnd else {
            return nil
        }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: cycleEnd).day ?? 0
        let planStr = account.plan?.capitalized ?? "Pro"
        return "\(planStr) · \(max(0, days))d"
    }

    private var syncTimeString: String {
        guard let lastSync = appState.lastSyncDate else {
            return "Gerade eben"
        }
        let mins = Int(Date().timeIntervalSince(lastSync) / 60)
        if mins == 0 { return "just now" }
        return "\(mins)m ago"
    }

    public var body: some View {
        VStack(spacing: 16) {
            // Header Row: Accounts & Cycle Info
            if !appState.accounts.isEmpty {
                HStack(alignment: .firstTextBaseline) {
                    HStack(spacing: 8) {
                        ForEach(appState.accounts) { account in
                            Button(action: {
                                appState.selectAccount(id: account.id)
                            }) {
                                Text(account.label)
                                    .font(.system(size: 12, weight: (appState.selectedAccount?.id == account.id) ? .semibold : .regular))
                                    .foregroundColor((appState.selectedAccount?.id == account.id) ? Color(white: 0.95) : Color(white: 0.5))
                            }
                            .buttonStyle(PlainButtonStyle())

                            if account.id != appState.accounts.last?.id {
                                Text("/")
                                    .font(.system(size: 11))
                                    .foregroundColor(Color(white: 0.3))
                            }
                        }
                    }

                    Spacer()

                    if let countdown = countdownString {
                        Text(countdown)
                            .font(.system(size: 11, weight: .regular, design: .monospaced))
                            .foregroundColor(Color(white: 0.4))
                    }
                }
            }

            // Body
            if appState.accounts.isEmpty {
                EmptyAccountsView {
                    Task { await appState.refreshAllAccounts() }
                }
            } else if let account = appState.selectedAccount {
                if case .loginRequired = account.status {
                    ReauthBannerView(accountLabel: account.label) {
                        Task { await appState.refreshAllAccounts() }
                    }
                } else {
                    VStack(spacing: 14) {
                        // Pool 1: Cursor Models
                        MetricBlockView(
                            title: "Cursor Models",
                            percent: account.snapshot?.cursorModelsPercent,
                            tintColor: Color(red: 0.06, green: 0.73, blue: 0.51) // #10B981
                        )

                        // Pool 2: Other Models
                        MetricBlockView(
                            title: "Other Models",
                            percent: account.snapshot?.otherModelsPercent,
                            tintColor: Color(red: 0.96, green: 0.62, blue: 0.04) // #F59E0B
                        )
                    }
                }
            }

            // Quiet Footer
            HStack {
                Text(appState.isRefreshing ? "updating..." : syncTimeString)
                    .font(.system(size: 11))
                    .foregroundColor(Color(white: 0.4))

                Spacer()

                HStack(spacing: 10) {
                    Button(action: {
                        Task { await appState.refreshAllAccounts() }
                    }) {
                        Text("Sync")
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(Color(white: 0.6))
                    }
                    .buttonStyle(PlainButtonStyle())

                    Button(action: {
                        onOpenSettings?()
                    }) {
                        Text("⚙")
                            .font(.system(size: 11))
                            .foregroundColor(Color(white: 0.6))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.top, 4)
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color(white: 0.12)),
                alignment: .top
            )
        }
        .padding(16)
        .frame(width: 270)
        .background(Color(red: 0.07, green: 0.07, blue: 0.07)) // #121212
    }
}
