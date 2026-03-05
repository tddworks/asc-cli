import Foundation
import Testing
@testable import Domain

@Suite
struct AuthStatusTests {

    @Test func `auth status carries keyID issuerID and source`() {
        let status = AuthStatus(keyID: "KEY123", issuerID: "ISSUER456", source: .file)
        #expect(status.keyID == "KEY123")
        #expect(status.issuerID == "ISSUER456")
        #expect(status.source == .file)
    }

    @Test func `auth status id equals name when name is set`() {
        let status = AuthStatus(name: "work", keyID: "KEY123", issuerID: "ISSUER456", source: .file)
        #expect(status.id == "work")
    }

    @Test func `auth status id falls back to keyID when name is nil`() {
        let status = AuthStatus(keyID: "KEY123", issuerID: "ISSUER456", source: .environment)
        #expect(status.id == "KEY123")
    }

    @Test func `auth status affordances include check list login and logout commands`() {
        let status = AuthStatus(keyID: "KEY123", issuerID: "ISSUER456", source: .file)
        #expect(status.affordances["check"] == "asc auth check")
        #expect(status.affordances["list"] == "asc auth list")
        #expect(status.affordances["login"] == "asc auth login --key-id <id> --issuer-id <id> --private-key-path <path>")
        #expect(status.affordances["logout"] == "asc auth logout")
    }

    @Test func `auth status name is omitted from JSON when nil`() throws {
        let status = AuthStatus(keyID: "KEY123", issuerID: "ISSUER456", source: .environment)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(status)
        let json = String(decoding: data, as: UTF8.self)
        #expect(!json.contains("name"))
    }

    @Test func `auth status name is included in JSON when set`() throws {
        let status = AuthStatus(name: "work", keyID: "KEY123", issuerID: "ISSUER456", source: .file)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(status)
        let json = String(decoding: data, as: UTF8.self)
        #expect(json.contains("\"name\":\"work\""))
    }
}
