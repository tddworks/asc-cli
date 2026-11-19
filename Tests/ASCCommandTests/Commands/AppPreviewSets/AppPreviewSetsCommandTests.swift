import Mockable
import Testing
@testable import ASCCommand
@testable import ASCKit

@Suite
struct AppPreviewSetsCommandTests {

    // MARK: - list

    @Test func `listed preview sets include affordances for navigation`() async throws {
        let mockRepo = MockAppPreviews()
        given(mockRepo).listPreviewSets(localizationId: .any).willReturn([
            AppPreviewSet(id: "set-1", localizationId: "loc-1", previewType: .iphone67, previewsCount: 3),
        ])

        let cmd = try AppPreviewSetsList.parse(["--localization-id", "loc-1", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "listPreviewSets" : "asc app-preview-sets list --localization-id loc-1",
                "listPreviews" : "asc app-previews list --set-id set-1"
              },
              "id" : "set-1",
              "localizationId" : "loc-1",
              "previewType" : "IPHONE_67",
              "previewsCount" : 3
            }
          ]
        }
        """)
    }

    @Test func `listed preview sets returns empty data array when none exist`() async throws {
        let mockRepo = MockAppPreviews()
        given(mockRepo).listPreviewSets(localizationId: .any).willReturn([])

        let cmd = try AppPreviewSetsList.parse(["--localization-id", "loc-1", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [

          ]
        }
        """)
    }

    @Test func `table output for preview sets includes all row fields`() async throws {
        let mockRepo = MockAppPreviews()
        given(mockRepo).listPreviewSets(localizationId: .any).willReturn([
            AppPreviewSet(id: "set-1", localizationId: "loc-1", previewType: .iphone67, previewsCount: 2),
        ])

        let cmd = try AppPreviewSetsList.parse(["--localization-id", "loc-1", "--output", "table"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output.contains("set-1"))
        #expect(output.contains("IPHONE_67"))
        #expect(output.contains("iPhone"))
        #expect(output.contains("2"))
    }

    // MARK: - create

    @Test func `created preview set is returned with affordances`() async throws {
        let mockRepo = MockAppPreviews()
        given(mockRepo).createPreviewSet(localizationId: .any, previewType: .any).willReturn(
            AppPreviewSet(id: "set-new", localizationId: "loc-1", previewType: .iphone67, previewsCount: 0)
        )

        let cmd = try AppPreviewSetsCreate.parse(["--localization-id", "loc-1", "--preview-type", "IPHONE_67", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "listPreviewSets" : "asc app-preview-sets list --localization-id loc-1",
                "listPreviews" : "asc app-previews list --set-id set-new"
              },
              "id" : "set-new",
              "localizationId" : "loc-1",
              "previewType" : "IPHONE_67",
              "previewsCount" : 0
            }
          ]
        }
        """)
    }

    @Test func `unknown preview type throws validation error`() async throws {
        let mockRepo = MockAppPreviews()
        let cmd = try AppPreviewSetsCreate.parse(["--localization-id", "loc-1", "--preview-type", "INVALID_TYPE"])
        await #expect(throws: (any Error).self) {
            try await cmd.execute(repo: mockRepo)
        }
    }

    @Test func `created Apple TV preview set returns correct preview type`() async throws {
        let mockRepo = MockAppPreviews()
        given(mockRepo).createPreviewSet(localizationId: .any, previewType: .any).willReturn(
            AppPreviewSet(id: "set-1", localizationId: "loc-42", previewType: .appleTV, previewsCount: 0)
        )

        let cmd = try AppPreviewSetsCreate.parse(["--localization-id", "loc-42", "--preview-type", "APPLE_TV", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "listPreviewSets" : "asc app-preview-sets list --localization-id loc-42",
                "listPreviews" : "asc app-previews list --set-id set-1"
              },
              "id" : "set-1",
              "localizationId" : "loc-42",
              "previewType" : "APPLE_TV",
              "previewsCount" : 0
            }
          ]
        }
        """)
    }
}
