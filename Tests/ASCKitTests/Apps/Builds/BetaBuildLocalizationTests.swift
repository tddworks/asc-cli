import Foundation
import Testing
@testable import ASCKit

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

    @Test func `decode round-trip preserves all fields`() throws {
        let original = BetaBuildLocalization(id: "bbl-1", buildId: "build-42", locale: "en-US", whatsNew: "Bug fixes")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(BetaBuildLocalization.self, from: data)
        #expect(decoded.id == "bbl-1")
        #expect(decoded.buildId == "build-42")
        #expect(decoded.locale == "en-US")
        #expect(decoded.whatsNew == "Bug fixes")
    }

    @Test func `decode round-trip omits whats new when nil`() throws {
        let original = BetaBuildLocalization(id: "bbl-2", buildId: "build-1", locale: "fr-FR", whatsNew: nil)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(BetaBuildLocalization.self, from: data)
        #expect(decoded.whatsNew == nil)
    }
}
