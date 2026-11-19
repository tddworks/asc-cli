import Foundation
import Mockable
import Testing
@testable import ASCKit

@Suite
struct SubmissionPlannerTests {

    private let version = MockRepositoryFactory.makeVersion(
        id: "v-1", appId: "app-1", versionString: "1.0", platform: .iOS, state: .prepareForSubmission
    )

    private struct Repos {
        let iaps = MockInAppPurchases()
        let groups = MockSubscriptionGroups()
        let subscriptions = MockSubscriptions()
        let versions = MockProductVersions()

        var planner: SubmissionPlanner {
            SubmissionPlanner(iapRepo: iaps, groupRepo: groups, subscriptionRepo: subscriptions, productVersionRepo: versions)
        }

        func noProducts() {
            given(iaps).listInAppPurchases(appId: .any, limit: .any).willReturn(PaginatedResponse(data: []))
            given(groups).listSubscriptionGroups(appId: .any, limit: .any).willReturn(PaginatedResponse(data: []))
        }
    }

    // MARK: - Planning

    @Test func `with no ready products the plan holds just the app version`() async throws {
        let repos = Repos()
        repos.noProducts()

        let plan = try await repos.planner.plan(for: version)

        #expect(plan.appId == "app-1")
        #expect(plan.platform == .iOS)
        #expect(plan.items == [PlannedReviewItem(kind: .appStoreVersion, versionId: "v-1", productId: "app-1", name: "1.0")])
    }

    @Test func `a ready in-app purchase joins the plan after the app version`() async throws {
        let repos = Repos()
        given(repos.iaps).listInAppPurchases(appId: .value("app-1"), limit: .any).willReturn(PaginatedResponse(data: [
            MockRepositoryFactory.makeInAppPurchase(id: "iap-1", referenceName: "Lifetime", state: .readyToSubmit),
            MockRepositoryFactory.makeInAppPurchase(id: "iap-2", referenceName: "Draft", state: .missingMetadata),
        ]))
        given(repos.groups).listSubscriptionGroups(appId: .any, limit: .any).willReturn(PaginatedResponse(data: []))
        given(repos.versions).listInAppPurchaseVersions(iapId: .value("iap-1")).willReturn([
            MockRepositoryFactory.makeProductVersion(id: "iv-1", productId: "iap-1", kind: .inAppPurchase, state: .prepareForSubmission),
        ])

        let plan = try await repos.planner.plan(for: version)

        #expect(plan.items.map(\.kind) == [.appStoreVersion, .inAppPurchaseVersion])
        #expect(plan.items[1] == PlannedReviewItem(kind: .inAppPurchaseVersion, versionId: "iv-1", productId: "iap-1", name: "Lifetime"))
    }

