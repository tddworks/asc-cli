import ArgumentParser
import Domain
import Foundation

struct IrisAuthLogout: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "logout",
        abstract: "Clear the saved iris session (does not revoke cookies on Apple's side — they expire naturally)"
    )

    @OptionGroup var globals: GlobalOptions

    func run() async throws {
        let sessionRepo = ClientProvider.makeIrisSessionRepository()
        let pendingURL = ClientProvider.pendingTwoFactorURL()
        try sessionRepo.delete()
        try? FileManager.default.removeItem(at: pendingURL)
        print("Iris session cleared.")
    }
}
