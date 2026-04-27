import ArgumentParser
import Domain

struct SubscriptionPriceScheduleGet: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "get",
        abstract: "Get the per-territory price schedule for a subscription"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Subscription ID")
    var subscriptionId: String

    func run() async throws {
        let repo = try ClientProvider.makeSubscriptionPriceRepository()
        print(try await execute(repo: repo))
    }

    func execute(
        repo: any SubscriptionPriceRepository,
        affordanceMode: AffordanceMode = .cli
    ) async throws -> String {
        let schedule = try await repo.getPriceSchedule(subscriptionId: subscriptionId)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(schedule.map { [$0] } ?? [], affordanceMode: affordanceMode)
    }
}
