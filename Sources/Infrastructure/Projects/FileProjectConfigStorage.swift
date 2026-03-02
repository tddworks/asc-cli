import Domain
import Foundation

public struct FileProjectConfigStorage: ProjectConfigStorage {
    private let fileURL: URL

    public init(directoryURL: URL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)) {
        self.fileURL = directoryURL
            .appendingPathComponent(".asc")
            .appendingPathComponent("project.json")
    }

    public func save(_ config: ProjectConfig) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(config)
        let directory = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try data.write(to: fileURL, options: .atomic)
    }

    public func load() throws -> ProjectConfig? {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return nil
        }
        let data = try Data(contentsOf: fileURL)
        return try JSONDecoder().decode(ProjectConfig.self, from: data)
    }

    public func delete() throws {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        try FileManager.default.removeItem(at: fileURL)
    }
}
