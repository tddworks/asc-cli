import Testing
@testable import Domain

@Suite
struct AppScreenshotSetTests {

    @Test
    func `empty set when screenshots count is zero`() {
        let set = AppScreenshotSet(id: "1", screenshotDisplayType: .iphone67, screenshotsCount: 0)
        #expect(set.isEmpty == true)
    }

    @Test
    func `not empty when screenshots count is positive`() {
        let set = AppScreenshotSet(id: "1", screenshotDisplayType: .iphone67, screenshotsCount: 3)
        #expect(set.isEmpty == false)
    }

    @Test
    func `device category delegates to display type`() {
        let iPhoneSet = AppScreenshotSet(id: "1", screenshotDisplayType: .iphone67)
        let iPadSet = AppScreenshotSet(id: "2", screenshotDisplayType: .ipadPro3gen129)
        #expect(iPhoneSet.deviceCategory == .iPhone)
        #expect(iPadSet.deviceCategory == .iPad)
    }

    @Test
    func `display type name delegates to display type`() {
        let set = AppScreenshotSet(id: "1", screenshotDisplayType: .iphone67)
        #expect(set.displayTypeName == "iPhone 6.7\"")
    }

    @Test
    func `default screenshots count is zero`() {
        let set = AppScreenshotSet(id: "1", screenshotDisplayType: .desktop)
        #expect(set.screenshotsCount == 0)
    }

    @Test
    func `set is equatable`() {
        let a = AppScreenshotSet(id: "1", screenshotDisplayType: .iphone67, screenshotsCount: 2)
        let b = AppScreenshotSet(id: "1", screenshotDisplayType: .iphone67, screenshotsCount: 2)
        #expect(a == b)
    }
}
