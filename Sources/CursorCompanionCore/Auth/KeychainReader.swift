import Foundation
import Security

/// Liest Authentifizierungs-Tokens aus dem macOS-Schlüsselbund (Cursor Fallback)
public enum KeychainReader: Sendable {
    public static func readCursorTokens() -> RawAuthData? {
        guard let access = readGenericPassword(service: "cursor-access-token"),
              let refresh = readGenericPassword(service: "cursor-refresh-token") else {
            return nil
        }
        return RawAuthData(accessToken: access, refreshToken: refresh)
    }

    public static func readGenericPassword(service: String, account: String? = nil) -> String? {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        if let account = account {
            query[kSecAttrAccount as String] = account
        }

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }
}
