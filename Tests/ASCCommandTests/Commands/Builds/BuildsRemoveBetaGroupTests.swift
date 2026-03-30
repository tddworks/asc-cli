import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct BuildsRemoveBetaGroupTests {

    @Test func `accepts global options including pretty`() throws {
        let cmd = try BuildsRemoveBetaGroup.parse(["--build-id", "b-1", "--beta-group-id", "bg-1", "--pretty"])
        #expect(cmd.globals.pretty == true)
    }

    @Test func `execute removes beta group from build`() async throws {
        let mockRepo = MockBuildRepository()
        given(mockRepo).removeBetaGroups(buildId: .any, betaGroupIds: .any).willReturn()

        let cmd = try BuildsRemoveBetaGroup.parse(["--build-id", "build-1", "--beta-group-id", "bg-42"])
        try await cmd.execute(repo: mockRepo)

        verify(mockRepo).removeBetaGroups(buildId: .value("build-1"), betaGroupIds: .value(["bg-42"])).called(.once)
    }
}
