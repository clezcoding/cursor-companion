import Foundation
import Combine

/// Zentraler, beobachtbarer Zustand für die SwiftUI-Oberfläche mit UserDefaults-Persistenz
@MainActor
public final class AppState: ObservableObject {
    private static let settingsStorageKey = "dev.cursorcompanion.user_settings"

    @Published public var accounts: [CursorAccount] = []
    @Published public var selectedAccountID: String?
    @Published public var isRefreshing: Bool = false
    @Published public var isSyncing: Bool = false
    @Published public var lastSyncDate: Date?
    @Published public var settings: UserSettings {
        didSet {
            saveSettings()
        }
    }

    public var selectedAccount: CursorAccount? {
        if let id = selectedAccountID {
            return accounts.first(where: { $0.id == id })
        }
        return activeAccount ?? accounts.first
    }

    public var activeAccount: CursorAccount? {
        return accounts.first(where: { $0.isActive })
    }

    public let store: AccountStore
    public let client: CursorClient
    public let historyStore: HistoryStore

    public init(store: AccountStore, client: CursorClient = CursorClient(), historyStore: HistoryStore = HistoryStore(databaseURL: URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true).first ?? NSTemporaryDirectory()).appendingPathComponent("CursorCompanion").appendingPathComponent("history.sqlite"))) {
        self.store = store
        self.client = client
        self.historyStore = historyStore
        
        if let data = UserDefaults.standard.data(forKey: Self.settingsStorageKey),
           let saved = try? JSONDecoder().decode(UserSettings.self, from: data) {
            self.settings = saved
        } else {
            self.settings = UserSettings()
        }
    }

    private func saveSettings() {
        if let data = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(data, forKey: Self.settingsStorageKey)
        }
    }

    /// Kaltstart: Lädt sofort alle gecachten Accounts aus dem lokalen Speicher (< 1s)
    public func loadCachedAccounts() async {
        let loaded = await store.loadAccounts()
        self.accounts = loaded
        if selectedAccountID == nil {
            self.selectedAccountID = loaded.first(where: { $0.isActive })?.id ?? loaded.first?.id
        }
    }

    /// Wählt einen Account für die Popover-Ansicht aus
    public func selectAccount(id: String) {
        self.selectedAccountID = id
    }

    /// Synchronisiert die aktuell auf dem Mac aktive Cursor-Session
    public func syncActiveCursorAccount() async {
        guard let activeAuth = CursorAuth.detectActiveSession(),
              let userID = CursorAuth.userID(fromAccessToken: activeAuth.accessToken) else {
            // Kein aktiver Login gefunden
            return
        }

        let tokens = AuthTokens(
            accessToken: activeAuth.accessToken,
            refreshToken: activeAuth.refreshToken
        )

        let existing = accounts.first(where: { $0.id == userID })
        let label = existing?.label ?? (accounts.isEmpty ? "Work" : "Account \(accounts.count + 1)")
        let account = CursorAccount(
            id: userID,
            label: label,
            isActive: true,
            plan: existing?.plan ?? activeAuth.membershipType,
            snapshot: existing?.snapshot,
            status: .ok,
            lastSeen: Date()
        )

        // Markiere andere als inaktiv
        await store.setActiveAccount(accountID: userID)
        await store.saveOrUpdateAccount(account, tokens: tokens)
        await loadCachedAccounts()
    }

    /// Aktualisiert alle verwalteten Accounts parallel im Hintergrund
    public func refreshAllAccounts() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        isSyncing = true
        defer {
            isRefreshing = false
            isSyncing = false
            lastSyncDate = Date()
        }

        // Zuerst sicherstellen, dass die aktive Session aktuell eingelesen ist
        await syncActiveCursorAccount()

        let currentAccounts = await store.loadAccounts()
        guard !currentAccounts.isEmpty else { return }

        var updatedAccounts: [CursorAccount] = []

        await withTaskGroup(of: CursorAccount.self) { group in
            for acc in currentAccounts {
                group.addTask {
                    return await self.client.fetchAccountUsage(account: acc, store: self.store)
                }
            }

            for await result in group {
                updatedAccounts.append(result)
                
                let workspace = WorkspaceTrackerService.shared.getActiveWorkspace()
                
                if result.status == .ok, let snap = result.snapshot {
                    AnalyticsDatabase.shared.saveSnapshot(
                        accountID: result.id,
                        cursorPercent: snap.cursorModelsPercent ?? 0.0,
                        otherPercent: snap.otherModelsPercent ?? 0.0,
                        workspace: workspace
                    )
                    
                    Task {
                        await self.historyStore.saveSnapshot(snap, for: result.id)
                    }
                }
            }
        }

        // Alphabetisch/stabil nach ID oder Label sortieren
        self.accounts = updatedAccounts.sorted(by: { $0.isActive && !$1.isActive })
    }

    /// Ändert das benutzerdefinierte Label eines Accounts
    public func updateAccountLabel(accountID: String, newLabel: String) async {
        await store.updateLabel(accountID: accountID, newLabel: newLabel)
        await loadCachedAccounts()
    }

    /// Entfernt einen Account aus der Verwaltung
    public func removeAccount(accountID: String) async {
        await store.removeAccount(accountID: accountID)
        if selectedAccountID == accountID {
            selectedAccountID = nil
        }
        await loadCachedAccounts()
    }
}
