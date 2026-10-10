import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct AgeRatingUpdateTests {

    @Test func `age-rating update returns updated declaration with exact JSON`() async throws {
        let mockRepo = MockAgeRatingDeclarationRepository()
        given(mockRepo).updateDeclaration(id: .any, update: .any)
            .willReturn(AgeRatingDeclaration(
                id: "decl-1",
                appInfoId: "info-42",
                isAdvertising: false,
                violenceRealistic: ContentIntensity.none
            ))

        let cmd = try AgeRatingUpdate.parse([
            "--declaration-id", "decl-1",
            "--advertising", "false",
            "--violence-realistic", "NONE",
            "--pretty",
        ])
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
              "id" : "decl-1",
              "isAdvertising" : false,
              "violenceRealistic" : "NONE"
            }
          ]
        }
        """)
    }

    @Test func `age-rating update passes only specified flags`() async throws {
        let mockRepo = MockAgeRatingDeclarationRepository()

        var capturedUpdate: AgeRatingDeclarationUpdate?
        given(mockRepo).updateDeclaration(id: .any, update: .any)
            .willProduce { _, update in
                capturedUpdate = update
                return AgeRatingDeclaration(id: "decl-1", appInfoId: "")
            }

        let cmd = try AgeRatingUpdate.parse([
            "--declaration-id", "decl-1",
            "--gambling", "true",
            "--violence-cartoon", "INFREQUENT_OR_MILD",
            "--age-rating-override", "THIRTEEN_PLUS",
        ])
        _ = try await cmd.execute(repo: mockRepo)

        let update = try #require(capturedUpdate)
        #expect(update.isGambling == true)
        #expect(update.violenceCartoonOrFantasy == .infrequentOrMild)
        #expect(update.ageRatingOverride == .thirteenPlus)
        #expect(update.isAdvertising == nil)
        #expect(update.violenceRealistic == nil)
    }

    @Test func `should set a Korea override of twelve plus`() async throws {
        // Given - App Store Connect applies the override it is sent
        let mockRepo = MockAgeRatingDeclarationRepository()
        given(mockRepo).updateDeclaration(id: .any, update: .any)
            .willProduce { id, update in
                AgeRatingDeclaration(id: id, appInfoId: "info-42", koreaAgeRatingOverride: update.koreaAgeRatingOverride)
            }

        // When
        let cmd = try AgeRatingUpdate.parse([
            "--declaration-id", "decl-1",
            "--korea-age-rating-override", "TWELVE_PLUS",
            "--pretty",
        ])
        let output = try await cmd.execute(repo: mockRepo)

        // Then
        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "getAgeRating" : "asc age-rating get --app-info-id info-42",
                "update" : "asc age-rating update --declaration-id decl-1"
              },
              "appInfoId" : "info-42",
              "id" : "decl-1",
              "koreaAgeRatingOverride" : "TWELVE_PLUS"
            }
          ]
        }
        """)
    }

    @Test func `should set Korea's GRAC classification number`() async throws {
        // Given - App Store Connect applies the number it is sent
        let mockRepo = MockAgeRatingDeclarationRepository()
        given(mockRepo).updateDeclaration(id: .any, update: .any)
            .willProduce { id, update in
                AgeRatingDeclaration(id: id, appInfoId: "info-42", gracRatingClassificationNumber: update.gracRatingClassificationNumber)
            }

        // When
        let cmd = try AgeRatingUpdate.parse([
            "--declaration-id", "decl-1",
            "--grac-rating-classification-number", "CC-OL-000000-000",
            "--pretty",
        ])
        let output = try await cmd.execute(repo: mockRepo)

        // Then
        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "getAgeRating" : "asc age-rating get --app-info-id info-42",
                "update" : "asc age-rating update --declaration-id decl-1"
              },
              "appInfoId" : "info-42",
              "gracRatingClassificationNumber" : "CC-OL-000000-000",
              "id" : "decl-1"
            }
          ]
        }
        """)
    }
}
