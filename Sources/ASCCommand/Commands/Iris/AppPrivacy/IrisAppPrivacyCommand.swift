import ArgumentParser
import ASCKit

/// `asc iris app-privacy` — the app's App Privacy label ("nutrition label"). Iris private
/// API only: there is no public endpoint, yet App Review refuses a submission until it's published.
struct IrisAppPrivacyCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "app-privacy",
        abstract: "Show, declare and publish an app's App Privacy label (iris session)",
        subcommands: [IrisAppPrivacyGet.self, IrisAppPrivacyDeclare.self, IrisAppPrivacyPublish.self]
    )
}

struct IrisAppPrivacyGet: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "get",
        abstract: "Show what an app's privacy label declares and whether it is published"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "App ID")
    var appId: String

    func run() async throws {
        print(try await execute(cookieProvider: ClientProvider.makeIrisCookieProvider(), repo: ClientProvider.makeIrisAppPrivacyRepository()))
    }

    func execute(cookieProvider: any IrisCookieProvider, repo: any IrisAppPrivacyRepository, affordanceMode: AffordanceMode = .cli) async throws -> String {
        let privacy = try await repo.fetchPrivacy(session: try cookieProvider.resolveSession(), appId: appId)
        return try OutputFormatter(format: globals.outputFormat, pretty: globals.pretty).formatAgentItems([privacy], affordanceMode: affordanceMode)
    }
}

struct IrisAppPrivacyPublish: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "publish",
        abstract: "Publish an app's declared privacy label so it no longer blocks review"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "App ID")
    var appId: String

    func run() async throws {
        print(try await execute(cookieProvider: ClientProvider.makeIrisCookieProvider(), repo: ClientProvider.makeIrisAppPrivacyRepository()))
    }

    func execute(cookieProvider: any IrisCookieProvider, repo: any IrisAppPrivacyRepository, affordanceMode: AffordanceMode = .cli) async throws -> String {
        let session = try cookieProvider.resolveSession()
        let published = try await repo.fetchPrivacy(session: session, appId: appId).publish(session: session, repo: repo)
        return try OutputFormatter(format: globals.outputFormat, pretty: globals.pretty).formatAgentItems([published], affordanceMode: affordanceMode)
    }
}
