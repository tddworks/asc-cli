import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct AppInfosUpdateTests {

    @Test func `updated app info with primary category is returned with affordances`() async throws {
        let mockRepo = MockAppInfoRepository()
        given(mockRepo)
            .updateCategories(
                id: .any,
                primaryCategoryId: .any,
                primarySubcategoryOneId: .any,
                primarySubcategoryTwoId: .any,
                secondaryCategoryId: .any,
                secondarySubcategoryOneId: .any,
                secondarySubcategoryTwoId: .any
            )
            .willReturn(AppInfo(id: "info-1", appId: "app-1", primaryCategoryId: "6014"))

        let cmd = try AppInfosUpdate.parse([
            "--app-info-id", "info-1",
            "--primary-category", "6014",
            "--pretty",
        ])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "getAgeRating" : "asc age-rating get --app-info-id info-1",
                "getPrimaryCategory" : "asc app-categories get --category-id 6014",
                "listAppInfos" : "asc app-infos list --app-id app-1",
                "listLocalizations" : "asc app-info-localizations list --app-info-id info-1",
                "updateCategories" : "asc app-infos update --app-info-id info-1"
              },
              "appId" : "app-1",
              "id" : "info-1",
              "primaryCategoryId" : "6014"
            }
          ]
        }
        """)
    }

    @Test func `update passes all category flags to repository`() async throws {
        let mockRepo = MockAppInfoRepository()
        var capturedPrimary: String??
        var capturedSecondary: String??
        given(mockRepo)
            .updateCategories(
                id: .any,
                primaryCategoryId: .any,
                primarySubcategoryOneId: .any,
                primarySubcategoryTwoId: .any,
                secondaryCategoryId: .any,
                secondarySubcategoryOneId: .any,
                secondarySubcategoryTwoId: .any
            )
            .willProduce { _, primary, _, _, secondary, _, _ in
                capturedPrimary = primary
                capturedSecondary = secondary
                return AppInfo(id: "info-1", appId: "app-1")
            }

        let cmd = try AppInfosUpdate.parse([
            "--app-info-id", "info-1",
            "--primary-category", "6014",
            "--secondary-category", "6005",
        ])
        _ = try await cmd.execute(repo: mockRepo)

        #expect(capturedPrimary == "6014")
        #expect(capturedSecondary == "6005")
    }
}
