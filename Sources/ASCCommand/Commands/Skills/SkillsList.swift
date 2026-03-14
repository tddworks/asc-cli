import ArgumentParser
import Domain

struct SkillsList: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List available skills from the asc-cli repository"
    )

    @OptionGroup var globals: GlobalOptions

    func run() async throws {
        let repo = ClientProvider.makeSkillRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any SkillRepository) async throws -> String {
        let output = try await repo.listAvailable()
        return output
    }
}
