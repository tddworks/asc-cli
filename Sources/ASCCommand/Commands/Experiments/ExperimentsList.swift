import ArgumentParser
import ASCKit

struct ExperimentsList: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List product page optimization tests for an app"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "App ID")
    var appId: String

    @Option(name: .long, help: "Filter by state (e.g. PREPARE_FOR_SUBMISSION, APPROVED, COMPLETED)")
    var state: String?

    @Option(name: .long, help: "Max results")
    var limit: Int?

    func run() async throws {
        let repo = try ClientProvider.makeExperimentRepository()
        print(try await execute(repo: repo))
    }

    func execute(
        repo: any ExperimentRepository,
        affordanceMode: AffordanceMode = .cli
    ) async throws -> String {
        var stateFilter: AppStoreVersionExperimentState?
        if let state {
            guard let parsed = AppStoreVersionExperimentState(rawValue: state.uppercased()) else {
                let known = AppStoreVersionExperimentState.allCases.map(\.rawValue).joined(separator: ", ")
                throw ValidationError("Unknown state '\(state)'. Use one of: \(known)")
            }
            stateFilter = parsed
        }
        let response = try await repo.listExperiments(appId: appId, state: stateFilter, limit: limit)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(response.data, affordanceMode: affordanceMode)
    }
}
