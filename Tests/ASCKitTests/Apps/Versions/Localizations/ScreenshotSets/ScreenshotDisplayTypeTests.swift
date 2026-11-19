import Testing
@testable import ASCKit

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

    @Test(arguments: zip(
        ScreenshotDisplayType.DeviceCategory.allCases,
        ["iPhone", "iPad", "Mac", "Apple Watch", "Apple TV", "Apple Vision Pro", "iMessage"]
    ))
    func `device category display names are human readable`(
        category: ScreenshotDisplayType.DeviceCategory, expected: String
    ) {
        #expect(category.displayName == expected)
    }

    @Test(arguments: zip(
        ScreenshotDisplayType.allCases,
        [
            // iPhone
            "iPhone 6.7\"", "iPhone 6.5\"", "iPhone 6.1\"", "iPhone 5.8\"",
            "iPhone 5.5\"", "iPhone 4.7\"", "iPhone 4.0\"", "iPhone 3.5\"",
            // iPad
            "iPad Pro 12.9\" (3rd gen)", "iPad Pro 11\" (3rd gen)",
            "iPad Pro 12.9\"", "iPad 10.5\"", "iPad 9.7\"",
            // Other
            "Mac", "Apple Watch Ultra", "Apple Watch Series 10",
            "Apple Watch Series 7", "Apple Watch Series 4", "Apple Watch Series 3",
            "Apple TV", "Apple Vision Pro",
            // iMessage
            "iMessage iPhone 6.7\"", "iMessage iPhone 6.5\"", "iMessage iPhone 6.1\"",
            "iMessage iPhone 5.8\"", "iMessage iPhone 5.5\"", "iMessage iPhone 4.7\"",
            "iMessage iPhone 4.0\"",
            "iMessage iPad Pro 12.9\" (3rd gen)", "iMessage iPad Pro 11\" (3rd gen)",
            "iMessage iPad Pro 12.9\"", "iMessage iPad 10.5\"", "iMessage iPad 9.7\"",
        ]
    ))
    func `all display types have correct display name`(
        type: ScreenshotDisplayType, expected: String
    ) {
        #expect(type.displayName == expected)
    }
}
