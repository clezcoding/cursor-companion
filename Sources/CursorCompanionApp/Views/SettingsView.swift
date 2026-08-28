import SwiftUI
import CursorCompanionCore

/// Einstellungen-Fenster für CursorCompanion
public struct SettingsView: View {
    @ObservedObject var appState: AppState
    @State private var renamingAccountID: String?
    @State private var renamingText: String = ""

    public init(appState: AppState) {
        self.appState = appState
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text("Einstellungen")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
            }

            // Aktualisierungsintervall
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Intervall")
                        .font(.system(size: 12))
                        .foregroundColor(Color(white: 0.7))
                    Spacer()
                    Picker("", selection: $appState.settings.refreshIntervalMinutes) {
                        Text("1 min").tag(1)
                        Text("5 min").tag(5)
                        Text("15 min").tag(15)
                        Text("30 min").tag(30)
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(width: 90)
                }
            }

            // Gecachte Accounts
            VStack(alignment: .leading, spacing: 8) {
                Text("Gecachte Accounts")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color(white: 0.5))
                    .textCase(.uppercase)

                ForEach(appState.accounts) { account in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Text(account.label)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.white)
                                
                                if account.isActive {
                                    Text("AKTIV")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundColor(Color(red: 0.06, green: 0.73, blue: 0.51))
                                }
                            }

                            Text(account.id)
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(Color(white: 0.4))
                        }

                        Spacer()

                        Button(action: {
                            renamingAccountID = account.id
                            renamingText = account.label
                        }) {
                            Text("Umbenennen")
                                .font(.system(size: 11))
                                .foregroundColor(Color(white: 0.8))
                        }
                        .buttonStyle(PlainButtonStyle())

                        if !account.isActive {
                            Button(action: {
                                Task { await appState.removeAccount(accountID: account.id) }
                            }) {
                                Text("Entfernen")
                                    .font(.system(size: 11))
                                    .foregroundColor(Color(red: 0.96, green: 0.25, blue: 0.37))
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            if let renameID = renamingAccountID {
                HStack {
                    TextField("Neuer Name", text: $renamingText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button("Speichern") {
                        Task {
                            await appState.updateAccountLabel(accountID: renameID, newLabel: renamingText)
                            renamingAccountID = nil
                        }
                    }
                    Button("Abbrechen") {
                        renamingAccountID = nil
                    }
                }
            }

            Spacer()
        }
        .padding(20)
        .frame(width: 360, height: 320)
        .background(Color(red: 0.07, green: 0.07, blue: 0.07))
    }
}
