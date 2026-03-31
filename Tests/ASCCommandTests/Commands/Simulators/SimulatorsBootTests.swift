import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct SimulatorsBootTests {

    @Test func `boot simulator returns success message`() async throws {
        let mockRepo = MockSimulatorRepository()
        given(mockRepo).bootSimulator(udid: .value("ABCD-1234")).willReturn(())

        let cmd = try SimulatorsBoot.parse(["--udid", "ABCD-1234"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output.contains("ABCD-1234"))
        #expect(output.contains("booted"))
    }
}
