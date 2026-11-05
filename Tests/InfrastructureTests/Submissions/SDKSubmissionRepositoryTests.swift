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

    @Test func `should resubmit an open draft that already contains the version`() async throws {
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

        // Step 3: the draft already contains this version, so no item is added
        stub.enqueue(ReviewSubmissionItemsResponse(
            data: [ReviewSubmissionItem(
                type: .reviewSubmissionItems,
                id: "item-1",
                relationships: .init(appStoreVersion: .init(data: .init(type: .appStoreVersions, id: "v-3")))
            )],
            links: .init(this: "")
        ))

        // Step 4: patch (resubmit) response — skips create + add item
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

    // MARK: - getSubmission

    @Test func `getSubmission injects appId from app relationship and maps state`() async throws {
        let stub = SequencedStubAPIClient()
        stub.enqueue(ReviewSubmissionResponse(
            data: ReviewSubmission(
                type: .reviewSubmissions,
                id: "sub-77",
                attributes: .init(platform: .ios, state: .unresolvedIssues),
                relationships: .init(app: .init(data: .init(type: .apps, id: "app-42")))
            ),
            links: .init(this: "")
        ))

        let repo = OpenAPISubmissionRepository(client: stub)
        let result = try await repo.getSubmission(id: "sub-77")

        #expect(result.id == "sub-77")
        #expect(result.appId == "app-42")
        #expect(result.state == .unresolvedIssues)
        #expect(result.hasIssues == true)
    }

    // MARK: - listSubmissionItems

    @Test func `listSubmissionItems injects submissionId and maps state`() async throws {
        let stub = SequencedStubAPIClient()
        stub.enqueue(ReviewSubmissionItemsResponse(
            data: [
                ReviewSubmissionItem(
                    type: .reviewSubmissionItems,
                    id: "item-1",
                    attributes: .init(state: .rejected),
                    relationships: .init(
                        appStoreVersion: .init(data: .init(type: .appStoreVersions, id: "v-9"))
                    )
                ),
                ReviewSubmissionItem(
                    type: .reviewSubmissionItems,
                    id: "item-2",
                    attributes: .init(state: .approved),
                    relationships: .init(
                        appStoreVersion: .init(data: .init(type: .appStoreVersions, id: "v-10"))
                    )
                ),
            ],
            links: .init(this: "")
        ))

        let repo = OpenAPISubmissionRepository(client: stub)
        let results = try await repo.listSubmissionItems(submissionId: "sub-1")

        #expect(results.count == 2)
        #expect(results.allSatisfy { $0.submissionId == "sub-1" })
        #expect(results.first?.state == .rejected)
        #expect(results.first?.isRejected == true)
        #expect(results.first?.linkedResourceId == "v-9")
        #expect(results.first?.linkedResourceType == .appStoreVersion)
        #expect(results.last?.state == .approved)
        #expect(results.last?.isApproved == true)
    }

    @Test func `listSubmissionItems handles item with no linked relationship`() async throws {
        let stub = SequencedStubAPIClient()
        stub.enqueue(ReviewSubmissionItemsResponse(
            data: [
                ReviewSubmissionItem(
                    type: .reviewSubmissionItems,
                    id: "item-1",
                    attributes: .init(state: .readyForReview)
                ),
            ],
            links: .init(this: "")
        ))

        let repo = OpenAPISubmissionRepository(client: stub)
        let results = try await repo.listSubmissionItems(submissionId: "sub-1")

        #expect(results.first?.linkedResourceId == nil)
        #expect(results.first?.linkedResourceType == nil)
        #expect(results.first?.isPending == true)
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

    @Test func `listing items asks Apple which resource each item points at`() async throws {
        // Apple only returns an item's relationship linkage when asked via `include`.
        let stub = StubAPIClient()
        stub.willReturn(ReviewSubmissionItemsResponse(data: [], links: .init(this: "")))

        let repo = OpenAPISubmissionRepository(client: stub)
        _ = try await repo.listSubmissionItems(submissionId: "sub-1")

        let query = Dictionary(uniqueKeysWithValues: (stub.lastQuery ?? []).map { ($0.0, $0.1 ?? "") })
        let included = Set((query["include"] ?? "").split(separator: ",").map(String.init))
        #expect(included.isSuperset(of: [
            "appStoreVersion", "appCustomProductPageVersion",
            "appStoreVersionExperimentV2", "appEvent", "backgroundAssetVersion",
            "gameCenterAchievementVersion", "gameCenterActivityVersion", "gameCenterChallengeVersion",
            "gameCenterLeaderboardSetVersion", "gameCenterLeaderboardVersion",
            "inAppPurchaseVersion", "subscriptionVersion", "subscriptionGroupVersion",
        ]))
        // Apple rejects v1 and v2 experiments in the same request (400 PARAMETER_ERROR.INVALID).
        #expect(!included.contains("appStoreVersionExperiment"))
    }

    @Test func `product version items show which product version they point at`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(ReviewSubmissionItemsResponse(
            data: [
                ReviewSubmissionItem(
                    type: .reviewSubmissionItems, id: "item-iap", attributes: .init(state: .readyForReview),
                    relationships: .init(inAppPurchaseVersion: .init(data: .init(type: .inAppPurchaseVersions, id: "iapv-1")))
                ),
                ReviewSubmissionItem(
                    type: .reviewSubmissionItems, id: "item-sub", attributes: .init(state: .readyForReview),
                    relationships: .init(subscriptionVersion: .init(data: .init(type: .subscriptionVersions, id: "subv-1")))
                ),
                ReviewSubmissionItem(
                    type: .reviewSubmissionItems, id: "item-group", attributes: .init(state: .readyForReview),
                    relationships: .init(subscriptionGroupVersion: .init(data: .init(type: .subscriptionGroupVersions, id: "grpv-1")))
                ),
            ],
            links: .init(this: "")
        ))

        let repo = OpenAPISubmissionRepository(client: stub)
        let items = try await repo.listSubmissionItems(submissionId: "sub-1")

        #expect(items.map(\.linkedResourceType) == [.inAppPurchaseVersion, .subscriptionVersion, .subscriptionGroupVersion])
        #expect(items.map(\.linkedResourceId) == ["iapv-1", "subv-1", "grpv-1"])
    }

    // MARK: - Building a submission

    @Test func `creating a submission reuses the app's open draft for that platform`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(ReviewSubmissionsResponse(
            data: [ReviewSubmission(type: .reviewSubmissions, id: "draft-1",
                                    attributes: .init(platform: .ios, state: .readyForReview))],
            links: .init(this: "")
        ))

        let repo = OpenAPISubmissionRepository(client: stub)
        let submission = try await repo.createSubmission(appId: "app-1", platform: .iOS)

        #expect(submission == Domain.ReviewSubmission(id: "draft-1", appId: "app-1", platform: .iOS, state: .readyForReview))
        #expect(!stub.requests.contains { $0.method == "POST" })
    }

    @Test func `creating a submission creates a draft when the app has none open`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(ReviewSubmissionsResponse(data: [], links: .init(this: "")))
        stub.willReturn(ReviewSubmissionResponse(
            data: ReviewSubmission(type: .reviewSubmissions, id: "new-1",
                                   attributes: .init(platform: .ios, state: .readyForReview)),
            links: .init(this: "")
        ))

        let repo = OpenAPISubmissionRepository(client: stub)
        let submission = try await repo.createSubmission(appId: "app-1", platform: .iOS)

        #expect(submission == Domain.ReviewSubmission(id: "new-1", appId: "app-1", platform: .iOS, state: .readyForReview))
        let post = stub.requests.first { $0.method == "POST" }
        #expect(post?.path == "/v1/reviewSubmissions")
        #expect(post?.body == #"{"data":{"attributes":{"platform":"IOS"},"relationships":{"app":{"data":{"id":"app-1","type":"apps"}}},"type":"reviewSubmissions"}}"#)
    }

    @Test func `adding each kind of version sends it as the item's relationship`() async throws {
        let cases: [(ReviewItemTarget, String, Domain.ReviewSubmissionItemLinkedResource)] = [
            (.appStoreVersion("v-1"), #""appStoreVersion":{"data":{"id":"v-1","type":"appStoreVersions"}}"#, .appStoreVersion),
            (.inAppPurchaseVersion("iv-1"), #""inAppPurchaseVersion":{"data":{"id":"iv-1","type":"inAppPurchaseVersions"}}"#, .inAppPurchaseVersion),
            (.subscriptionVersion("sv-1"), #""subscriptionVersion":{"data":{"id":"sv-1","type":"subscriptionVersions"}}"#, .subscriptionVersion),
            (.subscriptionGroupVersion("gv-1"), #""subscriptionGroupVersion":{"data":{"id":"gv-1","type":"subscriptionGroupVersions"}}"#, .subscriptionGroupVersion),
        ]
        for (target, relationship, linkedType) in cases {
            let stub = StubAPIClient()
            stub.willReturn(ReviewSubmissionItemResponse(
                data: ReviewSubmissionItem(type: .reviewSubmissionItems, id: "item-1", attributes: .init(state: .readyForReview)),
                links: .init(this: "")
            ))

            let repo = OpenAPISubmissionRepository(client: stub)
            let item = try await repo.addItem(submissionId: "sub-1", target: target)

            let post = stub.requests.first { $0.method == "POST" }
            #expect(post?.path == "/v1/reviewSubmissionItems")
            #expect(post?.body?.contains(relationship) == true)
            #expect(post?.body?.contains(#""reviewSubmission":{"data":{"id":"sub-1","type":"reviewSubmissions"}}"#) == true)
            #expect(item == Domain.ReviewSubmissionItem(
                id: "item-1", submissionId: "sub-1", state: .readyForReview,
                linkedResourceId: target.id, linkedResourceType: linkedType
            ))
        }
    }

    @Test func `removing an item deletes it from its submission`() async throws {
        let stub = StubAPIClient()

        let repo = OpenAPISubmissionRepository(client: stub)
        try await repo.removeItem(itemId: "item-1")

        #expect(stub.requests.map { "\($0.method) \($0.path)" } == ["DELETE /v1/reviewSubmissionItems/item-1"])
    }

    @Test func `submitting sends the draft to review and returns its new state`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(ReviewSubmissionResponse(
            data: ReviewSubmission(type: .reviewSubmissions, id: "sub-1",
                                   attributes: .init(platform: .ios, state: .waitingForReview),
                                   relationships: .init(app: .init(data: .init(type: .apps, id: "app-1")))),
            links: .init(this: "")
        ))

        let repo = OpenAPISubmissionRepository(client: stub)
        let submission = try await repo.submit(submissionId: "sub-1")

        let patch = stub.requests.first { $0.method == "PATCH" }
        #expect(patch?.path == "/v1/reviewSubmissions/sub-1")
        #expect(patch?.body == #"{"data":{"attributes":{"submitted":true},"id":"sub-1","type":"reviewSubmissions"}}"#)
        #expect(submission == Domain.ReviewSubmission(id: "sub-1", appId: "app-1", platform: .iOS, state: .waitingForReview))
    }

    // MARK: - Apple's reasons for refusing

    /// The 409 Apple returns when an app version isn't ready: the headline says to look at
    /// associated errors, and the real reasons sit in `meta.associatedErrors`.
    private func appVersionNotReviewable() -> APIProvider.Error {
        func error(_ code: String, _ detail: String) -> ResponseError {
            ResponseError(status: "409", code: code, title: "The request entity is not valid.", detail: detail)
        }
        return .requestFailure(409, ErrorResponse(errors: [
            ResponseError(
                status: "409", code: "STATE_ERROR.ENTITY_STATE_INVALID", title: "The request cannot be fulfilled.",
                detail: "This resource cannot be reviewed, please check associated errors to see why.",
                meta: .init(associatedErrors: [
                    "/v2/appPrices/": [error("STATE_ERROR.APP_PRICING_REQUIRED",
                                             "App is not eligible for submission until pricing has been set.")],
                    "/v1/appScreenshots/": [error("STATE_ERROR.SCREENSHOT_REQUIRED.APP_IPAD_PRO_3GEN_129",
                                                  "A screenshot for one of the following types is required but was not provided: APP_IPAD_PRO_3GEN_129")],
                ])
            ),
        ]), nil)
    }

    @Test func `when Apple refuses an item the error lists each reason it gave`() async throws {
        let stub = StubAPIClient()
        stub.errorToThrow = appVersionNotReviewable()

        let repo = OpenAPISubmissionRepository(client: stub)
        await #expect {
            _ = try await repo.addItem(submissionId: "sub-1", target: .appStoreVersion("v-1"))
        } throws: { error in
            String(describing: error) == """
            Apple refused the review submission: This resource cannot be reviewed, please check associated errors to see why.
              - A screenshot for one of the following types is required but was not provided: APP_IPAD_PRO_3GEN_129
              - App is not eligible for submission until pricing has been set.
            """
        }
    }

    @Test func `when Apple refuses to submit the error lists each reason it gave`() async throws {
        let stub = StubAPIClient()
        stub.errorToThrow = appVersionNotReviewable()

        let repo = OpenAPISubmissionRepository(client: stub)
        await #expect {
            _ = try await repo.submit(submissionId: "sub-1")
        } throws: { error in
            String(describing: error).hasPrefix("Apple refused the review submission: ")
                && String(describing: error).contains("  - App is not eligible for submission until pricing has been set.")
        }
    }

    @Test func `an Apple server error is reported as it is, not as a refusal`() async throws {
        let stub = StubAPIClient()
        stub.errorToThrow = APIProvider.Error.requestFailure(500, ErrorResponse(errors: [
            ResponseError(status: "500", code: "UNEXPECTED_ERROR", title: "An unexpected error occurred.",
                          detail: "An unexpected error occurred on the server side."),
        ]), nil)

        let repo = OpenAPISubmissionRepository(client: stub)
        await #expect {
            _ = try await repo.addItem(submissionId: "sub-1", target: .appStoreVersion("v-1"))
        } throws: { error in
            !(error is ReviewSubmissionError) && String(describing: error).contains("UNEXPECTED_ERROR")
        }
    }

    // MARK: - submitVersion with an open draft, and Apple's refusals

    /// Answers every request `submitVersion` makes for version v-1 of app-1.
    private func submitVersionStub(
        openDrafts: [AppStoreConnect_Swift_SDK.ReviewSubmission] = [],
        itemsInDraft: [AppStoreConnect_Swift_SDK.ReviewSubmissionItem] = []
    ) -> StubAPIClient {
        let stub = StubAPIClient()
        stub.willReturn(AppStoreVersionResponse(
            data: AppStoreVersion(
                type: .appStoreVersions, id: "v-1",
                attributes: .init(platform: .ios, versionString: "1.0.0"),
                relationships: .init(app: .init(data: .init(type: .apps, id: "app-1")))
            ),
            links: .init(this: "")
        ))
        stub.willReturn(ReviewSubmissionsResponse(data: openDrafts, links: .init(this: "")))
        stub.willReturn(ReviewSubmissionItemsResponse(data: itemsInDraft, links: .init(this: "")))
        stub.willReturn(ReviewSubmissionItemResponse(
            data: ReviewSubmissionItem(type: .reviewSubmissionItems, id: "item-new"),
            links: .init(this: "")
        ))
        stub.willReturn(ReviewSubmissionResponse(
            data: ReviewSubmission(type: .reviewSubmissions, id: "sub-1", attributes: .init(state: .waitingForReview)),
            links: .init(this: "")
        ))
        return stub
    }

    private var openDraft: AppStoreConnect_Swift_SDK.ReviewSubmission {
        ReviewSubmission(type: .reviewSubmissions, id: "sub-1", attributes: .init(state: .readyForReview))
    }

    @Test func `should add the version before submitting when the open draft is empty`() async throws {
        let stub = submitVersionStub(openDrafts: [openDraft], itemsInDraft: [])

        let submission = try await OpenAPISubmissionRepository(client: stub).submitVersion(versionId: "v-1")

        #expect(stub.requests.filter { $0.method != "GET" }.map { "\($0.method) \($0.path)" } == [
            "POST /v1/reviewSubmissionItems",
            "PATCH /v1/reviewSubmissions/sub-1",
        ])
        let addItem = stub.requests.first { $0.method == "POST" }
        #expect(addItem?.body == #"{"data":{"relationships":{"appStoreVersion":{"data":{"id":"v-1","type":"appStoreVersions"}},"reviewSubmission":{"data":{"id":"sub-1","type":"reviewSubmissions"}}},"type":"reviewSubmissionItems"}}"#)
        #expect(submission.state == .waitingForReview)
    }

    @Test func `should submit without adding the version again when the open draft already contains it`() async throws {
        let stub = submitVersionStub(openDrafts: [openDraft], itemsInDraft: [
            ReviewSubmissionItem(
                type: .reviewSubmissionItems, id: "item-1",
                relationships: .init(appStoreVersion: .init(data: .init(type: .appStoreVersions, id: "v-1")))
            ),
        ])

        let submission = try await OpenAPISubmissionRepository(client: stub).submitVersion(versionId: "v-1")

        #expect(stub.requests.filter { $0.method != "GET" }.map { "\($0.method) \($0.path)" } == [
            "PATCH /v1/reviewSubmissions/sub-1",
        ])
        #expect(submission.state == .waitingForReview)
    }

    @Test func `should add the version when the open draft only contains other items`() async throws {
        let stub = submitVersionStub(openDrafts: [openDraft], itemsInDraft: [
            ReviewSubmissionItem(
                type: .reviewSubmissionItems, id: "item-1",
                relationships: .init(inAppPurchaseVersion: .init(data: .init(type: .inAppPurchaseVersions, id: "iap-v-1")))
            ),
        ])

        _ = try await OpenAPISubmissionRepository(client: stub).submitVersion(versionId: "v-1")

        #expect(stub.requests.filter { $0.method != "GET" }.map { "\($0.method) \($0.path)" } == [
            "POST /v1/reviewSubmissionItems",
            "PATCH /v1/reviewSubmissions/sub-1",
        ])
    }

    @Test(arguments: [
        "POST /v1/reviewSubmissions",
        "POST /v1/reviewSubmissionItems",
        "PATCH /v1/reviewSubmissions/sub-1",
    ])
    func `should list each reason Apple gave when it refuses to submit a version`(refusedRequest: String) async throws {
        let stub = submitVersionStub()
        stub.errorsByRequest[refusedRequest] = appVersionNotReviewable()

        await #expect {
            _ = try await OpenAPISubmissionRepository(client: stub).submitVersion(versionId: "v-1")
        } throws: { error in
            String(describing: error) == """
            Apple refused the review submission: This resource cannot be reviewed, please check associated errors to see why.
              - A screenshot for one of the following types is required but was not provided: APP_IPAD_PRO_3GEN_129
              - App is not eligible for submission until pricing has been set.
            """
        }
    }
}
