import ArgumentParser
import Domain

struct IAPUnsubmit: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "unsubmit",
        abstract: "Withdraw an in-app purchase from review by deleting its submission"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Submission ID")
    var submissionId: String

    func run() async throws {
        let repo = try ClientProvider.makeInAppPurchaseSubmissionRepository()
        try await execute(repo: repo)
    }

    func execute(repo: any InAppPurchaseSubmissionRepository) async throws {
        try await repo.deleteSubmission(submissionId: submissionId)
    }
}
