import Foundation
import Testing
@testable import ASCKit

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
        #expect(tester.affordances["remove"] == "asc testflight testers remove --beta-group-id g-1 --tester-id t-1")
    }

    @Test func `beta tester affordances include listTesters with groupId`() {
        let tester = MockRepositoryFactory.makeBetaTester(id: "t-1", groupId: "g-1")
        #expect(tester.affordances["listTesters"] == "asc testflight testers list --beta-group-id g-1")
    }

    // MARK: - Codable round-trip

    @Test func `decode round-trip preserves all fields including inviteType`() throws {
        let original = BetaTester(
            id: "t-1", groupId: "g-1",
            firstName: "Jane", lastName: "Doe",
            email: "jane@example.com", inviteType: .email
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(BetaTester.self, from: data)
        #expect(decoded.id == "t-1")
        #expect(decoded.groupId == "g-1")
        #expect(decoded.firstName == "Jane")
        #expect(decoded.lastName == "Doe")
        #expect(decoded.email == "jane@example.com")
        #expect(decoded.inviteType == .email)
    }

    @Test func `decode round-trip with nil optional fields`() throws {
        let original = BetaTester(id: "t-2", groupId: "g-2")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(BetaTester.self, from: data)
        #expect(decoded.id == "t-2")
        #expect(decoded.firstName == nil)
        #expect(decoded.lastName == nil)
        #expect(decoded.email == nil)
        #expect(decoded.inviteType == nil)
    }
}
