import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct SimulatorsShutdownTests {

    @Test func `shutdown simulator returns success message`() async throws {
        let mockRepo = MockSimulatorRepository()
        given(mockRepo).shutdownSimulator(udid: .value("ABCD-1234")).willReturn(())

        let cmd = try SimulatorsShutdown.parse(["--udid", "ABCD-1234"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output.contains("ABCD-1234"))
        #expect(output.contains("shut down"))
    }
}
