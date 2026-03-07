import Foundation
import Testing
@testable import Domain

@Suite
struct XcodeCloudWorkflowTests {

    @Test func `workflow carries product id`() {
        let workflow = MockRepositoryFactory.makeXcodeCloudWorkflow(id: "wf-1", productId: "prod-42")
        #expect(workflow.productId == "prod-42")
    }

    @Test func `workflow affordances include listBuildRuns always`() {
        let workflow = MockRepositoryFactory.makeXcodeCloudWorkflow(id: "wf-1", productId: "prod-1", isEnabled: false)
        #expect(workflow.affordances["listBuildRuns"] == "asc xcode-cloud builds list --workflow-id wf-1")
    }

    @Test func `workflow affordances include listWorkflows command`() {
        let workflow = MockRepositoryFactory.makeXcodeCloudWorkflow(id: "wf-1", productId: "prod-42")
        #expect(workflow.affordances["listWorkflows"] == "asc xcode-cloud workflows list --product-id prod-42")
    }

    @Test func `workflow affordances include startBuild only when enabled`() {
        let enabled = MockRepositoryFactory.makeXcodeCloudWorkflow(id: "wf-1", productId: "prod-1", isEnabled: true)
        let disabled = MockRepositoryFactory.makeXcodeCloudWorkflow(id: "wf-2", productId: "prod-1", isEnabled: false)
        #expect(enabled.affordances["startBuild"] == "asc xcode-cloud builds start --workflow-id wf-1")
        #expect(disabled.affordances["startBuild"] == nil)
    }

    @Test func `optional fields are omitted from json when nil`() throws {
        let workflow = XcodeCloudWorkflow(
            id: "wf-1", productId: "p-1", name: "Build",
            description: nil, isEnabled: true, isLockedForEditing: false, containerFilePath: nil
        )
        let data = try JSONEncoder().encode(workflow)
        let json = String(decoding: data, as: UTF8.self)
        #expect(!json.contains("description"))
        #expect(!json.contains("containerFilePath"))
    }

    @Test func `decode round-trip preserves all fields`() throws {
        let original = MockRepositoryFactory.makeXcodeCloudWorkflow(
            id: "wf-1", productId: "prod-1", name: "CI Build",
            description: "Runs on every commit", isEnabled: true, isLockedForEditing: false
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(XcodeCloudWorkflow.self, from: data)
        #expect(decoded.id == "wf-1")
        #expect(decoded.productId == "prod-1")
        #expect(decoded.name == "CI Build")
        #expect(decoded.description == "Runs on every commit")
        #expect(decoded.isEnabled == true)
        #expect(decoded.isLockedForEditing == false)
    }
}
