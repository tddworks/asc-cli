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
        #expect(version.affordances["listLocalizations"] == "asc version-localizations list --version-id v1")
        #expect(version.affordances["listVersions"] == "asc versions list --app-id app-abc")
    }

    @Test
    func `version affordances include checkReadiness always`() {
        let version = MockRepositoryFactory.makeVersion(id: "v1", state: .readyForSale)
        #expect(version.affordances["checkReadiness"] == "asc versions check-readiness --version-id v1")
    }

    @Test
    func `version affordances include submitForReview only when editable`() {
        let editable = MockRepositoryFactory.makeVersion(id: "v1", state: .prepareForSubmission)
        let live = MockRepositoryFactory.makeVersion(id: "v2", state: .readyForSale)
        #expect(editable.affordances["submitForReview"] != nil)
        #expect(live.affordances["submitForReview"] == nil)
    }

    // MARK: - VersionReadiness affordances

    @Test
    func `version readiness affordances include checkReadiness and listLocalizations always`() {
        let readiness = MockRepositoryFactory.makeVersionReadiness(id: "v-42", isReadyToSubmit: false)
        #expect(readiness.affordances["checkReadiness"] == "asc versions check-readiness --version-id v-42")
        #expect(readiness.affordances["listLocalizations"] == "asc version-localizations list --version-id v-42")
    }

    @Test
    func `version readiness affordances include submit only when ready to submit`() {
        let ready = MockRepositoryFactory.makeVersionReadiness(id: "v-r", isReadyToSubmit: true)
        let notReady = MockRepositoryFactory.makeVersionReadiness(id: "v-n", isReadyToSubmit: false)
        #expect(ready.affordances["submit"] == "asc versions submit --version-id v-r")
        #expect(notReady.affordances["submit"] == nil)
    }

    // MARK: - AppStoreVersionLocalization affordances

    @Test
    func `localization affordances include listScreenshotSets and listLocalizations`() {
        let loc = MockRepositoryFactory.makeLocalization(id: "loc-1", versionId: "v1")
        #expect(loc.affordances["listScreenshotSets"] == "asc screenshot-sets list --localization-id loc-1")
        #expect(loc.affordances["listLocalizations"] == "asc version-localizations list --version-id v1")
    }

    @Test
    func `localization affordances include updateLocalization command`() {
        let loc = MockRepositoryFactory.makeLocalization(id: "loc-42", versionId: "v1")
        #expect(loc.affordances["updateLocalization"] == "asc version-localizations update --localization-id loc-42")
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

    // MARK: - BundleID affordances

    @Test
    func `bundle id affordances include listProfiles and delete`() {
        let bundleId = MockRepositoryFactory.makeBundleID(id: "bid-42")
        #expect(bundleId.affordances["listProfiles"] == "asc profiles list --bundle-id-id bid-42")
        #expect(bundleId.affordances["delete"] == "asc bundle-ids delete --bundle-id-id bid-42")
    }

    // MARK: - Certificate affordances

    @Test
    func `certificate affordances include revoke`() {
        let cert = MockRepositoryFactory.makeCertificate(id: "cert-1")
        #expect(cert.affordances["revoke"] == "asc certificates revoke --certificate-id cert-1")
    }

    // MARK: - Device affordances

    @Test
    func `device affordances include listDevices`() {
        let device = MockRepositoryFactory.makeDevice(id: "dev-1")
        #expect(device.affordances["listDevices"] == "asc devices list")
    }

    // MARK: - Profile affordances

    @Test
    func `profile affordances include delete and listProfiles`() {
        let profile = MockRepositoryFactory.makeProfile(id: "prof-1", bundleIdId: "bid-abc")
        #expect(profile.affordances["delete"] == "asc profiles delete --profile-id prof-1")
        #expect(profile.affordances["listProfiles"] == "asc profiles list --bundle-id-id bid-abc")
    }

    // MARK: - BuildUpload affordances

    @Test
    func `build upload affordances include checkStatus always`() {
        let upload = MockRepositoryFactory.makeBuildUpload(id: "up-1", appId: "app-1", state: .processing)
        #expect(upload.affordances["checkStatus"] == "asc builds uploads get --upload-id up-1")
    }

    @Test
    func `build upload affordances include listBuilds only when complete`() {
        let complete = MockRepositoryFactory.makeBuildUpload(id: "up-1", appId: "app-1", state: .complete)
        let processing = MockRepositoryFactory.makeBuildUpload(id: "up-2", appId: "app-1", state: .processing)
        #expect(complete.affordances["listBuilds"] == "asc builds list --app-id app-1")
        #expect(processing.affordances["listBuilds"] == nil)
    }

    // MARK: - BetaGroup affordances

    @Test
    func `beta group affordances include listTesters importTesters and exportTesters`() {
        let group = MockRepositoryFactory.makeBetaGroup(id: "g-1", appId: "app-1")
        #expect(group.affordances["listTesters"] == "asc testflight testers list --beta-group-id g-1")
        #expect(group.affordances["importTesters"] == "asc testflight testers import --beta-group-id g-1 --file testers.csv")
        #expect(group.affordances["exportTesters"] == "asc testflight testers export --beta-group-id g-1")
    }

    // MARK: - BetaTester affordances

    @Test
    func `beta tester affordances include remove and listTesters`() {
        let tester = MockRepositoryFactory.makeBetaTester(id: "t-1", groupId: "g-1")
        #expect(tester.affordances["remove"] == "asc testflight testers remove --beta-group-id g-1 --tester-id t-1")
        #expect(tester.affordances["listTesters"] == "asc testflight testers list --beta-group-id g-1")
    }

    // MARK: - BetaBuildLocalization affordances

    @Test
    func `beta build localization affordances include updateNotes`() {
        let loc = MockRepositoryFactory.makeBetaBuildLocalization(id: "bbl-1", buildId: "build-abc", locale: "en-US")
        #expect(loc.affordances["updateNotes"] == "asc builds update-beta-notes --build-id build-abc --locale en-US --notes <text>")
    }

    // MARK: - AppPreviewSet affordances

    @Test
    func `preview set affordances include listPreviews and listPreviewSets`() {
        let set = MockRepositoryFactory.makePreviewSet(id: "set-1", localizationId: "loc-1")
        #expect(set.affordances["listPreviews"] == "asc app-previews list --set-id set-1")
        #expect(set.affordances["listPreviewSets"] == "asc app-preview-sets list --localization-id loc-1")
    }

    // MARK: - AppPreview affordances

    @Test
    func `preview affordances include listPreviews`() {
        let preview = MockRepositoryFactory.makePreview(id: "p-1", setId: "set-1")
        #expect(preview.affordances["listPreviews"] == "asc app-previews list --set-id set-1")
    }
}
