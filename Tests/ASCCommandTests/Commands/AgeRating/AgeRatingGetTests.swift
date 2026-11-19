import Mockable
import Testing
@testable import ASCCommand
@testable import ASCKit

@Suite
struct AgeRatingGetTests {

    @Test func `age-rating get returns declaration with id and affordances`() async throws {
        let mockRepo = MockAgeRatingDeclarationRepository()
        given(mockRepo).getDeclaration(appInfoId: .any)
            .willReturn(AgeRatingDeclaration(id: "decl-1", appInfoId: "info-42"))

        let cmd = try AgeRatingGet.parse(["--app-info-id", "info-42", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "getAgeRating" : "asc age-rating get --app-info-id info-42",
                "update" : "asc age-rating update --declaration-id decl-1"
              },
              "appInfoId" : "info-42",
              "id" : "decl-1"
            }
          ]
        }
        """)
    }

    @Test func `age-rating get includes non-nil content fields in output`() async throws {
        let mockRepo = MockAgeRatingDeclarationRepository()
        given(mockRepo).getDeclaration(appInfoId: .any)
            .willReturn(AgeRatingDeclaration(
                id: "decl-2",
                appInfoId: "info-1",
                isAdvertising: true,
                violenceRealistic: .frequentOrIntense,
                ageRatingOverride: .eighteenPlus
            ))

        let cmd = try AgeRatingGet.parse(["--app-info-id", "info-1", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "getAgeRating" : "asc age-rating get --app-info-id info-1",
                "update" : "asc age-rating update --declaration-id decl-2"
              },
              "ageRatingOverride" : "EIGHTEEN_PLUS",
              "appInfoId" : "info-1",
              "id" : "decl-2",
              "isAdvertising" : true,
              "violenceRealistic" : "FREQUENT_OR_INTENSE"
            }
          ]
        }
        """)
    }
}
