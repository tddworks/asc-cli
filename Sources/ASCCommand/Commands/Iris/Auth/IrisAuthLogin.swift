import ArgumentParser
import Domain
import Foundation

struct IrisAuthLogin: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "login",
        abstract: "Sign in with Apple ID + password via SRP. Prompts for the 2FA code separately."
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Apple ID email")
    var appleId: String

    @Option(name: .long, help: "Apple ID password (omit to be prompted on stdin)")
    var password: String?

    func run() async throws {
        let resolvedPassword = try password ?? promptForPassword()
        let creds = IrisAuthCredentials(appleId: appleId, password: resolvedPassword)
        let authRepo = ClientProvider.makeIrisAuthRepository()
        let sessionRepo = ClientProvider.makeIrisSessionRepository()
        let pendingURL = ClientProvider.pendingTwoFactorURL()
        print(try await execute(credentials: creds, authRepo: authRepo, sessionRepo: sessionRepo, pendingURL: pendingURL))
    }

    func execute(
        credentials: IrisAuthCredentials,
        authRepo: any IrisAuthRepository,
        sessionRepo: any IrisSessionRepository,
        pendingURL: URL,
        affordanceMode: AffordanceMode = .cli
    ) async throws -> String {
        do {
            let session = try await authRepo.login(credentials: credentials)
            try sessionRepo.save(session)
            try? FileManager.default.removeItem(at: pendingURL)
            let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
            return try formatter.formatAgentItems([IrisAuthSummary(session)], affordanceMode: affordanceMode)
        } catch IrisAuthError.twoFactorRequired(let pending) {
            try writePending(pending, to: pendingURL)
            return Self.formatTwoFactorMessage(pending)
        }
    }

    private func writePending(_ pending: PendingTwoFactorState, to url: URL) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(pending)
        try data.write(to: url)
        try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: url.path)
    }

    private func promptForPassword() throws -> String {
        FileHandle.standardError.write(Data("Apple ID password: ".utf8))
        guard let cstr = getpass("") else {
            throw IrisAuthError.networkFailure(message: "could not read password from stdin")
        }
        return String(cString: cstr)
    }

    static func formatTwoFactorMessage(_ pending: PendingTwoFactorState) -> String {
        let dest = pending.challenge.maskedDestination
        return """
        Two-factor authentication required.
        Code sent to: \(dest)
        Run: asc iris auth verify-code <\(pending.challenge.codeLength)-digit code>
        """
    }
}
