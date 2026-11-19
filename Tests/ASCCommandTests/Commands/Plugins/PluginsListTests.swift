import Mockable
import Testing
@testable import ASCCommand
@testable import ASCKit

@Suite("PluginsList — list installed dylib plugins")
struct PluginsListTests {

    @Test func `list shows installed plugins with affordances`() async throws {
        let mockRepo = MockPlugins()
        given(mockRepo).listInstalled().willReturn([
            Plugin(id: "asc-pro", name: "ASC Pro", version: "1.0",
                   description: "Simulator streaming", author: "tddworks",
                   isInstalled: true, slug: "ASCPro", uiScripts: ["ui/sim-stream.js"]),
        ])

        let cmd = try PluginsList.parse(["--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output.contains("\"name\" : \"ASC Pro\""))
        #expect(output.contains("\"isInstalled\" : true"))
        #expect(output.contains("\"uninstall\" : \"asc plugins uninstall --name ASCPro\""))
    }

    @Test func `list shows empty data when no plugins installed`() async throws {
        let mockRepo = MockPlugins()
        given(mockRepo).listInstalled().willReturn([])

        let cmd = try PluginsList.parse(["--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [

          ]
        }
        """)
    }
}
