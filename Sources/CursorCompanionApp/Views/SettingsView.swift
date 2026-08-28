import SwiftUI
import CursorCompanionCore

/// Modernes, edles macOS-Einstellungsfenster für CursorCompanion
public struct SettingsView: View {
    @ObservedObject var appState: AppState
    @StateObject private var permissions = PermissionService.shared
    @State private var selectedTab: SettingsTab = .general
    @State private var renamingAccountID: String?
    @State private var renamingText: String = ""
    public var onOpenOnboarding: (() -> Void)?

    public enum SettingsTab: String, CaseIterable, Identifiable {
        case general = "Allgemein"
        case accounts = "Accounts"
        case permissions = "Berechtigungen"
        case about = "Über"

        public var id: String { rawValue }

        public var iconName: String {
            switch self {
            case .general: return "gearshape.fill"
            case .accounts: return "person.2.fill"
            case .permissions: return "lock.shield.fill"
            case .about: return "info.circle.fill"
            }
        }
    }

    public init(appState: AppState, onOpenOnboarding: (() -> Void)? = nil) {
        self.appState = appState
        self.onOpenOnboarding = onOpenOnboarding
    }

    public var body: some View {
        HStack(spacing: 0) {
            // Sidebar Navigation
            VStack(alignment: .leading, spacing: 4) {
                // App Title & Mini Icon
                HStack(spacing: 8) {
                    Image(nsImage: NSImage(named: "AppIcon") ?? NSImage())
                        .resizable()
                        .frame(width: 20, height: 20)
                    Text("CursorCompanion")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 12)
                .padding(.top, 14)
                .padding(.bottom, 12)

                ForEach(SettingsTab.allCases) { tab in
                    Button(action: { selectedTab = tab }) {
                        HStack(spacing: 8) {
                            Image(systemName: tab.iconName)
                                .font(.system(size: 12))
                                .frame(width: 16)
                            Text(tab.rawValue)
                                .font(.system(size: 12, weight: selectedTab == tab ? .semibold : .regular))
                            Spacer()
                        }
                        .foregroundColor(selectedTab == tab ? .white : Color(white: 0.6))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(selectedTab == tab ? Color(white: 0.16) : Color.clear)
                        .cornerRadius(6)
                    }
                    .buttonStyle(PlainButtonStyle())
                }

                Spacer()

                Button("Onboarding öffnen") {
                    onOpenOnboarding?()
                }
                .buttonStyle(PlainButtonStyle())
                .font(.system(size: 11))
                .foregroundColor(Color(white: 0.5))
                .padding(.horizontal, 10)
                .padding(.bottom, 12)
            }
            .frame(width: 145)
            .background(Color(red: 0.09, green: 0.08, blue: 0.07))

            Divider()
                .background(Color(white: 0.12))

            // Main Content Area
            VStack(alignment: .leading, spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        switch selectedTab {
                        case .general:
                            sectionGeneral
                        case .accounts:
                            sectionAccounts
                        case .permissions:
                            sectionPermissions
                        case .about:
                            AboutView()
                        }
                    }
                    .padding(20)
                }

                Divider()
                    .background(Color(white: 0.12))

                HStack {
                    Spacer()
                    Button("Fertig") {
                        NSApp.keyWindow?.close()
                    }
                    .buttonStyle(PlainButtonStyle())
                    .font(.system(size: 11.5, weight: .semibold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 5)
                    .background(Color.white)
                    .cornerRadius(5)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(white: 0.06))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 500, height: 380)
        .background(Color(red: 0.07, green: 0.06, blue: 0.05))
    }

    // MARK: - General Section
    private var sectionGeneral: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Allgemeine Einstellungen")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white)

