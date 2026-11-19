import Foundation
import Mockable
import Testing
@testable import ASCKit

@Suite("PluginSource — composable registry sources")
struct PluginSourceTests {

    @Test func `source returns plugins with isInstalled false`() async throws {
        let source = MockPluginSource()
        given(source).fetchPlugins().willReturn([
            Plugin(
                id: "asc-pro", name: "ASC Pro", version: "1.0",
                description: "Pro features", downloadURL: "https://example.com/asc-pro.zip"
            ),
        ])

        let plugins = try await source.fetchPlugins()
        #expect(plugins.count == 1)
        #expect(plugins[0].id == "asc-pro")
        #expect(plugins[0].isInstalled == false)
    }

    @Test func `source has a human readable name`() {
        let source = MockPluginSource()
        given(source).name.willReturn("GitHub: tddworks/asc-registry")
        #expect(source.name == "GitHub: tddworks/asc-registry")
    }
}
