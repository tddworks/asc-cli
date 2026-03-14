import Domain
import Foundation

public struct FileSkillConfigStorage: SkillConfigStorage {
    private let fileURL: URL

    public static let defaultConfigURL: URL = {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return home
            .appendingPathComponent(".asc")
            .appendingPathComponent("skills-config.json")
    }()

    public init(fileURL: URL = FileSkillConfigStorage.defaultConfigURL) {
        self.fileURL = fileURL
    }

    public func save(_ config: SkillConfig) async throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(config)
        let directory = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try data.write(to: fileURL, options: .atomic)
    }

    public func load() async throws -> SkillConfig? {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return nil
        }
        let data = try Data(contentsOf: fileURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(SkillConfig.self, from: data)
    }
}
