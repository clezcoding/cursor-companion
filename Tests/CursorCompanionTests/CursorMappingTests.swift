import XCTest
@testable import CursorCompanionCore

final class CursorMappingTests: XCTestCase {
    private func loadFixture(_ name: String) throws -> [String: Any] {
        let url = Bundle.module.url(forResource: "fixtures/\(name)", withExtension: nil)
            ?? Bundle.module.url(forResource: name, withExtension: nil)
            ?? Bundle.module.url(forResource: "fixtures/\(name)", withExtension: "json")
            ?? Bundle.module.url(forResource: name, withExtension: "json")
            
        let foundUrl = try XCTUnwrap(url, "Fixture nicht gefunden: \(name)")
        let data = try Data(contentsOf: foundUrl)
        return try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
    }

    func test_individual_mapsBothPools() throws {
        let json = try loadFixture("usage-summary-individual.json")
        let snapshot = try CursorUsageMapper.mapSummary(json)

        let cursorPercent = try XCTUnwrap(snapshot.cursorModelsPercent)
        let otherPercent = try XCTUnwrap(snapshot.otherModelsPercent)
        let totalPercent = try XCTUnwrap(snapshot.totalPercent)

        XCTAssertEqual(cursorPercent, 63.0, accuracy: 0.001)
        XCTAssertEqual(otherPercent, 41.2, accuracy: 0.001)
        XCTAssertEqual(totalPercent, 52.4, accuracy: 0.001)
        XCTAssertNotNil(snapshot.cycleEnd)
    }

    func test_team_missingPercents_yieldsNoData_noCrash() throws {
        let json = try loadFixture("usage-summary-team.json")
        let snapshot = try CursorUsageMapper.mapSummary(json)

        XCTAssertNil(snapshot.cursorModelsPercent, "Team-Form ohne Prozente -> Keine Daten")
        XCTAssertNil(snapshot.otherModelsPercent)
        XCTAssertNotNil(snapshot.cycleEnd, "cycleEnd wird trotzdem gelesen")
    }

    func test_partial_onlyOtherModels() throws {
        let json = try loadFixture("usage-summary-partial.json")
        let snapshot = try CursorUsageMapper.mapSummary(json)

        XCTAssertNil(snapshot.cursorModelsPercent)
        let otherPercent = try XCTUnwrap(snapshot.otherModelsPercent)
        XCTAssertEqual(otherPercent, 18.5, accuracy: 0.001)
        XCTAssertNil(snapshot.totalPercent)
        XCTAssertNil(snapshot.cycleEnd)
    }

    func test_empty_allNoData_noCrash() throws {
        let json = try loadFixture("usage-summary-empty.json")
        _ = try? CursorUsageMapper.mapSummary(json)
    }

    func test_requestBasedFallback() throws {
        let json = try loadFixture("api-usage-requests.json")
        let requests = try CursorUsageMapper.mapRequestUsage(json)

        XCTAssertEqual(requests.used, 412)
        XCTAssertEqual(requests.limit, 500)
    }
}
