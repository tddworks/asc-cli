import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct BuildsUploadsDeleteTests {

    @Test func `accepts global options including pretty`() throws {
        let cmd = try BuildsUploadsDelete.parse(["--upload-id", "up-1", "--pretty"])
        #expect(cmd.globals.pretty == true)
    }

    @Test func `execute deletes upload record`() async throws {
        let mockRepo = MockBuildUploadRepository()
        given(mockRepo).deleteBuildUpload(id: .any).willReturn()

        let cmd = try BuildsUploadsDelete.parse(["--upload-id", "up-42"])
        try await cmd.execute(repo: mockRepo)

        verify(mockRepo).deleteBuildUpload(id: .value("up-42")).called(.once)
    }
}
