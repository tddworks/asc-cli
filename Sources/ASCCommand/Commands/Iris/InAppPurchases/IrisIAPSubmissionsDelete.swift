import ArgumentParser
import Domain

/// `asc iris iap-submissions delete --submission-id <id>` — removes an iris-queued
/// IAP submission. Iris-queued submissions can only round-trip through the iris
/// DELETE endpoint (the public-SDK delete won't accept them); the submission
/// resource is keyed by parent IAP id, so the IAP id is also the submission id.
struct IrisIAPSubmissionsDelete: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "delete",
        abstract: "Remove an iris-queued IAP submission (dequeue from next app version)"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Submission ID (same value as the parent IAP id for iris-queued submissions)")
    var submissionId: String

    func run() async throws {
        let cookieProvider = ClientProvider.makeIrisCookieProvider()
        let repo = ClientProvider.makeIrisInAppPurchaseSubmissionRepository()
        try await execute(cookieProvider: cookieProvider, repo: repo)
    }

    func execute(
        cookieProvider: any IrisCookieProvider,
        repo: any IrisInAppPurchaseSubmissionRepository
    ) async throws {
        let session = try cookieProvider.resolveSession()
        try await repo.deleteSubmission(session: session, submissionId: submissionId)
    }
}
