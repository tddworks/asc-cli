import Mockable
import Testing
@testable import ASCCommand
@testable import ASCKit

@Suite
struct VersionsSubmitTests {

    private func draftThenSubmitted() -> MockSubmissionRepository {
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

    @Test func `should show the submission waiting for review after submitting a version`() async throws {
        let cmd = try VersionsSubmit.parse(["--version-id", "v-1", "--pretty"])
        let output = try await cmd.execute(versionRepo: appVersionRepo(), submissionRepo: draftThenSubmitted())

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "getSubmission" : "asc review-submissions get --submission-id sub-1",
                "listItems" : "asc review-submissions items list --submission-id sub-1",
                "listVersions" : "asc versions list --app-id app-1"
              },
              "appId" : "app-1",
              "id" : "sub-1",
              "platform" : "IOS",
              "state" : "WAITING_FOR_REVIEW"
            }
          ]
        }
        """)
    }

    @Test func `should refuse to submit a version that is already on sale`() async throws {
        let versions = MockVersionRepository()
        given(versions).getVersion(id: .value("v-1")).willReturn(
            AppStoreVersion(id: "v-1", appId: "app-1", versionString: "1.0", platform: .iOS, state: .readyForSale)
        )
        let cmd = try VersionsSubmit.parse(["--version-id", "v-1"])

        await #expect(throws: ReviewSubmissionError.versionNotEditable(versionString: "1.0", state: .readyForSale)) {
            try await cmd.execute(versionRepo: versions, submissionRepo: MockSubmissionRepository())
        }
    }

    // MARK: - --with-products

    private func planner(iapRepo: MockInAppPurchaseRepository, versionRepo: MockProductVersionRepository) -> SubmissionPlanner {
        let groups = MockSubscriptionGroupRepository()
        given(groups).listSubscriptionGroups(appId: .any, limit: .any).willReturn(PaginatedResponse(data: []))
        return SubmissionPlanner(iapRepo: iapRepo, groupRepo: groups,
                                 subscriptionRepo: MockSubscriptionRepository(), productVersionRepo: versionRepo)
    }

    private func readyLifetimeIAP() -> (MockInAppPurchaseRepository, MockProductVersionRepository) {
        let iaps = MockInAppPurchaseRepository()
        given(iaps).listInAppPurchases(appId: .any, limit: .any).willReturn(PaginatedResponse(data: [
            InAppPurchase(id: "iap-1", appId: "app-1", referenceName: "Lifetime", productId: "com.app.lifetime",
                          type: .nonConsumable, state: .readyToSubmit),
        ]))
        let versions = MockProductVersionRepository()
        given(versions).listInAppPurchaseVersions(iapId: .any).willReturn([
            ProductVersion(id: "iv-1", productId: "iap-1", kind: .inAppPurchase, version: 1, state: .prepareForSubmission),
        ])
        return (iaps, versions)
    }

    private func appVersionRepo() -> MockVersionRepository {
        let repo = MockVersionRepository()
        given(repo).getVersion(id: .value("v-1")).willReturn(
            AppStoreVersion(id: "v-1", appId: "app-1", versionString: "1.0", platform: .iOS, state: .prepareForSubmission)
        )
        return repo
    }

    @Test func `a dry run lists what would go to review with the app version and submits nothing`() async throws {
        let (iaps, versions) = readyLifetimeIAP()
        let submissions = MockSubmissionRepository()

        let cmd = try VersionsSubmit.parse(["--version-id", "v-1", "--with-products", "--dry-run", "--pretty"])
        let output = try await cmd.executeWithProducts(
            submissionRepo: submissions, versionRepo: appVersionRepo(), planner: planner(iapRepo: iaps, versionRepo: versions)
        )

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "getVersion" : "asc versions get --version-id v-1"
              },
              "kind" : "APP_STORE_VERSION",
              "name" : "1.0",
              "productId" : "app-1",
              "versionId" : "v-1"
            },
            {
              "affordances" : {
                "listVersions" : "asc iap versions list --iap-id iap-1"
              },
              "kind" : "IN_APP_PURCHASE_VERSION",
              "name" : "Lifetime",
              "productId" : "iap-1",
              "versionId" : "iv-1"
            }
          ]
        }
        """)
        verify(submissions).createSubmission(appId: .any, platform: .any).called(0)
        verify(submissions).submit(submissionId: .any).called(0)
    }

    @Test func `with products the app version and ready products are submitted together`() async throws {
        let (iaps, versions) = readyLifetimeIAP()
        let submissions = MockSubmissionRepository()
        given(submissions).createSubmission(appId: .any, platform: .any).willReturn(
            ReviewSubmission(id: "sub-1", appId: "app-1", platform: .iOS, state: .readyForReview)
        )
        given(submissions).addItem(submissionId: .any, target: .any).willReturn(
            ReviewSubmissionItem(id: "item-1", submissionId: "sub-1", state: .readyForReview)
        )
        given(submissions).submit(submissionId: .value("sub-1")).willReturn(
            ReviewSubmission(id: "sub-1", appId: "app-1", platform: .iOS, state: .waitingForReview)
        )

        let cmd = try VersionsSubmit.parse(["--version-id", "v-1", "--with-products", "--pretty"])
        let output = try await cmd.executeWithProducts(
            submissionRepo: submissions, versionRepo: appVersionRepo(), planner: planner(iapRepo: iaps, versionRepo: versions)
        )

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "getSubmission" : "asc review-submissions get --submission-id sub-1",
                "listItems" : "asc review-submissions items list --submission-id sub-1",
                "listVersions" : "asc versions list --app-id app-1"
              },
              "appId" : "app-1",
              "id" : "sub-1",
              "platform" : "IOS",
              "state" : "WAITING_FOR_REVIEW"
            }
          ]
        }
        """)
        verify(submissions).addItem(submissionId: .value("sub-1"), target: .value(.appStoreVersion("v-1"))).called(1)
        verify(submissions).addItem(submissionId: .value("sub-1"), target: .value(.inAppPurchaseVersion("iv-1"))).called(1)
    }
}
