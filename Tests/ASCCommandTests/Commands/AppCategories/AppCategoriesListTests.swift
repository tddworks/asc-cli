import Mockable
import Testing
@testable import ASCCommand
@testable import ASCKit

@Suite
struct AppCategoriesListTests {

    @Test func `listed categories include id platforms and affordances`() async throws {
        let mockRepo = MockAppCategoryRepository()
        given(mockRepo).listCategories(platform: .any).willReturn([
            AppCategory(id: "6014", platforms: ["IOS"], parentId: nil),
        ])

        let cmd = try AppCategoriesList.parse(["--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "listCategories" : "asc app-categories list"
              },
              "id" : "6014",
              "platforms" : [
                "IOS"
              ]
            }
          ]
        }
        """)
    }

    @Test func `listed subcategory includes parent id`() async throws {
        let mockRepo = MockAppCategoryRepository()
        given(mockRepo).listCategories(platform: .any).willReturn([
            AppCategory(id: "6014-action", platforms: ["IOS"], parentId: "6014"),
        ])

        let cmd = try AppCategoriesList.parse(["--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "listCategories" : "asc app-categories list"
              },
              "id" : "6014-action",
              "parentId" : "6014",
              "platforms" : [
                "IOS"
              ]
            }
          ]
        }
        """)
    }
}
