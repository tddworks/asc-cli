import Foundation
import Testing
@testable import ASCKit

/// Test-only type to avoid polluting the global AffordanceRegistry for real domain types.
private struct StubModel: AffordanceProviding {
    var affordances: [String: String] { [:] }
}

@Suite(.serialized)
struct AffordanceRegistryTests {

    init() {
        AffordanceRegistry.reset()
    }

    @Test func `register and retrieve affordances for a model type`() {
        AffordanceRegistry.register(StubModel.self) { id, _ in
            [Affordance(key: "test", command: "test", action: "run", params: ["id": id])]
        }
        let affordances = AffordanceRegistry.affordances(for: StubModel.self, id: "123")
        #expect(affordances.count == 1)
        #expect(affordances[0].key == "test")
        #expect(affordances[0].cliCommand == "asc test run --id 123")
    }

    @Test func `returns empty when no providers registered for type`() {
        struct UnknownModel: AffordanceProviding {
            var affordances: [String: String] { [:] }
        }
        let affordances = AffordanceRegistry.affordances(for: UnknownModel.self, id: "x")
        #expect(affordances.isEmpty)
    }

    @Test func `multiple providers merge affordances`() {
        AffordanceRegistry.register(StubModel.self) { id, _ in
            [Affordance(key: "action1", command: "cmd1", action: "run", params: ["id": id])]
        }
        AffordanceRegistry.register(StubModel.self) { id, _ in
            [Affordance(key: "action2", command: "cmd2", action: "run", params: ["id": id])]
        }
        let affordances = AffordanceRegistry.affordances(for: StubModel.self, id: "abc")
        #expect(affordances.count == 2)
        #expect(affordances.contains { $0.key == "action1" })
        #expect(affordances.contains { $0.key == "action2" })
    }

    @Test func `provider receives properties and returns conditional affordances`() {
        AffordanceRegistry.register(StubModel.self) { id, props in
            guard props["isBooted"] == "true" else { return [] }
            return [Affordance(key: "stream", command: "simulators", action: "stream", params: ["udid": id])]
        }
        let booted = AffordanceRegistry.affordances(for: StubModel.self, id: "u1", properties: ["isBooted": "true"])
        let shutdown = AffordanceRegistry.affordances(for: StubModel.self, id: "u2", properties: ["isBooted": "false"])
        #expect(booted.count == 1)
        #expect(booted[0].cliCommand == "asc simulators stream --udid u1")
        #expect(shutdown.isEmpty)
    }

    @Test func `structured affordance renders to REST link`() {
        AffordanceRegistry.register(StubModel.self) { id, _ in
            [Affordance(key: "stream", command: "simulators", action: "stream", params: ["udid": id])]
        }
        let affordances = AffordanceRegistry.affordances(for: StubModel.self, id: "u1")
        let link = affordances[0].restLink
        #expect(link.method == "POST")
        #expect(link.href.contains("simulators"))
    }

    // MARK: - Plugin affordances merged into a real domain model
    //
    // These live here, not in SimulatorTests, on purpose. AffordanceRegistry is
    // process-global mutable state, and `.serialized` only orders tests *within*
    // a suite — separate suites still run concurrently. Any test that registers a
    // provider must therefore share this one serialized suite, or `init()`'s reset
    // will wipe its registration mid-test. Register from anywhere else and you
    // reintroduce a flake that only shows up under parallel scheduling.

    @Test func `booted simulator affordances include plugin stream when registered`() {
        AffordanceRegistry.register(Simulator.self) { id, props in
            guard props["isBooted"] == "true" else { return [] }
            return [Affordance(key: "stream", command: "simulators", action: "stream", params: ["udid": id])]
        }
        let sim = MockRepositoryFactory.makeSimulator(id: "SIM-1", state: .booted)
        // Plugin affordance should be merged into the model's own affordances
        #expect(sim.affordances["stream"] == "asc simulators stream --udid SIM-1")
        // Model's own affordances still present
        #expect(sim.affordances["shutdown"] == "asc simulators shutdown --udid SIM-1")
    }

    @Test func `shutdown simulator does not get stream affordance from plugin`() {
        AffordanceRegistry.register(Simulator.self) { id, props in
            guard props["isBooted"] == "true" else { return [] }
            return [Affordance(key: "stream", command: "simulators", action: "stream", params: ["udid": id])]
        }
        let sim = MockRepositoryFactory.makeSimulator(id: "SIM-2", state: .shutdown)
        #expect(sim.affordances["stream"] == nil)
    }

    @Test func `booted simulator apiLinks include plugin stream when registered`() {
        AffordanceRegistry.register(Simulator.self) { id, props in
            guard props["isBooted"] == "true" else { return [] }
            return [Affordance(key: "stream", command: "simulators", action: "stream", params: ["udid": id])]
        }
        let sim = MockRepositoryFactory.makeSimulator(id: "SIM-1", state: .booted)
        // Plugin affordance should appear in REST links too
        #expect(sim.apiLinks["stream"] != nil)
        #expect(sim.apiLinks["stream"]?.method == "POST")
    }
}
