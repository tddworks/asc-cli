import Mockable
import Testing
@testable import ASCCommand
@testable import ASCKit

@Suite
struct SimulatorsShutdownTests {

    @Test func `shutdown simulator returns success message with udid`() async throws {
        let mockRepo = MockSimulatorRepository()
        given(mockRepo).shutdownSimulator(udid: .value("ABCD-1234")).willReturn(())

        let cmd = try SimulatorsShutdown.parse(["--udid", "ABCD-1234"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output.contains("ABCD-1234"))
        #expect(output.contains("shut down"))
    }

    @Test func `shutdown parses udid option correctly`() throws {
        let cmd = try SimulatorsShutdown.parse(["--udid", "MY-UUID-HERE"])
        #expect(cmd.udid == "MY-UUID-HERE")
    }
}
