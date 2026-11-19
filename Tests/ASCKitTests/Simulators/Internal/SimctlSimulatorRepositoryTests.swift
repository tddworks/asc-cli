import Testing
@testable import ASCKit

@Suite
struct SimctlSimulatorRepositoryTests {

    // MARK: - listSimulators

    @Test func `listSimulators parses simctl json with iOS devices`() async throws {
        let json = """
        {
          "devices": {
            "com.apple.CoreSimulator.SimRuntime.iOS-18-2": [
              { "udid": "AAA-111", "name": "iPhone 16 Pro Max", "state": "Booted" },
              { "udid": "BBB-222", "name": "iPhone 15", "state": "Shutdown" }
            ],
            "com.apple.CoreSimulator.SimRuntime.watchOS-11-2": [
              { "udid": "CCC-333", "name": "Apple Watch", "state": "Shutdown" }
            ]
          }
        }
        """
        let repo = SimctlSimulatorRepository(shellRunner: StubShellRunner(stdout: json))
        let sims = try await repo.listSimulators(filter: .available)

        // Only iOS devices, watchOS filtered out
        #expect(sims.count == 2)
        // Booted first
        #expect(sims[0].id == "AAA-111")
        #expect(sims[0].name == "iPhone 16 Pro Max")
        #expect(sims[0].state == .booted)
        #expect(sims[0].runtime == "com.apple.CoreSimulator.SimRuntime.iOS-18-2")
        #expect(sims[0].isBooted == true)
        // Shutdown second
        #expect(sims[1].id == "BBB-222")
        #expect(sims[1].name == "iPhone 15")
        #expect(sims[1].state == .shutdown)
        #expect(sims[1].isBooted == false)
    }

    @Test func `listSimulators filters out non-iOS runtimes`() async throws {
        let json = """
        {
          "devices": {
            "com.apple.CoreSimulator.SimRuntime.tvOS-18-2": [
              { "udid": "TV-1", "name": "Apple TV", "state": "Shutdown" }
            ],
            "com.apple.CoreSimulator.SimRuntime.visionOS-2-2": [
              { "udid": "VP-1", "name": "Apple Vision Pro", "state": "Shutdown" }
            ]
          }
        }
        """
        let repo = SimctlSimulatorRepository(shellRunner: StubShellRunner(stdout: json))
        let sims = try await repo.listSimulators(filter: .all)

        #expect(sims.isEmpty)
    }

    @Test func `listSimulators skips devices with unknown state`() async throws {
        let json = """
        {
          "devices": {
            "com.apple.CoreSimulator.SimRuntime.iOS-18-2": [
              { "udid": "AAA-111", "name": "iPhone 16", "state": "Booted" },
              { "udid": "BBB-222", "name": "iPhone 15", "state": "SomeWeirdState" }
            ]
          }
        }
        """
        let repo = SimctlSimulatorRepository(shellRunner: StubShellRunner(stdout: json))
        let sims = try await repo.listSimulators(filter: .all)

        #expect(sims.count == 1)
        #expect(sims[0].id == "AAA-111")
    }

    @Test func `listSimulators sorts booted first then by name`() async throws {
        let json = """
        {
          "devices": {
            "com.apple.CoreSimulator.SimRuntime.iOS-18-2": [
              { "udid": "C", "name": "Zebra Phone", "state": "Shutdown" },
              { "udid": "A", "name": "Alpha Phone", "state": "Booted" },
              { "udid": "B", "name": "Beta Phone", "state": "Shutdown" }
            ]
          }
        }
        """
        let repo = SimctlSimulatorRepository(shellRunner: StubShellRunner(stdout: json))
        let sims = try await repo.listSimulators(filter: .all)

        #expect(sims.map(\.name) == ["Alpha Phone", "Beta Phone", "Zebra Phone"])
        #expect(sims[0].isBooted == true)
    }

    @Test func `listSimulators returns empty for invalid json`() async throws {
        let repo = SimctlSimulatorRepository(shellRunner: StubShellRunner(stdout: "not json"))
        do {
            _ = try await repo.listSimulators(filter: .all)
            Issue.record("Expected error")
        } catch {
            // Expected: JSON decoding error
        }
    }

    @Test func `listSimulators handles empty json object`() async throws {
        let repo = SimctlSimulatorRepository(shellRunner: StubShellRunner(stdout: "{\"devices\":{}}"))
        let sims = try await repo.listSimulators(filter: .all)
        #expect(sims.isEmpty)
    }

    @Test func `listSimulators uses booted filter arguments`() async throws {
        let json = """
        { "devices": { "com.apple.CoreSimulator.SimRuntime.iOS-18-2": [] } }
        """
        let runner = RecordingShellRunner(stdout: json)
        let repo = SimctlSimulatorRepository(shellRunner: runner)
        _ = try await repo.listSimulators(filter: .booted)

        #expect(runner.lastArguments?.contains("booted") == true)
    }

    @Test func `listSimulators uses available filter arguments`() async throws {
        let json = """
        { "devices": { "com.apple.CoreSimulator.SimRuntime.iOS-18-2": [] } }
        """
        let runner = RecordingShellRunner(stdout: json)
        let repo = SimctlSimulatorRepository(shellRunner: runner)
        _ = try await repo.listSimulators(filter: .available)

        #expect(runner.lastArguments?.contains("available") == true)
    }

    // MARK: - bootSimulator / shutdownSimulator

    @Test func `bootSimulator calls xcrun simctl boot with udid`() async throws {
        let runner = RecordingShellRunner(stdout: "")
        let repo = SimctlSimulatorRepository(shellRunner: runner)
        try await repo.bootSimulator(udid: "TEST-UDID")

        #expect(runner.lastCommand == "xcrun")
        #expect(runner.lastArguments?.contains("boot") == true)
        #expect(runner.lastArguments?.contains("TEST-UDID") == true)
    }

    @Test func `shutdownSimulator calls xcrun simctl shutdown with udid`() async throws {
        let runner = RecordingShellRunner(stdout: "")
        let repo = SimctlSimulatorRepository(shellRunner: runner)
        try await repo.shutdownSimulator(udid: "TEST-UDID")

        #expect(runner.lastCommand == "xcrun")
        #expect(runner.lastArguments?.contains("shutdown") == true)
        #expect(runner.lastArguments?.contains("TEST-UDID") == true)
    }

    @Test func `bootSimulator throws when shell fails`() async throws {
        let repo = SimctlSimulatorRepository(shellRunner: StubShellRunner(error: ShellRunnerError.executionFailed(exitCode: 1, stderr: "Already booted")))
        do {
            try await repo.bootSimulator(udid: "X")
            Issue.record("Expected error")
        } catch {
            // Expected
        }
    }
}

// MARK: - Recording Shell Runner

private final class RecordingShellRunner: ShellRunner, @unchecked Sendable {
    let stdout: String
    var lastCommand: String?
    var lastArguments: [String]?

    init(stdout: String) {
        self.stdout = stdout
    }

    func run(command: String, arguments: [String], environment: [String: String]?) async throws -> String {
        lastCommand = command
        lastArguments = arguments
        return stdout
    }
}
