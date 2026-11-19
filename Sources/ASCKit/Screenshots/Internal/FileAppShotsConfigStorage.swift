import Foundation

public struct FileAppShotsConfigStorage: AppShotsConfigStorage {
    private let fileURL: URL

    public static let defaultConfigURL: URL = {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return home
            .appendingPathComponent(".asc")
            .appendingPathComponent("app-shots-config.json")
    }()

    public init(fileURL: URL = FileAppShotsConfigStorage.defaultConfigURL) {
        self.fileURL = fileURL
    }

    public func save(_ config: AppShotsConfig) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(config)
        let directory = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try data.write(to: fileURL, options: .atomic)
    }

    public func load() throws -> AppShotsConfig? {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return nil
        }
        let data = try Data(contentsOf: fileURL)
        return try JSONDecoder().decode(AppShotsConfig.self, from: data)
    }

    public func delete() throws {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        try FileManager.default.removeItem(at: fileURL)
    }
}
