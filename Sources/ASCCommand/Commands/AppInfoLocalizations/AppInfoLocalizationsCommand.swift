import ArgumentParser
import Domain

struct AppInfoLocalizationsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "app-info-localizations",
        abstract: "Manage App Store app info localizations",
        subcommands: [
            AppInfoLocalizationsList.self,
            AppInfoLocalizationsCreate.self,
            AppInfoLocalizationsUpdate.self,
        ]
    )
}

struct AppInfoLocalizationsList: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List localizations for an app info"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "App info ID")
    var appInfoId: String

    func run() async throws {
        let repo = try ClientProvider.makeAppInfoRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any AppInfoRepository) async throws -> String {
        let locs = try await repo.listLocalizations(appInfoId: appInfoId)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            locs,
            headers: ["ID", "Locale", "Name", "Subtitle"],
            rowMapper: { [$0.id, $0.locale, $0.name ?? "-", $0.subtitle ?? "-"] }
        )
    }
}

struct AppInfoLocalizationsCreate: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "create",
        abstract: "Create a new app info localization"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "App info ID")
    var appInfoId: String

    @Option(name: .long, help: "Locale identifier (e.g. en-US, zh-Hans)")
    var locale: String

    @Option(name: .long, help: "App name (up to 30 characters)")
    var name: String

    func run() async throws {
        let repo = try ClientProvider.makeAppInfoRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any AppInfoRepository) async throws -> String {
        let loc = try await repo.createLocalization(appInfoId: appInfoId, locale: locale, name: name)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            [loc],
            headers: ["ID", "Locale", "Name", "Subtitle"],
            rowMapper: { [$0.id, $0.locale, $0.name ?? "-", $0.subtitle ?? "-"] }
        )
    }
}

struct AppInfoLocalizationsUpdate: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "update",
        abstract: "Update an app info localization"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Localization ID")
    var localizationId: String

    @Option(name: .long, help: "App name (up to 30 characters)")
    var name: String?

    @Option(name: .long, help: "Subtitle (up to 30 characters)")
    var subtitle: String?

    @Option(name: .long, help: "Privacy policy URL")
    var privacyPolicyUrl: String?

    func run() async throws {
        let repo = try ClientProvider.makeAppInfoRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any AppInfoRepository) async throws -> String {
        let loc = try await repo.updateLocalization(
            id: localizationId,
            name: name,
            subtitle: subtitle,
            privacyPolicyUrl: privacyPolicyUrl
        )
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            [loc],
            headers: ["ID", "Locale", "Name", "Subtitle"],
            rowMapper: { [$0.id, $0.locale, $0.name ?? "-", $0.subtitle ?? "-"] }
        )
    }
}
