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

    static func makeScreenshotSet(
        id: String = "1",
        displayType: ScreenshotDisplayType = .iphone67,
        screenshotsCount: Int = 0
    ) -> AppScreenshotSet {
        AppScreenshotSet(id: id, screenshotDisplayType: displayType, screenshotsCount: screenshotsCount)
    }

    static func makeScreenshot(
        id: String = "1",
        fileName: String = "screenshot.png",
        fileSize: Int = 1_048_576,
        assetState: AppScreenshot.AssetDeliveryState? = .complete,
        imageWidth: Int? = 2796,
        imageHeight: Int? = 1290
    ) -> AppScreenshot {
        AppScreenshot(
            id: id,
            fileName: fileName,
            fileSize: fileSize,
            assetState: assetState,
            imageWidth: imageWidth,
            imageHeight: imageHeight
        )
    }
}
