import Foundation
import Testing
@testable import Domain
@testable import Infrastructure

@Suite
struct FileIrisSessionRepositoryTests {

    private func tempURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("iris-session-test-\(UUID().uuidString).json")
    }

    @Test func `save then load roundtrips the session`() throws {
        let url = tempURL()
        defer { try? FileManager.default.removeItem(at: url) }
        let repo = FileIrisSessionRepository(fileURL: url)
        let session = IrisAuthSession(
            cookies: "myacinfo=A1", scnt: "scnt", serviceKey: "key",
            appleIDSessionID: "sess", providerID: 42, teamId: "T", userEmail: "u@x.com",
            expiresAt: Date(timeIntervalSince1970: 1_900_000_000)
        )
        try repo.save(session)
        #expect(try repo.current() == session)
    }

    @Test func `current returns nil when no session is persisted`() throws {
        let url = tempURL()
        let repo = FileIrisSessionRepository(fileURL: url)
        #expect(try repo.current() == nil)
    }

    @Test func `delete removes the persisted file`() throws {
        let url = tempURL()
        let repo = FileIrisSessionRepository(fileURL: url)
        try repo.save(IrisAuthSession(
            cookies: "c", scnt: "s", serviceKey: "k", appleIDSessionID: "id",
            userEmail: "u@x.com", expiresAt: Date()
        ))
        try repo.delete()
        #expect(try repo.current() == nil)
        #expect(!FileManager.default.fileExists(atPath: url.path))
    }

    @Test func `save writes file with 0600 permissions`() throws {
        let url = tempURL()
        defer { try? FileManager.default.removeItem(at: url) }
        let repo = FileIrisSessionRepository(fileURL: url)
        try repo.save(IrisAuthSession(
            cookies: "c", scnt: "s", serviceKey: "k", appleIDSessionID: "id",
            userEmail: "u@x.com", expiresAt: Date()
        ))
        let attrs = try FileManager.default.attributesOfItem(atPath: url.path)
        let perms = attrs[.posixPermissions] as? NSNumber
        #expect(perms?.intValue == 0o600)
    }
}
