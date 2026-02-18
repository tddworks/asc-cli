import Testing
@testable import Domain

@Suite
struct AppScreenshotTests {

    @Test
    func `complete asset state is complete`() {
        let screenshot = AppScreenshot(id: "1", fileName: "screen.png", fileSize: 1024, assetState: .complete)
        #expect(screenshot.isComplete == true)
    }

    @Test
    func `non-complete asset state is not complete`() {
        let screenshot = AppScreenshot(id: "1", fileName: "screen.png", fileSize: 1024, assetState: .awaitingUpload)
        #expect(screenshot.isComplete == false)
    }

    @Test
    func `nil asset state is not complete`() {
        let screenshot = AppScreenshot(id: "1", fileName: "screen.png", fileSize: 1024)
        #expect(screenshot.isComplete == false)
    }

    @Test
    func `file size description formats bytes`() {
        let screenshot = AppScreenshot(id: "1", fileName: "s.png", fileSize: 512)
        #expect(screenshot.fileSizeDescription == "512 B")
    }

    @Test
    func `file size description formats kilobytes`() {
        let screenshot = AppScreenshot(id: "1", fileName: "s.png", fileSize: 2048)
        #expect(screenshot.fileSizeDescription == "2.0 KB")
    }

    @Test
    func `file size description formats megabytes`() {
        let screenshot = AppScreenshot(id: "1", fileName: "s.png", fileSize: 3_145_728)
        #expect(screenshot.fileSizeDescription == "3.0 MB")
    }

    @Test
    func `dimensions description returns formatted string when both dimensions present`() {
        let screenshot = AppScreenshot(id: "1", fileName: "s.png", fileSize: 1024, imageWidth: 2796, imageHeight: 1290)
        #expect(screenshot.dimensionsDescription == "2796 × 1290")
    }

    @Test
    func `dimensions description returns nil when dimensions missing`() {
        let screenshot = AppScreenshot(id: "1", fileName: "s.png", fileSize: 1024)
        #expect(screenshot.dimensionsDescription == nil)
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
    func `screenshot is equatable`() {
        let a = AppScreenshot(id: "1", fileName: "s.png", fileSize: 1024)
        let b = AppScreenshot(id: "1", fileName: "s.png", fileSize: 1024)
        #expect(a == b)
    }
}
