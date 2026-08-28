import SwiftUI
import CursorCompanionCore

/// Einstellungen-Fenster für CursorCompanion mit Tabs und vollem Funktionsumfang
public struct SettingsView: View {
    @ObservedObject var appState: AppState
    @State private var selectedTab: Int = 0
    @State private var renamingAccountID: String?
    @State private var renamingText: String = ""
    public var onOpenOnboarding: (() -> Void)?

    public init(appState: AppState, onOpenOnboarding: (() -> Void)? = nil) {
        self.appState = appState
        self.onOpenOnboarding = onOpenOnboarding
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Segmented Tab Picker
            Picker("", selection: $selectedTab) {
                Text("Allgemein").tag(0)
                Text("Accounts (\(appState.accounts.count))").tag(1)
                Text("Über").tag(2)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 12)

            Divider()
                .background(Color(white: 0.15))

            // Tab Content
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    switch selectedTab {
                    case 0:
                        tabGeneral
                    case 1:
                        tabAccounts
                    case 2:
                        AboutView()
                    default:
                        EmptyView()
                    }
                }
                .padding(20)
            }

            Divider()
                .background(Color(white: 0.15))

            // Bottom Actions
            HStack {
                Button("Onboarding-Assistent öffnen") {
                    onOpenOnboarding?()
                }
                .buttonStyle(PlainButtonStyle())
                .font(.system(size: 11))
                .foregroundColor(Color(white: 0.6))

                Spacer()

                Button("Schließen") {
                    NSApp.keyWindow?.close()
                }
                .buttonStyle(PlainButtonStyle())
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color(white: 0.05))
        }
        .frame(width: 420, height: 380)
        .background(Color(red: 0.08, green: 0.07, blue: 0.06))
    }

    // MARK: - Tab: General
    private var tabGeneral: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Abfrageintervall
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
                    Text("30 Min.").tag(30)
                }
                .pickerStyle(MenuPickerStyle())
                .frame(width: 140)
            }
            .padding(10)
            .background(Color(white: 0.11))
            .cornerRadius(8)

            // Autostart
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Bei macOS-Login starten")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                    Text("CursorCompanion automatisch im Hintergrund öffnen")
                        .font(.system(size: 10.5))
                        .foregroundColor(Color(white: 0.5))
                }
                Spacer()
                Toggle("", isOn: Binding(
                    get: { appState.settings.launchAtLogin },
                    set: { val in
                        appState.settings.launchAtLogin = val
                        LaunchAtLoginHelper.setEnabled(val)
                    }
                ))
                .toggleStyle(SwitchToggleStyle())
            }
            .padding(10)
            .background(Color(white: 0.11))
            .cornerRadius(8)

            // Benachrichtigungen
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Warnung bei hohem Verbrauch")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                    Text("macOS-Benachrichtigung bei ≥ 85% Verbrauch")
                        .font(.system(size: 10.5))
                        .foregroundColor(Color(white: 0.5))
                }
                Spacer()
                Toggle("", isOn: Binding(
                    get: { appState.settings.notifyHighUsage },
                    set: { val in
                        appState.settings.notifyHighUsage = val
                        if val { NotificationService.shared.requestAuthorization() }
                    }
                ))
                .toggleStyle(SwitchToggleStyle())
            }
            .padding(10)
            .background(Color(white: 0.11))
            .cornerRadius(8)
        }
    }

    // MARK: - Tab: Accounts
    private var tabAccounts: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(appState.accounts) { account in
                VStack(spacing: 8) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Text(account.label)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.white)

                                if account.isActive {
                                    Text("AKTIV")
                                        .font(.system(size: 9, weight: .bold))
                                        .padding(.horizontal, 5)
                                        .padding(.vertical, 1)
                                        .background(Color(red: 0.06, green: 0.73, blue: 0.51).opacity(0.2))
                                        .foregroundColor(Color(red: 0.06, green: 0.73, blue: 0.51))
                                        .cornerRadius(3)
                                } else {
                                    Text("CACHED")
                                        .font(.system(size: 9, weight: .bold))
                                        .padding(.horizontal, 5)
                                        .padding(.vertical, 1)
                                        .background(Color(white: 0.15))
                                        .foregroundColor(Color(white: 0.6))
                                        .cornerRadius(3)
                                }
                            }

                            Text(account.id)
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(Color(white: 0.4))
                        }

                        Spacer()

                        Button("Umbenennen") {
                            renamingAccountID = account.id
                            renamingText = account.label
                        }
                        .buttonStyle(PlainButtonStyle())
                        .font(.system(size: 11))
                        .foregroundColor(Color(white: 0.8))

                        if !account.isActive {
                            Button("Entfernen") {
                                Task { await appState.removeAccount(accountID: account.id) }
                            }
                            .buttonStyle(PlainButtonStyle())
                            .font(.system(size: 11))
                            .foregroundColor(Color(red: 0.96, green: 0.25, blue: 0.37))
                        }
                    }

                    if renamingAccountID == account.id {
                        HStack {
                            TextField("Neues Label", text: $renamingText)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            Button("Speichern") {
                                Task {
                                    await appState.updateAccountLabel(accountID: account.id, newLabel: renamingText)
                                    renamingAccountID = nil
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            .font(.system(size: 11, weight: .semibold))

                            Button("Abbrechen") {
                                renamingAccountID = nil
                            }
                            .buttonStyle(PlainButtonStyle())
                            .font(.system(size: 11))
                            .foregroundColor(Color(white: 0.6))
                        }
                    }
                }
                .padding(10)
                .background(Color(white: 0.11))
                .cornerRadius(8)
            }
        }
    }
}
