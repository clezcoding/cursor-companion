import XCTest
@testable import CursorCompanionCore

final class CursorClientTests: XCTestCase {
    func test_refreshTokenResponseParsing() throws {
        let url = Bundle.module.url(forResource: "oauth-token-refresh-response", withExtension: "json", subdirectory: "fixtures")
            ?? Bundle.module.url(forResource: "fixtures/oauth-token-refresh-response", withExtension: "json")
            ?? Bundle.module.url(forResource: "oauth-token-refresh-response.json", withExtension: nil)
        let foundUrl = try XCTUnwrap(url)
        let data = try Data(contentsOf: foundUrl)
        
        let tokens = try CursorClient.parseRefreshResponse(data, fallbackRefreshToken: "existing_refresh")
        XCTAssertEqual(tokens.accessToken, "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.NEW_ACCESS_TOKEN_PAYLOAD.SIGNATURE_NOT_VERIFIED")
        XCTAssertEqual(tokens.refreshToken, "REFRESH_TOKEN_MAY_OR_MAY_NOT_ROTATE")
    }

    func test_refreshTokenResponse_fallbackWhenNoNewRefreshToken() throws {
        let json: [String: Any] = [
            "access_token": "new_access_only",
            "expires_in": 3600
        ]
        let data = try JSONSerialization.data(withJSONObject: json)
        let tokens = try CursorClient.parseRefreshResponse(data, fallbackRefreshToken: "kept_refresh")
        XCTAssertEqual(tokens.accessToken, "new_access_only")
        XCTAssertEqual(tokens.refreshToken, "kept_refresh")
    }
}
