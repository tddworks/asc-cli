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

    @Option(name: .long, help: "Account name (defaults to \"default\"); no spaces allowed")
    var name: String?

    @Option(name: .long, help: "Path to .p8 private key file")
    var privateKeyPath: String?

    @Option(name: .long, help: "Private key PEM content (alternative to --private-key-path)")
    var privateKey: String?

    @Option(name: .long, help: "Vendor number for financial/sales reports (found in App Store Connect → Payments and Financial Reports)")
    var vendorNumber: String?

    func run() async throws {
        let storage = FileAuthStorage()
        print(try await execute(storage: storage))
    }

    func execute(storage: any AuthStorage, affordanceMode: AffordanceMode = .cli) async throws -> String {
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

        let accountName = name ?? "default"
        guard !accountName.contains(where: \.isWhitespace) else {
            throw ValidationError("Account name must not contain spaces. Got: \"\(accountName)\"")
        }
        let credentials = AuthCredentials(keyID: keyId, issuerID: issuerId, privateKeyPEM: privateKeyPEM, vendorNumber: vendorNumber)
        try credentials.validate()
        try storage.save(credentials, name: accountName)
        try storage.setActive(name: accountName)

        let status = AuthStatus(name: accountName, keyID: keyId, issuerID: issuerId, source: .file, vendorNumber: vendorNumber)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            [status],
            headers: ["Name", "Key ID", "Issuer ID", "Source"],
            rowMapper: { [$0.name ?? "", $0.keyID, $0.issuerID, $0.source.rawValue] },
            affordanceMode: affordanceMode
        )
    }
}
