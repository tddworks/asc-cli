import ArgumentParser
import Domain
import Foundation

struct ReviewSubmissionsList: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List App Store review submissions for an app"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "App ID to filter submissions")
    var appId: String

    @Option(name: .long, help: "Comma-separated states (e.g. WAITING_FOR_REVIEW,IN_REVIEW,READY_FOR_REVIEW)")
    var state: String?

    @Option(name: .long, help: "Maximum number of submissions to return")
    var limit: Int?

    func run() async throws {
        let repo = try ClientProvider.makeSubmissionRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any SubmissionRepository) async throws -> String {
        let parsedStates = state.map { csv in
            csv.split(separator: ",").compactMap {
                ReviewSubmissionState(rawValue: String($0).trimmingCharacters(in: .whitespaces).uppercased())
            }
        }
        let items = try await repo.listSubmissions(appId: appId, states: parsedStates, limit: limit)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            items,
            headers: ["ID", "App ID", "Platform", "State"],
            rowMapper: { [$0.id, $0.appId, $0.platform.rawValue, $0.state.rawValue] }
        )
    }
}
