import ArgumentParser
import Domain

struct BetaAppLocalizationsCreate: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "create",
        abstract: "Create a beta app localization for an app"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "App ID to create the beta localization for")
    var appId: String

    @Option(name: .long, help: "Locale code (e.g. en-US, zh-Hans)")
    var locale: String

    @Option(name: .long, help: "Beta app description shown to TestFlight testers")
    var description: String?

    @Option(name: .long, help: "Tester feedback email")
    var feedbackEmail: String?

    @Option(name: .long, help: "Marketing URL")
    var marketingUrl: String?

    @Option(name: .long, help: "Privacy policy URL")
    var privacyPolicyUrl: String?

    @Option(name: .long, help: "tvOS-specific privacy policy text")
    var tvOsPrivacyPolicy: String?

    func run() async throws {
        let repo = try ClientProvider.makeBetaAppLocalizationRepository()
        print(try await execute(repo: repo))
    }

    func execute(
        repo: any BetaAppLocalizationRepository,
        affordanceMode: AffordanceMode = .cli
    ) async throws -> String {
        let update = BetaAppLocalizationUpdate(
            description: description,
            feedbackEmail: feedbackEmail,
            marketingUrl: marketingUrl,
            privacyPolicyUrl: privacyPolicyUrl,
            tvOsPrivacyPolicy: tvOsPrivacyPolicy
        )
        let item = try await repo.createBetaAppLocalization(appId: appId, locale: locale, update: update)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems([item], affordanceMode: affordanceMode)
    }
}
