import Domain
import Foundation

public struct FileAuthStorage: AuthStorage {
    private let fileURL: URL

    public static let defaultCredentialsURL: URL = {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return home
            .appendingPathComponent(".asc")
            .appendingPathComponent("credentials.json")
    }()

    public init(fileURL: URL = FileAuthStorage.defaultCredentialsURL) {
        self.fileURL = fileURL
    }

    public func save(_ credentials: AuthCredentials) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(credentials)
        let directory = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try data.write(to: fileURL, options: .atomic)
    }

    public func load() throws -> AuthCredentials? {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return nil
        }
        let data = try Data(contentsOf: fileURL)
        return try JSONDecoder().decode(AuthCredentials.self, from: data)
    }

    public func delete() throws {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return
        }
        try FileManager.default.removeItem(at: fileURL)
    }
}
