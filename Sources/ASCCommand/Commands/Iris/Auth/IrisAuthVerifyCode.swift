import ArgumentParser
import Domain
import Foundation

struct IrisAuthVerifyCode: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "verify-code",
        abstract: "Submit the 2FA code from a pending `asc iris auth login`"
    )

    @OptionGroup var globals: GlobalOptions

    @Argument(help: "6-digit 2FA code")
    var code: String

    func run() async throws {
        let authRepo = ClientProvider.makeIrisAuthRepository()
        let sessionRepo = ClientProvider.makeIrisSessionRepository()
        let pendingURL = ClientProvider.pendingTwoFactorURL()
        print(try await execute(code: code, authRepo: authRepo, sessionRepo: sessionRepo, pendingURL: pendingURL))
    }

    func execute(
        code: String,
        authRepo: any IrisAuthRepository,
        sessionRepo: any IrisSessionRepository,
        pendingURL: URL,
        affordanceMode: AffordanceMode = .cli
    ) async throws -> String {
        guard FileManager.default.fileExists(atPath: pendingURL.path) else {
            throw IrisAuthError.networkFailure(message: "no pending 2FA login — run `asc iris auth login` first")
        }
        let data = try Data(contentsOf: pendingURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let pending = try decoder.decode(PendingTwoFactorState.self, from: data)

        let session = try await authRepo.submitTwoFactorCode(code, pending: pending)
        try sessionRepo.save(session)
        try? FileManager.default.removeItem(at: pendingURL)

        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems([IrisAuthSummary(session)], affordanceMode: affordanceMode)
    }
}
