import ArgumentParser
import ASCKit

struct SubscriptionOfferCodesUpdate: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "update",
        abstract: "Update an offer code (activate/deactivate)"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Offer code ID")
    var offerCodeId: String

    @Option(name: .long, help: "Active status (true/false)")
    var active: String

    func run() async throws {
        let repo = try ClientProvider.makeSubscriptionOfferCodeRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any SubscriptionOfferCodeRepository) async throws -> String {
        guard let isActive = Bool(active) else {
            throw ValidationError("Invalid value '\(active)' for --active. Use: true, false")
        }
        let item = try await repo.updateOfferCode(offerCodeId: offerCodeId, isActive: isActive)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            [item],
            headers: ["ID", "Name", "Duration", "Mode", "Periods", "Active"],
            rowMapper: { [$0.id, $0.name, $0.duration.rawValue, $0.offerMode.rawValue, String($0.numberOfPeriods), String($0.isActive)] }
        )
    }
}
