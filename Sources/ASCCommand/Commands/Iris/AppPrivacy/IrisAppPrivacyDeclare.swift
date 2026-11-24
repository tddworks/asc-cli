import ArgumentParser
import Foundation
import ASCKit

struct IrisAppPrivacyDeclare: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "declare",
        abstract: "Replace an app's privacy label (it stays a draft until `publish`)",
        discussion: """
        --not-collected declares the app collects no data. --file takes a JSON file listing what it collects:
          {"collectedData": [{"category": "EMAIL_ADDRESS", "purposes": ["APP_FUNCTIONALITY"],
                              "isLinkedToYou": true, "isUsedToTrackYou": false}]}
        the same shape `get` shows. The file may also be {"notCollected": true}.
        """
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "App ID")
    var appId: String

    @Flag(name: .long, help: "The app collects no data")
    var notCollected = false

    @Option(name: .long, help: "A JSON file of the data the app collects")
    var file: String?

    func validate() throws {
        guard notCollected != (file != nil) else {
            throw ValidationError("Give either --not-collected or --file <privacy.json>.")
        }
    }

    func run() async throws {
        print(try await execute(cookieProvider: ClientProvider.makeIrisCookieProvider(), repo: ClientProvider.makeIrisAppPrivacyRepository()))
    }

    func execute(cookieProvider: any IrisCookieProvider, repo: any IrisAppPrivacyRepository, affordanceMode: AffordanceMode = .cli) async throws -> String {
        let declaration = try declaration()
        let session = try cookieProvider.resolveSession()
        let declared = try await repo.fetchPrivacy(session: session, appId: appId).declare(declaration, session: session, repo: repo)
        return try OutputFormatter(format: globals.outputFormat, pretty: globals.pretty).formatAgentItems([declared], affordanceMode: affordanceMode)
    }

    private func declaration() throws -> PrivacyDeclaration {
        guard let file else { return .notCollected }
        return try JSONDecoder().decode(PrivacyDeclaration.self, from: Data(contentsOf: URL(fileURLWithPath: file)))
    }
}
