import ArgumentParser
import Domain

struct AppClipExperienceLocalizationsDelete: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "delete",
        abstract: "Delete a localization"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Localization ID")
    var localizationId: String

    func run() async throws {
        let repo = try ClientProvider.makeAppClipRepository()
        try await execute(repo: repo)
    }

    func execute(repo: any AppClipRepository) async throws {
        try await repo.deleteLocalization(id: localizationId)
    }
}
