import ArgumentParser
import Domain

/// `asc iris iap-submissions create --iap-id <id>` — submits an IAP via the iris
/// private API. The default `--with-next-version` (i.e. `submitWithNextAppStoreVersion: true`)
/// is what makes this path different from `asc iap submit` (public SDK): it's the only
/// way to attach a first-time IAP to the next App Store version.
struct IrisIAPSubmissionsCreate: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "create",
        abstract: "Submit an IAP for review via iris (attaches to next app version by default)"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "IAP ID to submit for review")
    var iapId: String

    @Flag(
        name: .long,
        inversion: .prefixedNo,
        help: "Bind the submission to the next App Store version (Apple-required for first-time IAP submissions)"
    )
    var withNextVersion: Bool = true

    func run() async throws {
        let cookieProvider = ClientProvider.makeIrisCookieProvider()
        let repo = ClientProvider.makeIrisInAppPurchaseSubmissionRepository()
        print(try await execute(cookieProvider: cookieProvider, repo: repo))
    }

    func execute(
        cookieProvider: any IrisCookieProvider,
        repo: any IrisInAppPurchaseSubmissionRepository,
        affordanceMode: AffordanceMode = .cli
    ) async throws -> String {
        let session = try cookieProvider.resolveSession()
        let submission = try await repo.submitInAppPurchase(
            session: session,
            iapId: iapId,
            submitWithNextAppStoreVersion: withNextVersion
        )
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems([submission], affordanceMode: affordanceMode)
    }
}
