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

    // MARK: - AuthStorage

    public func save(_ credentials: AuthCredentials, name: String) throws {
        var file = loadFileOrEmpty()
        file.accounts[name] = credentials
        if file.active == nil {
            file.active = name
        }
        try writeFile(file)
    }

    public func load(name: String?) throws -> AuthCredentials? {
        let file = loadFileOrEmpty()
        let key = name ?? file.active
        guard let key else { return nil }
        return file.accounts[key]
    }

    public func loadAll() throws -> [ConnectAccount] {
        let file = loadFileOrEmpty()
        return file.accounts
            .map { ConnectAccount(name: $0.key, keyID: $0.value.keyID, issuerID: $0.value.issuerID, isActive: $0.key == file.active) }
            .sorted { $0.name < $1.name }
    }

    public func delete(name: String?) throws {
        var file = loadFileOrEmpty()
        let key = name ?? file.active
        guard let key else { return }
        file.accounts.removeValue(forKey: key)
        if file.active == key {
            file.active = file.accounts.keys.sorted().first
        }
        if file.accounts.isEmpty {
            if FileManager.default.fileExists(atPath: fileURL.path) {
                try FileManager.default.removeItem(at: fileURL)
            }
        } else {
            try writeFile(file)
        }
    }

    public func setActive(name: String) throws {
        var file = try readFile()
        guard file.accounts[name] != nil else {
            throw AuthError.accountNotFound(name)
        }
        file.active = name
        try writeFile(file)
    }

    // MARK: - Private

    private struct CredentialsFile: Codable {
        var active: String?
        var accounts: [String: AuthCredentials]
    }

    /// Loads the file, migrating old single-credential format if needed.
    /// Returns an empty file if the file doesn't exist.
    private func loadFileOrEmpty() -> CredentialsFile {
        (try? readFile()) ?? CredentialsFile(active: nil, accounts: [:])
    }

    private func readFile() throws -> CredentialsFile {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return CredentialsFile(active: nil, accounts: [:])
        }
        let data = try Data(contentsOf: fileURL)

        // Detect new multi-account format by checking for "accounts" key
        if let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           dict["accounts"] != nil {
            return try JSONDecoder().decode(CredentialsFile.self, from: data)
        }

        // Migrate from legacy single-credential format
        let legacy = try JSONDecoder().decode(AuthCredentials.self, from: data)
        return CredentialsFile(active: "default", accounts: ["default": legacy])
    }

    private func writeFile(_ file: CredentialsFile) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(file)
        let directory = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try data.write(to: fileURL, options: .atomic)
    }
}
