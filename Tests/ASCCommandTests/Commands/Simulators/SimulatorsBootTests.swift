import Mockable
import Testing
@testable import ASCCommand
@testable import ASCKit

@Suite
struct SimulatorsBootTests {

    @Test func `boot simulator returns success message with udid`() async throws {
        let mockRepo = MockSimulators()
        given(mockRepo).bootSimulator(udid: .value("ABCD-1234")).willReturn(())

        let cmd = try SimulatorsBoot.parse(["--udid", "ABCD-1234"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output.contains("ABCD-1234"))
        #expect(output.contains("booted"))
    }

    @Test func `boot parses udid option correctly`() throws {
        let cmd = try SimulatorsBoot.parse(["--udid", "MY-UUID-HERE"])
        #expect(cmd.udid == "MY-UUID-HERE")
    }
}
