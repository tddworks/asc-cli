import Foundation
import Testing
@testable import Domain

@Suite("Plugin — installed dylib plugin model")
struct PluginTests {

    @Test func `plugin carries all fields`() {
        let plugin = MockRepositoryFactory.makePlugin()
        #expect(plugin.id == "asc-pro")
        #expect(plugin.name == "ASC Pro")
        #expect(plugin.version == "1.0")
        #expect(plugin.slug == "ASCPro")
        #expect(plugin.uiScripts == ["ui/sim-stream.js"])
    }

    @Test func `plugin encodes to JSON with correct field names`() throws {
        let plugin = MockRepositoryFactory.makePlugin()
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(plugin)
        let json = String(data: data, encoding: .utf8)!
        #expect(json == """
        {
          "id" : "asc-pro",
          "name" : "ASC Pro",
          "slug" : "ASCPro",
          "uiScripts" : [
            "ui\\/sim-stream.js"
          ],
          "version" : "1.0"
        }
        """)
    }

    @Test func `plugin affordances include uninstall and browse market`() {
        let plugin = MockRepositoryFactory.makePlugin()
        #expect(plugin.affordances["uninstall"] == "asc plugins uninstall --name ASCPro")
        #expect(plugin.affordances["browseMarket"] == "asc plugins market list")
    }

    @Test func `plugin without UI scripts omits uiScripts from affordances`() {
        let plugin = MockRepositoryFactory.makePlugin(uiScripts: [])
        #expect(plugin.affordances["uninstall"] == "asc plugins uninstall --name ASCPro")
    }

    @Test func `plugin conforms to Equatable`() {
        let a = MockRepositoryFactory.makePlugin()
        let b = MockRepositoryFactory.makePlugin()
        #expect(a == b)
    }
}
