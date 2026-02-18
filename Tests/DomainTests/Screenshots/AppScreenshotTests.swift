import Testing
@testable import Domain

@Suite
struct AppScreenshotTests {

    @Test
    func `complete asset state is complete`() {
        let s = MockRepositoryFactory.makeScreenshot(id: "1", assetState: .complete)
        #expect(s.isComplete == true)
    }

    @Test
    func `non-complete asset state is not complete`() {
        let s = MockRepositoryFactory.makeScreenshot(id: "1", assetState: .awaitingUpload)
        #expect(s.isComplete == false)
    }

    @Test
    func `nil asset state is not complete`() {
        let s = MockRepositoryFactory.makeScreenshot(id: "1", assetState: nil)
        #expect(s.isComplete == false)
    }

    @Test
    func `file size description formats bytes`() {
        let s = MockRepositoryFactory.makeScreenshot(id: "1", fileSize: 512)
        #expect(s.fileSizeDescription == "512 B")
    }

    @Test
    func `file size description formats kilobytes`() {
        let s = MockRepositoryFactory.makeScreenshot(id: "1", fileSize: 2048)
        #expect(s.fileSizeDescription == "2.0 KB")
    }

    @Test
    func `file size description formats megabytes`() {
        let s = MockRepositoryFactory.makeScreenshot(id: "1", fileSize: 3_145_728)
        #expect(s.fileSizeDescription == "3.0 MB")
    }

    @Test
    func `dimensions description returns formatted string when both dimensions present`() {
        let s = MockRepositoryFactory.makeScreenshot(id: "1", imageWidth: 2796, imageHeight: 1290)
        #expect(s.dimensionsDescription == "2796 × 1290")
    }

    @Test
    func `dimensions description returns nil when dimensions missing`() {
        let s = MockRepositoryFactory.makeScreenshot(id: "1", imageWidth: nil, imageHeight: nil)
        #expect(s.dimensionsDescription == nil)
    }

    @Test
    func `asset delivery state failed is not complete`() {
        #expect(AppScreenshot.AssetDeliveryState.failed.isComplete == false)
        #expect(AppScreenshot.AssetDeliveryState.failed.hasFailed == true)
    }

    @Test
    func `asset delivery state complete is complete`() {
        #expect(AppScreenshot.AssetDeliveryState.complete.isComplete == true)
        #expect(AppScreenshot.AssetDeliveryState.complete.hasFailed == false)
    }

    @Test
    func `asset delivery state display names are human readable`() {
        #expect(AppScreenshot.AssetDeliveryState.awaitingUpload.displayName == "Awaiting Upload")
        #expect(AppScreenshot.AssetDeliveryState.complete.displayName == "Complete")
        #expect(AppScreenshot.AssetDeliveryState.failed.displayName == "Failed")
    }

    @Test
    func `screenshot carries parent setId`() {
        let s = MockRepositoryFactory.makeScreenshot(id: "img-1", setId: "set-99")
        #expect(s.setId == "set-99")
    }

    @Test
    func `screenshot is equatable`() {
        let a = MockRepositoryFactory.makeScreenshot(id: "1")
        let b = MockRepositoryFactory.makeScreenshot(id: "1")
        #expect(a == b)
    }
}
