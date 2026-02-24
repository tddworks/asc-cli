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

    @Test func `auth status id equals keyID`() {
        let status = AuthStatus(keyID: "KEY123", issuerID: "ISSUER456", source: .environment)
        #expect(status.id == "KEY123")
    }

    @Test func `auth status affordances include check login and logout commands`() {
        let status = AuthStatus(keyID: "KEY123", issuerID: "ISSUER456", source: .file)
        #expect(status.affordances["check"] == "asc auth check")
        #expect(status.affordances["login"] == "asc auth login --key-id <id> --issuer-id <id> --private-key-path <path>")
        #expect(status.affordances["logout"] == "asc auth logout")
    }
}
