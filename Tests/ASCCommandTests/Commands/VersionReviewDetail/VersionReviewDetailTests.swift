import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct VersionReviewDetailGetTests {

    @Test func `get review detail returns affordances and all fields`() async throws {
        let mockRepo = MockReviewDetailRepository()
        given(mockRepo).getReviewDetail(versionId: .any).willReturn(
            AppStoreReviewDetail(
                id: "rd-1",
                versionId: "v-1",
                contactFirstName: "Jane",
                contactLastName: "Smith",
                contactPhone: "+1-555-0100",
                contactEmail: "jane@example.com",
                demoAccountRequired: false
            )
        )

        let cmd = try VersionReviewDetailGet.parse(["--version-id", "v-1", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "getReviewDetail" : "asc version-review-detail get --version-id v-1",
                "updateReviewDetail" : "asc version-review-detail update --version-id v-1"
              },
              "contactEmail" : "jane@example.com",
              "contactFirstName" : "Jane",
              "contactLastName" : "Smith",
              "contactPhone" : "+1-555-0100",
              "demoAccountRequired" : false,
              "id" : "rd-1",
              "versionId" : "v-1"
            }
          ]
        }
        """)
    }

    @Test func `get review detail omits nil optional fields from JSON`() async throws {
        let mockRepo = MockReviewDetailRepository()
        given(mockRepo).getReviewDetail(versionId: .any).willReturn(
            AppStoreReviewDetail(id: "rd-empty", versionId: "v-2", demoAccountRequired: false)
        )

        let cmd = try VersionReviewDetailGet.parse(["--version-id", "v-2", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "getReviewDetail" : "asc version-review-detail get --version-id v-2",
                "updateReviewDetail" : "asc version-review-detail update --version-id v-2"
              },
              "demoAccountRequired" : false,
              "id" : "rd-empty",
              "versionId" : "v-2"
            }
          ]
        }
        """)
    }
}

@Suite
struct VersionReviewDetailUpdateTests {

    @Test func `update review detail returns updated record with affordances`() async throws {
        let mockRepo = MockReviewDetailRepository()
        given(mockRepo).upsertReviewDetail(versionId: .any, update: .any).willReturn(
            AppStoreReviewDetail(
                id: "rd-2",
                versionId: "v-3",
                contactFirstName: "Bob",
                contactPhone: "+1-555-9999",
                contactEmail: "bob@example.com",
                demoAccountRequired: true,
                demoAccountName: "demo_user",
                demoAccountPassword: "secret",
                notes: "Use staging server"
            )
        )

        let cmd = try VersionReviewDetailUpdate.parse([
            "--version-id", "v-3",
            "--contact-first-name", "Bob",
            "--contact-phone", "+1-555-9999",
            "--contact-email", "bob@example.com",
            "--demo-account-required", "true",
            "--demo-account-name", "demo_user",
            "--demo-account-password", "secret",
            "--notes", "Use staging server",
            "--pretty",
        ])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "getReviewDetail" : "asc version-review-detail get --version-id v-3",
                "updateReviewDetail" : "asc version-review-detail update --version-id v-3"
              },
              "contactEmail" : "bob@example.com",
              "contactFirstName" : "Bob",
              "contactPhone" : "+1-555-9999",
              "demoAccountName" : "demo_user",
              "demoAccountPassword" : "secret",
              "demoAccountRequired" : true,
              "id" : "rd-2",
              "notes" : "Use staging server",
              "versionId" : "v-3"
            }
          ]
        }
        """)
    }
}
