import Foundation
import Security

/// Verwaltet den isolierten Keychain-Zugriff für CursorCompanion-Accounts
public struct SecureKeychainStorage: Sendable {
    public let servicePrefix: String

    public init(servicePrefix: String = "dev.cursorcompanion.account") {
        self.servicePrefix = servicePrefix
    }

    private func serviceName(for accountID: String) -> String {
        return "\(servicePrefix).\(accountID)"
    }

    /// Speichert oder aktualisiert AuthTokens im Schlüsselbund
    public func saveTokens(_ tokens: AuthTokens, accountID: String) {
        guard let data = try? JSONEncoder().encode(tokens) else { return }

        let service = serviceName(for: accountID)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "tokens"
        ]

        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            var newQuery = query
            for (k, v) in attributes { newQuery[k] = v }
            SecItemAdd(newQuery as CFDictionary, nil)
        }
    }

    /// Liest AuthTokens aus dem Schlüsselbund
    public func getTokens(accountID: String) -> AuthTokens? {
        let service = serviceName(for: accountID)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "tokens",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess,
              let data = item as? Data,
              let tokens = try? JSONDecoder().decode(AuthTokens.self, from: data) else {
            return nil
        }
        return tokens
    }

    /// Löscht die Tokens eines Accounts aus dem Schlüsselbund
    public func deleteTokens(accountID: String) {
        let service = serviceName(for: accountID)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service
        ]
        SecItemDelete(query as CFDictionary)
    }
}
