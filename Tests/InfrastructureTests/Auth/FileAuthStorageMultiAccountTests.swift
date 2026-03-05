import Foundation
import Testing
@testable import Domain
@testable import Infrastructure

@Suite
struct FileAuthStorageMultiAccountTests {

    private func makeTempFileURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("json")
    }

    private let credentials1 = AuthCredentials(
        keyID: "KEY1", issuerID: "ISSUER1",
        privateKeyPEM: "-----BEGIN PRIVATE KEY-----\nfake1\n-----END PRIVATE KEY-----"
    )
    private let credentials2 = AuthCredentials(
        keyID: "KEY2", issuerID: "ISSUER2",
        privateKeyPEM: "-----BEGIN PRIVATE KEY-----\nfake2\n-----END PRIVATE KEY-----"
    )

    @Test func `save and load named account`() throws {
        let url = makeTempFileURL()
        let storage = FileAuthStorage(fileURL: url)

        try storage.save(credentials1, name: "personal")
        let loaded = try storage.load(name: "personal")

        #expect(loaded == credentials1)
    }

    @Test func `first saved account becomes active`() throws {
        let url = makeTempFileURL()
        let storage = FileAuthStorage(fileURL: url)

        try storage.save(credentials1, name: "personal")
        let loaded = try storage.load(name: nil)  // active

        #expect(loaded == credentials1)
    }

    @Test func `second account does not replace active`() throws {
        let url = makeTempFileURL()
        let storage = FileAuthStorage(fileURL: url)

        try storage.save(credentials1, name: "personal")
        try storage.save(credentials2, name: "work")

        let active = try storage.load(name: nil)
        #expect(active == credentials1)  // still personal
    }

    @Test func `set active switches which account is returned by load nil`() throws {
        let url = makeTempFileURL()
        let storage = FileAuthStorage(fileURL: url)

        try storage.save(credentials1, name: "personal")
        try storage.save(credentials2, name: "work")
        try storage.setActive(name: "work")

        let active = try storage.load(name: nil)
        #expect(active == credentials2)
    }

    @Test func `load all returns all accounts with correct isActive flag`() throws {
        let url = makeTempFileURL()
        let storage = FileAuthStorage(fileURL: url)

        try storage.save(credentials1, name: "personal")
        try storage.save(credentials2, name: "work")

        let all = try storage.loadAll()
        #expect(all.count == 2)

        let personal = all.first { $0.name == "personal" }
        let work = all.first { $0.name == "work" }
        #expect(personal?.isActive == true)
        #expect(work?.isActive == false)
    }

    @Test func `delete named account removes only that account`() throws {
        let url = makeTempFileURL()
        let storage = FileAuthStorage(fileURL: url)

        try storage.save(credentials1, name: "personal")
        try storage.save(credentials2, name: "work")
        try storage.delete(name: "work")

        let all = try storage.loadAll()
        #expect(all.count == 1)
        #expect(all.first?.name == "personal")
    }

    @Test func `delete active account via nil removes it`() throws {
        let url = makeTempFileURL()
        let storage = FileAuthStorage(fileURL: url)

        try storage.save(credentials1, name: "personal")
        try storage.save(credentials2, name: "work")
        try storage.delete(name: nil)  // delete active (personal)

        let remaining = try storage.loadAll()
        #expect(remaining.count == 1)
        #expect(remaining.first?.name == "work")
    }

    @Test func `delete last account empties storage`() throws {
        let url = makeTempFileURL()
        let storage = FileAuthStorage(fileURL: url)

        try storage.save(credentials1, name: "personal")
        try storage.delete(name: nil)

        let all = try storage.loadAll()
        #expect(all.isEmpty)
    }

    @Test func `set active throws accountNotFound for unknown name`() throws {
        let url = makeTempFileURL()
        let storage = FileAuthStorage(fileURL: url)

        try storage.save(credentials1, name: "personal")

        #expect(throws: AuthError.accountNotFound("ghost")) {
            try storage.setActive(name: "ghost")
        }
    }

    @Test func `load returns nil for unknown name`() throws {
        let url = makeTempFileURL()
        let storage = FileAuthStorage(fileURL: url)

        try storage.save(credentials1, name: "personal")
        let loaded = try storage.load(name: "ghost")

        #expect(loaded == nil)
    }

    @Test func `load returns nil when no accounts saved`() throws {
        let url = makeTempFileURL()
        let storage = FileAuthStorage(fileURL: url)

        let loaded = try storage.load(name: nil)
        #expect(loaded == nil)
    }

    @Test func `migrates legacy single credential format to named default account`() throws {
        let url = makeTempFileURL()

        // Write legacy format directly
        let legacy = AuthCredentials(keyID: "LEGACY_KEY", issuerID: "LEGACY_ISSUER", privateKeyPEM: "pem")
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(legacy)
        try data.write(to: url)

        let storage = FileAuthStorage(fileURL: url)
        let active = try storage.load(name: nil)
        #expect(active == legacy)

        let all = try storage.loadAll()
        #expect(all.count == 1)
        #expect(all.first?.name == "default")
        #expect(all.first?.isActive == true)
    }
}
