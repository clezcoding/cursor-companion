import SwiftUI
import CursorCompanionCore

public struct PopoverView: View {
    @ObservedObject var appState: AppState
    public var onOpenSettings: (() -> Void)?
    @Namespace private var accountTabNamespace
    @State private var isVisible = false

    public init(appState: AppState, onOpenSettings: (() -> Void)? = nil) {
        self.appState = appState
        self.onOpenSettings = onOpenSettings
    }



    private var syncTimeString: String {
        guard let lastSync = appState.lastSyncDate else { return "Gerade eben" }
        let mins = Int(Date().timeIntervalSince(lastSync) / 60)
        if mins == 0 { return "just now" }
        return "\(mins)m ago"
    }

    private var pacingMessage: (text: String, color: Color)? {
        guard let account = appState.selectedAccount,
              let cycleEnd = account.snapshot?.cycleEnd,
              let cursorPct = account.snapshot?.cursorModelsPercent else { return nil }
        
        let daysTotal = 30.0 // Approximate
        let daysLeft = Double(max(1, Calendar.current.dateComponents([.day], from: Date(), to: cycleEnd).day ?? 1))
        let daysPassed = daysTotal - daysLeft
        let idealPacing = (daysPassed / daysTotal) * 100.0
        
        if cursorPct > idealPacing + 15 {
            return ("Verbrauch deutlich zu hoch", DesignSystem.accentError)
        } else if cursorPct > idealPacing + 5 {
            return ("Leicht erhöhtes Pacing", DesignSystem.accentWarning)
        } else {
            return ("Gutes Daily Pacing", DesignSystem.accentSuccess)
        }
    }

    public var body: some View {
        VStack(spacing: 16) {
            // Header Row
            if !appState.accounts.isEmpty {
                    SegmentedHeaderView(appState: appState)
            }

            // Body
            Group {
                if appState.accounts.isEmpty {
                    EmptyAccountsView {
                        Task { await appState.refreshAllAccounts() }
                    }
                    .transition(.scale(scale: 0.95).combined(with: .opacity))
                } else if let account = appState.selectedAccount {
                    if case .loginRequired = account.status {
                        ReauthBannerView(accountLabel: account.label) {
                            Task { await appState.refreshAllAccounts() }
                        }
                        .transition(.scale(scale: 0.95).combined(with: .opacity))
                    } else {
                        VStack(spacing: 12) {
                            MetricBlockView(
                                title: "Cursor Models",
                                subtitle: "Composer & Grok Pool",
                                percentUsed: account.snapshot?.cursorModelsPercent
                            )
                            .opacity(isVisible ? 1 : 0)
                            .offset(y: isVisible ? 0 : 10)
                            .animation(DesignSystem.Animations.snappyEaseOut.delay(0.1), value: isVisible)

                            MetricBlockView(
                                title: "Other Models",
                                subtitle: "Claude 3.7 & GPT-4o",
                                percentUsed: account.snapshot?.otherModelsPercent
                            )
                            .opacity(isVisible ? 1 : 0)
                            .offset(y: isVisible ? 0 : 10)
                            .animation(DesignSystem.Animations.snappyEaseOut.delay(0.15), value: isVisible)
                            
                            if let pacing = pacingMessage {
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(pacing.color)
                                        .frame(width: 6, height: 6)
                                        .shadow(color: pacing.color.opacity(0.5), radius: 2)
                                    Text(pacing.text)
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(pacing.color)
                                    Spacer()
                                }
                                .padding(.horizontal, 4)
                                .padding(.top, 4)
                                .opacity(isVisible ? 1 : 0)
                                .animation(DesignSystem.Animations.snappyEaseOut.delay(0.2), value: isVisible)
                            }
                            
                            HistoryChartView(accountID: account.id)
                                .opacity(isVisible ? 1 : 0)
                                .offset(y: isVisible ? 0 : 10)
                                .animation(DesignSystem.Animations.snappyEaseOut.delay(0.25), value: isVisible)
                        }
                        .transition(.scale(scale: 0.95).combined(with: .opacity))
                    }
                }
            }
            .animation(DesignSystem.Animations.smoothTransition, value: appState.selectedAccount?.id)
            .animation(DesignSystem.Animations.smoothTransition, value: appState.accounts.isEmpty)

            // Footer
            HStack(alignment: .center) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(appState.isRefreshing ? DesignSystem.accentWarning : DesignSystem.accentSuccess)
                        .frame(width: 6, height: 6)
                        .scaleEffect(appState.isRefreshing ? 1.4 : 1.0)
                        .animation(appState.isRefreshing ? Animation.easeInOut(duration: 0.8).repeatForever() : .default, value: appState.isRefreshing)
                        .shadow(color: appState.isRefreshing ? DesignSystem.accentWarning : DesignSystem.accentSuccess, radius: 3)
                    
                    Text(appState.isRefreshing ? "updating..." : syncTimeString)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(DesignSystem.textMuted)
                        .contentTransition(.numericText())
                }

                Spacer()

                HStack(spacing: 10) {
                    Button(action: {
                        Task { await appState.refreshAllAccounts() }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 10, weight: .bold))
                                .rotationEffect(Angle(degrees: appState.isRefreshing ? 360 : 0))
                                .animation(appState.isRefreshing ? Animation.linear(duration: 1).repeatForever(autoreverses: false) : .default, value: appState.isRefreshing)
                            Text("Sync")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .foregroundColor(DesignSystem.textSecondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(DesignSystem.bgSecondary)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(DesignSystem.borderHighlight, lineWidth: 0.5))
                        .cornerRadius(6)
                    }
                    .buttonStyle(.springy)

                    Button(action: {
                        onOpenSettings?()
                    }) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(DesignSystem.textSecondary)
                            .frame(width: 24, height: 24)
                            .background(DesignSystem.bgSecondary)
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(DesignSystem.borderHighlight, lineWidth: 0.5))
                            .cornerRadius(6)
                    }
                    .buttonStyle(.springy)
                }
            }
            .padding(.top, 8)
            .opacity(isVisible ? 1 : 0)
            .animation(DesignSystem.Animations.snappyEaseOut.delay(0.2), value: isVisible)
        }
        .padding(12)
        .frame(width: 270)
        .background(VisualEffectView(material: .popover, blendingMode: .behindWindow).ignoresSafeArea())
        .monospacedDigit()
        .onAppear {
            isVisible = true
        }
    }
}
