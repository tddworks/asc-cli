import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct VersionsSetBuildTests {

    @Test func `accepts global options including pretty`() throws {
        let cmd = try VersionsSetBuild.parse(["--version-id", "v-1", "--build-id", "b-1", "--pretty"])
        #expect(cmd.globals.pretty == true)
    }

    @Test func `execute links build to version`() async throws {
        let mockRepo = MockVersionRepository()
        given(mockRepo).setBuild(versionId: .any, buildId: .any).willReturn()

        let cmd = try VersionsSetBuild.parse(["--version-id", "v-1", "--build-id", "build-42"])
        try await cmd.execute(repo: mockRepo)

        verify(mockRepo).setBuild(versionId: .value("v-1"), buildId: .value("build-42")).called(.once)
    }
}
