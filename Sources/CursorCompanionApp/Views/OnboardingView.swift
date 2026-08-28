import SwiftUI
import CursorCompanionCore

/// Interaktiver 5-stufiger Onboarding & Welcome Assistant mit gezielter Ein-Klick-Berechtigungs-Abfrage
public struct OnboardingView: View {
    @ObservedObject var appState: AppState
    @StateObject private var permissions = PermissionService.shared
    @State private var currentStep: Int = 0
    public var onComplete: () -> Void

    public init(appState: AppState, onComplete: @escaping () -> Void) {
        self.appState = appState
        self.onComplete = onComplete
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header Progress Pips
            HStack(spacing: 8) {
                ForEach(0..<5) { index in
                    Capsule()
                        .fill(index == currentStep ? Color(red: 0.06, green: 0.73, blue: 0.51) : Color(white: 0.2))
                        .frame(width: index == currentStep ? 24 : 8, height: 4)
                        .animation(.easeInOut(duration: 0.2), value: currentStep)
                }
            }
            .padding(.top, 18)
            .padding(.bottom, 14)

            // Step Content
            VStack {
                switch currentStep {
                case 0:
                    stepWelcome
                case 1:
                    stepPermissions
                case 2:
                    stepAccountDetection
                case 3:
                    stepConfiguration
                case 4:
                    stepReady
                default:
                    EmptyView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 28)

            // Footer Navigation
            HStack {
                if currentStep > 0 && currentStep < 4 {
                    Button("Zurück") {
                        withAnimation { currentStep -= 1 }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .foregroundColor(Color(white: 0.6))
                }

                Spacer()

                if currentStep < 4 {
                    Button(action: {
                        withAnimation { currentStep += 1 }
                    }) {
                        Text("Weiter →")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 7)
                            .background(Color.white)
                            .cornerRadius(6)
                    }
                    .buttonStyle(PlainButtonStyle())
                } else {
                    Button(action: {
                        appState.settings.hasCompletedOnboarding = true
                        onComplete()
                    }) {
                        Text("CursorCompanion starten")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(Color(red: 0.06, green: 0.73, blue: 0.51))
                            .cornerRadius(6)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 20)
            .padding(.top, 10)
        }
        .frame(width: 500, height: 420)
        .background(Color(red: 0.08, green: 0.07, blue: 0.06))
    }

    // MARK: - Step 1: Welcome
    private var stepWelcome: some View {
        VStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(white: 0.12))
                    .frame(width: 60, height: 60)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(white: 0.25), lineWidth: 1)
                    )
                
