import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct BuildsListTests {

    @Test func `execute json output`() async throws {
        let mockRepo = MockBuildRepository()
        given(mockRepo).listBuilds(appId: .any, limit: .any).willReturn(
            PaginatedResponse(data: [
                Build(id: "b-1", version: "42", expired: false, processingState: .valid),
            ], nextCursor: nil)
        )

        let cmd = try BuildsList.parse(["--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        [
          {
            "expired" : false,
            "id" : "b-1",
            "processingState" : "VALID",
            "version" : "42"
          }
        ]
        """)
    }

    @Test func `execute json output for expired build`() async throws {
        let mockRepo = MockBuildRepository()
        given(mockRepo).listBuilds(appId: .any, limit: .any).willReturn(
            PaginatedResponse(data: [
                Build(id: "b-1", version: "1", expired: true, processingState: .valid),
            ], nextCursor: nil)
        )

        let cmd = try BuildsList.parse(["--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        [
          {
            "expired" : true,
            "id" : "b-1",
            "processingState" : "VALID",
            "version" : "1"
          }
        ]
        """)
    }
}
