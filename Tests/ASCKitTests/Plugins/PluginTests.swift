import Foundation
import Testing
@testable import ASCKit

@Suite("Plugin — unified plugin model")
struct PluginTests {

    @Test func `installed plugin carries all fields`() {
        let plugin = MockRepositoryFactory.makePlugin()
        #expect(plugin.id == "asc-pro")
        #expect(plugin.name == "ASC Pro")
        #expect(plugin.version == "1.0")
        #expect(plugin.description == "Simulator streaming, interaction & tunnel sharing")
        #expect(plugin.author == "tddworks")
        #expect(plugin.repositoryURL == "https://github.com/tddworks/asc-registry")
        #expect(plugin.categories == ["simulators", "streaming"])
        #expect(plugin.isInstalled == true)
        #expect(plugin.slug == "ASCPro")
        #expect(plugin.uiScripts == ["ui/sim-stream.js"])
    }

    @Test func `marketplace plugin has downloadURL and no slug`() {
        let plugin = MockRepositoryFactory.makePlugin(
            downloadURL: "https://example.com/plugin.zip",
            isInstalled: false,
            slug: nil,
            uiScripts: []
        )
        #expect(plugin.isInstalled == false)
        #expect(plugin.downloadURL == "https://example.com/plugin.zip")
        #expect(plugin.slug == nil)
    }

    @Test func `encodes to JSON omitting nil optional fields`() throws {
        let plugin = MockRepositoryFactory.makePlugin(author: nil, repositoryURL: nil, downloadURL: nil, slug: nil)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(plugin)
        let json = String(data: data, encoding: .utf8)!
        #expect(!json.contains("author"))
        #expect(!json.contains("repositoryURL"))
        #expect(!json.contains("downloadURL"))
        #expect(!json.contains("slug"))
    }

    @Test func `installed plugin affordances include uninstall`() {
        let plugin = MockRepositoryFactory.makePlugin(isInstalled: true, slug: "ASCPro")
        #expect(plugin.affordances["uninstall"] == "asc plugins uninstall --name ASCPro")
        #expect(plugin.affordances["install"] == nil)
    }

    @Test func `marketplace plugin affordances include install`() {
        let plugin = MockRepositoryFactory.makePlugin(isInstalled: false, slug: nil)
        #expect(plugin.affordances["install"] == "asc plugins install --name asc-pro")
        #expect(plugin.affordances["uninstall"] == nil)
    }

    @Test func `affordances include repository link when available`() {
        let plugin = MockRepositoryFactory.makePlugin(repositoryURL: "https://github.com/tddworks/asc-registry")
        #expect(plugin.affordances["viewRepository"] == "https://github.com/tddworks/asc-registry")
    }

    @Test func `affordances omit repository link when nil`() {
        let plugin = MockRepositoryFactory.makePlugin(repositoryURL: nil)
        #expect(plugin.affordances["viewRepository"] == nil)
    }

    @Test func `plugin conforms to Equatable`() {
        let a = MockRepositoryFactory.makePlugin()
        let b = MockRepositoryFactory.makePlugin()
        #expect(a == b)
    }
}