            VStack(spacing: 8) {
                settingRow(
                    title: "Abfrageintervall",
                    desc: "Hintergrundabfrage der Kontingente"
                ) {
                    Picker("", selection: $appState.settings.refreshIntervalMinutes) {
                        Text("1 Min.").tag(1)
                        Text("5 Min. (Standard)").tag(5)
                        Text("15 Min.").tag(15)
                        Text("30 Min.").tag(30)
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(width: 130)
                }

                settingRow(
                    title: "Bei macOS-Login starten",
                    desc: "CursorCompanion automatisch im Hintergrund öffnen"
                ) {
                    Toggle("", isOn: Binding(
                        get: { appState.settings.launchAtLogin },
                        set: { val in
                            appState.settings.launchAtLogin = val
                            LaunchAtLoginHelper.setEnabled(val)
                        }
                    ))
                    .toggleStyle(SwitchToggleStyle())
                }

                settingRow(
                    title: "Warnung bei hohem Verbrauch",
                    desc: "macOS-Benachrichtigung bei ≥ 85% Verbrauch"
                ) {
                    Toggle("", isOn: Binding(
                        get: { appState.settings.notifyHighUsage },
                        set: { val in
                            appState.settings.notifyHighUsage = val
                            if val { permissions.requestNotificationPermission() }
                        }
                    ))
                    .toggleStyle(SwitchToggleStyle())
                }
            }
        }
    }

    // MARK: - Accounts Section
    private var sectionAccounts: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Verwaltete Accounts")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                Button(action: {
                    Task { await appState.syncActiveCursorAccount() }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise")
                        Text("Jetzt scannen")
                    }
                    .font(.system(size: 11))
                    .foregroundColor(Color(red: 0.06, green: 0.73, blue: 0.51))
                }
                .buttonStyle(PlainButtonStyle())
            }

            if appState.accounts.isEmpty {
                Text("Keine Accounts gecacht. Bitte öffne die Cursor-App und melde dich an.")
                    .font(.system(size: 11.5))
                    .foregroundColor(Color(white: 0.5))
                    .padding(.vertical, 8)
            } else {
                ForEach(appState.accounts) { account in
                    VStack(alignment: .leading, spacing: 6) {
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

                                    if let plan = account.plan {
                                        Text(plan.uppercased())
                                            .font(.system(size: 9, weight: .bold))
                                            .padding(.horizontal, 5)
                                            .padding(.vertical, 1)
                                            .background(Color(white: 0.12))
                                            .foregroundColor(Color(red: 0.96, green: 0.62, blue: 0.04))
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
                            .padding(.top, 4)
                        }
                    }
                    .padding(10)
                    .background(Color(white: 0.11))
                    .cornerRadius(8)
                }
            }
        }
    }

    // MARK: - Permissions Section
    private var sectionPermissions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("System-Berechtigungen & Status")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white)

            VStack(spacing: 8) {
                permissionRow(
                    title: "Cursor Datenbank (state.vscdb)",
                    desc: "Lesender Zugriff auf lokale Cursor-Session",
                    status: permissions.sqliteStatus
                )

                permissionRow(
                    title: "Schlüsselbund-Zugriff (Keychain)",
                    desc: "Sichere Speicherung für Multi-Account-Sessions (nur 1x nötig)",
                    status: permissions.keychainStatus,
                    actionTitle: "Einmalig erlauben"
                ) {
                    permissions.requestKeychainAuthorization()
                }

                permissionRow(
                    title: "macOS Benachrichtigungen",
                    desc: "Warnmeldungen bei hoher Kontingent-Auslastung",
                    status: permissions.notificationStatus,
                    actionTitle: "Aktivieren"
                ) {
                    permissions.requestNotificationPermission()
                }
            }

            Button("Status aktualisieren") {
                permissions.refreshAll()
            }
            .buttonStyle(PlainButtonStyle())
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(Color(red: 0.06, green: 0.73, blue: 0.51))
            .padding(.top, 4)
        }
    }

    private func settingRow<Content: View>(title: String, desc: String, @ViewBuilder content: () -> Content) -> some View {
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
            content()
        }
        .padding(10)
        .background(Color(white: 0.11))
        .cornerRadius(8)
    }

    private func permissionRow(title: String, desc: String, status: PermissionStatus, actionTitle: String? = nil, action: (() -> Void)? = nil) -> some View {
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
}
