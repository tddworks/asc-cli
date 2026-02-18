import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct BuildsListTests {

    @Test func `execute json output contains version and raw processing state`() async throws {
        let mockRepo = MockBuildRepository()
        given(mockRepo).listBuilds(appId: .any, limit: .any).willReturn(
            PaginatedResponse(data: [
                Build(id: "b-1", version: "42", expired: false, processingState: .valid, buildNumber: nil),
            ], nextCursor: nil)
        )

        let cmd = try BuildsList.parse([])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output.contains("\"version\":\"42\""))
        #expect(output.contains("VALID"))
        #expect(output.contains("\"expired\":false"))
    }

    @Test func `execute json output shows expired true for expired build`() async throws {
        let mockRepo = MockBuildRepository()
        given(mockRepo).listBuilds(appId: .any, limit: .any).willReturn(
            PaginatedResponse(data: [
                Build(id: "b-1", version: "1", expired: true, processingState: .valid, buildNumber: nil),
            ], nextCursor: nil)
        )

        let cmd = try BuildsList.parse([])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output.contains("\"expired\":true"))
    }
}
