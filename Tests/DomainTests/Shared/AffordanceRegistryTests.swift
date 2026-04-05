import Foundation
import Testing
@testable import Domain

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
}
