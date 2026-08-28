import XCTest
@testable import CursorCompanionCore

final class HistoryStoreTests: XCTestCase {
    func test_saveAndFetchSnapshot() async throws {
        let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("test_history_\(UUID().uuidString).sqlite")
        let store = HistoryStore(databaseURL: url)
        let snapshot = UsageSnapshot(cursorModelsPercent: 50.0, otherModelsPercent: 40.0, totalPercent: nil, cycleEnd: Date(), modelBreakdown: [:])
        
        await store.saveSnapshot(snapshot, for: "test_user")
        let history = await store.fetchHistory(for: "test_user")
        
        XCTAssertEqual(history.count, 1)
        XCTAssertEqual(history[0].cursorModelsPercent, 50.0)
    }
}
