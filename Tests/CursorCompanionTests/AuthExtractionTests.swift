import XCTest
@testable import CursorCompanionCore

final class AuthExtractionTests: XCTestCase {
    func test_selectionLogic_prefersKeychainWhenFreeAndMismatch() {
        let sqliteData = RawAuthData(
            accessToken: TokenFixtures.jwt(sub: "free_user", exp: Date().timeIntervalSince1970 + 3600),
            refreshToken: "ref1",
            membershipType: "free"
        )
        let keychainData = RawAuthData(
            accessToken: TokenFixtures.jwt(sub: "pro_user", exp: Date().timeIntervalSince1970 + 3600),
            refreshToken: "ref2",
            membershipType: "pro"
        )
        
        let chosen = CursorAuth.resolveSession(sqlite: sqliteData, keychain: keychainData)
        XCTAssertEqual(CursorAuth.userID(fromAccessToken: chosen?.accessToken ?? ""), "pro_user")
    }

    func test_selectionLogic_prefersSQLiteNormally() {
        let sqliteData = RawAuthData(
            accessToken: TokenFixtures.jwt(sub: "pro_user_sql", exp: Date().timeIntervalSince1970 + 3600),
            refreshToken: "ref1",
            membershipType: "pro"
        )
        let keychainData = RawAuthData(
            accessToken: TokenFixtures.jwt(sub: "pro_user_kc", exp: Date().timeIntervalSince1970 + 3600),
            refreshToken: "ref2",
            membershipType: "pro"
        )
        
        let chosen = CursorAuth.resolveSession(sqlite: sqliteData, keychain: keychainData)
        XCTAssertEqual(CursorAuth.userID(fromAccessToken: chosen?.accessToken ?? ""), "pro_user_sql")
    }

    func test_selectionLogic_fallsBackToEitherIfOtherNil() {
        let sqliteData = RawAuthData(
            accessToken: TokenFixtures.jwt(sub: "only_sql", exp: Date().timeIntervalSince1970 + 3600),
            refreshToken: "ref1"
        )
        let keychainData = RawAuthData(
            accessToken: TokenFixtures.jwt(sub: "only_kc", exp: Date().timeIntervalSince1970 + 3600),
            refreshToken: "ref2"
        )
        
        XCTAssertEqual(CursorAuth.userID(fromAccessToken: CursorAuth.resolveSession(sqlite: sqliteData, keychain: nil)?.accessToken ?? ""), "only_sql")
        XCTAssertEqual(CursorAuth.userID(fromAccessToken: CursorAuth.resolveSession(sqlite: nil, keychain: keychainData)?.accessToken ?? ""), "only_kc")
        XCTAssertNil(CursorAuth.resolveSession(sqlite: nil, keychain: nil))
    }
}
