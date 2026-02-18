import Testing
@testable import Domain

@Suite
struct ScreenshotDisplayTypeTests {

    @Test
    func `iphone67 has iphone device category`() {
        #expect(ScreenshotDisplayType.iphone67.deviceCategory == .iPhone)
    }

    @Test
    func `ipadPro3gen129 has ipad device category`() {
        #expect(ScreenshotDisplayType.ipadPro3gen129.deviceCategory == .iPad)
    }

    @Test
    func `desktop has mac device category`() {
        #expect(ScreenshotDisplayType.desktop.deviceCategory == .mac)
    }

    @Test
    func `watchUltra has watch device category`() {
        #expect(ScreenshotDisplayType.watchUltra.deviceCategory == .watch)
    }

    @Test
    func `appleTV has appleTV device category`() {
        #expect(ScreenshotDisplayType.appleTV.deviceCategory == .appleTV)
    }

    @Test
    func `appleVisionPro has appleVisionPro device category`() {
        #expect(ScreenshotDisplayType.appleVisionPro.deviceCategory == .appleVisionPro)
    }

    @Test
    func `imessage type has iMessage device category`() {
        #expect(ScreenshotDisplayType.imessageIphone67.deviceCategory == .iMessage)
        #expect(ScreenshotDisplayType.imessageIpadPro3gen129.deviceCategory == .iMessage)
    }

    @Test
    func `iphone67 display name is correct`() {
        #expect(ScreenshotDisplayType.iphone67.displayName == "iPhone 6.7\"")
    }

    @Test
    func `desktop display name is Mac`() {
        #expect(ScreenshotDisplayType.desktop.displayName == "Mac")
    }

    @Test
    func `appleVisionPro display name is correct`() {
        #expect(ScreenshotDisplayType.appleVisionPro.displayName == "Apple Vision Pro")
    }

    @Test
    func `raw value round trips from string`() {
        let type = ScreenshotDisplayType(rawValue: "APP_IPHONE_67")
        #expect(type == .iphone67)
    }

    @Test
    func `unknown raw value returns nil`() {
        let type = ScreenshotDisplayType(rawValue: "UNKNOWN_DEVICE")
        #expect(type == nil)
    }

    @Test
    func `appleTV category display name is Apple TV`() {
        #expect(ScreenshotDisplayType.DeviceCategory.appleTV.displayName == "Apple TV")
    }

    @Test
    func `appleVisionPro category display name is Apple Vision Pro`() {
        #expect(ScreenshotDisplayType.DeviceCategory.appleVisionPro.displayName == "Apple Vision Pro")
    }

    @Test
    func `iMessage category display name is iMessage`() {
        #expect(ScreenshotDisplayType.DeviceCategory.iMessage.displayName == "iMessage")
    }
}
