import Foundation
import Testing
@testable import Domain

@Suite
struct SimulatorTests {

    @Test func `simulator carries all fields`() {
        let sim = MockRepositoryFactory.makeSimulator(
            id: "ABCD-1234",
            name: "iPhone 16 Pro",
            state: .shutdown,
            runtime: "com.apple.CoreSimulator.SimRuntime.iOS-18-2"
        )
        #expect(sim.id == "ABCD-1234")
        #expect(sim.name == "iPhone 16 Pro")
        #expect(sim.state == .shutdown)
        #expect(sim.runtime == "com.apple.CoreSimulator.SimRuntime.iOS-18-2")
    }

    @Test func `simulator isBooted is true when state is booted`() {
        let sim = MockRepositoryFactory.makeSimulator(state: .booted)
        #expect(sim.isBooted == true)
    }

    @Test func `simulator isBooted is false when state is shutdown`() {
        let sim = MockRepositoryFactory.makeSimulator(state: .shutdown)
        #expect(sim.isBooted == false)
    }

    @Test func `simulator displayRuntime converts runtime identifier to human readable`() {
        let sim = MockRepositoryFactory.makeSimulator(
            runtime: "com.apple.CoreSimulator.SimRuntime.iOS-18-2"
        )
        #expect(sim.displayRuntime == "iOS 18.2")
    }

    @Test func `simulator displayRuntime handles unknown format gracefully`() {
        let sim = MockRepositoryFactory.makeSimulator(runtime: "custom-runtime")
        #expect(sim.displayRuntime == "custom-runtime")
    }

    @Test func `shutdown simulator affordances include boot`() {
        let sim = MockRepositoryFactory.makeSimulator(id: "ABC-123", state: .shutdown)
        #expect(sim.affordances["boot"] == "asc simulators boot --udid ABC-123")
        #expect(sim.affordances["shutdown"] == nil)
        #expect(sim.affordances["stream"] == nil)
    }

    @Test func `booted simulator affordances include shutdown and stream`() {
        let sim = MockRepositoryFactory.makeSimulator(id: "ABC-123", state: .booted)
        #expect(sim.affordances["shutdown"] == "asc simulators shutdown --udid ABC-123")
        #expect(sim.affordances["stream"] == "asc simulators stream --udid ABC-123")
        #expect(sim.affordances["boot"] == nil)
    }

    @Test func `all simulator affordances include listSimulators`() {
        let shutdown = MockRepositoryFactory.makeSimulator(state: .shutdown)
        let booted = MockRepositoryFactory.makeSimulator(state: .booted)
        #expect(shutdown.affordances["listSimulators"] == "asc simulators list")
        #expect(booted.affordances["listSimulators"] == "asc simulators list")
    }

    @Test func `simulator state semantic booleans`() {
        #expect(SimulatorState.booted.isBooted == true)
        #expect(SimulatorState.shutdown.isBooted == false)
        #expect(SimulatorState.shuttingDown.isBooted == false)
        #expect(SimulatorState.creating.isBooted == false)

        #expect(SimulatorState.booted.isAvailable == true)
        #expect(SimulatorState.shutdown.isAvailable == true)
        #expect(SimulatorState.shuttingDown.isAvailable == false)
        #expect(SimulatorState.creating.isAvailable == false)
    }

    @Test func `simulator state raw values match simctl output`() {
        #expect(SimulatorState.booted.rawValue == "Booted")
        #expect(SimulatorState.shutdown.rawValue == "Shutdown")
        #expect(SimulatorState.shuttingDown.rawValue == "Shutting Down")
        #expect(SimulatorState.creating.rawValue == "Creating")
    }

    @Test func `simulator state initializes from simctl string`() {
        #expect(SimulatorState(rawValue: "Booted") == .booted)
        #expect(SimulatorState(rawValue: "Shutdown") == .shutdown)
        #expect(SimulatorState(rawValue: "Unknown") == nil)
    }

    @Test func `simulator omits nil fields in json encoding`() throws {
        let sim = MockRepositoryFactory.makeSimulator(
            id: "sim-1",
            name: "iPhone 16",
            state: .booted,
            runtime: "com.apple.CoreSimulator.SimRuntime.iOS-18-2"
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(sim)
        let json = String(data: data, encoding: .utf8)!
        #expect(json.contains("\"id\""))
        #expect(json.contains("\"name\""))
        #expect(json.contains("\"state\""))
        #expect(json.contains("\"isBooted\""))
        #expect(json.contains("\"displayRuntime\""))
    }
}
