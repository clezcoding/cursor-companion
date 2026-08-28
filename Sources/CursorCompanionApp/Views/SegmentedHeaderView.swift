import SwiftUI
import CursorCompanionCore

public struct SegmentedHeaderView: View {
    @ObservedObject var appState: AppState
    @Namespace private var accountTabNamespace
    @State private var isVisible = false

    public init(appState: AppState) {
        self.appState = appState
    }

    private var countdownString: String? {
        guard let account = appState.selectedAccount,
              let cycleEnd = account.snapshot?.cycleEnd else { return nil }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: cycleEnd).day ?? 0
        return "\(max(0, days))d" // simplified per mockup to just '15d'
    }

    public var body: some View {
        HStack(alignment: .center) {
            // Segmented Tabs
            HStack(spacing: 0) {
                ForEach(Array(appState.accounts.enumerated()), id: \.element.id) { index, account in
                    let isSelected = (appState.selectedAccount?.id == account.id)
                    
                    Button(action: {
                        withAnimation(DesignSystem.Animations.snappyEaseOut) {
                            appState.selectAccount(id: account.id)
                        }
                    }) {
                        Text(account.label) // Only label based on mockup 'Work', 'Personal'
                            .font(.system(size: 11, weight: isSelected ? .semibold : .medium))
                            .foregroundColor(isSelected ? DesignSystem.textPrimary : DesignSystem.textSecondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(
                                ZStack {
                                    if isSelected {
                                        Capsule()
                                            .fill(DesignSystem.bgTertiary)
                                            .matchedGeometryEffect(id: "activeTab", in: accountTabNamespace)
                                            .overlay(
                                                Capsule()
                                                    .stroke(Color.white.opacity(0.1), lineWidth: 0.5) // inner glow
                                            )
                                            .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
                                    }
                                }
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                    // tactile scale effect added
                    .scaleEffect(isSelected ? 1.0 : 0.98)
                    .animation(DesignSystem.Animations.fastSpring, value: isSelected)
                }
            }
            .padding(2)
            .background(DesignSystem.bgSecondary)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(DesignSystem.borderDefault, lineWidth: 0.5))

            Spacer()

            if let countdown = countdownString {
                Text(countdown)
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(DesignSystem.textPrimary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(DesignSystem.bgSecondary.opacity(0.5))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(DesignSystem.borderDefault, lineWidth: 0.5))
            }
        }
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : -5)
        .animation(DesignSystem.Animations.snappyEaseOut, value: isVisible)
        .onAppear {
            isVisible = true
        }
    }
}
