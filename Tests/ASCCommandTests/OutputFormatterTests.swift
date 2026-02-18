import Foundation
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct OutputFormatterTests {

    @Test
    func `formats json output`() throws {
        let formatter = OutputFormatter(format: .json, pretty: false)
        let app = App(id: "1", name: "Test", bundleId: "com.test")
        let output = try formatter.format(app)
        #expect(output.contains("\"id\":\"1\""))
        #expect(output.contains("\"name\":\"Test\""))
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
        let formatter = OutputFormatter(format: .json, pretty: false)
        let apps = [App(id: "1", name: "Test App", bundleId: "com.test")]
        let output = try formatter.formatAgentItems(
            apps,
            headers: ["ID", "Name"],
            rowMapper: { [$0.id, $0.name] }
        )
        #expect(output.contains("\"data\""))
        #expect(output.contains("\"id\":\"1\""))
    }

    @Test
    func `formatAgentItems merges affordances into each json item`() throws {
        let formatter = OutputFormatter(format: .json, pretty: false)
        let apps = [App(id: "app-1", name: "Test", bundleId: "com.test")]
        let output = try formatter.formatAgentItems(
            apps,
            headers: ["ID", "Name"],
            rowMapper: { [$0.id, $0.name] }
        )
        #expect(output.contains("\"affordances\""))
        #expect(output.contains("asc versions list --app-id app-1"))
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
}
