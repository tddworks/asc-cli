import Mockable
import Testing
@testable import ASCCommand
@testable import ASCKit

@Suite
struct BundleIDsDeleteTests {

    @Test func `execute deletes bundle id`() async throws {
        let mockRepo = MockBundleIDRepository()
        given(mockRepo).deleteBundleID(id: .any).willReturn()

        let cmd = try BundleIDsDelete.parse(["--bundle-id-id", "bid-42"])
        try await cmd.execute(repo: mockRepo)

        verify(mockRepo).deleteBundleID(id: .value("bid-42")).called(.once)
    }
}
