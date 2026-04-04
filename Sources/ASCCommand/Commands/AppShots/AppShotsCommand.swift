import ArgumentParser
import Domain

struct AppShotsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "app-shots",
        abstract: "AI-powered App Store screenshot planning and generation",
        subcommands: [AppShotsTemplatesCommand.self, AppShotsGenerate.self, AppShotsTranslate.self, AppShotsHTML.self, AppShotsConfig.self]
    )
}
