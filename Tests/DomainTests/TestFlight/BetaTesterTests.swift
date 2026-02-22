import Testing
@testable import Domain

@Suite
struct BetaTesterTests {

    // MARK: - displayName

    @Test func `displayName combines first and last name`() {
        let tester = BetaTester(id: "1", firstName: "Jane", lastName: "Doe", email: "jane@example.com")
        #expect(tester.displayName == "Jane Doe")
    }

    @Test func `displayName uses only first name when last name is nil`() {
        let tester = BetaTester(id: "1", firstName: "Jane", lastName: nil, email: "jane@example.com")
        #expect(tester.displayName == "Jane")
    }

    @Test func `displayName falls back to email when name is nil`() {
        let tester = BetaTester(id: "1", firstName: nil, lastName: nil, email: "jane@example.com")
        #expect(tester.displayName == "jane@example.com")
    }

    @Test func `displayName falls back to id when name and email are nil`() {
        let tester = BetaTester(id: "tester-42", firstName: nil, lastName: nil, email: nil)
        #expect(tester.displayName == "tester-42")
    }

    @Test func `displayName ignores empty name parts`() {
        let tester = BetaTester(id: "1", firstName: "", lastName: "Doe", email: "jane@example.com")
        #expect(tester.displayName == "Doe")
    }

    // MARK: - InviteType raw values

    @Test func `inviteType email raw value matches API string`() {
        #expect(BetaTester.InviteType.email.rawValue == "EMAIL")
    }

    @Test func `inviteType publicLink raw value matches API string`() {
        #expect(BetaTester.InviteType.publicLink.rawValue == "PUBLIC_LINK")
    }
}
