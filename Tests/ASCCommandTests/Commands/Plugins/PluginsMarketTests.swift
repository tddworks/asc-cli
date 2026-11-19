import Mockable
import Testing
@testable import ASCCommand
@testable import ASCKit

@Suite("PluginsMarket — browse and search marketplace")
struct PluginsMarketTests {

    @Test func `market list shows available plugins with install affordance`() async throws {
        let mockRepo = MockPlugins()
        given(mockRepo).listAvailable().willReturn([
            Plugin(
                id: "asc-pro", name: "ASC Pro", version: "1.0",
                description: "Simulator streaming, interaction & tunnel sharing",
                author: "tddworks",
                repositoryURL: "https://github.com/tddworks/asc-registry",
                categories: ["simulators", "streaming"],
                downloadURL: "https://github.com/tddworks/asc-registry/releases/latest/download/ASCPro.plugin.zip"
            ),
        ])

        let cmd = try MarketList.parse(["--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output.contains("\"name\" : \"ASC Pro\""))
        #expect(output.contains("\"install\" : \"asc plugins install --name asc-pro\""))
        #expect(output.contains("\"isInstalled\" : false"))
    }

    @Test func `market search filters by query`() async throws {
        let mockRepo = MockPlugins()
        given(mockRepo).searchAvailable(query: .value("sim")).willReturn([
            Plugin(id: "asc-pro", name: "ASC Pro", version: "1.0",
                   description: "Simulator streaming",
                   downloadURL: "https://example.com/asc-pro.zip"),
        ])

        let cmd = try MarketSearch.parse(["--query", "sim", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output.contains("\"name\" : \"ASC Pro\""))
        #expect(output.contains("\"install\" : \"asc plugins install --name asc-pro\""))
    }

    @Test func `market list shows uninstall affordance for installed plugins`() async throws {
        let mockRepo = MockPlugins()
        given(mockRepo).listAvailable().willReturn([
            Plugin(id: "asc-pro", name: "ASC Pro", version: "1.0",
                   description: "Pro features",
                   downloadURL: "https://example.com/asc-pro.zip",
                   isInstalled: true, slug: "ASCPro"),
        ])

        let cmd = try MarketList.parse(["--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output.contains("\"uninstall\" : \"asc plugins uninstall --name ASCPro\""))
        #expect(!output.contains("\"install\" :"))
    }
}
