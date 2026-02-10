import Foundation
import Testing
@testable import Infrastructure

@Suite
struct PrivateKeyLoaderTests {
    private let loader = PrivateKeyLoader()

    @Test
    func `loads key from base64 encoded string`() throws {
        let originalPEM = "-----BEGIN PRIVATE KEY-----\nfakekey\n-----END PRIVATE KEY-----"
        let base64 = Data(originalPEM.utf8).base64EncodedString()

        let result = try loader.loadFromBase64(base64)
        #expect(result == originalPEM)
    }

    @Test
    func `throws for invalid base64 string`() {
        #expect(throws: Error.self) {
            try loader.loadFromBase64("not-valid-base64!!!")
        }
    }

    @Test
    func `loads key from file`() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let keyFile = tempDir.appendingPathComponent("test-key-\(UUID().uuidString).p8")
        let pemContent = "-----BEGIN PRIVATE KEY-----\ntestkey\n-----END PRIVATE KEY-----"
        try pemContent.write(to: keyFile, atomically: true, encoding: .utf8)

        defer { try? FileManager.default.removeItem(at: keyFile) }

        let result = try loader.loadFromFile(path: keyFile.path)
        #expect(result == pemContent)
    }

    @Test
    func `throws for non-existent file`() {
        #expect(throws: Error.self) {
            try loader.loadFromFile(path: "/nonexistent/path/key.p8")
        }
    }
}
