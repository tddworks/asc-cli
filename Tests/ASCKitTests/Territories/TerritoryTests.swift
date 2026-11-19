import Foundation
import Testing
@testable import ASCKit

@Suite
struct TerritoryTests {

    @Test func `territory carries id and currency`() {
        let territory = MockRepositoryFactory.makeTerritory(id: "USA", currency: "USD")
        #expect(territory.id == "USA")
        #expect(territory.currency == "USD")
    }

    @Test func `territory with nil currency omits it from json`() throws {
        let territory = Territory(id: "USA", currency: nil)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(territory)
        let json = String(data: data, encoding: .utf8)!
        #expect(json.contains("\"id\""))
        #expect(!json.contains("\"currency\""))
    }

    @Test func `affordances include list territories`() {
        let territory = MockRepositoryFactory.makeTerritory(id: "USA")
        #expect(territory.affordances["listTerritories"] == "asc territories list")
    }
}
