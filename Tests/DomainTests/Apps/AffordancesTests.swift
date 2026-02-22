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

    // MARK: - ReviewSubmission affordances

    @Test
    func `review submission affordances include listVersions command`() {
        let submission = MockRepositoryFactory.makeReviewSubmission(id: "sub-1", appId: "app-abc")
        #expect(submission.affordances["listVersions"] == "asc versions list --app-id app-abc")
    }

    // MARK: - AppScreenshotSet affordances

    @Test
    func `screenshot set affordances include listScreenshots and listScreenshotSets`() {
        let set = MockRepositoryFactory.makeScreenshotSet(id: "set-1", localizationId: "loc-1")
        #expect(set.affordances["listScreenshots"] == "asc screenshots list --set-id set-1")
        #expect(set.affordances["listScreenshotSets"] == "asc screenshot-sets list --localization-id loc-1")
    }
}
