import ArgumentParser

struct IrisAuthCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "auth",
        abstract: "Apple ID SRP login for iris (private API)",
        subcommands: [IrisAuthLogin.self, IrisAuthVerifyCode.self, IrisAuthLogout.self]
    )
}
