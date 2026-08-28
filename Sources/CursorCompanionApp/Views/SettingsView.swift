import SwiftUI
import CursorCompanionCore

/// Modernes, edles macOS-Einstellungsfenster für CursorCompanion V2
public struct SettingsView: View {
    @ObservedObject var appState: AppState
    @StateObject private var permissions = PermissionService.shared
    @State private var selectedTab: SettingsTab = .general
    @State private var renamingAccountID: String?
    @State private var renamingText: String = ""
    public var onOpenOnboarding: (() -> Void)?
    @Namespace private var tabNamespace
    @State private var isVisible = false

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
            VStack(alignment: .leading, spacing: 6) {
                // App Title & Mini Icon
                HStack(spacing: 8) {
                    Image(nsImage: NSImage(named: "AppIcon") ?? NSImage())
                        .resizable()
                        .frame(width: 24, height: 24)
                        .shadow(color: .black.opacity(0.3), radius: 2, y: 1)
                    Text("CursorCompanion")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(DesignSystem.textPrimary)
                }
                .padding(.horizontal, 12)
                .padding(.top, 20)
                .padding(.bottom, 16)
                .interactiveTilt()

                ForEach(SettingsTab.allCases) { tab in
                    Button(action: {
                        withAnimation(DesignSystem.Animations.snappyEaseOut) {
                            selectedTab = tab
                        }
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: tab.iconName)
                                .font(.system(size: 13))
                                .frame(width: 18)
                            Text(tab.rawValue)
                                .font(.system(size: 12, weight: selectedTab == tab ? .semibold : .medium))
                            Spacer()
                        }
                        .foregroundColor(selectedTab == tab ? DesignSystem.textPrimary : DesignSystem.textSecondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            ZStack {
                                if selectedTab == tab {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(DesignSystem.bgTertiary)
                                        .matchedGeometryEffect(id: "activeSidebarTab", in: tabNamespace)
                                        .shadow(color: .black.opacity(0.2), radius: 2, y: 1)
                                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(DesignSystem.borderHighlight, lineWidth: 0.5))
                                }
                            }
                        )
                        .modernHoverEffect(hoverColor: DesignSystem.bgSecondary, cornerRadius: 8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }

                Spacer()

                Button(action: {
                    onOpenOnboarding?()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles.rectangle.stack.fill")
                            .font(.system(size: 12))
                        Text("Onboarding öffnen")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(DesignSystem.textMuted)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .modernHoverEffect(hoverColor: DesignSystem.bgSecondary)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.bottom, 16)
            }
            .frame(width: 170)
            .padding(.horizontal, 8)
            .background(VisualEffectView(material: .sidebar, blendingMode: .behindWindow, state: .active))

            Divider()
                .background(DesignSystem.borderDefault)

            // Main Content Area
            VStack(alignment: .leading, spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        Group {
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
                        .transition(.scale(scale: 0.98).combined(with: .opacity))
                    }
                    .padding(24)
                }
                .animation(DesignSystem.Animations.snappyEaseOut, value: selectedTab)

                Divider()
                    .background(DesignSystem.borderDefault)

                HStack {
                    Spacer()
                    Button(action: {
                        NSApp.keyWindow?.close()
                    }) {
                        Text("Fertig")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .background(Color.white)
                            .cornerRadius(6)
                            .shadow(color: .white.opacity(0.3), radius: 4)
                    }
                    .buttonStyle(.modern)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(VisualEffectView(material: .titlebar, blendingMode: .withinWindow, state: .active))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(DesignSystem.bgPrimary)
        }
        .frame(width: 600, height: 400)
        .opacity(isVisible ? 1 : 0)
        .scaleEffect(isVisible ? 1 : 0.95)
        .onAppear {
            withAnimation(DesignSystem.Animations.snappyEaseOut) {
                isVisible = true
            }
        }
    }

    // MARK: - General Section
    private var sectionGeneral: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Allgemeine Einstellungen")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(DesignSystem.textPrimary)

