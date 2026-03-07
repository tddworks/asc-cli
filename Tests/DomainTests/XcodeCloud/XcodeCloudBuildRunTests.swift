import Foundation
import Testing
@testable import Domain

@Suite
struct XcodeCloudBuildRunTests {

    @Test func `build run carries workflow id`() {
        let run = MockRepositoryFactory.makeXcodeCloudBuildRun(id: "run-1", workflowId: "wf-42")
        #expect(run.workflowId == "wf-42")
    }

    @Test func `build run affordances include getBuildRun always`() {
        let run = MockRepositoryFactory.makeXcodeCloudBuildRun(id: "run-1", workflowId: "wf-1")
        #expect(run.affordances["getBuildRun"] == "asc xcode-cloud builds get --build-run-id run-1")
    }

    @Test func `build run affordances include listBuildRuns command`() {
        let run = MockRepositoryFactory.makeXcodeCloudBuildRun(id: "run-1", workflowId: "wf-42")
        #expect(run.affordances["listBuildRuns"] == "asc xcode-cloud builds list --workflow-id wf-42")
    }

    @Test func `execution progress semantic booleans`() {
        #expect(XcodeCloudBuildRunExecutionProgress.pending.isPending)
        #expect(!XcodeCloudBuildRunExecutionProgress.running.isPending)
        #expect(!XcodeCloudBuildRunExecutionProgress.complete.isPending)

        #expect(XcodeCloudBuildRunExecutionProgress.running.isRunning)
        #expect(!XcodeCloudBuildRunExecutionProgress.pending.isRunning)

        #expect(XcodeCloudBuildRunExecutionProgress.complete.isComplete)
        #expect(!XcodeCloudBuildRunExecutionProgress.running.isComplete)
    }

    @Test func `completion status semantic booleans`() {
        #expect(XcodeCloudBuildRunCompletionStatus.succeeded.isSucceeded)
        #expect(!XcodeCloudBuildRunCompletionStatus.failed.isSucceeded)

        #expect(XcodeCloudBuildRunCompletionStatus.failed.hasFailed)
        #expect(XcodeCloudBuildRunCompletionStatus.errored.hasFailed)
        #expect(!XcodeCloudBuildRunCompletionStatus.succeeded.hasFailed)
        #expect(!XcodeCloudBuildRunCompletionStatus.canceled.hasFailed)
    }

    @Test func `execution progress raw values match ASC API`() {
        #expect(XcodeCloudBuildRunExecutionProgress.pending.rawValue == "PENDING")
        #expect(XcodeCloudBuildRunExecutionProgress.running.rawValue == "RUNNING")
        #expect(XcodeCloudBuildRunExecutionProgress.complete.rawValue == "COMPLETE")
    }

    @Test func `completion status raw values match ASC API`() {
        #expect(XcodeCloudBuildRunCompletionStatus.succeeded.rawValue == "SUCCEEDED")
        #expect(XcodeCloudBuildRunCompletionStatus.failed.rawValue == "FAILED")
        #expect(XcodeCloudBuildRunCompletionStatus.errored.rawValue == "ERRORED")
        #expect(XcodeCloudBuildRunCompletionStatus.canceled.rawValue == "CANCELED")
        #expect(XcodeCloudBuildRunCompletionStatus.skipped.rawValue == "SKIPPED")
    }

    @Test func `optional fields are omitted from json when nil`() throws {
        let run = XcodeCloudBuildRun(
            id: "run-1", workflowId: "wf-1",
            number: nil, executionProgress: .pending,
            completionStatus: nil, startReason: nil,
            createdDate: nil, startedDate: nil, finishedDate: nil
        )
        let data = try JSONEncoder().encode(run)
        let json = String(decoding: data, as: UTF8.self)
        #expect(!json.contains("number"))
        #expect(!json.contains("completionStatus"))
        #expect(!json.contains("startReason"))
        #expect(!json.contains("createdDate"))
        #expect(!json.contains("startedDate"))
        #expect(!json.contains("finishedDate"))
    }

    @Test func `decode round-trip preserves all fields`() throws {
        let original = MockRepositoryFactory.makeXcodeCloudBuildRun(
            id: "run-1", workflowId: "wf-1", number: 42,
            executionProgress: .complete,
            completionStatus: .succeeded,
            startReason: .manual
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(XcodeCloudBuildRun.self, from: data)
        #expect(decoded.id == "run-1")
        #expect(decoded.workflowId == "wf-1")
        #expect(decoded.number == 42)
        #expect(decoded.executionProgress == .complete)
        #expect(decoded.completionStatus == .succeeded)
        #expect(decoded.startReason == .manual)
    }
}
