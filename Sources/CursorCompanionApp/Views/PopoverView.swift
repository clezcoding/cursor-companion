import SwiftUI
import CursorCompanionCore

/// Haupt-Popover im Emil Kowalski Minimalist Stil (270px Breite) mit vergrößertem Settings-Button
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
                HStack(alignment: .center) {
                    HStack(spacing: 6) {
                        ForEach(appState.accounts) { account in
                            let isSelected = (appState.selectedAccount?.id == account.id)
                            Button(action: {
                                appState.selectAccount(id: account.id)
                            }) {
                                HStack(spacing: 4) {
                                    if account.isActive {
                                        Circle()
                                            .fill(Color(red: 0.06, green: 0.73, blue: 0.51))
                                            .frame(width: 5, height: 5)
                                    }
                                    Text(account.label)
                                        .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                                        .foregroundColor(isSelected ? Color(white: 0.95) : Color(white: 0.5))
                                }
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(isSelected ? Color(white: 0.12) : Color.clear)
                                .cornerRadius(6)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }

                    Spacer()

                    if let countdown = countdownString {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.system(size: 9))
                                .foregroundColor(Color(white: 0.4))
                            Text(countdown)
                                .font(.system(size: 11, weight: .regular, design: .monospaced))
                                .foregroundColor(Color(white: 0.45))
                        }
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
                            subtitle: "Composer & Grok Pool",
                            percentUsed: account.snapshot?.cursorModelsPercent
                        )

                        // Pool 2: Other Models
                        MetricBlockView(
                            title: "Other Models",
                            subtitle: "Claude 3.7 & GPT-4o",
                            percentUsed: account.snapshot?.otherModelsPercent
                        )
                    }
                }
            }

            // Quiet Footer mit vergrößertem Settings Icon
            HStack(alignment: .center) {
                HStack(spacing: 5) {
                    Circle()
                        .fill(appState.isRefreshing ? Color(red: 0.96, green: 0.62, blue: 0.04) : Color(red: 0.06, green: 0.73, blue: 0.51))
                        .frame(width: 5, height: 5)
                    
                    Text(appState.isRefreshing ? "updating..." : syncTimeString)
                        .font(.system(size: 11))
                        .foregroundColor(Color(white: 0.45))
                }

                Spacer()

                HStack(spacing: 8) {
                    // Sync Button
                    Button(action: {
                        Task { await appState.refreshAllAccounts() }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 11, weight: .medium))
                            Text("Sync")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundColor(Color(white: 0.7))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 4)
                        .background(Color(white: 0.1))
                        .cornerRadius(5)
                    }
                    .buttonStyle(PlainButtonStyle())

                    // Größeres, elegantes Settings Icon
                    Button(action: {
                        onOpenSettings?()
                    }) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color(white: 0.75))
                            .frame(width: 26, height: 26)
                            .background(Color(white: 0.1))
                            .cornerRadius(6)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help("Einstellungen")
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
