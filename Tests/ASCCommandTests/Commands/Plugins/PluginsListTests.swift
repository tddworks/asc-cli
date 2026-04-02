import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite("PluginsList — list installed dylib plugins")
struct PluginsListTests {

    @Test func `list shows installed plugins with affordances`() async throws {
        let mockRepo = MockPluginRepository()
        given(mockRepo).listInstalled().willReturn([
            Plugin(id: "asc-pro", name: "ASC Pro", version: "1.0", slug: "ASCPro", uiScripts: ["ui/sim-stream.js"]),
        ])

        let cmd = try PluginsList.parse(["--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "browseMarket" : "asc plugins market list",
                "uninstall" : "asc plugins uninstall --name ASCPro"
              },
              "id" : "asc-pro",
              "name" : "ASC Pro",
              "slug" : "ASCPro",
              "uiScripts" : [
                "ui\\/sim-stream.js"
              ],
              "version" : "1.0"
            }
          ]
        }
        """)
    }

    @Test func `list shows empty data when no plugins installed`() async throws {
        let mockRepo = MockPluginRepository()
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
