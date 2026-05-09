import ArgumentParser

struct BetaAppLocalizationsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "beta-app-localizations",
        abstract: "Manage TestFlight beta app descriptions and per-locale metadata",
        subcommands: [
            BetaAppLocalizationsList.self,
            BetaAppLocalizationsGet.self,
            BetaAppLocalizationsCreate.self,
            BetaAppLocalizationsUpdate.self,
            BetaAppLocalizationsDelete.self,
        ]
    )
}
