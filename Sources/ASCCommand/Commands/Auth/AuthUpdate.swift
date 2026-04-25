import ArgumentParser
import Domain
import Infrastructure

struct AuthUpdate: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "update",
        abstract: "Update an existing account (e.g. add vendor number)"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Account name (defaults to active account)")
    var name: String?

    @Option(name: .long, help: "Vendor number for financial/sales reports")
    var vendorNumber: String?

    func run() async throws {
        let storage = FileAuthStorage()
        print(try await execute(storage: storage))
    }

    func execute(storage: any AuthStorage, affordanceMode: AffordanceMode = .cli) async throws -> String {
        guard vendorNumber != nil else {
            throw ValidationError("Provide at least one field to update (e.g. --vendor-number)")
        }

        let accountName: String
        if let name {
            accountName = name
        } else {
            let accounts = try storage.loadAll()
            guard let active = accounts.first(where: \.isActive) else {
                throw AuthError.accountNotFound("no active account")
            }
            accountName = active.name
        }

        guard let existing = try storage.load(name: accountName) else {
            throw AuthError.accountNotFound(accountName)
        }

        let updated = AuthCredentials(
            keyID: existing.keyID,
            issuerID: existing.issuerID,
            privateKeyPEM: existing.privateKeyPEM,
            vendorNumber: vendorNumber ?? existing.vendorNumber
        )
        try storage.save(updated, name: accountName)

        let status = AuthStatus(
            name: accountName,
            keyID: updated.keyID,
            issuerID: updated.issuerID,
            source: .file,
            vendorNumber: updated.vendorNumber
        )
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            [status],
            headers: ["Name", "Key ID", "Issuer ID", "Source", "Vendor Number"],
            rowMapper: { [$0.name ?? "", $0.keyID, $0.issuerID, $0.source.rawValue, $0.vendorNumber ?? ""] },
            affordanceMode: affordanceMode
        )
    }
}
