import ArgumentParser
import Domain
import Infrastructure

struct AuthCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "auth",
        abstract: "Manage App Store Connect authentication",
        subcommands: [AuthCheck.self, AuthLogin.self, AuthLogout.self, AuthList.self, AuthUse.self]
    )
}

struct AuthCheck: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "check",
        abstract: "Verify authentication credentials and show status"
    )

    @OptionGroup var globals: GlobalOptions

    func run() async throws {
        let storage = FileAuthStorage()
        let envProvider = EnvironmentAuthProvider()
        print(try await execute(storage: storage, envProvider: envProvider))
    }

    func execute(storage: any AuthStorage, envProvider: any AuthProvider) async throws -> String {
        let credentials: AuthCredentials
        let source: CredentialSource
        let accountName: String?

        if let active = try? storage.load(name: nil) {
            credentials = active
            source = .file
            let accounts = (try? storage.loadAll()) ?? []
            accountName = accounts.first(where: \.isActive)?.name
        } else {
            credentials = try envProvider.resolve()
            source = .environment
            accountName = nil
        }

        let status = AuthStatus(name: accountName, keyID: credentials.keyID, issuerID: credentials.issuerID, source: source)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            [status],
            headers: ["Name", "Key ID", "Issuer ID", "Source"],
            rowMapper: { [$0.name ?? "", $0.keyID, $0.issuerID, $0.source.rawValue] }
        )
    }
}
