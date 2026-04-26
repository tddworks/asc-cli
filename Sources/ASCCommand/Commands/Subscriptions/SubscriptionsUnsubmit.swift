import ArgumentParser
import Domain

struct SubscriptionsUnsubmit: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "unsubmit",
        abstract: "Withdraw a subscription from review by deleting its submission"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Submission ID")
    var submissionId: String

    func run() async throws {
        let repo = try ClientProvider.makeSubscriptionSubmissionRepository()
        try await execute(repo: repo)
    }

    func execute(repo: any SubscriptionSubmissionRepository) async throws {
        try await repo.deleteSubmission(submissionId: submissionId)
    }
}
