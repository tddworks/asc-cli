import ArgumentParser
import Domain
import Foundation
import Infrastructure

struct AuthLogin: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "login",
        abstract: "Save API key credentials for authentication"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "App Store Connect API Key ID")
    var keyId: String

    @Option(name: .long, help: "App Store Connect Issuer ID")
    var issuerId: String

    @Option(name: .long, help: "Path to .p8 private key file")
    var privateKeyPath: String?

    @Option(name: .long, help: "Private key PEM content (alternative to --private-key-path)")
    var privateKey: String?

    func run() async throws {
        let storage = FileAuthStorage()
        print(try await execute(storage: storage))
    }

    func execute(storage: any AuthStorage) async throws -> String {
        let privateKeyPEM: String

        if let path = privateKeyPath {
            let expandedPath = NSString(string: path).expandingTildeInPath
            let url = URL(fileURLWithPath: expandedPath)
            privateKeyPEM = try String(contentsOf: url, encoding: .utf8)
        } else if let key = privateKey {
            privateKeyPEM = key
        } else {
            throw ValidationError("Provide either --private-key-path or --private-key")
        }

        let credentials = AuthCredentials(keyID: keyId, issuerID: issuerId, privateKeyPEM: privateKeyPEM)
        try credentials.validate()
        try storage.save(credentials)

        let status = AuthStatus(keyID: keyId, issuerID: issuerId, source: .file)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            [status],
            headers: ["Key ID", "Issuer ID", "Source"],
            rowMapper: { [$0.keyID, $0.issuerID, $0.source.rawValue] }
        )
    }
}
