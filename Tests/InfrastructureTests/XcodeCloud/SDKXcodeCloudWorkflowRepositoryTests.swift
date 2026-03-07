@preconcurrency import AppStoreConnect_Swift_SDK
import Testing
@testable import Infrastructure
@testable import Domain

@Suite
struct SDKXcodeCloudWorkflowRepositoryTests {

    @Test func `listWorkflows maps name and isEnabled from SDK response`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(CiWorkflowsResponse(
            data: [
                CiWorkflow(
                    type: .ciWorkflows,
                    id: "wf-1",
                    attributes: .init(name: "CI Build", description: "Main CI workflow", isEnabled: true, isLockedForEditing: false, containerFilePath: "App.xcodeproj"),
                    relationships: .init(
                        product: .init(data: .init(type: .ciProducts, id: "prod-1"))
                    )
                ),
            ],
            links: .init(this: "")
        ))

        let repo = SDKXcodeCloudWorkflowRepository(client: stub)
        let result = try await repo.listWorkflows(productId: "prod-1")

        #expect(result[0].id == "wf-1")
        #expect(result[0].name == "CI Build")
        #expect(result[0].description == "Main CI workflow")
        #expect(result[0].isEnabled == true)
        #expect(result[0].isLockedForEditing == false)
        #expect(result[0].containerFilePath == "App.xcodeproj")
    }

    @Test func `listWorkflows injects productId into each workflow`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(CiWorkflowsResponse(
            data: [
                CiWorkflow(
                    type: .ciWorkflows,
                    id: "wf-1",
                    attributes: .init(name: "CI Build", isEnabled: true, isLockedForEditing: false)
                ),
            ],
            links: .init(this: "")
        ))

        let repo = SDKXcodeCloudWorkflowRepository(client: stub)
        let result = try await repo.listWorkflows(productId: "prod-42")

        #expect(result[0].productId == "prod-42")
    }
}
