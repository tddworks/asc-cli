import ArgumentParser
import ASCKit

struct VersionsSubmit: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "submit",
        abstract: "Submit an App Store version for review",
        discussion: """
        --with-products also sends every in-app purchase and subscription that is \
        READY_TO_SUBMIT (with its subscription group) in the same review submission — \
        the way first-time products must go to review. --dry-run shows those items \
        and submits nothing.
        """
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "App Store Version ID")
    var versionId: String

    @Flag(name: .long, help: "Also submit every ready in-app purchase and subscription version with this app version")
    var withProducts: Bool = false

    @Flag(name: .long, help: "List what would be submitted without submitting (implies --with-products)")
    var dryRun: Bool = false

    func run() async throws {
        if withProducts || dryRun {
            let planner = SubmissionPlanner(
                iapRepo: try ClientProvider.makeInAppPurchaseRepository(),
                groupRepo: try ClientProvider.makeSubscriptionGroupRepository(),
                subscriptionRepo: try ClientProvider.makeSubscriptionRepository(),
                productVersionRepo: try ClientProvider.makeProductVersionRepository()
            )
            print(try await executeWithProducts(
                submissionRepo: try ClientProvider.makeReviewSubmissions(),
                versionRepo: try ClientProvider.makeVersionRepository(),
                planner: planner
            ))
        } else {
            print(try await execute(repo: try ClientProvider.makeReviewSubmissions()))
        }
    }

    func execute(repo: any ReviewSubmissions) async throws -> String {
        let submission = try await repo.submitVersion(versionId: versionId)

        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            [submission],
            headers: ["ID", "Platform", "State"],
            rowMapper: { [$0.id, $0.platform.displayName, $0.state.displayName] }
        )
    }

    func executeWithProducts(
        submissionRepo: any ReviewSubmissions,
        versionRepo: any VersionRepository,
        planner: SubmissionPlanner,
        affordanceMode: AffordanceMode = .cli
    ) async throws -> String {
        let version = try await versionRepo.getVersion(id: versionId)
        let plan = try await planner.plan(for: version)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        if dryRun {
            return try formatter.formatAgentItems(plan.items, affordanceMode: affordanceMode)
        }
        let submission = try await plan.submit(repo: submissionRepo)
        return try formatter.formatAgentItems([submission], affordanceMode: affordanceMode)
    }
}
