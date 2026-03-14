import ArgumentParser
import Domain

struct SkillsUpdate: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "update",
        abstract: "Update installed skills to the latest version"
    )

    @OptionGroup var globals: GlobalOptions

    func run() async throws {
        let repo = ClientProvider.makeSkillRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any SkillRepository) async throws -> String {
        try await repo.update()
    }
}
