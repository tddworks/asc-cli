import ArgumentParser
import Domain

struct AnalyticsReportsDelete: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "delete",
        abstract: "Delete an analytics report request"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Request ID")
    var requestId: String

    func run() async throws {
        let repo = try ClientProvider.makeAnalyticsReportRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any AnalyticsReportRepository) async throws -> String {
        try await repo.deleteRequest(id: requestId)
        return "Deleted analytics report request \(requestId)"
    }
}
