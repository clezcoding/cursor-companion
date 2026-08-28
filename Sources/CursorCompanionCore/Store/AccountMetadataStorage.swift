import Foundation

/// Verwaltet die Speicherung von Account-Metadaten (ohne geheime Tokens) in UserDefaults
public struct AccountMetadataStorage: Sendable {
    private let storageKey: String

    public init(storageKey: String = "dev.cursorcompanion.accounts_metadata") {
        self.storageKey = storageKey
    }

    public func loadAccounts() -> [CursorAccount] {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let accounts = try? JSONDecoder().decode([CursorAccount].self, from: data) else {
            return []
        }
        return accounts
    }

    public func saveAccounts(_ accounts: [CursorAccount]) {
        guard let data = try? JSONEncoder().encode(accounts) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}
