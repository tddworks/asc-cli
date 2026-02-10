import ArgumentParser
import Domain
import Infrastructure

struct AuthCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "auth",
        abstract: "Check authentication status",
        subcommands: [AuthCheck.self]
    )
}

struct AuthCheck: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "check",
        abstract: "Verify authentication credentials"
    )

    func run() async throws {
        let provider = EnvironmentAuthProvider()
        do {
            let creds = try provider.resolve()
            print("Authentication OK")
            print("  Key ID: \(creds.keyID)")
            print("  Issuer ID: \(creds.issuerID)")
        } catch {
            print("Authentication failed: \(error)")
            throw ExitCode.failure
        }
    }
}
