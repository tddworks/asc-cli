import Mockable
import Testing
@testable import ASCCommand
@testable import ASCKit

@Suite
struct BetaReviewDetailGetTests {

    @Test func `get detail shows contact info and affordances`() async throws {
        let mockRepo = MockBetaAppReviewRepository()
        given(mockRepo).getDetail(appId: .value("app-1"))
            .willReturn(
                BetaAppReviewDetail(
                    id: "d-1",
                    appId: "app-1",
                    contactFirstName: "John",
                    contactLastName: "Doe",
                    contactPhone: "+1-555-0100",
                    contactEmail: "john@example.com"
                )
            )

        let cmd = try BetaReviewDetailGet.parse(["--app-id", "app-1", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "getDetail" : "asc beta-review detail get --app-id app-1",
                "updateDetail" : "asc beta-review detail update --detail-id d-1"
              },
              "appId" : "app-1",
              "contactEmail" : "john@example.com",
              "contactFirstName" : "John",
              "contactLastName" : "Doe",
              "contactPhone" : "+1-555-0100",
              "demoAccountRequired" : false,
              "id" : "d-1"
            }
          ]
        }
        """)
    }

    @Test func `get detail omits nil optional fields`() async throws {
        let mockRepo = MockBetaAppReviewRepository()
        given(mockRepo).getDetail(appId: .value("app-1"))
            .willReturn(
                BetaAppReviewDetail(id: "d-1", appId: "app-1")
            )

        let cmd = try BetaReviewDetailGet.parse(["--app-id", "app-1", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(!output.contains("contactFirstName"))
        #expect(!output.contains("notes"))
        #expect(output.contains("demoAccountRequired"))
    }
}
