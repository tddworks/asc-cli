import ArgumentParser
import Domain
import Foundation

struct TestFlightCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "testflight",
        abstract: "Manage TestFlight beta testing",
        subcommands: [BetaGroupsCommand.self, BetaTestersCommand.self]
    )
}

// MARK: - Beta Groups

struct BetaGroupsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "groups",
        abstract: "Manage beta groups",
        subcommands: [BetaGroupsList.self, BetaGroupsCreate.self]
    )
}

struct BetaGroupsList: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List beta groups"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Filter by app ID")
    var appId: String?

    @Option(name: .long, help: "Maximum number of groups to return")
    var limit: Int?

    func run() async throws {
        let repo = try ClientProvider.makeTestFlightRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any TestFlightRepository, affordanceMode: AffordanceMode = .cli) async throws -> String {
        let response = try await repo.listBetaGroups(appId: appId, limit: limit)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(response.data, affordanceMode: affordanceMode)
    }
}

struct BetaGroupsCreate: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "create",
        abstract: "Create a beta group (external by default; use --internal for an internal group)"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "App ID that owns the group")
    var appId: String

    @Option(name: .long, help: "Group name")
    var name: String

    @Flag(name: .customLong("internal"), help: "Create an internal beta group (testers must be members of your App Store Connect team). Default: external.")
    var isInternal: Bool = false

    @Flag(name: .long, inversion: .prefixedNo, exclusivity: .exclusive, help: "Enable the public TestFlight link (external groups only)")
    var publicLinkEnabled: Bool = false

    @Flag(name: .long, inversion: .prefixedNo, exclusivity: .exclusive, help: "Enable tester feedback (external groups only)")
    var feedbackEnabled: Bool = false

    func run() async throws {
        let repo = try ClientProvider.makeTestFlightRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any TestFlightRepository) async throws -> String {
        let group = try await repo.createBetaGroup(
            appId: appId,
            name: name,
            isInternalGroup: isInternal,
            publicLinkEnabled: isInternal ? nil : publicLinkEnabled,
            feedbackEnabled: isInternal ? nil : feedbackEnabled
        )
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems([group])
    }
}

// MARK: - Beta Testers

struct BetaTestersCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "testers",
        abstract: "Manage beta testers",
        subcommands: [
            BetaTestersList.self,
            BetaTestersAdd.self,
            BetaTestersRemove.self,
            BetaTestersImport.self,
            BetaTestersExport.self,
        ]
    )
}

struct BetaTestersList: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List beta testers in a group"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Beta group ID")
    var betaGroupId: String

    @Option(name: .long, help: "Maximum number of testers to return")
    var limit: Int?

    func run() async throws {
        let repo = try ClientProvider.makeTestFlightRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any TestFlightRepository) async throws -> String {
        let response = try await repo.listBetaTesters(groupId: betaGroupId, limit: limit)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(response.data)
    }
}

struct BetaTestersAdd: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "add",
        abstract: "Add a beta tester to a group"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Beta group ID")
    var betaGroupId: String

    @Option(name: .long, help: "Tester email address")
    var email: String

    @Option(name: .long, help: "Tester first name")
    var firstName: String?

    @Option(name: .long, help: "Tester last name")
    var lastName: String?

    func run() async throws {
        let repo = try ClientProvider.makeTestFlightRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any TestFlightRepository) async throws -> String {
        let tester = try await repo.addBetaTester(groupId: betaGroupId, email: email, firstName: firstName, lastName: lastName)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems([tester])
    }
}

struct BetaTestersRemove: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "remove",
        abstract: "Remove a beta tester from a group"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Beta group ID")
    var betaGroupId: String

    @Option(name: .long, help: "Tester ID to remove")
    var testerId: String

    func run() async throws {
        let repo = try ClientProvider.makeTestFlightRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any TestFlightRepository) async throws -> String {
        try await repo.removeBetaTester(groupId: betaGroupId, testerId: testerId)
        return "Removed tester \(testerId) from group \(betaGroupId)"
    }
}

struct BetaTestersImport: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "import",
        abstract: "Import beta testers from a CSV file (columns: email,firstName,lastName)"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Beta group ID")
    var betaGroupId: String

    @Option(name: .long, help: "Path to CSV file with columns: email,firstName,lastName")
    var file: String

    func run() async throws {
        let repo = try ClientProvider.makeTestFlightRepository()
        let content = try String(contentsOfFile: file, encoding: .utf8)
        print(try await execute(repo: repo, csvContent: content))
    }

    func execute(repo: any TestFlightRepository, csvContent: String) async throws -> String {
        let entries = parseCSV(csvContent)

        var added: [BetaTester] = []
        for entry in entries {
            let tester = try await repo.addBetaTester(
                groupId: betaGroupId,
                email: entry.email,
                firstName: entry.firstName,
                lastName: entry.lastName
            )
            added.append(tester)
        }

        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(added)
    }

    private struct CSVEntry {
        let email: String
        let firstName: String?
        let lastName: String?
    }

    private func parseCSV(_ content: String) -> [CSVEntry] {
        let lines = content.components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard lines.count > 1 else { return [] }

        // Skip the header row
        return lines.dropFirst().compactMap { line in
            let fields = line.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            guard let email = fields.first, !email.isEmpty else { return nil }
            let firstName = fields.count > 1 && !fields[1].isEmpty ? fields[1] : nil
            let lastName = fields.count > 2 && !fields[2].isEmpty ? fields[2] : nil
            return CSVEntry(email: email, firstName: firstName, lastName: lastName)
        }
    }
}

struct BetaTestersExport: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "export",
        abstract: "Export beta testers from a group as CSV"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Beta group ID")
    var betaGroupId: String

    @Option(name: .long, help: "Maximum number of testers to export")
    var limit: Int?

    func run() async throws {
        let repo = try ClientProvider.makeTestFlightRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any TestFlightRepository) async throws -> String {
        let response = try await repo.listBetaTesters(groupId: betaGroupId, limit: limit)
        return formatCSV(response.data)
    }

    private func formatCSV(_ testers: [BetaTester]) -> String {
        var lines = ["email,firstName,lastName"]
        for tester in testers {
            let email = tester.email ?? ""
            let first = tester.firstName ?? ""
            let last = tester.lastName ?? ""
            lines.append("\(email),\(first),\(last)")
        }
        return lines.joined(separator: "\n")
    }
}