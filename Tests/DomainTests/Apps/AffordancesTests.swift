import Testing
@testable import Domain

@Suite
struct AffordancesTests {

    // MARK: - App affordances

    @Test
    func `app affordances include listVersions command`() {
        let app = App(id: "app-1", name: "My App", bundleId: "com.example")
        #expect(app.affordances["listVersions"] == "asc versions list --app-id app-1")
    }

    // MARK: - AppStoreVersion affordances

    @Test
    func `version affordances include listLocalizations and listVersions`() {
        let version = MockRepositoryFactory.makeVersion(id: "v1", appId: "app-abc")
        #expect(version.affordances["listLocalizations"] == "asc localizations list --version-id v1")
        #expect(version.affordances["listVersions"] == "asc versions list --app-id app-abc")
    }

    @Test
    func `version affordances include submitForReview only when editable`() {
        let editable = MockRepositoryFactory.makeVersion(id: "v1", state: .prepareForSubmission)
        let live = MockRepositoryFactory.makeVersion(id: "v2", state: .readyForSale)
        #expect(editable.affordances["submitForReview"] != nil)
        #expect(live.affordances["submitForReview"] == nil)
    }

    // MARK: - AppStoreVersionLocalization affordances

    @Test
    func `localization affordances include listScreenshotSets and listLocalizations`() {
        let loc = MockRepositoryFactory.makeLocalization(id: "loc-1", versionId: "v1")
        #expect(loc.affordances["listScreenshotSets"] == "asc screenshot-sets list --localization-id loc-1")
        #expect(loc.affordances["listLocalizations"] == "asc localizations list --version-id v1")
    }

    @Test
    func `localization affordances include updateLocalization command`() {
        let loc = MockRepositoryFactory.makeLocalization(id: "loc-42", versionId: "v1")
        #expect(loc.affordances["updateLocalization"] == "asc localizations update --localization-id loc-42")
    }

    // MARK: - ReviewSubmission affordances

    @Test
    func `review submission affordances include listVersions command`() {
        let submission = MockRepositoryFactory.makeReviewSubmission(id: "sub-1", appId: "app-abc")
        #expect(submission.affordances["listVersions"] == "asc versions list --app-id app-abc")
    }

    // MARK: - App affordances (extended)

    @Test
    func `app affordances include listAppInfos command`() {
        let app = App(id: "app-1", name: "My App", bundleId: "com.example")
        #expect(app.affordances["listAppInfos"] == "asc app-infos list --app-id app-1")
    }

    // MARK: - AppInfo affordances

    @Test
    func `app info affordances include listLocalizations and listAppInfos`() {
        let info = MockRepositoryFactory.makeAppInfo(id: "info-1", appId: "app-abc")
        #expect(info.affordances["listLocalizations"] == "asc app-info-localizations list --app-info-id info-1")
        #expect(info.affordances["listAppInfos"] == "asc app-infos list --app-id app-abc")
    }

    // MARK: - AppInfoLocalization affordances

    @Test
    func `app info localization affordances include listLocalizations and updateLocalization`() {
        let loc = MockRepositoryFactory.makeAppInfoLocalization(id: "loc-1", appInfoId: "info-abc")
        #expect(loc.affordances["listLocalizations"] == "asc app-info-localizations list --app-info-id info-abc")
        #expect(loc.affordances["updateLocalization"] == "asc app-info-localizations update --localization-id loc-1")
    }

    // MARK: - AuthStatus affordances

    @Test
    func `auth status affordances include check login and logout`() {
        let status = MockRepositoryFactory.makeAuthStatus(keyID: "KEY123")
        #expect(status.affordances["check"] == "asc auth check")
        #expect(status.affordances["login"] == "asc auth login --key-id <id> --issuer-id <id> --private-key-path <path>")
        #expect(status.affordances["logout"] == "asc auth logout")
    }

    // MARK: - AppScreenshotSet affordances

    @Test
    func `screenshot set affordances include listScreenshots and listScreenshotSets`() {
        let set = MockRepositoryFactory.makeScreenshotSet(id: "set-1", localizationId: "loc-1")
        #expect(set.affordances["listScreenshots"] == "asc screenshots list --set-id set-1")
        #expect(set.affordances["listScreenshotSets"] == "asc screenshot-sets list --localization-id loc-1")
    }
}
