import ArgumentParser
import Domain

struct SkillsInstall: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "install",
        abstract: "Install skills from the asc-cli repository"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Name of a specific skill to install")
    var name: String?

    @Flag(name: .long, help: "Install all available skills")
    var all: Bool = false

    func run() async throws {
        let repo = ClientProvider.makeSkillRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any SkillRepository) async throws -> String {
        if all {
            return try await repo.installAll()
        } else if let name {
            return try await repo.install(name: name)
        } else {
            return try await repo.installAll()
        }
    }
}