    @Test func `a ready subscription joins the plan after its group's version`() async throws {
        let repos = Repos()
        given(repos.iaps).listInAppPurchases(appId: .any, limit: .any).willReturn(PaginatedResponse(data: []))
        given(repos.groups).listSubscriptionGroups(appId: .value("app-1"), limit: .any).willReturn(PaginatedResponse(data: [
            MockRepositoryFactory.makeSubscriptionGroup(id: "grp-1", referenceName: "Pro"),
        ]))
        given(repos.subscriptions).listSubscriptions(groupId: .value("grp-1"), limit: .any).willReturn(PaginatedResponse(data: [
            MockRepositoryFactory.makeSubscription(id: "sub-1", groupId: "grp-1", name: "Monthly", state: .readyToSubmit),
        ]))
        given(repos.versions).listSubscriptionGroupVersions(groupId: .value("grp-1")).willReturn([
            MockRepositoryFactory.makeProductVersion(id: "gv-1", productId: "grp-1", kind: .subscriptionGroup),
        ])
        given(repos.versions).listSubscriptionVersions(subscriptionId: .value("sub-1")).willReturn([
            MockRepositoryFactory.makeProductVersion(id: "sv-1", productId: "sub-1", kind: .subscription),
        ])

        let plan = try await repos.planner.plan(for: version)

        #expect(plan.items == [
            PlannedReviewItem(kind: .appStoreVersion, versionId: "v-1", productId: "app-1", name: "1.0"),
            PlannedReviewItem(kind: .subscriptionGroupVersion, versionId: "gv-1", productId: "grp-1", name: "Pro"),
            PlannedReviewItem(kind: .subscriptionVersion, versionId: "sv-1", productId: "sub-1", name: "Monthly"),
        ])
    }

    @Test func `a group with no ready subscription is left out`() async throws {
        let repos = Repos()
        given(repos.iaps).listInAppPurchases(appId: .any, limit: .any).willReturn(PaginatedResponse(data: []))
        given(repos.groups).listSubscriptionGroups(appId: .any, limit: .any).willReturn(PaginatedResponse(data: [
            MockRepositoryFactory.makeSubscriptionGroup(id: "grp-1"),
        ]))
        given(repos.subscriptions).listSubscriptions(groupId: .any, limit: .any).willReturn(PaginatedResponse(data: [
            MockRepositoryFactory.makeSubscription(id: "sub-1", state: .missingMetadata),
        ]))

        let plan = try await repos.planner.plan(for: version)

        #expect(plan.items.map(\.kind) == [.appStoreVersion])
    }

    @Test func `a product whose version is already in review is left out`() async throws {
        let repos = Repos()
        given(repos.iaps).listInAppPurchases(appId: .any, limit: .any).willReturn(PaginatedResponse(data: [
            MockRepositoryFactory.makeInAppPurchase(id: "iap-1", state: .readyToSubmit),
        ]))
        given(repos.groups).listSubscriptionGroups(appId: .any, limit: .any).willReturn(PaginatedResponse(data: []))
        given(repos.versions).listInAppPurchaseVersions(iapId: .any).willReturn([
            MockRepositoryFactory.makeProductVersion(kind: .inAppPurchase, state: .waitingForReview),
        ])

        let plan = try await repos.planner.plan(for: version)

        #expect(plan.items.map(\.kind) == [.appStoreVersion])
    }

    // MARK: - Submitting

    @Test func `submitting a plan adds every item to the app's draft and sends it`() async throws {
        let plan = SubmissionPlan(appId: "app-1", platform: .iOS, items: [
            PlannedReviewItem(kind: .appStoreVersion, versionId: "v-1", productId: "app-1", name: "1.0"),
            PlannedReviewItem(kind: .inAppPurchaseVersion, versionId: "iv-1", productId: "iap-1", name: "Lifetime"),
        ])
        let repo = MockReviewSubmissions()
        given(repo).createSubmission(appId: .any, platform: .any).willReturn(
            MockRepositoryFactory.makeReviewSubmission(id: "sub-1", appId: "app-1", state: .readyForReview)
        )
        given(repo).addItem(submissionId: .any, target: .any).willReturn(MockRepositoryFactory.makeReviewSubmissionItem())
        given(repo).submit(submissionId: .value("sub-1")).willReturn(
            MockRepositoryFactory.makeReviewSubmission(id: "sub-1", appId: "app-1", state: .waitingForReview)
        )

        let submission = try await plan.submit(repo: repo)

        #expect(submission.state == .waitingForReview)
        verify(repo).createSubmission(appId: .value("app-1"), platform: .value(.iOS)).called(1)
        verify(repo).addItem(submissionId: .value("sub-1"), target: .value(.appStoreVersion("v-1"))).called(1)
        verify(repo).addItem(submissionId: .value("sub-1"), target: .value(.inAppPurchaseVersion("iv-1"))).called(1)
    }

    @Test func `if Apple refuses the app version no products are added and nothing is submitted`() async throws {
        struct Refused: Error {}
        let plan = SubmissionPlan(appId: "app-1", platform: .iOS, items: [
            PlannedReviewItem(kind: .appStoreVersion, versionId: "v-1", productId: "app-1", name: "1.0"),
            PlannedReviewItem(kind: .inAppPurchaseVersion, versionId: "iv-1", productId: "iap-1", name: "Lifetime"),
        ])
        let repo = MockReviewSubmissions()
        given(repo).createSubmission(appId: .any, platform: .any).willReturn(
            MockRepositoryFactory.makeReviewSubmission(id: "sub-1", state: .readyForReview)
        )
        given(repo).addItem(submissionId: .any, target: .value(.appStoreVersion("v-1"))).willThrow(Refused())

        await #expect(throws: Refused.self) { try await plan.submit(repo: repo) }
        verify(repo).addItem(submissionId: .any, target: .value(.inAppPurchaseVersion("iv-1"))).called(0)
        verify(repo).submit(submissionId: .any).called(0)
    }
}
