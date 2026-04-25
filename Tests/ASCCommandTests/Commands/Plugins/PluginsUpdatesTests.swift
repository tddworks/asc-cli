import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite("PluginsUpdates — list outdated plugins")
struct PluginsUpdatesTests {

    @Test func `outdated plugins are listed with installed and latest versions plus update affordance`() async throws {
        let mockRepo = MockPluginRepository()
        given(mockRepo).listOutdated().willReturn([
            PluginUpdate(
                name: "Hello",
                installedVersion: "1.0.0",
                latestVersion: "1.2.0"
            ),
        ])

        let cmd = try PluginsUpdates.parse(["--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "list" : "asc plugins updates",
                "update" : "asc plugins update --name Hello"
              },
              "installedVersion" : "1.0.0",
              "latestVersion" : "1.2.0",
              "name" : "Hello"
            }
          ]
        }
        """)
    }

    @Test func `no outdated plugins returns empty data array`() async throws {
        let mockRepo = MockPluginRepository()
        given(mockRepo).listOutdated().willReturn([])
        let cmd = try PluginsUpdates.parse(["--pretty"])
        let output = try await cmd.execute(repo: mockRepo)
        #expect(output == """
        {
          "data" : [

          ]
        }
        """)
    }
}
