import Foundation

/// Hilfsklasse zum Parsen von unverschlüsselten JWT-Payloads (Claims)
public enum JWTHelper: Sendable {
    /// Extrahiert die Payload-Claims aus einem JWT
    public static func decodeClaims(from jwt: String) -> [String: Any]? {
        let parts = jwt.components(separatedBy: ".")
        guard parts.count >= 2 else { return nil }
        
        let payloadPart = parts[1]
        var base64 = payloadPart
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        
        // Base64-Padding auffüllen falls nötig
        let remainder = base64.count % 4
        if remainder > 0 {
            base64.append(String(repeating: "=", count: 4 - remainder))
        }
        
        guard let data = Data(base64Encoded: base64),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        
        return json
    }
}
