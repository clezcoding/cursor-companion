import Foundation

/// Thread-sicherer Actor für die Multi-Account-Verwaltung und Persistenz
public actor AccountStore {
    private var accounts: [CursorAccount]
    private let keychainStorage: SecureKeychainStorage
    private let metadataStorage: AccountMetadataStorage

    public init(
        servicePrefix: String = "dev.cursorcompanion.account",
        metadataKey: String? = nil
    ) {
        self.keychainStorage = SecureKeychainStorage(servicePrefix: servicePrefix)
        let metaKey = metadataKey ?? "\(servicePrefix).metadata"
        self.metadataStorage = AccountMetadataStorage(storageKey: metaKey)
        self.accounts = metadataStorage.loadAccounts()
    }

    /// Gibt alle aktuell verwalteten Accounts zurück
    public func loadAccounts() -> [CursorAccount] {
        return accounts
    }

    /// Speichert oder aktualisiert einen Account und optional dessen Tokens
    public func saveOrUpdateAccount(_ account: CursorAccount, tokens: AuthTokens?) {
        if let tokens = tokens {
            keychainStorage.saveTokens(tokens, accountID: account.id)
        }

        if let index = accounts.firstIndex(where: { $0.id == account.id }) {
            accounts[index] = account
        } else {
            accounts.append(account)
        }
        metadataStorage.saveAccounts(accounts)
    }

    /// Liest die AuthTokens für einen Account
    public func getTokens(accountID: String) -> AuthTokens? {
        return keychainStorage.getTokens(accountID: accountID)
    }

    /// Aktualisiert den Snapshot, Status und Plan eines Accounts
    public func updateSnapshot(
        accountID: String,
        snapshot: UsageSnapshot?,
        status: AccountStatus,
        plan: String? = nil
    ) {
        guard let index = accounts.firstIndex(where: { $0.id == accountID }) else { return }
        accounts[index].snapshot = snapshot
        accounts[index].status = status
        if let plan = plan {
            accounts[index].plan = plan
        }
        accounts[index].lastSeen = Date()
        metadataStorage.saveAccounts(accounts)
    }

    /// Ändert das Label eines Accounts
    public func updateLabel(accountID: String, newLabel: String) {
        guard let index = accounts.firstIndex(where: { $0.id == accountID }) else { return }
        accounts[index].label = newLabel
        metadataStorage.saveAccounts(accounts)
    }

    /// Markiert einen Account als aktiv (und andere als inaktiv)
    public func setActiveAccount(accountID: String) {
        for i in 0..<accounts.count {
            accounts[i].isActive = (accounts[i].id == accountID)
        }
        metadataStorage.saveAccounts(accounts)
    }

    /// Entfernt einen Account und seine Tokens vollständig
    public func removeAccount(accountID: String) {
        accounts.removeAll { $0.id == accountID }
        keychainStorage.deleteTokens(accountID: accountID)
        metadataStorage.saveAccounts(accounts)
    }
}
