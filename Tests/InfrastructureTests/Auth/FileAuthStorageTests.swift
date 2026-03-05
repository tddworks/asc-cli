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

    @Test func `save writes credentials and load by name reads them back`() throws {
        let url = makeTempFileURL()
        let storage = FileAuthStorage(fileURL: url)
        let credentials = AuthCredentials(
            keyID: "KEY123",
            issuerID: "ISSUER456",
            privateKeyPEM: "-----BEGIN PRIVATE KEY-----\nfake\n-----END PRIVATE KEY-----"
        )

        try storage.save(credentials, name: "myaccount")
        let loaded = try storage.load(name: "myaccount")

        #expect(loaded == credentials)
    }

    @Test func `load nil returns nil when no accounts saved`() throws {
        let url = makeTempFileURL()
        let storage = FileAuthStorage(fileURL: url)

        let loaded = try storage.load(name: nil)

        #expect(loaded == nil)
    }

    @Test func `delete nil removes active account`() throws {
        let url = makeTempFileURL()
        let storage = FileAuthStorage(fileURL: url)
        let credentials = AuthCredentials(keyID: "KEY123", issuerID: "ISSUER456", privateKeyPEM: "key")

        try storage.save(credentials, name: "myaccount")
        try storage.delete(name: nil)
        let loaded = try storage.load(name: nil)

        #expect(loaded == nil)
    }

    @Test func `delete nil succeeds when no accounts exist`() throws {
        let url = makeTempFileURL()
        let storage = FileAuthStorage(fileURL: url)
        try storage.delete(name: nil)  // should not throw
    }

    @Test func `load all returns empty when no accounts saved`() throws {
        let url = makeTempFileURL()
        let storage = FileAuthStorage(fileURL: url)

        let accounts = try storage.loadAll()
        #expect(accounts.isEmpty)
    }
}
