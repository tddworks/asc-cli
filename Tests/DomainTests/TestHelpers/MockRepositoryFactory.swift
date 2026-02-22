import Foundation
import Mockable
@testable import Domain

struct MockRepositoryFactory {

    static func makeAuthCredentials(
        keyID: String = "TEST_KEY_ID",
        issuerID: String = "TEST_ISSUER_ID",
        privateKeyPEM: String = "-----BEGIN PRIVATE KEY-----\ntest\n-----END PRIVATE KEY-----"
    ) -> AuthCredentials {
        AuthCredentials(keyID: keyID, issuerID: issuerID, privateKeyPEM: privateKeyPEM)
    }

    static func makeApp(
        id: String = "1",
        name: String = "Test App",
        bundleId: String = "com.test.app",
        sku: String? = nil,
        primaryLocale: String? = "en-US"
    ) -> App {
        App(id: id, name: name, bundleId: bundleId, sku: sku, primaryLocale: primaryLocale)
    }

    static func makeBuild(
        id: String = "1",
        version: String = "1.0",
        expired: Bool = false,
        processingState: Build.ProcessingState = .valid,
        buildNumber: String? = "1"
    ) -> Build {
        Build(
            id: id,
            version: version,
            expired: expired,
            processingState: processingState,
            buildNumber: buildNumber
        )
    }

    static func makeBetaGroup(
        id: String = "1",
        name: String = "External Testers",
        isInternalGroup: Bool = false
    ) -> BetaGroup {
        BetaGroup(id: id, name: name, isInternalGroup: isInternalGroup)
    }

    static func makeBetaTester(
        id: String = "1",
        firstName: String? = "John",
        lastName: String? = "Doe",
        email: String? = "john@example.com"
    ) -> BetaTester {
        BetaTester(id: id, firstName: firstName, lastName: lastName, email: email)
    }

    static func makeVersion(
        id: String = "1",
        appId: String = "app-1",
        versionString: String = "1.0.0",
        platform: AppStorePlatform = .iOS,
        state: AppStoreVersionState = .readyForSale
    ) -> AppStoreVersion {
        AppStoreVersion(id: id, appId: appId, versionString: versionString, platform: platform, state: state)
    }

    static func makeLocalization(
        id: String = "1",
        versionId: String = "version-1",
        locale: String = "en-US"
    ) -> AppStoreVersionLocalization {
        AppStoreVersionLocalization(id: id, versionId: versionId, locale: locale)
    }

    static func makeScreenshotSet(
        id: String = "1",
        localizationId: String = "loc-1",
        displayType: ScreenshotDisplayType = .iphone67,
        screenshotsCount: Int = 0
    ) -> AppScreenshotSet {
        AppScreenshotSet(
            id: id,
            localizationId: localizationId,
            screenshotDisplayType: displayType,
            screenshotsCount: screenshotsCount
        )
    }

    static func makeReviewSubmission(
        id: String = "sub-1",
        appId: String = "app-1",
        platform: AppStorePlatform = .iOS,
        state: ReviewSubmissionState = .waitingForReview,
        submittedDate: Date? = nil
    ) -> ReviewSubmission {
        ReviewSubmission(id: id, appId: appId, platform: platform, state: state, submittedDate: submittedDate)
    }

    static func makeScreenshot(
        id: String = "1",
        setId: String = "set-1",
        fileName: String = "screenshot.png",
        fileSize: Int = 1_048_576,
        assetState: AppScreenshot.AssetDeliveryState? = .complete,
        imageWidth: Int? = 2796,
        imageHeight: Int? = 1290
    ) -> AppScreenshot {
        AppScreenshot(
            id: id,
            setId: setId,
            fileName: fileName,
            fileSize: fileSize,
            assetState: assetState,
            imageWidth: imageWidth,
            imageHeight: imageHeight
        )
    }
}
