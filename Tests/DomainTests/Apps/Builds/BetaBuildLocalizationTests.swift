import Foundation
import Testing
@testable import Domain

@Suite
struct BetaBuildLocalizationTests {

    @Test func `beta build localization carries build id`() {
        let loc = MockRepositoryFactory.makeBetaBuildLocalization(id: "bbl-1", buildId: "build-42")
        #expect(loc.buildId == "build-42")
    }

    @Test func `beta build localization affordances include updateNotes`() {
        let loc = MockRepositoryFactory.makeBetaBuildLocalization(id: "bbl-1", buildId: "build-1", locale: "en-US")
        #expect(loc.affordances["updateNotes"] == "asc builds update-beta-notes --build-id build-1 --locale en-US --notes <text>")
    }

    @Test func `whats new is omitted from json when nil`() throws {
        let loc = BetaBuildLocalization(id: "bbl-1", buildId: "build-1", locale: "en-US", whatsNew: nil)
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let data = try encoder.encode(loc)
        let json = String(decoding: data, as: UTF8.self)
        #expect(!json.contains("whatsNew"))
    }

    @Test func `whats new is present in json when set`() throws {
        let loc = MockRepositoryFactory.makeBetaBuildLocalization(whatsNew: "New feature added")
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let data = try encoder.encode(loc)
        let json = String(decoding: data, as: UTF8.self)
        #expect(json.contains("whatsNew"))
        #expect(json.contains("New feature added"))
    }
}
