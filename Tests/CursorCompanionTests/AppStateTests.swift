import XCTest
@testable import CursorCompanionCore

final class AppStateTests: XCTestCase {
    @MainActor
    func test_initialCacheLoadUnderOneSecond() async {
        let store = AccountStore(servicePrefix: "test.cursorcompanion.speed.\(UUID().uuidString)")
        let appState = AppState(store: store)
        let start = Date()
        await appState.loadCachedAccounts()
        let duration = Date().timeIntervalSince(start)
        XCTAssertLessThan(duration, 1.0, "Kaltstart-Ladezeit muss unter 1 Sekunde liegen")
    }

    @MainActor
    func test_accountSelection() async {
        let store = AccountStore(servicePrefix: "test.cursorcompanion.sel.\(UUID().uuidString)")
        let acc1 = CursorAccount(id: "u1", label: "Work", isActive: true)
        let acc2 = CursorAccount(id: "u2", label: "Personal", isActive: false)
        await store.saveOrUpdateAccount(acc1, tokens: nil)
        await store.saveOrUpdateAccount(acc2, tokens: nil)

        let appState = AppState(store: store)
        await appState.loadCachedAccounts()

        XCTAssertEqual(appState.selectedAccount?.id, "u1")
        appState.selectAccount(id: "u2")
        XCTAssertEqual(appState.selectedAccount?.id, "u2")
    }
    @MainActor
    func test_isSyncing_state() async {
        let store = AccountStore(servicePrefix: "test.cursorcompanion.sync.\(UUID().uuidString)")
        let appState = AppState(store: store)
        XCTAssertFalse(appState.isSyncing)
        
        let task = Task {
            await appState.refreshAllAccounts()
        }
        
        try? await Task.sleep(nanoseconds: 50_000_000)
        // Note: exact timing in async tests can be flaky, but this tests the toggle intent
        XCTAssertTrue(appState.isSyncing)
        
        await task.value
        XCTAssertFalse(appState.isSyncing)
    }
}
