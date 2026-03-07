import ArgumentParser
import Domain
import Foundation

struct XcodeCloudCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "xcode-cloud",
        abstract: "Read Xcode Cloud data, manage workflows, and start builds",
        subcommands: [
            XcodeCloudProductsCommand.self,
            XcodeCloudWorkflowsCommand.self,
            XcodeCloudBuildsCommand.self,
        ]
    )
}

// MARK: - Products

struct XcodeCloudProductsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "products",
        abstract: "Manage Xcode Cloud products",
        subcommands: [XcodeCloudProductsList.self]
    )
}

struct XcodeCloudProductsList: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List Xcode Cloud products"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Filter by app ID")
    var appId: String?

    func run() async throws {
        let repo = try ClientProvider.makeXcodeCloudProductRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any XcodeCloudProductRepository) async throws -> String {
        let products = try await repo.listProducts(appId: appId)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            products,
            headers: ["ID", "Name", "Type"],
            rowMapper: { [$0.id, $0.name, $0.productType.rawValue] }
        )
    }
}

// MARK: - Workflows

struct XcodeCloudWorkflowsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "workflows",
        abstract: "Manage Xcode Cloud workflows",
        subcommands: [XcodeCloudWorkflowsList.self]
    )
}

struct XcodeCloudWorkflowsList: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List workflows for an Xcode Cloud product"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Xcode Cloud product ID")
    var productId: String

    func run() async throws {
        let repo = try ClientProvider.makeXcodeCloudWorkflowRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any XcodeCloudWorkflowRepository) async throws -> String {
        let workflows = try await repo.listWorkflows(productId: productId)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            workflows,
            headers: ["ID", "Name", "Enabled", "Locked"],
            rowMapper: { [$0.id, $0.name, $0.isEnabled ? "Yes" : "No", $0.isLockedForEditing ? "Yes" : "No"] }
        )
    }
}

// MARK: - Builds

struct XcodeCloudBuildsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "builds",
        abstract: "Manage Xcode Cloud build runs",
        subcommands: [
            XcodeCloudBuildsList.self,
            XcodeCloudBuildsGet.self,
            XcodeCloudBuildsStart.self,
        ]
    )
}

struct XcodeCloudBuildsList: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List build runs for a workflow"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Workflow ID")
    var workflowId: String

    func run() async throws {
        let repo = try ClientProvider.makeXcodeCloudBuildRunRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any XcodeCloudBuildRunRepository) async throws -> String {
        let runs = try await repo.listBuildRuns(workflowId: workflowId)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            runs,
            headers: ["ID", "Number", "Progress", "Status"],
            rowMapper: { [$0.id, $0.number.map(String.init) ?? "-", $0.executionProgress.rawValue, $0.completionStatus?.rawValue ?? "-"] }
        )
    }
}

struct XcodeCloudBuildsGet: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "get",
        abstract: "Get a specific build run"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Build run ID")
    var buildRunId: String

    func run() async throws {
        let repo = try ClientProvider.makeXcodeCloudBuildRunRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any XcodeCloudBuildRunRepository) async throws -> String {
        let run = try await repo.getBuildRun(id: buildRunId)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            [run],
            headers: ["ID", "Number", "Progress", "Status"],
            rowMapper: { [$0.id, $0.number.map(String.init) ?? "-", $0.executionProgress.rawValue, $0.completionStatus?.rawValue ?? "-"] }
        )
    }
}

struct XcodeCloudBuildsStart: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "start",
        abstract: "Start a new build run for a workflow"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Workflow ID")
    var workflowId: String

    @Flag(name: .long, help: "Perform a clean build")
    var clean: Bool = false

    func run() async throws {
        let repo = try ClientProvider.makeXcodeCloudBuildRunRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any XcodeCloudBuildRunRepository) async throws -> String {
        let run = try await repo.startBuildRun(workflowId: workflowId, clean: clean)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            [run],
            headers: ["ID", "Number", "Progress", "Status"],
            rowMapper: { [$0.id, $0.number.map(String.init) ?? "-", $0.executionProgress.rawValue, $0.completionStatus?.rawValue ?? "-"] }
        )
    }
}
