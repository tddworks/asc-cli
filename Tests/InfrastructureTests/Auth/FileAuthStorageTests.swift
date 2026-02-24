import Foundation
import Testing
@testable import Domain
@testable import Infrastructure

@Suite
struct FileAuthStorageTests {

    private func makeTempFileURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("json")
    }

    @Test func `save writes credentials and load reads them back`() throws {
        let url = makeTempFileURL()
        let storage = FileAuthStorage(fileURL: url)
        let credentials = AuthCredentials(
            keyID: "KEY123",
            issuerID: "ISSUER456",
            privateKeyPEM: "-----BEGIN PRIVATE KEY-----\nfake\n-----END PRIVATE KEY-----"
        )

        try storage.save(credentials)
        let loaded = try storage.load()

        #expect(loaded == credentials)
    }

    @Test func `load returns nil when file does not exist`() throws {
        let url = makeTempFileURL()
        let storage = FileAuthStorage(fileURL: url)

        let loaded = try storage.load()

        #expect(loaded == nil)
    }

    @Test func `delete removes credentials file`() throws {
        let url = makeTempFileURL()
        let storage = FileAuthStorage(fileURL: url)
        let credentials = AuthCredentials(keyID: "KEY123", issuerID: "ISSUER456", privateKeyPEM: "key")

        try storage.save(credentials)
        try storage.delete()
        let loaded = try storage.load()

        #expect(loaded == nil)
    }

    @Test func `delete succeeds when file does not exist`() throws {
        let url = makeTempFileURL()
        let storage = FileAuthStorage(fileURL: url)
        try storage.delete()  // should not throw
    }
}
