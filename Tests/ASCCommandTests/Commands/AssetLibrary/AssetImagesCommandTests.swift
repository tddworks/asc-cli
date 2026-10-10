import Foundation
import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct AssetImagesCommandTests {

    // MARK: - list

    @Test func `should list the library's images with their state and what can be done with each`() async throws {
        let mockRepo = MockLibraryImageRepository()
        given(mockRepo).listImages(libraryId: .value("lib-1"), imageId: .value(nil), state: .value(.prepareForSubmission), category: .value(nil)).willReturn([
            LibraryImage(id: "img-1", libraryId: "lib-1", fileName: "home.png", fileSize: 14619,
                         category: .appScreenshotsAndPreviews, state: .prepareForSubmission, referenceName: "Home", specId: "spec-1",
                         width: 1290, height: 2796),
        ])

        let cmd = try AssetImagesList.parse(["--library-id", "lib-1", "--state", "PREPARE_FOR_SUBMISSION", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "delete" : "asc asset-images delete --image-id img-1",
                "listImages" : "asc asset-images list --library-id lib-1",
                "listPlacements" : "asc asset-placements list --image-id img-1",
                "place" : "asc asset-placements create --image-id img-1 --localization-id <localization-id> --placement-group <placement-group> --placement-type APP_SCREENSHOT"
              },
              "category" : "APP_SCREENSHOTS_AND_PREVIEWS",
              "fileName" : "home.png",
              "fileSize" : 14619,
              "height" : 2796,
              "id" : "img-1",
              "libraryId" : "lib-1",
              "referenceName" : "Home",
              "specId" : "spec-1",
              "state" : "PREPARE_FOR_SUBMISSION",
              "width" : 1290
            }
          ]
        }
        """)
    }

    @Test func `should show just one image when asked for it by id`() async throws {
        let mockRepo = MockLibraryImageRepository()
        given(mockRepo).listImages(libraryId: .value("lib-1"), imageId: .value("img-2"), state: .value(nil), category: .value(.creativeAssets)).willReturn([
            LibraryImage(id: "img-2", libraryId: "lib-1", fileName: "card.png", fileSize: 10, category: .creativeAssets, state: .uploadComplete),
        ])

        let cmd = try AssetImagesList.parse(["--library-id", "lib-1", "--image-id", "img-2", "--category", "CREATIVE_ASSETS", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "delete" : "asc asset-images delete --image-id img-2",
                "listImages" : "asc asset-images list --library-id lib-1",
                "listPlacements" : "asc asset-placements list --image-id img-2",
                "refresh" : "asc asset-images list --image-id img-2 --library-id lib-1"
              },
              "category" : "CREATIVE_ASSETS",
              "fileName" : "card.png",
              "fileSize" : 10,
              "id" : "img-2",
              "libraryId" : "lib-1",
              "state" : "UPLOAD_COMPLETE"
            }
          ]
        }
        """)
    }

    // MARK: - upload

    @Test func `should show the uploaded image while App Store Connect processes it`() async throws {
        let mockRepo = MockLibraryImageRepository()
        given(mockRepo).uploadImage(libraryId: .value("lib-1"), fileURL: .any, category: .value(.appScreenshotsAndPreviews), referenceName: .value("Home"))
            .willReturn(LibraryImage(id: "img-1", libraryId: "lib-1", fileName: "home.png", fileSize: 7,
                                     category: .appScreenshotsAndPreviews, state: .uploadComplete, referenceName: "Home"))

        let cmd = try AssetImagesUpload.parse(["--library-id", "lib-1", "--file", "home.png", "--reference-name", "Home", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "delete" : "asc asset-images delete --image-id img-1",
                "listImages" : "asc asset-images list --library-id lib-1",
                "listPlacements" : "asc asset-placements list --image-id img-1",
                "refresh" : "asc asset-images list --image-id img-1 --library-id lib-1"
              },
              "category" : "APP_SCREENSHOTS_AND_PREVIEWS",
              "fileName" : "home.png",
              "fileSize" : 7,
              "id" : "img-1",
              "libraryId" : "lib-1",
              "referenceName" : "Home",
              "state" : "UPLOAD_COMPLETE"
            }
          ]
        }
        """)
    }

    @Test func `should wait until App Store Connect has processed the image when asked to wait`() async throws {
        let mockRepo = MockLibraryImageRepository()
        given(mockRepo).uploadImage(libraryId: .any, fileURL: .any, category: .value(.creativeAssets), referenceName: .value(nil))
            .willReturn(LibraryImage(id: "img-1", libraryId: "lib-1", fileName: "card.png", fileSize: 7, category: .creativeAssets, state: .uploadComplete))
        given(mockRepo).listImages(libraryId: .value("lib-1"), imageId: .value("img-1"), state: .value(nil), category: .value(nil))
            .willReturn([LibraryImage(id: "img-1", libraryId: "lib-1", fileName: "card.png", fileSize: 7, category: .creativeAssets, state: .uploadComplete)])
            .listImages(libraryId: .value("lib-1"), imageId: .value("img-1"), state: .value(nil), category: .value(nil))
            .willReturn([LibraryImage(id: "img-1", libraryId: "lib-1", fileName: "card.png", fileSize: 7, category: .creativeAssets, state: .prepareForSubmission,
                                      specId: "spec-9", width: 1920, height: 1080)])

        let cmd = try AssetImagesUpload.parse(["--library-id", "lib-1", "--file", "card.png", "--category", "CREATIVE_ASSETS", "--wait", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo, sleep: { _ in })

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "delete" : "asc asset-images delete --image-id img-1",
                "listImages" : "asc asset-images list --library-id lib-1",
                "listPlacements" : "asc asset-placements list --image-id img-1",
                "place" : "asc asset-placements create --image-id img-1 --localization-id <localization-id> --placement-group <placement-group> --placement-type <placement-type>"
              },
              "category" : "CREATIVE_ASSETS",
              "fileName" : "card.png",
              "fileSize" : 7,
              "height" : 1080,
              "id" : "img-1",
              "libraryId" : "lib-1",
              "specId" : "spec-9",
              "state" : "PREPARE_FOR_SUBMISSION",
              "width" : 1920
            }
          ]
        }
        """)
    }

    @Test func `should stop waiting and show why when processing fails`() async throws {
        let mockRepo = MockLibraryImageRepository()
        given(mockRepo).uploadImage(libraryId: .any, fileURL: .any, category: .any, referenceName: .any)
            .willReturn(LibraryImage(id: "img-1", libraryId: "lib-1", fileName: "bad.png", fileSize: 7, category: .appScreenshotsAndPreviews, state: .uploadComplete))
        given(mockRepo).listImages(libraryId: .any, imageId: .any, state: .any, category: .any)
            .willReturn([LibraryImage(id: "img-1", libraryId: "lib-1", fileName: "bad.png", fileSize: 7, category: .appScreenshotsAndPreviews, state: .failed,
                                      stateDetails: [AssetStateDetail(code: "IMAGE_INCORRECT_DIMENSIONS", description: nil)])])

        let cmd = try AssetImagesUpload.parse(["--library-id", "lib-1", "--file", "bad.png", "--wait"])
        let output = try await cmd.execute(repo: mockRepo, sleep: { _ in })

        #expect(output == #"{"data":[{"affordances":{"delete":"asc asset-images delete --image-id img-1","listImages":"asc asset-images list --library-id lib-1","listPlacements":"asc asset-placements list --image-id img-1"},"category":"APP_SCREENSHOTS_AND_PREVIEWS","fileName":"bad.png","fileSize":7,"id":"img-1","libraryId":"lib-1","state":"FAILED","stateDetails":[{"code":"IMAGE_INCORRECT_DIMENSIONS"}]}]}"#)
    }

    // MARK: - delete

    @Test func `should report App Store Connect's refusal to delete an image that is still placed`() async throws {
        let mockRepo = MockLibraryImageRepository()
        given(mockRepo).deleteImage(imageId: .value("img-1")).willThrow(APIError.unknown("STATE_ERROR.ASSET_HAS_PLACEMENTS"))

        let cmd = try AssetImagesDelete.parse(["--image-id", "img-1"])

        await #expect(throws: APIError.unknown("STATE_ERROR.ASSET_HAS_PLACEMENTS")) {
            try await cmd.execute(repo: mockRepo)
        }
    }
}
