import ArgumentParser
import Domain
import Infrastructure

struct AuthCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "auth",
        abstract: "Manage App Store Connect authentication",
        subcommands: [AuthCheck.self, AuthLogin.self, AuthLogout.self]
    )
}

struct AuthCheck: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "check",
        abstract: "Verify authentication credentials and show status"
    )

    @OptionGroup var globals: GlobalOptions

    func run() async throws {
        let fileProvider = FileAuthProvider()
        let envProvider = EnvironmentAuthProvider()
        print(try await execute(fileProvider: fileProvider, envProvider: envProvider))
    }

    func execute(fileProvider: any AuthProvider, envProvider: any AuthProvider) async throws -> String {
        let credentials: AuthCredentials
        let source: CredentialSource

        if let creds = try? fileProvider.resolve() {
            credentials = creds
            source = .file
        } else {
            credentials = try envProvider.resolve()
            source = .environment
        }

        let status = AuthStatus(keyID: credentials.keyID, issuerID: credentials.issuerID, source: source)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            [status],
            headers: ["Key ID", "Issuer ID", "Source"],
            rowMapper: { [$0.keyID, $0.issuerID, $0.source.rawValue] }
        )
    }
}
