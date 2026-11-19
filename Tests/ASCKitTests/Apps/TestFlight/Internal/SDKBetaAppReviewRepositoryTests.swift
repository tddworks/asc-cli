@preconcurrency import AppStoreConnect_Swift_SDK
import Testing
@testable import ASCKit

@Suite
struct SDKBetaAppReviewRepositoryTests {

    // MARK: - Submissions

    @Test func `listSubmissions injects buildId into each submission`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(BetaAppReviewSubmissionsResponse(
            data: [
                BetaAppReviewSubmission(
                    type: .betaAppReviewSubmissions,
                    id: "sub-1",
                    attributes: .init(betaReviewState: .waitingForReview)
                ),
            ],
            links: .init(this: "")
        ))

        let repo = SDKBetaAppReviewRepository(client: stub)
        let result = try await repo.listSubmissions(buildId: "build-42")

        #expect(result.count == 1)
        #expect(result[0].id == "sub-1")
        #expect(result[0].buildId == "build-42")
        #expect(result[0].state == .waitingForReview)
    }

    @Test func `listSubmissions maps all review states`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(BetaAppReviewSubmissionsResponse(
            data: [
                BetaAppReviewSubmission(type: .betaAppReviewSubmissions, id: "s1", attributes: .init(betaReviewState: .approved)),
                BetaAppReviewSubmission(type: .betaAppReviewSubmissions, id: "s2", attributes: .init(betaReviewState: .rejected)),
                BetaAppReviewSubmission(type: .betaAppReviewSubmissions, id: "s3", attributes: .init(betaReviewState: .inReview)),
            ],
            links: .init(this: "")
        ))

        let repo = SDKBetaAppReviewRepository(client: stub)
        let result = try await repo.listSubmissions(buildId: "b-1")

        #expect(result[0].state == .approved)
        #expect(result[1].state == .rejected)
        #expect(result[2].state == .inReview)
    }

    @Test func `createSubmission returns submission with injected buildId`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(BetaAppReviewSubmissionResponse(
            data: BetaAppReviewSubmission(
                type: .betaAppReviewSubmissions,
                id: "sub-new",
                attributes: .init(betaReviewState: .waitingForReview)
            ),
            links: .init(this: "")
        ))

        let repo = SDKBetaAppReviewRepository(client: stub)
        let result = try await repo.createSubmission(buildId: "build-99")

        #expect(result.id == "sub-new")
        #expect(result.buildId == "build-99")
        #expect(result.state == .waitingForReview)
    }

    @Test func `getSubmission returns submission with buildId from relationship`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(BetaAppReviewSubmissionResponse(
            data: BetaAppReviewSubmission(
                type: .betaAppReviewSubmissions,
                id: "sub-1",
                attributes: .init(betaReviewState: .approved),
                relationships: .init(build: .init(data: .init(type: .builds, id: "build-77")))
            ),
            links: .init(this: "")
        ))

        let repo = SDKBetaAppReviewRepository(client: stub)
        let result = try await repo.getSubmission(id: "sub-1")

        #expect(result.id == "sub-1")
        #expect(result.buildId == "build-77")
        #expect(result.state == .approved)
    }

    // MARK: - Detail

    @Test func `getDetail returns detail with injected appId`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(BetaAppReviewDetailsResponse(
            data: [
                BetaAppReviewDetail(
                    type: .betaAppReviewDetails,
                    id: "detail-1",
                    attributes: .init(
                        contactFirstName: "John",
                        contactLastName: "Doe",
                        contactPhone: "+1-555-0100",
                        contactEmail: "john@example.com",
                        isDemoAccountRequired: false,
                        notes: "Test notes"
                    )
                ),
            ],
            links: .init(this: "")
        ))

        let repo = SDKBetaAppReviewRepository(client: stub)
        let result = try await repo.getDetail(appId: "app-42")

        #expect(result.id == "detail-1")
        #expect(result.appId == "app-42")
        #expect(result.contactFirstName == "John")
        #expect(result.contactLastName == "Doe")
        #expect(result.contactPhone == "+1-555-0100")
        #expect(result.contactEmail == "john@example.com")
        #expect(result.demoAccountRequired == false)
        #expect(result.notes == "Test notes")
    }

    @Test func `updateDetail returns updated detail with appId from relationship`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(BetaAppReviewDetailResponse(
            data: BetaAppReviewDetail(
                type: .betaAppReviewDetails,
                id: "detail-1",
                attributes: .init(
                    contactFirstName: "Jane",
                    contactEmail: "jane@example.com",
                    isDemoAccountRequired: true,
                    notes: "Updated"
                ),
                relationships: .init(app: .init(data: .init(type: .apps, id: "app-55")))
            ),
            links: .init(this: "")
        ))

        let repo = SDKBetaAppReviewRepository(client: stub)
        let result = try await repo.updateDetail(
            id: "detail-1",
            update: BetaAppReviewDetailUpdate(contactFirstName: "Jane", contactEmail: "jane@example.com", notes: "Updated")
        )

        #expect(result.id == "detail-1")
        #expect(result.appId == "app-55")
        #expect(result.contactFirstName == "Jane")
        #expect(result.demoAccountRequired == true)
        #expect(result.notes == "Updated")
    }
}
