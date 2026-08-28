import XCTest
@testable import CursorCompanionCore

final class AccountStoreTests: XCTestCase {
    func test_addAndRetrieveAccount() async throws {
        let store = AccountStore(servicePrefix: "test.cursorcompanion.\(UUID().uuidString)")
        let account = CursorAccount(
            id: "user_test_123",
            label: "Work Account",
            isActive: true,
            plan: "Pro",
            snapshot: nil,
            status: .ok
        )
        let tokens = AuthTokens(accessToken: "tok_access", refreshToken: "tok_refresh")
        
        await store.saveOrUpdateAccount(account, tokens: tokens)
        let accounts = await store.loadAccounts()
        XCTAssertTrue(accounts.contains { $0.id == "user_test_123" })
        
        let loadedTokens = await store.getTokens(accountID: "user_test_123")
        XCTAssertEqual(loadedTokens?.accessToken, "tok_access")
        XCTAssertEqual(loadedTokens?.refreshToken, "tok_refresh")
    }

    func test_updateLabel() async throws {
        let store = AccountStore(servicePrefix: "test.cursorcompanion.\(UUID().uuidString)")
        let account = CursorAccount(id: "user_rename_456", label: "Alt", isActive: false)
        await store.saveOrUpdateAccount(account, tokens: nil)

        await store.updateLabel(accountID: "user_rename_456", newLabel: "Neu")
        let accounts = await store.loadAccounts()
        let updated = accounts.first { $0.id == "user_rename_456" }
        XCTAssertEqual(updated?.label, "Neu")
    }

    func test_removeAccount() async throws {
        let store = AccountStore(servicePrefix: "test.cursorcompanion.\(UUID().uuidString)")
        let account = CursorAccount(id: "user_del_789", label: "To Delete", isActive: false)
        let tokens = AuthTokens(accessToken: "tok_a", refreshToken: "tok_r")
        await store.saveOrUpdateAccount(account, tokens: tokens)

        await store.removeAccount(accountID: "user_del_789")
        let accounts = await store.loadAccounts()
        XCTAssertFalse(accounts.contains { $0.id == "user_del_789" })
        
        let loadedTokens = await store.getTokens(accountID: "user_del_789")
        XCTAssertNil(loadedTokens)
    }
}
