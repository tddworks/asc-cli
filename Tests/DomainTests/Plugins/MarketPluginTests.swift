import Foundation
import Testing
@testable import Domain

@Suite("MarketPlugin — plugin marketplace listing model")
struct MarketPluginTests {

    @Test func `market plugin carries all fields`() {
        let mp = MockRepositoryFactory.makeMarketPlugin()
        #expect(mp.id == "asc-pro")
        #expect(mp.name == "ASC Pro")
        #expect(mp.version == "1.0")
        #expect(mp.description == "Simulator streaming, interaction & tunnel sharing")
        #expect(mp.author == "tddworks")
        #expect(mp.downloadURL == "https://github.com/tddworks/asc-pro/releases/latest/download/ASCPro.plugin.zip")
        #expect(mp.categories == ["simulators", "streaming"])
        #expect(mp.isInstalled == false)
    }

    @Test func `market plugin encodes to JSON omitting nil fields`() throws {
        let mp = MockRepositoryFactory.makeMarketPlugin(author: nil, repositoryURL: nil)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(mp)
        let json = String(data: data, encoding: .utf8)!
        #expect(!json.contains("author"))
        #expect(!json.contains("repositoryURL"))
    }

    @Test func `market plugin affordances include install when not installed`() {
        let mp = MockRepositoryFactory.makeMarketPlugin(isInstalled: false)
        #expect(mp.affordances["install"] == "asc plugins install --name asc-pro")
        #expect(mp.affordances["uninstall"] == nil)
    }

    @Test func `market plugin affordances include uninstall when installed`() {
        let mp = MockRepositoryFactory.makeMarketPlugin(isInstalled: true)
        #expect(mp.affordances["uninstall"] == "asc plugins uninstall --name asc-pro")
        #expect(mp.affordances["install"] == nil)
    }

    @Test func `market plugin affordances include repository link when available`() {
        let mp = MockRepositoryFactory.makeMarketPlugin(repositoryURL: "https://github.com/tddworks/asc-pro")
        #expect(mp.affordances["viewRepository"] != nil)
    }

    @Test func `market plugin affordances omit repository link when nil`() {
        let mp = MockRepositoryFactory.makeMarketPlugin(repositoryURL: nil)
        #expect(mp.affordances["viewRepository"] == nil)
    }

    @Test func `market plugin conforms to Equatable`() {
        let a = MockRepositoryFactory.makeMarketPlugin()
        let b = MockRepositoryFactory.makeMarketPlugin()
        #expect(a == b)
    }
}
