import Foundation

/// Haupt-Authentifizierungslogik für Cursor-Sessions
public enum CursorAuth: Sendable {
    /// Extrahiert die User-ID aus dem `sub`-Claim eines JWT
    public static func userID(fromAccessToken token: String) -> String? {
        guard let claims = JWTHelper.decodeClaims(from: token),
              let sub = claims["sub"] as? String else {
            return nil
        }
        return parseUserID(fromSub: sub)
    }

    /// Hilfsfunktion: Teilt `sub` an `|` auf; falls vorhanden, wird parts[1] gewählt, sonst parts[0]
    public static func parseUserID(fromSub sub: String) -> String {
        let parts = sub.components(separatedBy: "|")
        if parts.count > 1 {
            return parts[1]
        }
        return sub
    }

    /// Berechnet das Ablaufdatum aus dem `exp`-Claim eines JWT
    public static func expirationDate(fromAccessToken token: String) -> Date? {
        guard let claims = JWTHelper.decodeClaims(from: token) else { return nil }
        if let expNumber = claims["exp"] as? NSNumber {
            return Date(timeIntervalSince1970: expNumber.doubleValue)
        } else if let expDouble = claims["exp"] as? Double {
            return Date(timeIntervalSince1970: expDouble)
        }
        return nil
    }

    /// Erzeugt den Wert für den `WorkosCursorSessionToken`-Cookie
    /// Format: `<userID>%3A%3A<accessToken>` (entspricht URL-encodiert `userID::accessToken`)
    public static func sessionCookieValue(fromAccessToken token: String) -> String? {
        guard let uid = userID(fromAccessToken: token) else { return nil }
        return "\(uid)%3A%3A\(token)"
    }

    /// Prüft, ob ein Token erneuert werden muss (Standard: 300 Sekunden Puffer vor Ablauf)
    public static func needsRefresh(_ token: String, bufferSeconds: TimeInterval = 300, now: Date = Date()) -> Bool {
        guard let exp = expirationDate(fromAccessToken: token) else {
            // Kein lesbares Ablaufdatum -> defensiv als erneuerungsbedürftig werten
            return true
        }
        return exp.timeIntervalSince(now) < bufferSeconds
    }
}
