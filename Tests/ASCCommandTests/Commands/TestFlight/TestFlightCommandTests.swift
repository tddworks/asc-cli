import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct BetaGroupsListTests {

    @Test func `execute json output`() async throws {
        let mockRepo = MockTestFlightRepository()
        given(mockRepo).listBetaGroups(appId: .any, limit: .any).willReturn(
            PaginatedResponse(data: [
                BetaGroup(id: "g-1", name: "External Testers", isInternalGroup: false),
                BetaGroup(id: "g-2", name: "Internal Team", isInternalGroup: true),
            ], nextCursor: nil)
        )

        let cmd = try BetaGroupsList.parse(["--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        [
          {
            "id" : "g-1",
            "isInternalGroup" : false,
            "name" : "External Testers",
            "publicLinkEnabled" : false
          },
          {
            "id" : "g-2",
            "isInternalGroup" : true,
            "name" : "Internal Team",
            "publicLinkEnabled" : false
          }
        ]
        """)
    }
}

@Suite
struct BetaTestersListTests {

    @Test func `execute json output`() async throws {
        let mockRepo = MockTestFlightRepository()
        given(mockRepo).listBetaTesters(groupId: .any, limit: .any).willReturn(
            PaginatedResponse(data: [
                BetaTester(id: "t-1", firstName: "Jane", lastName: "Doe", email: "jane@example.com", inviteType: .email),
            ], nextCursor: nil)
        )

        let cmd = try BetaTestersList.parse(["--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        [
          {
            "email" : "jane@example.com",
            "firstName" : "Jane",
            "id" : "t-1",
            "inviteType" : "EMAIL",
            "lastName" : "Doe"
          }
        ]
        """)
    }

    @Test func `execute json output with missing optional fields`() async throws {
        let mockRepo = MockTestFlightRepository()
        given(mockRepo).listBetaTesters(groupId: .any, limit: .any).willReturn(
            PaginatedResponse(data: [
                BetaTester(id: "t-1", firstName: "Unknown", lastName: nil, email: nil, inviteType: nil),
            ], nextCursor: nil)
        )

        let cmd = try BetaTestersList.parse(["--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        [
          {
            "firstName" : "Unknown",
            "id" : "t-1"
          }
        ]
        """)
    }
}
