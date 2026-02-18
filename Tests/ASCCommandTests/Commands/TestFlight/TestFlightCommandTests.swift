import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct BetaGroupsListTests {

    @Test func `execute json output contains group names and internal flag`() async throws {
        let mockRepo = MockTestFlightRepository()
        given(mockRepo).listBetaGroups(appId: .any, limit: .any).willReturn(
            PaginatedResponse(data: [
                BetaGroup(id: "g-1", name: "External Testers", isInternalGroup: false),
                BetaGroup(id: "g-2", name: "Internal Team", isInternalGroup: true),
            ], nextCursor: nil)
        )

        let cmd = try BetaGroupsList.parse([])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output.contains("External Testers"))
        #expect(output.contains("Internal Team"))
        #expect(output.contains("\"isInternalGroup\":false"))
        #expect(output.contains("\"isInternalGroup\":true"))
    }
}

@Suite
struct BetaTestersListTests {

    @Test func `execute json output contains tester name and email`() async throws {
        let mockRepo = MockTestFlightRepository()
        given(mockRepo).listBetaTesters(groupId: .any, limit: .any).willReturn(
            PaginatedResponse(data: [
                BetaTester(id: "t-1", firstName: "Jane", lastName: "Doe", email: "jane@example.com", inviteType: .email),
            ], nextCursor: nil)
        )

        let cmd = try BetaTestersList.parse([])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output.contains("Jane"))
        #expect(output.contains("jane@example.com"))
    }

    @Test func `execute json output shows null for missing email`() async throws {
        let mockRepo = MockTestFlightRepository()
        given(mockRepo).listBetaTesters(groupId: .any, limit: .any).willReturn(
            PaginatedResponse(data: [
                BetaTester(id: "t-1", firstName: "Unknown", lastName: nil, email: nil, inviteType: nil),
            ], nextCursor: nil)
        )

        let cmd = try BetaTestersList.parse([])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output.contains("Unknown"))
    }
}
