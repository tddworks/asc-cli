@preconcurrency import AppStoreConnect_Swift_SDK
import Domain

public struct SDKXcodeCloudBuildRunRepository: XcodeCloudBuildRunRepository, @unchecked Sendable {
    private let client: any APIClient

    public init(client: any APIClient) {
        self.client = client
    }

    public func listBuildRuns(workflowId: String) async throws -> [XcodeCloudBuildRun] {
        let request = APIEndpoint.v1.ciWorkflows.id(workflowId).buildRuns.get()
        let response = try await client.request(request)
        return response.data.map { mapBuildRun($0, workflowId: workflowId) }
    }

    public func getBuildRun(id: String) async throws -> XcodeCloudBuildRun {
        let request = APIEndpoint.v1.ciBuildRuns.id(id).get()
        let response = try await client.request(request)
        let workflowId = response.data.relationships?.workflow?.data?.id ?? ""
        return mapBuildRun(response.data, workflowId: workflowId)
    }

    public func startBuildRun(workflowId: String, clean: Bool) async throws -> XcodeCloudBuildRun {
        let request = APIEndpoint.v1.ciBuildRuns.post(
            CiBuildRunCreateRequest(data: .init(
                type: .ciBuildRuns,
                attributes: .init(isClean: clean),
                relationships: .init(
                    workflow: .init(data: .init(type: .ciWorkflows, id: workflowId))
                )
            ))
        )
        let response = try await client.request(request)
        return mapBuildRun(response.data, workflowId: workflowId)
    }

    private func mapBuildRun(_ sdk: AppStoreConnect_Swift_SDK.CiBuildRun, workflowId: String) -> XcodeCloudBuildRun {
        let progress: XcodeCloudBuildRunExecutionProgress
        switch sdk.attributes?.executionProgress {
        case .pending: progress = .pending
        case .running: progress = .running
        case .complete: progress = .complete
        case nil: progress = .pending
        }

        let status: XcodeCloudBuildRunCompletionStatus?
        switch sdk.attributes?.completionStatus {
        case .succeeded: status = .succeeded
        case .failed: status = .failed
        case .errored: status = .errored
        case .canceled: status = .canceled
        case .skipped: status = .skipped
        case nil: status = nil
        }

        let startReason: XcodeCloudBuildRunStartReason?
        switch sdk.attributes?.startReason {
        case .gitRefChange: startReason = .gitRefChange
        case .manual: startReason = .manual
        case .manualRebuild: startReason = .manualRebuild
        case .pullRequestOpen: startReason = .pullRequestOpen
        case .pullRequestUpdate: startReason = .pullRequestUpdate
        case .schedule: startReason = .schedule
        case nil: startReason = nil
        }

        return XcodeCloudBuildRun(
            id: sdk.id,
            workflowId: workflowId,
            number: sdk.attributes?.number,
            executionProgress: progress,
            completionStatus: status,
            startReason: startReason,
            createdDate: sdk.attributes?.createdDate,
            startedDate: sdk.attributes?.startedDate,
            finishedDate: sdk.attributes?.finishedDate
        )
    }
}
