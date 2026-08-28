import SwiftUI
import CursorCompanionCore

/// V2 Emil Kowalski Styled Onboarding (Glassmorphic)
public struct OnboardingView: View {
    @ObservedObject var appState: AppState
    @StateObject private var permissions = PermissionService.shared

    @State private var step: Int = 1
    @State private var isVisible = false
    
    // States for staggered animations
    @State private var titleVisible = false
    @State private var subtitleVisible = false
    @State private var listVisible1 = false
    @State private var listVisible2 = false
    @State private var listVisible3 = false
    @State private var buttonVisible = false
    public var onFinish: (() -> Void)?

    public init(appState: AppState, onFinish: (() -> Void)? = nil) {
        self.appState = appState
        self.onFinish = onFinish
    }

    public var body: some View {
        ZStack {
            // Ambient background glow
            Circle()
                .fill(DesignSystem.accentInfo.opacity(0.15))
                .frame(width: 300, height: 300)
                .blur(radius: 80)
                .offset(x: -100, y: -150)
            
            Circle()
                .fill(DesignSystem.accentSuccess.opacity(0.1))
                .frame(width: 200, height: 200)
                .blur(radius: 60)
                .offset(x: 150, y: 150)

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 32) {
                    // Header mit Tilt-Effekt
                    VStack(spacing: 16) {
                        Image(nsImage: NSImage(named: "AppIcon") ?? NSImage())
                            .resizable()
                            .frame(width: 84, height: 84)
                            .shadow(color: .black.opacity(0.5), radius: 12, y: 6)
                            .interactiveTilt()

                        VStack(spacing: 8) {
                            Text("CursorCompanion")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(DesignSystem.textPrimary)
                                .opacity(titleVisible ? 1 : 0)
                                .offset(y: titleVisible ? 0 : 10)
                                .animation(DesignSystem.Animations.snappyEaseOut.delay(0.1), value: titleVisible)

                            Text("Verfolge deine Cursor KI-Nutzung direkt in der Menüleiste.")
                                .font(.system(size: 14))
                                .foregroundColor(DesignSystem.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                                .opacity(subtitleVisible ? 1 : 0)
                                .offset(y: subtitleVisible ? 0 : 10)
                                .animation(DesignSystem.Animations.snappyEaseOut.delay(0.15), value: subtitleVisible)
                        }
                    }

                    // Features Liste (Staggered)
                    if step == 1 {
                        VStack(alignment: .leading, spacing: 16) {
                            featureRow(
                                icon: "menubar.rectangle",
                                title: "Immer griffbereit",
                                desc: "Ein Klick in der Menüleiste zeigt deine verbleibenden Fast Requests."
                            )
                            .opacity(listVisible1 ? 1 : 0)
                            .offset(y: listVisible1 ? 0 : 10)
                            .animation(DesignSystem.Animations.snappyEaseOut.delay(0.2), value: listVisible1)

                            featureRow(
                                icon: "bell.badge",
                                title: "Intelligente Warnungen",
                                desc: "Erhalte Benachrichtigungen, wenn dein Kontingent knapp wird."
                            )
                            .opacity(listVisible2 ? 1 : 0)
                            .offset(y: listVisible2 ? 0 : 10)
                            .animation(DesignSystem.Animations.snappyEaseOut.delay(0.25), value: listVisible2)

                            featureRow(
                                icon: "person.2.fill",
                                title: "Multi-Account fähig",
                                desc: "Wechsle nahtlos zwischen Work und Personal Accounts."
                            )
                            .opacity(listVisible3 ? 1 : 0)
                            .offset(y: listVisible3 ? 0 : 10)
                            .animation(DesignSystem.Animations.snappyEaseOut.delay(0.3), value: listVisible3)
                        }
                        .padding(.horizontal, 30)
                        .transition(.scale(scale: 0.95).combined(with: .opacity))
                    } else if step == 2 {
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Berechtigungen")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(DesignSystem.textPrimary)

                            VStack(spacing: 14) {
                                permissionRequestRow(
                                    icon: "key.fill",
                                    title: "Sicherer Schlüsselbund",
                                    desc: "Wird benötigt, um Account-Tokens lokal zu speichern.",
                                    isGranted: permissions.keychainStatus == .authorized
                                ) {
                                    permissions.requestKeychainAuthorization()
                                }

                                permissionRequestRow(
                                    icon: "app.badge.fill",
                                    title: "Benachrichtigungen",
                                    desc: "Lass dich bei >85% Verbrauch warnen.",
                                    isGranted: permissions.notificationStatus == .authorized
                                ) {
                                    permissions.requestNotificationPermission()
                                }
                            }
                        }
                        .padding(.horizontal, 30)
                        .transition(.scale(scale: 0.95).combined(with: .opacity))
                    }
                }
                .animation(DesignSystem.Animations.smoothTransition, value: step)

                Spacer()

                // Footer
                VStack(spacing: 20) {
                    if step == 1 {
                        Button(action: {
                            withAnimation(DesignSystem.Animations.snappyEaseOut) {
                                step = 2
                            }
                        }) {
                            Text("Weiter")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.white)
                                .cornerRadius(10)
                                .shadow(color: Color.white.opacity(0.3), radius: 6, y: 2)
                        }
                        .buttonStyle(.springy)
                        .opacity(buttonVisible ? 1 : 0)
                        .animation(DesignSystem.Animations.snappyEaseOut.delay(0.35), value: buttonVisible)
                    } else {
                        Button(action: {
                            if let finish = onFinish {
                                finish()
                            } else {
                                NSApp.keyWindow?.close()
                            }
                        }) {
                            Text("Loslegen")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(DesignSystem.accentSuccess)
                                .cornerRadius(10)
                                .shadow(color: DesignSystem.accentSuccess.opacity(0.4), radius: 6, y: 2)
                        }
                        .buttonStyle(.springy)
                    }

                    HStack(spacing: 8) {
                        Capsule()
                            .fill(step == 1 ? DesignSystem.textPrimary : DesignSystem.borderHighlight)
                            .frame(width: step == 1 ? 16 : 6, height: 6)
                            .animation(DesignSystem.Animations.snappyEaseOut, value: step)
                        Capsule()
                            .fill(step == 2 ? DesignSystem.textPrimary : DesignSystem.borderHighlight)
                            .frame(width: step == 2 ? 16 : 6, height: 6)
                            .animation(DesignSystem.Animations.snappyEaseOut, value: step)
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
        }
        .frame(width: 440, height: 560)
        .background(VisualEffectView(material: .popover, blendingMode: .behindWindow, state: .active))
        .background(DesignSystem.bgPrimary.opacity(0.8))
        .onAppear {
            isVisible = true
            titleVisible = true
            subtitleVisible = true
            listVisible1 = true
            listVisible2 = true
            listVisible3 = true
            buttonVisible = true
        }
    }

    private func featureRow(icon: String, title: String, desc: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .light))
                .foregroundColor(DesignSystem.accentInfo)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(DesignSystem.textPrimary)
                Text(desc)
                    .font(.system(size: 12))
                    .foregroundColor(DesignSystem.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding()
        .background(DesignSystem.bgSecondary)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(DesignSystem.borderHighlight, lineWidth: 0.5))
    }

    private func permissionRequestRow(icon: String, title: String, desc: String, isGranted: Bool, action: @escaping () -> Void) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .light))
                .foregroundColor(isGranted ? DesignSystem.accentSuccess : DesignSystem.textSecondary)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(DesignSystem.textPrimary)
                Text(desc)
                    .font(.system(size: 12))
                    .foregroundColor(DesignSystem.textSecondary)
            }
            Spacer()
            
            if isGranted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(DesignSystem.accentSuccess)
                    .font(.system(size: 20))
            } else {
                Button(action: action) {
                    Text("Erlauben")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(Color.white)
                        .cornerRadius(6)
                }
                .buttonStyle(.springy)
            }
        }
        .padding(16)
        .background(DesignSystem.bgSecondary)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(DesignSystem.borderHighlight, lineWidth: 0.5))
        .cornerRadius(12)
    }
}
