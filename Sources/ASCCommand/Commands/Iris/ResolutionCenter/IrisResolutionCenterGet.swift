import ArgumentParser
import Domain

/// `asc iris resolution-center get --submission-id <id>` — reads App Review's
/// Resolution Center messages and rejection reasons for a review submission.
/// This data has no official App Store Connect API surface; it is only
/// reachable through the iris private API (browser-cookie auth).
struct IrisResolutionCenterGet: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "get",
        abstract: "Read Resolution Center messages and rejection reasons for a review submission"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Review submission ID (from `asc review-submissions list`)")
    var submissionId: String

    @Flag(name: .long, help: "Convert HTML message bodies to plain text")
    var plainText: Bool = false

    func run() async throws {
        let cookieProvider = ClientProvider.makeIrisCookieProvider()
        let repo = ClientProvider.makeIrisResolutionCenterRepository()
        print(try await execute(cookieProvider: cookieProvider, repo: repo))
    }

    func execute(
        cookieProvider: any IrisCookieProvider,
        repo: any IrisResolutionCenterRepository,
        affordanceMode: AffordanceMode = .cli
    ) async throws -> String {
        let session = try cookieProvider.resolveSession()
        var detail = try await repo.getResolution(session: session, submissionId: submissionId)
        if plainText {
            detail = detail.plainText()
        }
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems([detail], affordanceMode: affordanceMode)
    }
}
