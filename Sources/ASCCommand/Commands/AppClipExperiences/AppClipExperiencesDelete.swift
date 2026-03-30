import ArgumentParser
import Domain

struct AppClipExperiencesDelete: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "delete",
        abstract: "Delete a default experience"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Experience ID")
    var experienceId: String

    func run() async throws {
        let repo = try ClientProvider.makeAppClipRepository()
        try await execute(repo: repo)
    }

    func execute(repo: any AppClipRepository) async throws {
        try await repo.deleteExperience(id: experienceId)
    }
}