            VStack(spacing: 12) {
                settingRow(
                    icon: "clock.arrow.circlepath",
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
                    .frame(width: 140)
                }

                settingRow(
                    icon: "bolt.horizontal.fill",
                    title: "Bei macOS-Login starten",
                    desc: "CursorCompanion automatisch im Hintergrund öffnen"
                ) {
                    Toggle("", isOn: Binding(
                        get: { appState.settings.launchAtLogin },
                        set: { val in
                            withAnimation(DesignSystem.Animations.fastSpring) {
                                appState.settings.launchAtLogin = val
                                LaunchAtLoginHelper.setEnabled(val)
                            }
                        }
                    ))
                    .toggleStyle(SwitchToggleStyle())
                }

                settingRow(
                    icon: "bell.badge.fill",
                    title: "Warnung bei hohem Verbrauch",
                    desc: "macOS-Benachrichtigung bei ≥ 85% Verbrauch"
                ) {
                    Toggle("", isOn: Binding(
                        get: { appState.settings.notifyHighUsage },
                        set: { val in
                            withAnimation(DesignSystem.Animations.fastSpring) {
                                appState.settings.notifyHighUsage = val
                                if val { permissions.requestNotificationPermission() }
                            }
                        }
                    ))
                    .toggleStyle(SwitchToggleStyle())
                }
            }
        }
    }

    // MARK: - Accounts Section
    private var sectionAccounts: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Verwaltete Accounts")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(DesignSystem.textPrimary)
                Spacer()
                Button(action: {
                    Task { await appState.syncActiveCursorAccount() }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.clockwise")
                        Text("Jetzt scannen")
                    }
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(DesignSystem.textPrimary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(DesignSystem.bgTertiary)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(DesignSystem.borderHighlight, lineWidth: 0.5))
                    .cornerRadius(6)
                }
                .buttonStyle(.springy)
            }

            if appState.accounts.isEmpty {
                Text("Keine Accounts gecacht. Bitte öffne die Cursor-App und melde dich an.")
                    .font(.system(size: 12))
                    .foregroundColor(DesignSystem.textSecondary)
                    .padding(.vertical, 12)
            } else {
                ForEach(appState.accounts) { account in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 8) {
                                    Text(account.label)
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(DesignSystem.textPrimary)

                                    if account.isActive {
                                        Text("AKTIV")
                                            .font(.system(size: 9, weight: .bold))
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(DesignSystem.accentSuccess.opacity(0.15))
                                            .foregroundColor(DesignSystem.accentSuccess)
                                            .cornerRadius(4)
                                    } else {
                                        Text("CACHED")
                                            .font(.system(size: 9, weight: .bold))
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(DesignSystem.bgTertiary)
                                            .foregroundColor(DesignSystem.textSecondary)
                                            .cornerRadius(4)
                                    }

                                    if let plan = account.plan {
                                        Text(plan.uppercased())
                                            .font(.system(size: 9, weight: .bold))
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(DesignSystem.accentWarning.opacity(0.15))
                                            .foregroundColor(DesignSystem.accentWarning)
                                            .cornerRadius(4)
                                    }
                                }

                                Text(account.id)
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(DesignSystem.textMuted)
                            }

                            Spacer()

                            Button(action: {
                                withAnimation(DesignSystem.Animations.physicalSpring) {
                                    if renamingAccountID == account.id {
                                        renamingAccountID = nil
                                    } else {
                                        renamingAccountID = account.id
                                        renamingText = account.label
                                    }
                                }
                            }) {
                                Image(systemName: "pencil")
                                    .font(.system(size: 12))
                                    .foregroundColor(DesignSystem.textPrimary)
                                    .frame(width: 24, height: 24)
                                    .background(DesignSystem.bgTertiary)
                                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(DesignSystem.borderHighlight, lineWidth: 0.5))
                                    .cornerRadius(6)
                            }
                            .buttonStyle(.springy)
                            .help("Umbenennen")

                            if !account.isActive {
                                Button(action: {
                                    Task { await appState.removeAccount(accountID: account.id) }
                                }) {
                                    Image(systemName: "trash")
                                        .font(.system(size: 12))
                                        .foregroundColor(DesignSystem.accentError)
                                        .frame(width: 24, height: 24)
                                        .background(DesignSystem.bgTertiary)
                                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(DesignSystem.borderHighlight, lineWidth: 0.5))
                                        .cornerRadius(6)
                                }
                                .buttonStyle(.springy)
                                .help("Entfernen")
                            }
                        }

                        if renamingAccountID == account.id {
                            HStack(spacing: 8) {
                                TextField("Neues Label", text: $renamingText)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .frame(maxWidth: .infinity)
                                
                                Button(action: {
                                    Task {
                                        await appState.updateAccountLabel(accountID: account.id, newLabel: renamingText)
                                        withAnimation(DesignSystem.Animations.physicalSpring) {
                                            renamingAccountID = nil
                                        }
                                    }
                                }) {
                                    Text("Speichern")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(DesignSystem.textPrimary)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .background(DesignSystem.bgTertiary)
                                        .cornerRadius(6)
                                }
                                .buttonStyle(.springy)

                                Button(action: {
                                    withAnimation(DesignSystem.Animations.physicalSpring) {
                                        renamingAccountID = nil
                                    }
                                }) {
                                    Text("Abbrechen")
                                        .font(.system(size: 11))
                                        .foregroundColor(DesignSystem.textSecondary)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                }
                                .buttonStyle(.springy)
                            }
                            .padding(.top, 8)
                            .transition(AnyTransition.opacity.combined(with: AnyTransition.move(edge: .top)))
                        }
                    }
                    .padding(14)
                    .background(DesignSystem.bgSecondary)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(DesignSystem.borderHighlight, lineWidth: 0.5))
                    .cornerRadius(10)
                }
            }
        }
    }

    // MARK: - Permissions Section
    private var sectionPermissions: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("System-Berechtigungen & Status")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(DesignSystem.textPrimary)

            VStack(spacing: 12) {
                permissionRow(
                    icon: "doc.text.magnifyingglass",
                    title: "Cursor Datenbank (state.vscdb)",
                    desc: "Lesender Zugriff auf lokale Cursor-Session",
                    status: permissions.sqliteStatus
                )

                permissionRow(
                    icon: "key.fill",
                    title: "Schlüsselbund-Zugriff (Keychain)",
                    desc: "Sichere Speicherung für Multi-Account-Sessions",
                    status: permissions.keychainStatus,
                    actionTitle: "Einmalig erlauben"
                ) {
                    permissions.requestKeychainAuthorization()
                }

                permissionRow(
                    icon: "app.badge.fill",
                    title: "macOS Benachrichtigungen",
                    desc: "Warnmeldungen bei hoher Kontingent-Auslastung",
                    status: permissions.notificationStatus,
                    actionTitle: "Aktivieren"
                ) {
                    permissions.requestNotificationPermission()
                }
            }

            Button(action: {
                permissions.refreshAll()
            }) {
                Text("Status aktualisieren")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(DesignSystem.accentInfo)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(DesignSystem.bgTertiary)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(DesignSystem.borderHighlight, lineWidth: 0.5))
                    .cornerRadius(6)
            }
            .buttonStyle(.springy)
            .padding(.top, 8)
        }
    }

    private func settingRow<Content: View>(icon: String, title: String, desc: String, @ViewBuilder content: () -> Content) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(DesignSystem.textSecondary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(DesignSystem.textPrimary)
                Text(desc)
                    .font(.system(size: 11))
                    .foregroundColor(DesignSystem.textSecondary)
            }
            Spacer()
            content()
        }
        .padding(14)
        .background(DesignSystem.bgSecondary)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(DesignSystem.borderHighlight, lineWidth: 0.5))
        .cornerRadius(10)
    }

    private func permissionRow(icon: String, title: String, desc: String, status: PermissionStatus, actionTitle: String? = nil, action: (() -> Void)? = nil) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(DesignSystem.textSecondary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(DesignSystem.textPrimary)
                Text(desc)
                    .font(.system(size: 11))
                    .foregroundColor(DesignSystem.textSecondary)
            }
            Spacer()

            switch status {
            case .authorized:
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Erlaubt")
                }
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(DesignSystem.accentSuccess)

            case .denied, .notDetermined:
                if let action = action, let title = actionTitle {
                    Button(action: action) {
                        Text(title)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 5)
                            .background(DesignSystem.accentSuccess)
                            .shadow(color: DesignSystem.accentSuccess.opacity(0.4), radius: 4)
                            .cornerRadius(6)
                    }
                    .buttonStyle(.springy)
                } else {
                    Text("Bereit")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }

            case .notFound(let reason):
                Text("Nicht gefunden")
                    .font(.system(size: 12))
                    .foregroundColor(DesignSystem.accentWarning)
                    .help(reason)
            }
        }
        .padding(14)
        .background(DesignSystem.bgSecondary)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(DesignSystem.borderHighlight, lineWidth: 0.5))
        .cornerRadius(10)
    }
}
