import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite("PluginsUpdate — apply an update to one plugin")
struct PluginsUpdateTests {

    @Test func `updated plugin is returned with the new version and installed affordances`() async throws {
        let mockRepo = MockPluginRepository()
        given(mockRepo).update(name: .value("Hello")).willReturn(
            Plugin(
                id: "Hello.plugin",
                name: "Hello",
                version: "1.2.0",
                author: "me",
                isInstalled: true,
                slug: "Hello.plugin"
            )
        )

        let cmd = try PluginsUpdate.parse(["--name", "Hello", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "browseMarket" : "asc plugins market list",
                "checkUpdate" : "asc plugins updates",
                "uninstall" : "asc plugins uninstall --name Hello.plugin"
              },
              "categories" : [

              ],
              "description" : "",
              "id" : "Hello.plugin",
              "isInstalled" : true,
              "name" : "Hello",
              "slug" : "Hello.plugin",
              "uiScripts" : [

              ],
              "version" : "1.2.0",
              "author" : "me"
            }
          ]
        }
        """)
    }
}
