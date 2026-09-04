import Foundation

/// HTTP-Client für die Cursor Connect-RPC und REST APIs mit automatischer Token-Erneuerung
public final class CursorClient: Sendable {
    public enum ClientError: Error, Equatable {
        case unauthenticated
        case networkError(String)
        case decodingError
        case sessionExpired
    }

    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    /// Parst die Antwort des OAuth-Token-Refresh-Endpunkts
    public static func parseRefreshResponse(_ data: Data, fallbackRefreshToken: String) throws -> AuthTokens {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let accessToken = json["access_token"] as? String else {
            throw ClientError.decodingError
        }
        let refreshToken = json["refresh_token"] as? String ?? fallbackRefreshToken
        return AuthTokens(accessToken: accessToken, refreshToken: refreshToken)
    }

    /// Erneuert das Access Token über Cursors OAuth-Endpunkt
    public func refreshToken(refreshToken: String) async throws -> AuthTokens {
        var request = URLRequest(url: CursorEndpoints.oauthTokenURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: String] = [
            "grant_type": "refresh_token",
            "client_id": CursorEndpoints.clientID,
            "refresh_token": refreshToken
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw ClientError.networkError("Ungültige Antwort")
        }
        guard http.statusCode == 200 else {
            throw ClientError.sessionExpired
        }

        return try Self.parseRefreshResponse(data, fallbackRefreshToken: refreshToken)
    }

    /// Ruft GET https://cursor.com/api/usage-summary mit Session-Cookie ab
    public func fetchUsageSummary(tokens: AuthTokens) async throws -> UsageSnapshot {
        guard let cookieVal = CursorAuth.sessionCookieValue(fromAccessToken: tokens.accessToken) else {
            throw ClientError.unauthenticated
        }

        var request = URLRequest(url: CursorEndpoints.usageSummaryURL)
        request.httpMethod = "GET"
        request.setValue("WorkosCursorSessionToken=\(cookieVal)", forHTTPHeaderField: "Cookie")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw ClientError.networkError("Ungültige Antwort")
        }

        if http.statusCode == 401 || http.statusCode == 403 {
            throw ClientError.unauthenticated
        }

        guard (200...299).contains(http.statusCode),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw ClientError.decodingError
        }

        return try CursorUsageMapper.mapSummary(json)
    }

    /// Ruft GET https://cursor.com/api/usage?user=<id> ab
    public func fetchRequestUsage(tokens: AuthTokens, userID: String) async throws -> [String: Any] {
        guard let cookieVal = CursorAuth.sessionCookieValue(fromAccessToken: tokens.accessToken) else {
            throw ClientError.unauthenticated
        }

        var request = URLRequest(url: CursorEndpoints.requestUsageURL(userID: userID))
        request.httpMethod = "GET"
        request.setValue("WorkosCursorSessionToken=\(cookieVal)", forHTTPHeaderField: "Cookie")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw ClientError.networkError("Ungültige Antwort")
        }

        if http.statusCode == 401 || http.statusCode == 403 {
            throw ClientError.unauthenticated
        }

        guard (200...299).contains(http.statusCode),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw ClientError.decodingError
        }

        return json
    }

    /// Ruft PlanInfo über Connect-RPC ab (optional für Plandetails)
    public func fetchPlanInfo(tokens: AuthTokens) async throws -> String? {
        var request = URLRequest(url: CursorEndpoints.planInfoURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(tokens.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("1", forHTTPHeaderField: "Connect-Protocol-Version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = "{}".data(using: .utf8)

        guard let (data, response) = try? await session.data(for: request),
              let http = response as? HTTPURLResponse,
              (200...299).contains(http.statusCode),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }

        return json["planType"] as? String ?? json["membershipType"] as? String
    }

    /// Lädt die Nutzungsdaten für einen Account mit automatischer 401/403-Refresh-Schleife
    public func fetchAccountUsage(account: CursorAccount, store: AccountStore) async -> CursorAccount {
        guard var tokens = await store.getTokens(accountID: account.id) else {
            var updated = account
            updated.status = .loginRequired
            return updated
        }

        // Vorab prüfen: Läuft das Token in <5 Minuten ab?
        if CursorAuth.needsRefresh(tokens.accessToken) {
            if let refreshed = try? await refreshToken(refreshToken: tokens.refreshToken) {
                tokens = refreshed
                await store.saveOrUpdateAccount(account, tokens: refreshed)
            }
        }

        var attempt = 0
        while attempt < 2 {
            attempt += 1
            do {
                var snapshot = try await fetchUsageSummary(tokens: tokens)
                if let requestJson = try? await fetchRequestUsage(tokens: tokens, userID: account.id),
                   let parsed = try? CursorUsageMapper.mapRequestUsage(requestJson) {
                    snapshot.requestsUsed = parsed.used
                    snapshot.requestsLimit = parsed.limit
                    snapshot.modelBreakdown = parsed.breakdown
                }
                
                let plan = try? await fetchPlanInfo(tokens: tokens)

                var updated = account
                updated.snapshot = snapshot
                updated.status = .ok
                if let p = plan { updated.plan = p }
                updated.lastSeen = Date()

                await store.updateSnapshot(
                    accountID: account.id,
                    snapshot: snapshot,
                    status: .ok,
                    plan: plan
                )
                return updated
            } catch ClientError.unauthenticated {
                if attempt == 1 {
                    // Token abgelaufen -> genau 1x erneuern und wiederholen
                    if let refreshed = try? await refreshToken(refreshToken: tokens.refreshToken) {
                        tokens = refreshed
                        await store.saveOrUpdateAccount(account, tokens: refreshed)
                        continue
                    }
                }
                var updated = account
                updated.status = .loginRequired
                await store.updateSnapshot(accountID: account.id, snapshot: account.snapshot, status: .loginRequired)
                return updated
            } catch {
                var updated = account
                updated.status = .error(error.localizedDescription)
                return updated
            }
        }

        var updated = account
        updated.status = .loginRequired
        return updated
    }
}
