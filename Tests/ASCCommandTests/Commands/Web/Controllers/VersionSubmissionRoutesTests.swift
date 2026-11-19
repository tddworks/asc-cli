import Foundation
import Hummingbird
import HummingbirdTesting
import HummingbirdWebSocket
import Mockable
import NIOCore
import Testing
@testable import ASCCommand
@testable import ASCKit

@Suite
struct VersionSubmissionRoutesTests {
    private func versions(_ state: AppStoreVersionState) -> MockVersionRepository {
        let versions = MockVersionRepository()
        given(versions).getVersion(id: .value("v-1")).willReturn(
            AppStoreVersion(id: "v-1", appId: "app-1", versionString: "1.0", platform: .iOS, state: state)
        )
        return versions
    }

    private func submissions() -> MockSubmissionRepository {
        let submissions = MockSubmissionRepository()
        given(submissions).createSubmission(appId: .value("app-1"), platform: .value(.iOS))
            .willReturn(ReviewSubmission(id: "sub-1", appId: "app-1", platform: .iOS, state: .readyForReview))
        given(submissions).listSubmissionItems(submissionId: .value("sub-1")).willReturn([])
        given(submissions).addItem(submissionId: .value("sub-1"), target: .value(.appStoreVersion("v-1")))
            .willReturn(ReviewSubmissionItem(id: "item-1", submissionId: "sub-1", state: .readyForReview, linkedResourceId: "v-1"))
        given(submissions).submit(submissionId: .value("sub-1"))
            .willReturn(ReviewSubmission(id: "sub-1", appId: "app-1", platform: .iOS, state: .waitingForReview))
        return submissions
    }

    private func post(versions: MockVersionRepository, submissions: MockSubmissionRepository) async throws -> String {
        let router = Router(context: BasicWebSocketRequestContext.self)
        let planner = SubmissionPlanner(
            iapRepo: MockInAppPurchaseRepository(), groupRepo: MockSubscriptionGroupRepository(),
            subscriptionRepo: MockSubscriptionRepository(), productVersionRepo: MockProductVersionRepository()
        )
        VersionSubmissionController(submissionRepo: submissions, versionRepo: versions, planner: planner)
            .addRoutes(to: router.group("/api/v1"))
        return try await Application(router: router).test(.router) { client in
            try await client.execute(uri: "/api/v1/versions/v-1/submit", method: .post) { String(buffer: $0.body) }
        }
    }

    @Test func `should answer with the submission waiting for review after submitting a version over REST`() async throws {
        let response = try await post(versions: versions(.prepareForSubmission), submissions: submissions())

        let json = try #require(try JSONSerialization.jsonObject(with: Data(response.utf8)) as? [String: Any])
        let submission = try #require(json["data"] as? [String: Any] ?? (json["data"] as? [[String: Any]])?.first)
        #expect(submission["id"] as? String == "sub-1")
        #expect(submission["state"] as? String == "WAITING_FOR_REVIEW")
    }

    @Test func `should send nothing to Apple when the version is already on sale`() async throws {
        let submissions = MockSubmissionRepository()

        let response = try await post(versions: versions(.readyForSale), submissions: submissions)

        #expect(response.contains("Version 1.0 can't go to review while it is Ready for Sale."))
        verify(submissions).createSubmission(appId: .any, platform: .any).called(0)
    }
}
