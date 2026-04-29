import Domain
import Foundation

/// Persists `IrisAuthSession` to `~/.asc/iris/session.json` with `0600` permissions.
/// Cross-platform fallback for Linux and a default on macOS until `KeychainIrisSessionRepository`
/// lands; the composite repository tries keychain first and falls back here.
public struct FileIrisSessionRepository: IrisSessionRepository, @unchecked Sendable {
    private let fileURL: URL

    public static let defaultSessionURL: URL = {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return home
            .appendingPathComponent(".asc")
            .appendingPathComponent("iris")
            .appendingPathComponent("session.json")
    }()

    public init(fileURL: URL = FileIrisSessionRepository.defaultSessionURL) {
        self.fileURL = fileURL
    }

    public func save(_ session: IrisAuthSession) throws {
        let directory = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(session)
        try data.write(to: fileURL)
        // 0600 — owner read/write only. Cookies + scnt grant access to the user's
        // App Store Connect account, treat them like credentials.
        try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: fileURL.path)
    }

    public func current() throws -> IrisAuthSession? {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
        let data = try Data(contentsOf: fileURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(IrisAuthSession.self, from: data)
    }

    public func delete() throws {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        try FileManager.default.removeItem(at: fileURL)
    }
}
