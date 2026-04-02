import Foundation
import Testing
@testable import Domain
@testable import Infrastructure

@Suite("GitHubPluginSource — fetches registry from GitHub")
struct GitHubPluginSourceTests {

    @Test func `source name includes owner and repo`() {
        let source = GitHubPluginSource(owner: "tddworks", repo: "asc-plugins")
        #expect(source.name == "GitHub: tddworks/asc-plugins")
    }

    @Test func `parses registry JSON into market plugins`() async throws {
        let json = """
        {
          "plugins": [
            {
              "id": "asc-pro",
              "name": "ASC Pro",
              "version": "1.0",
              "description": "Simulator streaming",
              "author": "tddworks",
              "repositoryURL": "https://github.com/tddworks/asc-pro",
              "downloadURL": "https://github.com/tddworks/asc-pro/releases/download/v1.0/ASCPro.plugin.zip",
              "categories": ["simulators"]
            }
          ]
        }
        """.data(using: .utf8)!

        let source = GitHubPluginSource(owner: "tddworks", repo: "asc-plugins", fetcher: { _ in json })
        let plugins = try await source.fetchPlugins()

        #expect(plugins.count == 1)
        #expect(plugins[0].id == "asc-pro")
        #expect(plugins[0].name == "ASC Pro")
        #expect(plugins[0].version == "1.0")
        #expect(plugins[0].author == "tddworks")
        #expect(plugins[0].categories == ["simulators"])
        #expect(plugins[0].isInstalled == false)
    }

    @Test func `returns empty array when registry has no plugins key`() async throws {
        let json = "{}".data(using: .utf8)!
        let source = GitHubPluginSource(owner: "x", repo: "y", fetcher: { _ in json })
        let plugins = try await source.fetchPlugins()
        #expect(plugins.isEmpty)
    }

    @Test func `multiple plugins parsed correctly`() async throws {
        let json = """
        {
          "plugins": [
            {"id": "a", "name": "A", "version": "1", "description": "Desc A", "downloadURL": "https://example.com/a.zip"},
            {"id": "b", "name": "B", "version": "2", "description": "Desc B", "downloadURL": "https://example.com/b.zip", "author": "bob"}
          ]
        }
        """.data(using: .utf8)!

        let source = GitHubPluginSource(owner: "x", repo: "y", fetcher: { _ in json })
        let plugins = try await source.fetchPlugins()

        #expect(plugins.count == 2)
        #expect(plugins[0].id == "a")
        #expect(plugins[1].author == "bob")
    }
}
