@preconcurrency import AppStoreConnect_Swift_SDK
import Foundation
import Testing
@testable import Infrastructure
@testable import Domain

@Suite
struct SDKSubmissionRepositoryTests {

    @Test func `submitVersion injects appId from version relationship`() async throws {
        let stub = SequencedStubAPIClient()

        // Step 1: version response with app relationship
        stub.enqueue(AppStoreVersionResponse(
            data: AppStoreVersion(
                type: .appStoreVersions,
                id: "v-1",
                attributes: .init(platform: .ios, versionString: "1.0.0"),
                relationships: .init(
                    app: .init(data: .init(type: .apps, id: "app-42"))
                )
            ),
            links: .init(this: "")
        ))

        // Step 2: no existing open submissions
        stub.enqueue(ReviewSubmissionsResponse(data: [], links: .init(this: "")))

        // Step 3: create submission response
        stub.enqueue(ReviewSubmissionResponse(
            data: ReviewSubmission(
                type: .reviewSubmissions,
                id: "sub-99",
                attributes: .init(state: .waitingForReview)
            ),
            links: .init(this: "")
        ))

        // Step 4: add item response
        stub.enqueue(ReviewSubmissionItemResponse(
            data: ReviewSubmissionItem(
                type: .reviewSubmissionItems,
                id: "item-1"
            ),
            links: .init(this: "")
        ))

        // Step 5: patch (submitted) response
        stub.enqueue(ReviewSubmissionResponse(
            data: ReviewSubmission(
                type: .reviewSubmissions,
                id: "sub-99",
                attributes: .init(state: .waitingForReview)
            ),
            links: .init(this: "")
        ))

        let repo = OpenAPISubmissionRepository(client: stub)
        let result = try await repo.submitVersion(versionId: "v-1")

        #expect(result.id == "sub-99")
        #expect(result.appId == "app-42")
        #expect(result.platform == .iOS)
        #expect(result.state == .waitingForReview)
    }

    @Test func `submitVersion maps state correctly`() async throws {
        let stub = SequencedStubAPIClient()

        stub.enqueue(AppStoreVersionResponse(
            data: AppStoreVersion(
                type: .appStoreVersions,
                id: "v-2",
                attributes: .init(platform: .macOs, versionString: "2.0.0"),
                relationships: .init(
                    app: .init(data: .init(type: .apps, id: "app-7"))
                )
            ),
            links: .init(this: "")
        ))
        stub.enqueue(ReviewSubmissionsResponse(data: [], links: .init(this: "")))
        stub.enqueue(ReviewSubmissionResponse(
            data: ReviewSubmission(
                type: .reviewSubmissions,
                id: "sub-77",
                attributes: .init(state: .inReview)
            ),
            links: .init(this: "")
        ))
        stub.enqueue(ReviewSubmissionItemResponse(
            data: ReviewSubmissionItem(type: .reviewSubmissionItems, id: "item-2"),
            links: .init(this: "")
        ))
        stub.enqueue(ReviewSubmissionResponse(
            data: ReviewSubmission(
                type: .reviewSubmissions,
                id: "sub-77",
                attributes: .init(state: .inReview)
            ),
            links: .init(this: "")
        ))

        let repo = OpenAPISubmissionRepository(client: stub)
        let result = try await repo.submitVersion(versionId: "v-2")

        #expect(result.platform == .macOS)
        #expect(result.state == .inReview)
        #expect(result.isPending == true)
    }

    @Test func `submitVersion reuses existing UNRESOLVED_ISSUES submission`() async throws {
        let stub = SequencedStubAPIClient()

        // Step 1: version response
        stub.enqueue(AppStoreVersionResponse(
            data: AppStoreVersion(
                type: .appStoreVersions,
                id: "v-3",
                attributes: .init(platform: .ios, versionString: "1.0.0"),
                relationships: .init(
                    app: .init(data: .init(type: .apps, id: "app-42"))
                )
            ),
            links: .init(this: "")
        ))

        // Step 2: existing submission with UNRESOLVED_ISSUES
        stub.enqueue(ReviewSubmissionsResponse(
            data: [ReviewSubmission(
                type: .reviewSubmissions,
                id: "sub-existing",
                attributes: .init(state: .unresolvedIssues)
            )],
            links: .init(this: "")
        ))

        // Step 3: patch (resubmit) response — skips create + add item
        stub.enqueue(ReviewSubmissionResponse(
            data: ReviewSubmission(
                type: .reviewSubmissions,
                id: "sub-existing",
                attributes: .init(state: .waitingForReview)
            ),
            links: .init(this: "")
        ))

        let repo = OpenAPISubmissionRepository(client: stub)
        let result = try await repo.submitVersion(versionId: "v-3")

        #expect(result.id == "sub-existing")
        #expect(result.appId == "app-42")
        #expect(result.state == .waitingForReview)
    }

    @Test func `listSubmissions maps sdk submissions and injects appId from param`() async throws {
        let stub = SequencedStubAPIClient()
        stub.enqueue(ReviewSubmissionsResponse(
            data: [
                ReviewSubmission(
                    type: .reviewSubmissions,
                    id: "sub-1",
                    attributes: .init(platform: .ios, state: .waitingForReview),
                    relationships: .init(app: .init(data: .init(type: .apps, id: "app-42")))
                ),
                ReviewSubmission(
                    type: .reviewSubmissions,
                    id: "sub-2",
                    attributes: .init(platform: .ios, state: .unresolvedIssues),
                    relationships: .init(app: .init(data: .init(type: .apps, id: "app-42")))
                ),
            ],
            links: .init(this: "")
        ))

        let repo = OpenAPISubmissionRepository(client: stub)
        let results = try await repo.listSubmissions(appId: "app-42", states: nil, limit: nil)

        #expect(results.count == 2)
        #expect(results.allSatisfy { $0.appId == "app-42" })
        #expect(results.first?.id == "sub-1")
        #expect(results.first?.state == .waitingForReview)
        #expect(results.last?.state == .unresolvedIssues)
    }

    @Test func `listSubmissions maps all states and preserves submittedDate`() async throws {
        let stub = SequencedStubAPIClient()
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        stub.enqueue(ReviewSubmissionsResponse(
            data: [ReviewSubmission(
                type: .reviewSubmissions,
                id: "sub-9",
                attributes: .init(platform: .macOs, submittedDate: date, state: .inReview),
                relationships: .init(app: .init(data: .init(type: .apps, id: "app-9")))
            )],
            links: .init(this: "")
        ))

        let repo = OpenAPISubmissionRepository(client: stub)
        let results = try await repo.listSubmissions(
            appId: "app-9",
            states: [.inReview, .waitingForReview],
            limit: 50
        )

        #expect(results.first?.platform == .macOS)
        #expect(results.first?.submittedDate == date)
        #expect(results.first?.state == .inReview)
    }
}
