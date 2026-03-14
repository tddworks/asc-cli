import ArgumentParser
import Domain
import Foundation

struct SkillsCheck: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "check",
        abstract: "Check for available skill updates"
    )

    @OptionGroup var globals: GlobalOptions

    func run() async throws {
        let repo = ClientProvider.makeSkillRepository()
        let storage = ClientProvider.makeSkillConfigStorage()
        print(try await execute(repo: repo, storage: storage))
    }

    func execute(repo: any SkillRepository, storage: any SkillConfigStorage) async throws -> String {
        let result = try await repo.check()

        // Persist the check timestamp
        var config = (try? await storage.load()) ?? SkillConfig()
        config.skillsCheckedAt = Date()
        try? await storage.save(config)

        switch result {
        case .upToDate:
            return "All skills are up to date."
        case .updatesAvailable:
            return "Skill updates are available. Run 'asc skills update' to refresh installed skills."
        case .unavailable:
            return "Skills CLI is not available. Install with: npm install -g skills"
        }
    }
}
