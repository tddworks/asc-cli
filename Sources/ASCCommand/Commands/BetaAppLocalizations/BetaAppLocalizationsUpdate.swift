import ArgumentParser
import Domain

struct BetaAppLocalizationsUpdate: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "update",
        abstract: "Update an existing beta app localization"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Beta app localization ID")
    var localizationId: String

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
        let item = try await repo.updateBetaAppLocalization(localizationId: localizationId, update: update)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems([item], affordanceMode: affordanceMode)
    }
}
