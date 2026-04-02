import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite("PluginsMarket — browse and search marketplace")
struct PluginsMarketTests {

    @Test func `market list shows available plugins with install affordance`() async throws {
        let mockRepo = MockPluginRepository()
        given(mockRepo).listAvailable().willReturn([
            MarketPlugin(
                id: "asc-pro",
                name: "ASC Pro",
                version: "1.0",
                description: "Simulator streaming, interaction & tunnel sharing",
                author: "tddworks",
                repositoryURL: "https://github.com/tddworks/asc-pro",
                downloadURL: "https://github.com/tddworks/asc-pro/releases/latest/download/ASCPro.plugin.zip",
                categories: ["simulators", "streaming"],
                isInstalled: false
            ),
        ])

        let cmd = try MarketList.parse(["--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "install" : "asc plugins install --name asc-pro",
                "listMarket" : "asc plugins market list",
                "viewRepository" : "https:\\/\\/github.com\\/tddworks\\/asc-pro"
              },
              "author" : "tddworks",
              "categories" : [
                "simulators",
                "streaming"
              ],
              "description" : "Simulator streaming, interaction & tunnel sharing",
              "downloadURL" : "https:\\/\\/github.com\\/tddworks\\/asc-pro\\/releases\\/latest\\/download\\/ASCPro.plugin.zip",
              "id" : "asc-pro",
              "isInstalled" : false,
              "name" : "ASC Pro",
              "repositoryURL" : "https:\\/\\/github.com\\/tddworks\\/asc-pro",
              "version" : "1.0"
            }
          ]
        }
        """)
    }

    @Test func `market search filters by query`() async throws {
        let mockRepo = MockPluginRepository()
        given(mockRepo).searchAvailable(query: .value("sim")).willReturn([
            MarketPlugin(
                id: "asc-pro",
                name: "ASC Pro",
                version: "1.0",
                description: "Simulator streaming",
                downloadURL: "https://example.com/asc-pro.zip"
            ),
        ])

        let cmd = try MarketSearch.parse(["--query", "sim", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output.contains("\"name\" : \"ASC Pro\""))
        #expect(output.contains("\"install\" : \"asc plugins install --name asc-pro\""))
    }

    @Test func `market list shows uninstall affordance for installed plugins`() async throws {
        let mockRepo = MockPluginRepository()
        given(mockRepo).listAvailable().willReturn([
            MarketPlugin(
                id: "asc-pro",
                name: "ASC Pro",
                version: "1.0",
                description: "Pro features",
                downloadURL: "https://example.com/asc-pro.zip",
                isInstalled: true
            ),
        ])

        let cmd = try MarketList.parse(["--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output.contains("\"uninstall\" : \"asc plugins uninstall --name asc-pro\""))
        #expect(!output.contains("\"install\" :"))
    }
}
