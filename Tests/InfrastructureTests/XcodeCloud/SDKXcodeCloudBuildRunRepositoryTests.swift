@preconcurrency import AppStoreConnect_Swift_SDK
import Testing
@testable import Infrastructure
@testable import Domain

@Suite
struct SDKXcodeCloudBuildRunRepositoryTests {

    private func makeSDKBuildRun(
        id: String = "run-1",
        number: Int? = 5,
        executionProgress: CiExecutionProgress = .complete,
        completionStatus: CiCompletionStatus? = .succeeded,
        startReason: AppStoreConnect_Swift_SDK.CiBuildRun.Attributes.StartReason? = .manual
    ) -> AppStoreConnect_Swift_SDK.CiBuildRun {
        AppStoreConnect_Swift_SDK.CiBuildRun(
            type: .ciBuildRuns,
            id: id,
            attributes: .init(
                number: number,
                executionProgress: executionProgress,
                completionStatus: completionStatus,
                startReason: startReason
            )
        )
    }

    @Test func `listBuildRuns maps executionProgress and completionStatus`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(CiBuildRunsResponse(
            data: [makeSDKBuildRun(id: "run-1", number: 7, executionProgress: .complete, completionStatus: .succeeded)],
            links: .init(this: "")
        ))

        let repo = SDKXcodeCloudBuildRunRepository(client: stub)
        let result = try await repo.listBuildRuns(workflowId: "wf-1")

        #expect(result[0].id == "run-1")
        #expect(result[0].number == 7)
        #expect(result[0].executionProgress == .complete)
        #expect(result[0].completionStatus == .succeeded)
    }

    @Test func `listBuildRuns injects workflowId into each build run`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(CiBuildRunsResponse(
            data: [makeSDKBuildRun(id: "run-1")],
            links: .init(this: "")
        ))

        let repo = SDKXcodeCloudBuildRunRepository(client: stub)
        let result = try await repo.listBuildRuns(workflowId: "wf-99")

        #expect(result[0].workflowId == "wf-99")
    }

    @Test func `getBuildRun maps single build run`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(CiBuildRunResponse(
            data: makeSDKBuildRun(id: "run-42", number: 42, executionProgress: .running, completionStatus: nil),
            links: .init(this: "")
        ))

        let repo = SDKXcodeCloudBuildRunRepository(client: stub)
        let result = try await repo.getBuildRun(id: "run-42")

        #expect(result.id == "run-42")
        #expect(result.number == 42)
        #expect(result.executionProgress == .running)
        #expect(result.completionStatus == nil)
    }

    @Test func `startBuildRun posts to ciBuildRuns and returns new run`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(CiBuildRunResponse(
            data: makeSDKBuildRun(id: "run-new", number: nil, executionProgress: .pending, completionStatus: nil, startReason: .manual),
            links: .init(this: "")
        ))

        let repo = SDKXcodeCloudBuildRunRepository(client: stub)
        let result = try await repo.startBuildRun(workflowId: "wf-1", clean: false)

        #expect(result.id == "run-new")
        #expect(result.executionProgress == .pending)
        #expect(result.workflowId == "wf-1")
    }
}
