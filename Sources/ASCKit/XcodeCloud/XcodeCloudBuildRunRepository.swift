import Mockable

@Mockable
public protocol XcodeCloudBuildRunRepository: Sendable {
    func listBuildRuns(workflowId: String) async throws -> [XcodeCloudBuildRun]
    func getBuildRun(id: String) async throws -> XcodeCloudBuildRun
    func startBuildRun(workflowId: String, clean: Bool) async throws -> XcodeCloudBuildRun
}
