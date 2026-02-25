import Testing
@testable import Domain

@Suite
struct BetaTesterTests {

    // MARK: - Parent ID

    @Test func `beta tester carries groupId`() {
        let tester = MockRepositoryFactory.makeBetaTester(id: "t-1", groupId: "g-42")
        #expect(tester.groupId == "g-42")
    }

    // MARK: - displayName

    @Test func `displayName combines first and last name`() {
        let tester = BetaTester(id: "1", groupId: "g-1", firstName: "Jane", lastName: "Doe", email: "jane@example.com")
        #expect(tester.displayName == "Jane Doe")
    }

    @Test func `displayName uses only first name when last name is nil`() {
        let tester = BetaTester(id: "1", groupId: "g-1", firstName: "Jane", lastName: nil, email: "jane@example.com")
        #expect(tester.displayName == "Jane")
    }

    @Test func `displayName falls back to email when name is nil`() {
        let tester = BetaTester(id: "1", groupId: "g-1", firstName: nil, lastName: nil, email: "jane@example.com")
        #expect(tester.displayName == "jane@example.com")
    }

    @Test func `displayName falls back to id when name and email are nil`() {
        let tester = BetaTester(id: "tester-42", groupId: "g-1", firstName: nil, lastName: nil, email: nil)
        #expect(tester.displayName == "tester-42")
    }

    @Test func `displayName ignores empty name parts`() {
        let tester = BetaTester(id: "1", groupId: "g-1", firstName: "", lastName: "Doe", email: "jane@example.com")
        #expect(tester.displayName == "Doe")
    }

    // MARK: - InviteType raw values

    @Test func `inviteType email raw value matches API string`() {
        #expect(BetaTester.InviteType.email.rawValue == "EMAIL")
    }

    @Test func `inviteType publicLink raw value matches API string`() {
        #expect(BetaTester.InviteType.publicLink.rawValue == "PUBLIC_LINK")
    }

    // MARK: - Affordances

    @Test func `beta tester affordances include remove with groupId and testerId`() {
        let tester = MockRepositoryFactory.makeBetaTester(id: "t-1", groupId: "g-1")
        #expect(tester.affordances["remove"] == "asc testflight testers remove --group-id g-1 --tester-id t-1")
    }

    @Test func `beta tester affordances include listSiblings with groupId`() {
        let tester = MockRepositoryFactory.makeBetaTester(id: "t-1", groupId: "g-1")
        #expect(tester.affordances["listSiblings"] == "asc testflight testers list --group-id g-1")
    }
}
