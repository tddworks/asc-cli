import ArgumentParser
import ASCKit

struct ReviewSubmissionItemsAdd: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "add",
        abstract: "Add an app version, or an IAP, subscription or subscription group version, to a draft review submission"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Review submission ID")
    var submissionId: String

    @Option(name: .long, help: "App Store version ID")
    var versionId: String?

    @Option(name: .long, help: "In-app purchase version ID (from `asc iap versions list`)")
    var iapVersionId: String?

    @Option(name: .long, help: "Subscription version ID (from `asc subscriptions versions list`)")
    var subscriptionVersionId: String?

    @Option(name: .long, help: "Subscription group version ID (from `asc subscription-groups versions list`)")
    var subscriptionGroupVersionId: String?

    func run() async throws {
        let repo = try ClientProvider.makeReviewSubmissions()
        print(try await execute(repo: repo))
    }

    func execute(repo: any ReviewSubmissions, affordanceMode: AffordanceMode = .cli) async throws -> String {
        guard let target = ReviewItemTarget(
            versionId: versionId,
            iapVersionId: iapVersionId,
            subscriptionVersionId: subscriptionVersionId,
            subscriptionGroupVersionId: subscriptionGroupVersionId
        ) else {
            throw ValidationError(
                "Pass exactly one of --version-id, --iap-version-id, --subscription-version-id, --subscription-group-version-id"
            )
        }
        let item = try await repo.addItem(submissionId: submissionId, target: target)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems([item], affordanceMode: affordanceMode)
    }
}
