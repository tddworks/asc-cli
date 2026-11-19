import ArgumentParser
import ASCKit

struct BetaReviewDetailGet: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "get",
        abstract: "Get beta app review contact details for an app"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "App ID")
    var appId: String

    func run() async throws {
        let repo = try ClientProvider.makeBetaAppReviewRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any BetaAppReviewRepository) async throws -> String {
        let detail = try await repo.getDetail(appId: appId)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            [detail],
            headers: ["ID", "Contact", "Demo Required", "Notes"],
            rowMapper: {
                let contact = [$0.contactFirstName, $0.contactLastName].compactMap { $0 }.joined(separator: " ")
                return [$0.id, contact.isEmpty ? "-" : contact, $0.demoAccountRequired ? "Yes" : "No", $0.notes ?? "-"]
            }
        )
    }
}
