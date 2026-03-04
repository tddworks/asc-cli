import ArgumentParser
import Domain
import Foundation
import Infrastructure

struct AppWallSubmit: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "submit",
        abstract: "Submit your app to the asc app wall by opening a pull request on GitHub"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Your developer display name (required)")
    var developer: String

    @Option(name: .long, help: "Your Apple developer/seller ID — auto-fetches all your App Store apps")
    var developerId: String?

    @Option(name: .long, help: "Your GitHub username")
    var github: String?

    @Option(name: .long, help: "Your X (Twitter) handle")
    var x: String?

    @Option(name: .long, help: "Specific App Store URL (repeat for multiple apps)")
    var app: [String] = []

    @Option(name: .long, help: "GitHub personal access token (or set GITHUB_TOKEN)")
    var githubToken: String?

    func run() async throws {
        let token = try resolveGitHubToken()
        let repo = ClientProvider.makeAppWallRepository(token: token)
        print(try await execute(repo: repo))
    }

    func execute(repo: any AppWallRepository) async throws -> String {
        let wallApp = AppWallApp(
            developer: developer,
            developerId: developerId,
            github: github,
            x: x,
            apps: app.isEmpty ? nil : app
        )
        let submission = try await repo.submit(app: wallApp)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            [submission],
            headers: ["PR #", "Title", "URL"],
            rowMapper: { [String($0.prNumber), $0.title, $0.prUrl] }
        )
    }

    // MARK: - Token resolution: flag → $GITHUB_TOKEN → gh auth token

    private func resolveGitHubToken() throws -> String {
        if let token = githubToken, !token.isEmpty { return token }
        if let token = ProcessInfo.processInfo.environment["GITHUB_TOKEN"], !token.isEmpty { return token }
        if let token = runGHAuthToken(), !token.isEmpty { return token }
        throw ValidationError(
            "GitHub token required. " +
            "Pass --github-token, set GITHUB_TOKEN, or run `gh auth login`."
        )
    }

    private func runGHAuthToken() -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["gh", "auth", "token"]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()
        guard (try? process.run()) != nil else { return nil }
        process.waitUntilExit()
        guard process.terminationStatus == 0 else { return nil }
        return String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
