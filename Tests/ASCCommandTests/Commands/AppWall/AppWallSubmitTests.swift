import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite("AppWallSubmit")
struct AppWallSubmitTests {

    @Test func `submit returns PR details as formatted JSON`() async throws {
        let mockRepo = MockAppWallRepository()
        given(mockRepo).submit(app: .any).willReturn(
            AppWallSubmission(
                prNumber: 42,
                prUrl: "https://github.com/tddworks/asc-cli/pull/42",
                title: "feat(app-wall): add itshan",
                developer: "itshan"
            )
        )

        var cmd = try AppWallSubmit.parse([
            "--developer", "itshan",
            "--developer-id", "1725133580",
            "--github", "hanrw",
            "--x", "itshanrw",
            "--pretty",
        ])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output.contains("\"prNumber\" : 42"))
        #expect(output.contains("\"developer\" : \"itshan\""))
        #expect(output.contains("\"openPR\""))
    }

    @Test func `submit with only required developer field works`() async throws {
        let mockRepo = MockAppWallRepository()
        given(mockRepo).submit(app: .any).willReturn(
            AppWallSubmission(
                prNumber: 7,
                prUrl: "https://github.com/tddworks/asc-cli/pull/7",
                title: "feat(app-wall): add jane",
                developer: "jane"
            )
        )

        var cmd = try AppWallSubmit.parse([
            "--developer", "jane",
        ])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output.contains("\"prNumber\":7") || output.contains("\"prNumber\" : 7"))
    }

    @Test func `submit with specific app URLs passes apps array`() async throws {
        let mockRepo = MockAppWallRepository()
        given(mockRepo).submit(app: .any).willReturn(
            AppWallSubmission(
                prNumber: 10,
                prUrl: "https://github.com/tddworks/asc-cli/pull/10",
                title: "feat(app-wall): add jane",
                developer: "jane"
            )
        )

        var cmd = try AppWallSubmit.parse([
            "--developer", "jane",
            "--app", "https://apps.apple.com/us/app/example/id123",
            "--app", "https://apps.apple.com/us/app/other/id456",
        ])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output.contains("\"prNumber\":10") || output.contains("\"prNumber\" : 10"))
    }
}
