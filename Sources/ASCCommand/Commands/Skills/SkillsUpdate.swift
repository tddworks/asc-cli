import ArgumentParser
import ASCKit

struct SkillsUpdate: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "update",
        abstract: "Update installed skills to the latest version"
    )

    @OptionGroup var globals: GlobalOptions

    func run() async throws {
        let repo = ClientProvider.makeSkills()
        print(try await execute(repo: repo))
    }

    func execute(repo: any Skills) async throws -> String {
        try await repo.update()
    }
}