                Image(nsImage: NSImage(named: "AppIcon") ?? NSImage())
                    .resizable()
                    .frame(width: 60, height: 60)
            }

            VStack(spacing: 4) {
                Text("Willkommen bei CursorCompanion")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)

                Text("Dein eleganter macOS-Begleiter für permanente Übersicht aller Cursor-Nutzungspools.")
                    .font(.system(size: 12))
                    .foregroundColor(Color(white: 0.6))
                    .multilineTextAlignment(.center)
            }

            VStack(alignment: .leading, spacing: 10) {
                featureRow(icon: "bolt.fill", color: Color(red: 0.06, green: 0.73, blue: 0.51), title: "Beide Pools im Blick", desc: "Cursor Models und Other Models direkt in deiner Menüleiste.")
                featureRow(icon: "person.2.fill", color: Color(red: 0.96, green: 0.62, blue: 0.04), title: "Multi-Account Caching", desc: "Verwalte Work, Personal und Team-Konten gleichzeitig.")
                featureRow(icon: "lock.shield.fill", color: Color(red: 0.5, green: 0.5, blue: 0.95), title: "100% Sicher & Lokal", desc: "Rein lesender Zugriff auf Cursors lokale Datenbank.")
            }
            .padding(.top, 6)
        }
    }

    // MARK: - Step 2: Permissions
    private var stepPermissions: some View {
        VStack(spacing: 16) {
            VStack(spacing: 4) {
                Text("Berechtigungen & Zugriff")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                Text("CursorCompanion benötigt Zugriff auf Schlüsselbund und lokale Sitzung.")
                    .font(.system(size: 11.5))
                    .foregroundColor(Color(white: 0.6))
            }

            VStack(spacing: 10) {
                // SQLite
                permissionItem(
                    icon: "externaldrive.fill",
                    title: "Cursor Datenbank (state.vscdb)",
                    desc: "Lesender Zugriff auf deine lokale Cursor-Session",
                    status: permissions.sqliteStatus
                )

                // Keychain
                permissionItem(
                    icon: "key.fill",
                    title: "macOS Schlüsselbund (Keychain)",
                    desc: "Sichere Speicherung für Multi-Account-Sessions (nur 1x nötig)",
                    status: permissions.keychainStatus,
                    actionTitle: "Einmalig erlauben",
                    action: {
                        permissions.requestKeychainAuthorization()
                    }
                )

                // Notifications
                permissionItem(
                    icon: "bell.fill",
                    title: "macOS Benachrichtigungen",
                    desc: "Warnmeldung bei Erreichen von ≥ 85% Verbrauch",
                    status: permissions.notificationStatus,
                    actionTitle: "Aktivieren",
                    action: {
                        permissions.requestNotificationPermission()
                    }
                )
            }

            Button("Status aktualisieren") {
                permissions.refreshAll()
            }
            .buttonStyle(PlainButtonStyle())
            .font(.system(size: 11))
            .foregroundColor(Color(red: 0.06, green: 0.73, blue: 0.51))
        }
    }

    // MARK: - Step 3: Account Detection
    private var stepAccountDetection: some View {
        VStack(spacing: 16) {
            VStack(spacing: 4) {
                Text("Cursor-Erkennung")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                Text("Automatische Erkennung deiner angemeldeten Cursor-Konten.")
                    .font(.system(size: 11.5))
                    .foregroundColor(Color(white: 0.6))
            }

            if let active = appState.activeAccount ?? appState.accounts.first {
                VStack(spacing: 10) {
                    HStack(spacing: 12) {
                        Circle()
                            .fill(Color(red: 0.06, green: 0.73, blue: 0.51))
                            .frame(width: 10, height: 10)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Aktiver Cursor-Login gefunden!")
                                .font(.system(size: 12.5, weight: .semibold))
                                .foregroundColor(.white)
                            Text("Account: \(active.label) (\(active.id))")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(Color(white: 0.5))
                        }
                        Spacer()
                        
                        if let plan = active.plan {
                            Text(plan.uppercased())
                                .font(.system(size: 9.5, weight: .bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color(white: 0.15))
                                .cornerRadius(4)
                                .foregroundColor(Color(red: 0.06, green: 0.73, blue: 0.51))
                        }
                    }
                    .padding(14)
                    .background(Color(white: 0.11))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(red: 0.06, green: 0.73, blue: 0.51).opacity(0.3), lineWidth: 1)
                    )

                    Text("Deine Nutzungspools werden ab sofort im Hintergrund synchronisiert.")
                        .font(.system(size: 11))
                        .foregroundColor(Color(white: 0.5))
                }
            } else {
                VStack(spacing: 12) {
                    Text("Noch kein aktiver Login in der Cursor-App gefunden.")
                        .font(.system(size: 12))
                        .foregroundColor(Color(white: 0.7))

                    Button("Cursor-App öffnen & anmelden") {
                        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.todesktop.230313mzl4w4u92") ?? NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.cursor.Cursor") {
                            NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration())
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .font(.system(size: 11.5, weight: .medium))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(white: 0.15))
                    .cornerRadius(6)
                    .foregroundColor(.white)

                    Button("Erneut scannen") {
                        Task { await appState.syncActiveCursorAccount() }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .font(.system(size: 11))
                    .foregroundColor(Color(red: 0.06, green: 0.73, blue: 0.51))
                }
                .padding(16)
                .background(Color(white: 0.11))
                .cornerRadius(10)
            }
        }
    }

    // MARK: - Step 4: Configuration
    private var stepConfiguration: some View {
        VStack(spacing: 16) {
            VStack(spacing: 4) {
                Text("Einstellungen anpassen")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                Text("Du kannst diese Werte jederzeit im Menü ändern.")
                    .font(.system(size: 11.5))
                    .foregroundColor(Color(white: 0.6))
            }

            VStack(spacing: 10) {
                configToggleRow(title: "Bei macOS-Login starten", desc: "Öffnet CursorCompanion automatisch im Hintergrund", binding: $appState.settings.launchAtLogin)
                configToggleRow(title: "Warnung bei hohem Verbrauch", desc: "Benachrichtigung bei ≥ 85% Verbrauch", binding: $appState.settings.notifyHighUsage)

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Abfrageintervall")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                        Text("Hintergrundabfrage der Kontingente")
                            .font(.system(size: 10.5))
                            .foregroundColor(Color(white: 0.5))
                    }
                    Spacer()
                    Picker("", selection: $appState.settings.refreshIntervalMinutes) {
                        Text("1 Min.").tag(1)
                        Text("5 Min. (Standard)").tag(5)
                        Text("15 Min.").tag(15)
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(width: 140)
                }
                .padding(10)
                .background(Color(white: 0.11))
                .cornerRadius(8)
            }
        }
    }

    // MARK: - Step 5: Ready
    private var stepReady: some View {
        VStack(spacing: 16) {
            Circle()
                .fill(Color(red: 0.06, green: 0.73, blue: 0.51).opacity(0.2))
                .frame(width: 56, height: 56)
                .overlay(
                    Image(systemName: "checkmark")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Color(red: 0.06, green: 0.73, blue: 0.51))
                )

            VStack(spacing: 6) {
                Text("Alles bereit!")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)

                Text("CursorCompanion läuft diskret in deiner Menüleiste oben rechts.")
                    .font(.system(size: 12))
                    .foregroundColor(Color(white: 0.6))
                    .multilineTextAlignment(.center)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text("●")
                        .font(.system(size: 8))
                        .foregroundColor(Color(red: 0.06, green: 0.73, blue: 0.51))
                    Text("Klick auf das Icon / die Zahlen in der Menüleiste öffnet das Popover.")
                        .font(.system(size: 11.5))
                        .foregroundColor(Color(white: 0.7))
                }
                HStack(spacing: 6) {
                    Text("●")
                        .font(.system(size: 8))
                        .foregroundColor(Color(red: 0.96, green: 0.62, blue: 0.04))
                    Text("Farben wechseln automatisch bei hoher Auslastung.")
                        .font(.system(size: 11.5))
                        .foregroundColor(Color(white: 0.7))
                }
            }
            .padding(12)
            .background(Color(white: 0.11))
            .cornerRadius(8)
        }
    }

    private func featureRow(icon: String, color: Color, title: String, desc: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundColor(color)
                .frame(width: 18)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 11.5, weight: .semibold))
                    .foregroundColor(.white)
                Text(desc)
                    .font(.system(size: 10.5))
                    .foregroundColor(Color(white: 0.5))
            }
        }
    }

    private func permissionItem(icon: String, title: String, desc: String, status: PermissionStatus, actionTitle: String? = nil, action: (() -> Void)? = nil) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(Color(white: 0.7))
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                Text(desc)
                    .font(.system(size: 10.5))
                    .foregroundColor(Color(white: 0.5))
            }
            Spacer()

            switch status {
            case .authorized:
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Erlaubt")
                }
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Color(red: 0.06, green: 0.73, blue: 0.51))

            case .denied, .notDetermined:
                if let action = action, let title = actionTitle {
                    Button(action: action) {
                        Text(title)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color(red: 0.06, green: 0.73, blue: 0.51))
                            .cornerRadius(5)
                    }
                    .buttonStyle(PlainButtonStyle())
                } else {
                    Text("Bereit")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }

            case .notFound(let reason):
                Text("Nicht gefunden")
                    .font(.system(size: 11))
                    .foregroundColor(Color(red: 0.96, green: 0.62, blue: 0.04))
                    .help(reason)
            }
        }
        .padding(10)
        .background(Color(white: 0.11))
        .cornerRadius(8)
    }

    private func configToggleRow(title: String, desc: String, binding: Binding<Bool>) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                Text(desc)
                    .font(.system(size: 10.5))
                    .foregroundColor(Color(white: 0.5))
            }
            Spacer()
            Toggle("", isOn: binding)
                .toggleStyle(SwitchToggleStyle())
        }
        .padding(10)
        .background(Color(white: 0.11))
        .cornerRadius(8)
    }
}
