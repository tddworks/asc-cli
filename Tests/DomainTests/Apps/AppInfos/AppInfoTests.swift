import Testing
@testable import Domain

@Suite
struct AppInfoTests {

    @Test func `appInfo carries appId`() {
        let info = AppInfo(id: "info-1", appId: "app-42")
        #expect(info.appId == "app-42")
    }

    @Test func `appInfo affordances include listLocalizations command`() {
        let info = AppInfo(id: "info-1", appId: "app-42")
        #expect(info.affordances["listLocalizations"] == "asc app-info-localizations list --app-info-id info-1")
    }

    @Test func `appInfo affordances include listAppInfos command`() {
        let info = AppInfo(id: "info-1", appId: "app-42")
        #expect(info.affordances["listAppInfos"] == "asc app-infos list --app-id app-42")
    }

    @Test func `appInfo category ids default to nil`() {
        let info = AppInfo(id: "info-1", appId: "app-1")
        #expect(info.primaryCategoryId == nil)
        #expect(info.secondaryCategoryId == nil)
    }

    @Test func `appInfo carries primary and secondary category ids`() {
        let info = AppInfo(id: "info-1", appId: "app-1", primaryCategoryId: "6014", secondaryCategoryId: "6005")
        #expect(info.primaryCategoryId == "6014")
        #expect(info.secondaryCategoryId == "6005")
    }

    @Test func `appInfo affordances include updateCategories command`() {
        let info = AppInfo(id: "info-42", appId: "app-1")
        #expect(info.affordances["updateCategories"] == "asc app-infos update --app-info-id info-42")
    }

    @Test func `appInfo carries appStoreState and state`() {
        let info = AppInfo(
            id: "info-1",
            appId: "app-1",
            appStoreState: "READY_FOR_SALE",
            state: "READY_FOR_DISTRIBUTION"
        )
        #expect(info.appStoreState == "READY_FOR_SALE")
        #expect(info.state == "READY_FOR_DISTRIBUTION")
    }

    @Test func `appInfo state defaults to nil`() {
        let info = AppInfo(id: "info-1", appId: "app-1")
        #expect(info.appStoreState == nil)
        #expect(info.state == nil)
    }
}
