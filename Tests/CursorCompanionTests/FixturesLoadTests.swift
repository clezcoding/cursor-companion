import XCTest
@testable import CursorCompanionCore

final class FixturesLoadTests: XCTestCase {
    func test_fixtureResourceLoading() throws {
        let url = Bundle.module.url(forResource: "usage-summary-individual", withExtension: "json", subdirectory: "fixtures")
            ?? Bundle.module.url(forResource: "fixtures/usage-summary-individual", withExtension: "json")
            ?? Bundle.module.url(forResource: "usage-summary-individual.json", withExtension: nil)
        
        let foundUrl = try XCTUnwrap(url, "Fixture usage-summary-individual.json nicht im Bundle gefunden")
        let data = try Data(contentsOf: foundUrl)
        XCTAssertFalse(data.isEmpty)
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        XCTAssertNotNil(json)
    }
}
