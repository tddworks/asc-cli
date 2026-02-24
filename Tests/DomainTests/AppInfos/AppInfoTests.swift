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
}
