import ArgumentParser
import Mockable
import Testing
@testable import ASCCommand
@testable import ASCKit

@Suite
struct ReviewSubmissionsBuildTests {

    // MARK: - create

    @Test func `creating a submission shows the draft with commands to add items and submit`() async throws {
        let mockRepo = MockSubmissionRepository()
        given(mockRepo).createSubmission(appId: .value("app-1"), platform: .value(.iOS)).willReturn(
            ReviewSubmission(id: "sub-1", appId: "app-1", platform: .iOS, state: .readyForReview)
        )

        let cmd = try ReviewSubmissionsCreate.parse(["--app-id", "app-1", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "addItem" : "asc review-submissions items add --submission-id sub-1 --version-id <version-id>",
                "getSubmission" : "asc review-submissions get --submission-id sub-1",
                "listItems" : "asc review-submissions items list --submission-id sub-1",
                "listVersions" : "asc versions list --app-id app-1",
                "submit" : "asc review-submissions submit --submission-id sub-1"
              },
              "appId" : "app-1",
              "id" : "sub-1",
              "platform" : "IOS",
              "state" : "READY_FOR_REVIEW"
            }
          ]
        }
        """)
    }

    @Test func `creating a submission for macOS asks for a macOS draft`() async throws {
        let mockRepo = MockSubmissionRepository()
        given(mockRepo).createSubmission(appId: .any, platform: .value(.macOS)).willReturn(
            ReviewSubmission(id: "sub-2", appId: "app-1", platform: .macOS, state: .readyForReview)
        )

        let cmd = try ReviewSubmissionsCreate.parse(["--app-id", "app-1", "--platform", "macos"])
        _ = try await cmd.execute(repo: mockRepo)

        verify(mockRepo).createSubmission(appId: .value("app-1"), platform: .value(.macOS)).called(1)
    }

    @Test func `creating a submission rejects an unknown platform`() async throws {
        let cmd = try ReviewSubmissionsCreate.parse(["--app-id", "app-1", "--platform", "android"])
        await #expect(throws: ValidationError.self) { try await cmd.execute(repo: MockSubmissionRepository()) }
    }

    // MARK: - items add

    @Test func `adding a subscription version shows the new item and how to remove it`() async throws {
        let mockRepo = MockSubmissionRepository()
        given(mockRepo).addItem(submissionId: .value("sub-1"), target: .value(.subscriptionVersion("sv-1"))).willReturn(
            ReviewSubmissionItem(id: "item-1", submissionId: "sub-1", state: .readyForReview,
                                 linkedResourceId: "sv-1", linkedResourceType: .subscriptionVersion)
        )

        let cmd = try ReviewSubmissionItemsAdd.parse(["--submission-id", "sub-1", "--subscription-version-id", "sv-1", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "getSubmission" : "asc review-submissions get --submission-id sub-1",
                "listSiblings" : "asc review-submissions items list --submission-id sub-1",
                "remove" : "asc review-submissions items remove --item-id item-1"
              },
              "id" : "item-1",
              "linkedResourceId" : "sv-1",
              "linkedResourceType" : "SUBSCRIPTION_VERSION",
              "state" : "READY_FOR_REVIEW",
              "submissionId" : "sub-1"
            }
          ]
        }
        """)
    }

    @Test func `each version flag adds that kind of version`() async throws {
        let cases: [(String, ReviewItemTarget)] = [
            ("--version-id", .appStoreVersion("x-1")),
            ("--iap-version-id", .inAppPurchaseVersion("x-1")),
            ("--subscription-version-id", .subscriptionVersion("x-1")),
            ("--subscription-group-version-id", .subscriptionGroupVersion("x-1")),
        ]
        for (flag, target) in cases {
            let mockRepo = MockSubmissionRepository()
            given(mockRepo).addItem(submissionId: .any, target: .any).willReturn(
                ReviewSubmissionItem(id: "item-1", submissionId: "sub-1", state: .readyForReview)
            )
            let cmd = try ReviewSubmissionItemsAdd.parse(["--submission-id", "sub-1", flag, "x-1"])
            _ = try await cmd.execute(repo: mockRepo)
            verify(mockRepo).addItem(submissionId: .value("sub-1"), target: .value(target)).called(1)
        }
    }

    @Test func `adding an item needs exactly one version flag`() async throws {
        let none = try ReviewSubmissionItemsAdd.parse(["--submission-id", "sub-1"])
        await #expect(throws: ValidationError.self) { try await none.execute(repo: MockSubmissionRepository()) }

        let two = try ReviewSubmissionItemsAdd.parse(["--submission-id", "sub-1", "--version-id", "v-1", "--iap-version-id", "iv-1"])
        await #expect(throws: ValidationError.self) { try await two.execute(repo: MockSubmissionRepository()) }
    }

    // MARK: - items remove

    @Test func `removing an item removes it from its submission`() async throws {
        let mockRepo = MockSubmissionRepository()
        given(mockRepo).removeItem(itemId: .any).willReturn()

        let cmd = try ReviewSubmissionItemsRemove.parse(["--item-id", "item-1"])
        try await cmd.execute(repo: mockRepo)

        verify(mockRepo).removeItem(itemId: .value("item-1")).called(1)
    }

    // MARK: - submit

    @Test func `submitting shows the submission waiting for review`() async throws {
        let mockRepo = MockSubmissionRepository()
        given(mockRepo).submit(submissionId: .value("sub-1")).willReturn(
            ReviewSubmission(id: "sub-1", appId: "app-1", platform: .iOS, state: .waitingForReview)
        )

        let cmd = try ReviewSubmissionsSubmit.parse(["--submission-id", "sub-1", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

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
}
