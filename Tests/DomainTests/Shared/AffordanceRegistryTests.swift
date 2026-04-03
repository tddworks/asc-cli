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
            ["test": "asc test --id \(id)"]
        }
        let affordances = AffordanceRegistry.affordances(for: StubModel.self, id: "123")
        #expect(affordances["test"] == "asc test --id 123")
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
            ["action1": "cmd1 --id \(id)"]
        }
        AffordanceRegistry.register(StubModel.self) { id, _ in
            ["action2": "cmd2 --id \(id)"]
        }
        let affordances = AffordanceRegistry.affordances(for: StubModel.self, id: "abc")
        #expect(affordances["action1"] == "cmd1 --id abc")
        #expect(affordances["action2"] == "cmd2 --id abc")
    }

    @Test func `later provider overrides earlier for same key`() {
        AffordanceRegistry.register(StubModel.self) { _, _ in
            ["key": "old"]
        }
        AffordanceRegistry.register(StubModel.self) { _, _ in
            ["key": "new"]
        }
        let affordances = AffordanceRegistry.affordances(for: StubModel.self, id: "x")
        #expect(affordances["key"] == "new")
    }

    @Test func `provider receives properties`() {
        AffordanceRegistry.register(StubModel.self) { id, props in
            if props["isBooted"] == "true" {
                return ["stream": "asc stream --udid \(id)"]
            }
            return [:]
        }
        let booted = AffordanceRegistry.affordances(for: StubModel.self, id: "u1", properties: ["isBooted": "true"])
        let shutdown = AffordanceRegistry.affordances(for: StubModel.self, id: "u2", properties: ["isBooted": "false"])
        #expect(booted["stream"] == "asc stream --udid u1")
        #expect(shutdown["stream"] == nil)
    }
}
