import XCTest
@testable import CursorCompanionCore

final class CursorAuthTests: XCTestCase {
    func test_jwt_userIDFromSubWithPipe() {
        let token = TokenFixtures.valid
        XCTAssertEqual(CursorAuth.userID(fromAccessToken: token), "user_ACTIVE001")
    }

    func test_jwt_userIDFromSubWithoutPipe() {
        let token = TokenFixtures.noPipe
        XCTAssertEqual(CursorAuth.userID(fromAccessToken: token), "user_NOPIPE003")
    }

    func test_session_cookieValueFormat() {
        let token = TokenFixtures.valid
        let cookie = CursorAuth.sessionCookieValue(fromAccessToken: token)
        XCTAssertEqual(cookie, "user_ACTIVE001%3A%3A\(token)")
    }

    func test_needsRefresh_states() {
        XCTAssertFalse(CursorAuth.needsRefresh(TokenFixtures.valid))
        XCTAssertTrue(CursorAuth.needsRefresh(TokenFixtures.expiring))
        XCTAssertTrue(CursorAuth.needsRefresh(TokenFixtures.expired))
        XCTAssertTrue(CursorAuth.needsRefresh("not.a.jwt"))
    }
}

enum TokenFixtures {
    static func jwt(sub: String, exp: TimeInterval) -> String {
        func b64url(_ obj: [String: Any]) -> String {
            let data = try! JSONSerialization.data(withJSONObject: obj)
            return data.base64EncodedString()
                .replacingOccurrences(of: "+", with: "-")
                .replacingOccurrences(of: "/", with: "_")
                .replacingOccurrences(of: "=", with: "")
        }
        let header = b64url(["alg": "HS256", "typ": "JWT"])
        let payload = b64url(["sub": sub, "exp": exp])
        return "\(header).\(payload).SIGNATURE_NOT_VERIFIED"
    }

    static var now: TimeInterval { Date().timeIntervalSince1970 }
    static var valid: String { jwt(sub: "auth0|user_ACTIVE001", exp: now + 3600) }
    static var expiring: String { jwt(sub: "auth0|user_ACTIVE001", exp: now + 120) }
    static var expired: String { jwt(sub: "workos|user_SECOND002", exp: now - 60) }
    static var noPipe: String { jwt(sub: "user_NOPIPE003", exp: now + 3600) }
}
