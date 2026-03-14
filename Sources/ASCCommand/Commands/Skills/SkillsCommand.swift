import ArgumentParser

struct SkillsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "skills",
        abstract: "Manage Claude Code agent skills from the asc-cli repository",
        subcommands: [
            SkillsList.self,
            SkillsInstall.self,
            SkillsUninstall.self,
            SkillsInstalled.self,
            SkillsCheck.self,
            SkillsUpdate.self,
        ]
    )
}
