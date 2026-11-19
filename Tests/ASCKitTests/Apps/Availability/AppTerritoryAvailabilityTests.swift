import Foundation
import Testing
@testable import ASCKit

@Suite
struct AppTerritoryAvailabilityTests {

    @Test func `territory availability carries territory id and available status`() {
        let ta = MockRepositoryFactory.makeAppTerritoryAvailability(
            id: "ta-1",
            territoryId: "USA",
            isAvailable: true
        )
        #expect(ta.territoryId == "USA")
        #expect(ta.isAvailable == true)
    }

    @Test func `unavailable territory shows blocking reasons`() {
        let ta = MockRepositoryFactory.makeAppTerritoryAvailability(
            isAvailable: false,
            contentStatuses: [.cannotSellRestrictedRating, .missingRating]
        )
        #expect(ta.isAvailable == false)
        #expect(ta.contentStatuses == [.cannotSellRestrictedRating, .missingRating])
    }

    @Test func `pre-order territory carries release date and pre-order flag`() {
        let ta = MockRepositoryFactory.makeAppTerritoryAvailability(
            isAvailable: true,
            releaseDate: "2026-04-01",
            isPreOrderEnabled: true
        )
        #expect(ta.releaseDate == "2026-04-01")
        #expect(ta.isPreOrderEnabled == true)
    }

    @Test func `nil optional fields omitted from json`() throws {
        let ta = AppTerritoryAvailability(
            id: "ta-1",
            territoryId: "USA",
            isAvailable: true,
            releaseDate: nil,
            isPreOrderEnabled: false,
            contentStatuses: [.available]
        )
        let encoder = Foundation.JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(ta)
        let json = String(data: data, encoding: .utf8)!
        #expect(!json.contains("\"releaseDate\""))
        #expect(json.contains("\"territoryId\""))
    }
}
