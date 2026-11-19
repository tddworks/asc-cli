import Foundation
import Testing
@testable import ASCKit

@Suite
struct AppStoreVersionExperimentTests {

    @Test func `experiment carries appId, name, platform and traffic proportion`() {
        let exp = MockRepositoryFactory.makeExperiment(id: "exp-1", appId: "app-1", name: "Icon test", trafficProportion: 30)
        #expect(exp.appId == "app-1")
        #expect(exp.name == "Icon test")
        #expect(exp.platform == .iOS)
        #expect(exp.trafficProportion == 30)
    }

    @Test func `experiment state is editable before submission, ready for review, or rejected`() {
        #expect(AppStoreVersionExperimentState.prepareForSubmission.isEditable == true)
        #expect(AppStoreVersionExperimentState.readyForReview.isEditable == true)
        #expect(AppStoreVersionExperimentState.rejected.isEditable == true)
        #expect(AppStoreVersionExperimentState.waitingForReview.isEditable == false)
        #expect(AppStoreVersionExperimentState.inReview.isEditable == false)
        #expect(AppStoreVersionExperimentState.accepted.isEditable == false)
        #expect(AppStoreVersionExperimentState.approved.isEditable == false)
        #expect(AppStoreVersionExperimentState.completed.isEditable == false)
        #expect(AppStoreVersionExperimentState.stopped.isEditable == false)
    }

    @Test func `experiment state is pending review while waiting for or in review`() {
        #expect(AppStoreVersionExperimentState.waitingForReview.isPendingReview == true)
        #expect(AppStoreVersionExperimentState.inReview.isPendingReview == true)
        #expect(AppStoreVersionExperimentState.approved.isPendingReview == false)
    }

    @Test func `experiment state is approved when accepted or approved`() {
        #expect(AppStoreVersionExperimentState.accepted.isApproved == true)
        #expect(AppStoreVersionExperimentState.approved.isApproved == true)
        #expect(AppStoreVersionExperimentState.readyForReview.isApproved == false)
    }

    @Test func `experiment state is finished when completed or stopped`() {
        #expect(AppStoreVersionExperimentState.completed.isFinished == true)
        #expect(AppStoreVersionExperimentState.stopped.isFinished == true)
        #expect(AppStoreVersionExperimentState.approved.isFinished == false)
    }

    @Test func `experiment is running when approved and started but not ended`() {
        let running = MockRepositoryFactory.makeExperiment(state: .approved, startDate: "2026-09-01T00:00:00Z")
        #expect(running.isRunning == true)
        #expect(running.canStart == false)

        let notStarted = MockRepositoryFactory.makeExperiment(state: .approved)
        #expect(notStarted.isRunning == false)
        #expect(notStarted.canStart == true)

        let ended = MockRepositoryFactory.makeExperiment(state: .completed, startDate: "2026-09-01T00:00:00Z", endDate: "2026-09-20T00:00:00Z")
        #expect(ended.isRunning == false)
        #expect(ended.canStart == false)
    }

    @Test func `editable experiment offers treatments, update and delete`() {
        let exp = MockRepositoryFactory.makeExperiment(id: "exp-1", appId: "app-1", state: .prepareForSubmission)
        #expect(exp.affordances["listSiblings"] == "asc experiments list --app-id app-1")
        #expect(exp.affordances["listTreatments"] == "asc experiment-treatments list --experiment-id exp-1")
        #expect(exp.affordances["createTreatment"] == "asc experiment-treatments create --experiment-id exp-1 --name <name>")
        #expect(exp.affordances["update"] == "asc experiments update --experiment-id exp-1")
        #expect(exp.affordances["delete"] == "asc experiments delete --experiment-id exp-1")
        #expect(exp.affordances["start"] == nil)
        #expect(exp.affordances["stop"] == nil)
    }

    @Test func `approved but unstarted experiment offers start only`() {
        let exp = MockRepositoryFactory.makeExperiment(id: "exp-1", appId: "app-1", state: .approved)
        #expect(exp.affordances["start"] == "asc experiments start --experiment-id exp-1")
        #expect(exp.affordances["stop"] == nil)
        #expect(exp.affordances["update"] == nil)
        #expect(exp.affordances["delete"] == nil)
        #expect(exp.affordances["createTreatment"] == nil)
    }

    @Test func `running experiment offers stop only`() {
        let exp = MockRepositoryFactory.makeExperiment(id: "exp-1", appId: "app-1", state: .approved, startDate: "2026-09-01T00:00:00Z")
        #expect(exp.affordances["stop"] == "asc experiments stop --experiment-id exp-1")
        #expect(exp.affordances["start"] == nil)
        #expect(exp.affordances["update"] == nil)
        #expect(exp.affordances["delete"] == nil)
    }

    @Test func `experiment in review offers no mutations`() {
        let exp = MockRepositoryFactory.makeExperiment(id: "exp-1", appId: "app-1", state: .inReview)
        #expect(exp.affordances["update"] == nil)
        #expect(exp.affordances["delete"] == nil)
        #expect(exp.affordances["start"] == nil)
        #expect(exp.affordances["stop"] == nil)
        #expect(exp.affordances["listTreatments"] == "asc experiment-treatments list --experiment-id exp-1")
    }

    @Test func `experiment apiLinks resolve to REST paths`() {
        let exp = MockRepositoryFactory.makeExperiment(id: "exp-1", appId: "app-1", state: .prepareForSubmission)
        #expect(exp.apiLinks["listSiblings"]?.href == "/api/v1/apps/app-1/experiments")
        #expect(exp.apiLinks["listTreatments"]?.href == "/api/v1/experiments/exp-1/experiment-treatments")
        #expect(exp.apiLinks["update"]?.href == "/api/v1/experiments/exp-1")
        #expect(exp.apiLinks["update"]?.method == "PATCH")
        #expect(exp.apiLinks["delete"]?.method == "DELETE")
    }

    @Test func `experiment omits nil dates and control version from JSON`() throws {
        let exp = MockRepositoryFactory.makeExperiment(id: "exp-1", appId: "app-1")
        let json = String(decoding: try JSONEncoder().encode(exp), as: UTF8.self)
        #expect(!json.contains("startDate"))
        #expect(!json.contains("endDate"))
        #expect(!json.contains("latestControlVersionId"))
    }

    @Test func `experiment table row shows name, platform, traffic and state`() {
        let exp = MockRepositoryFactory.makeExperiment(id: "exp-1", appId: "app-1", name: "Icon test", trafficProportion: 30, state: .approved)
        #expect(AppStoreVersionExperiment.tableHeaders == ["ID", "Name", "Platform", "Traffic %", "State", "Started"])
        #expect(exp.tableRow == ["exp-1", "Icon test", "iOS", "30", "APPROVED", "-"])
    }
}
