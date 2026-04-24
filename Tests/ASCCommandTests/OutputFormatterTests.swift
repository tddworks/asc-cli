import Foundation
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct OutputFormatterTests {

    @Test
    func `formats json output`() throws {
        let formatter = OutputFormatter(format: .json, pretty: true)
        let app = App(id: "1", name: "Test", bundleId: "com.test")
        let output = try formatter.format(app)
        #expect(output == """
        {
          "bundleId" : "com.test",
          "id" : "1",
          "name" : "Test"
        }
        """)
    }

    @Test
    func `formats pretty json output`() throws {
        let formatter = OutputFormatter(format: .json, pretty: true)
        let app = App(id: "1", name: "Test", bundleId: "com.test")
        let output = try formatter.format(app)
        #expect(output.contains("\n"))
        #expect(output.contains("  "))
    }

    @Test
    func `formats table output with headers`() throws {
        let formatter = OutputFormatter(format: .table)
        let apps = [
            App(id: "1", name: "App One", bundleId: "com.one"),
            App(id: "2", name: "App Two", bundleId: "com.two"),
        ]
        let output = try formatter.formatItems(
            apps,
            headers: ["ID", "Name", "Bundle ID"],
            rowMapper: { [$0.id, $0.name, $0.bundleId] }
        )
        #expect(output.contains("ID"))
        #expect(output.contains("Name"))
        #expect(output.contains("App One"))
        #expect(output.contains("App Two"))
        #expect(output.contains("---"))
    }

    @Test
    func `formats markdown table output`() throws {
        let formatter = OutputFormatter(format: .markdown)
        let apps = [
            App(id: "1", name: "App One", bundleId: "com.one"),
        ]
        let output = try formatter.formatItems(
            apps,
            headers: ["ID", "Name"],
            rowMapper: { [$0.id, $0.name] }
        )
        #expect(output.contains("| ID | Name |"))
        #expect(output.contains("| --- | --- |"))
        #expect(output.contains("| 1 | App One |"))
    }

    // MARK: - formatAgentItems (CAEOAS)

    @Test
    func `formatAgentItems wraps json output in data array`() throws {
        let formatter = OutputFormatter(format: .json, pretty: true)
        let apps = [App(id: "1", name: "Test App", bundleId: "com.test")]
        let output = try formatter.formatAgentItems(
            apps,
            headers: ["ID", "Name"],
            rowMapper: { [$0.id, $0.name] }
        )
        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "createVersion" : "asc versions create --app-id 1",
                "listAppInfos" : "asc app-infos list --app-id 1",
                "listReviews" : "asc reviews list --app-id 1",
                "listVersions" : "asc versions list --app-id 1"
              },
              "bundleId" : "com.test",
              "id" : "1",
              "name" : "Test App"
            }
          ]
        }
        """)
    }

    @Test
    func `formatAgentItems merges affordances into each json item`() throws {
        let formatter = OutputFormatter(format: .json, pretty: true)
        let apps = [App(id: "app-1", name: "Test", bundleId: "com.test")]
        let output = try formatter.formatAgentItems(
            apps,
            headers: ["ID", "Name"],
            rowMapper: { [$0.id, $0.name] }
        )
        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "createVersion" : "asc versions create --app-id app-1",
                "listAppInfos" : "asc app-infos list --app-id app-1",
                "listReviews" : "asc reviews list --app-id app-1",
                "listVersions" : "asc versions list --app-id app-1"
              },
              "bundleId" : "com.test",
              "id" : "app-1",
              "name" : "Test"
            }
          ]
        }
        """)
    }

    @Test
    func `formatAgentItems formats table output using rowMapper`() throws {
        let formatter = OutputFormatter(format: .table)
        let apps = [
            App(id: "1", name: "Alpha", bundleId: "com.alpha"),
            App(id: "2", name: "Beta", bundleId: "com.beta"),
        ]
        let output = try formatter.formatAgentItems(
            apps,
            headers: ["ID", "Name"],
            rowMapper: { [$0.id, $0.name] }
        )
        #expect(output.contains("ID"))
        #expect(output.contains("Alpha"))
        #expect(output.contains("Beta"))
    }

    @Test
    func `formatAgentItems formats markdown output using rowMapper`() throws {
        let formatter = OutputFormatter(format: .markdown)
        let apps = [App(id: "1", name: "My App", bundleId: "com.app")]
        let output = try formatter.formatAgentItems(
            apps,
            headers: ["ID", "Name"],
            rowMapper: { [$0.id, $0.name] }
        )
        #expect(output.contains("| ID | Name |"))
        #expect(output.contains("| 1 | My App |"))
    }

    // MARK: - REST mode (HATEOAS _links)

    @Test
    func `formatAgentItems in rest mode renders _links instead of affordances`() throws {
        let formatter = OutputFormatter(format: .json, pretty: true)
        let apps = [App(id: "1", name: "Test App", bundleId: "com.test")]
        let output = try formatter.formatAgentItems(
            apps,
            headers: ["ID", "Name"],
            rowMapper: { [$0.id, $0.name] },
            affordanceMode: .rest
        )
        #expect(output.contains("\"_links\""))
        #expect(output.contains("\"href\""))
        #expect(output.contains("\"method\""))
        #expect(!output.contains("\"affordances\""))
    }

    @Test
    func `formatAgentItems rest mode shows correct REST hrefs`() throws {
        let formatter = OutputFormatter(format: .json, pretty: true)
        let apps = [App(id: "42", name: "MyApp", bundleId: "com.test")]
        let output = try formatter.formatAgentItems(
            apps,
            headers: ["ID", "Name"],
            rowMapper: { [$0.id, $0.name] },
            affordanceMode: .rest
        )
        // JSON may escape slashes as \/ so check for both forms
        let normalized = output.replacingOccurrences(of: "\\/", with: "/")
        #expect(normalized.contains("/api/v1/apps/42/versions"))
        #expect(normalized.contains("/api/v1/apps/42/reviews"))
        #expect(normalized.contains("/api/v1/apps/42/app-infos"))
    }

    @Test
    func `formatAgentItems defaults to cli mode`() throws {
        let formatter = OutputFormatter(format: .json, pretty: true)
        let apps = [App(id: "1", name: "Test", bundleId: "com.test")]
        let output = try formatter.formatAgentItems(
            apps,
            headers: ["ID", "Name"],
            rowMapper: { [$0.id, $0.name] }
        )
        #expect(output.contains("\"affordances\""))
        #expect(!output.contains("\"_links\""))
    }

    // MARK: - Presentable overload (no headers/rowMapper)

    @Test
    func `presentable overload produces same json as explicit headers`() throws {
        let formatter = OutputFormatter(format: .json, pretty: true)
        let apps = [App(id: "1", name: "Test App", bundleId: "com.test")]

        let explicit = try formatter.formatAgentItems(
            apps,
            headers: ["ID", "Name", "Bundle ID", "SKU"],
            rowMapper: { [$0.id, $0.displayName, $0.bundleId, $0.sku ?? "-"] }
        )
        let presentable = try formatter.formatAgentItems(apps)

        #expect(explicit == presentable)
    }

    @Test
    func `presentable overload renders table using model tableHeaders and tableRow`() throws {
        let formatter = OutputFormatter(format: .table)
        let apps = [App(id: "1", name: "Alpha", bundleId: "com.alpha", sku: "S1")]
        let output = try formatter.formatAgentItems(apps)
        #expect(output.contains("ID"))
        #expect(output.contains("Name"))
        #expect(output.contains("Bundle ID"))
        #expect(output.contains("SKU"))
        #expect(output.contains("Alpha"))
        #expect(output.contains("S1"))
    }

    @Test
    func `presentable overload supports rest affordance mode`() throws {
        let formatter = OutputFormatter(format: .json, pretty: true)
        let apps = [App(id: "42", name: "MyApp", bundleId: "com.test")]
        let output = try formatter.formatAgentItems(apps, affordanceMode: .rest)
        #expect(output.contains("\"_links\""))
        #expect(!output.contains("\"affordances\""))
    }

    @Test
    func `presentable overload renders markdown using model metadata`() throws {
        let formatter = OutputFormatter(format: .markdown)
        let apps = [App(id: "1", name: "My App", bundleId: "com.app")]
        let output = try formatter.formatAgentItems(apps)
        #expect(output.contains("| ID | Name | Bundle ID | SKU |"))
        #expect(output.contains("| 1 | My App | com.app | - |"))
    }
}
