import Testing
@testable import Domain

@Suite
struct AppScreenshotSetTests {

    @Test
    func `empty set when screenshots count is zero`() {
        let set = MockRepositoryFactory.makeScreenshotSet(id: "1", screenshotsCount: 0)
        #expect(set.isEmpty == true)
    }

    @Test
    func `not empty when screenshots count is positive`() {
        let set = MockRepositoryFactory.makeScreenshotSet(id: "1", screenshotsCount: 3)
        #expect(set.isEmpty == false)
    }

    @Test
    func `device category delegates to display type`() {
        let iPhoneSet = MockRepositoryFactory.makeScreenshotSet(id: "1", displayType: .iphone67)
        let iPadSet = MockRepositoryFactory.makeScreenshotSet(id: "2", displayType: .ipadPro3gen129)
        #expect(iPhoneSet.deviceCategory == .iPhone)
        #expect(iPadSet.deviceCategory == .iPad)
    }

    @Test
    func `display type name delegates to display type`() {
        let set = MockRepositoryFactory.makeScreenshotSet(id: "1", displayType: .iphone67)
        #expect(set.displayTypeName == "iPhone 6.7\"")
    }

    @Test
    func `default screenshots count is zero`() {
        let set = MockRepositoryFactory.makeScreenshotSet(id: "1", displayType: .desktop)
        #expect(set.screenshotsCount == 0)
    }

    @Test
    func `set carries parent localizationId`() {
        let set = MockRepositoryFactory.makeScreenshotSet(id: "s1", localizationId: "loc-99")
        #expect(set.localizationId == "loc-99")
    }

    @Test
    func `set is equatable`() {
        let a = MockRepositoryFactory.makeScreenshotSet(id: "1")
        let b = MockRepositoryFactory.makeScreenshotSet(id: "1")
        #expect(a == b)
    }
}
