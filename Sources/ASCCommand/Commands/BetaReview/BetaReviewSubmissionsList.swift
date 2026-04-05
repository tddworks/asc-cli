import ArgumentParser
import Domain

struct BetaReviewSubmissionsList: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List beta app review submissions for a build"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Build ID to filter submissions")
    var buildId: String

    func run() async throws {
        let repo = try ClientProvider.makeBetaAppReviewRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any BetaAppReviewRepository) async throws -> String {
        let submissions = try await repo.listSubmissions(buildId: buildId)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(submissions)
    }
}
