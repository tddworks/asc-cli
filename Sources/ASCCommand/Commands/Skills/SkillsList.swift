import ArgumentParser
import ASCKit

struct SkillsList: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List available skills from the asc-cli repository"
    )

    @OptionGroup var globals: GlobalOptions

    func run() async throws {
        let repo = ClientProvider.makeSkills()
        print(try await execute(repo: repo))
    }

    func execute(repo: any Skills) async throws -> String {
        let output = try await repo.listAvailable()
        return output
    }
}
