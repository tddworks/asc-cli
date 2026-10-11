import Foundation

/// Files and decoded App Store Connect responses for repository upload tests.
enum UploadFixtures {
    /// Writes `contents` to `<tmp>/<uuid>/<name>` so request bodies can name the file exactly.
    static func file(named name: String, contents: String) throws -> URL {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("upload-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let url = dir.appendingPathComponent(name)
        try Data(contents.utf8).write(to: url)
        return url
    }

    static func decode<T: Decodable>(_ type: T.Type, _ json: String) throws -> T {
        try JSONDecoder().decode(T.self, from: Data(json.utf8))
    }
}
