import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct SimulatorsListTests {

    @Test func `listed simulators show id name state runtime and affordances`() async throws {
        let mockRepo = MockSimulatorRepository()
        given(mockRepo).listSimulators(filter: .any).willReturn([
            Simulator(
                id: "ABCD-1234",
                name: "iPhone 16 Pro",
                state: SimulatorState.shutdown,
                runtime: "com.apple.CoreSimulator.SimRuntime.iOS-18-2"
            ),
        ])

        let cmd = try SimulatorsList.parse(["--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "boot" : "asc simulators boot --udid ABCD-1234",
                "listSimulators" : "asc simulators list"
              },
              "displayRuntime" : "iOS 18.2",
              "id" : "ABCD-1234",
              "isBooted" : false,
              "name" : "iPhone 16 Pro",
              "runtime" : "com.apple.CoreSimulator.SimRuntime.iOS-18-2",
              "state" : "Shutdown"
            }
          ]
        }
        """)
    }

    @Test func `booted simulator shows shutdown and stream affordances`() async throws {
        let mockRepo = MockSimulatorRepository()
        given(mockRepo).listSimulators(filter: .any).willReturn([
            Simulator(
                id: "EFGH-5678",
                name: "iPhone 15",
                state: SimulatorState.booted,
                runtime: "com.apple.CoreSimulator.SimRuntime.iOS-17-5"
            ),
        ])

        let cmd = try SimulatorsList.parse(["--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "listSimulators" : "asc simulators list",
                "shutdown" : "asc simulators shutdown --udid EFGH-5678",
                "stream" : "asc simulators stream --udid EFGH-5678"
              },
              "displayRuntime" : "iOS 17.5",
              "id" : "EFGH-5678",
              "isBooted" : true,
              "name" : "iPhone 15",
              "runtime" : "com.apple.CoreSimulator.SimRuntime.iOS-17-5",
              "state" : "Booted"
            }
          ]
        }
        """)
    }

    @Test func `booted filter passes correct filter to repository`() async throws {
        let mockRepo = MockSimulatorRepository()
        given(mockRepo).listSimulators(filter: .value(.booted)).willReturn([])

        let cmd = try SimulatorsList.parse(["--booted", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [

          ]
        }
        """)
    }

    @Test func `table output includes all row fields`() async throws {
        let mockRepo = MockSimulatorRepository()
        given(mockRepo).listSimulators(filter: .any).willReturn([
            Simulator(
                id: "sim-1",
                name: "iPhone 16",
                state: SimulatorState.booted,
                runtime: "com.apple.CoreSimulator.SimRuntime.iOS-18-2"
            ),
        ])

        let cmd = try SimulatorsList.parse(["--output", "table"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output.contains("sim-1"))
        #expect(output.contains("iPhone 16"))
        #expect(output.contains("Booted"))
        #expect(output.contains("iOS 18.2"))
    }
}
