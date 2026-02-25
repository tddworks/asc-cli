import Foundation
import Mockable
@testable import Domain

struct MockRepositoryFactory {

    static func makeAuthStatus(
        keyID: String = "TEST_KEY_ID",
        issuerID: String = "TEST_ISSUER_ID",
        source: CredentialSource = .file
    ) -> AuthStatus {
        AuthStatus(keyID: keyID, issuerID: issuerID, source: source)
    }

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
        appId: String = "app-1",
        name: String = "External Testers",
        isInternalGroup: Bool = false
    ) -> BetaGroup {
        BetaGroup(id: id, appId: appId, name: name, isInternalGroup: isInternalGroup)
    }

    static func makeBetaTester(
        id: String = "1",
        groupId: String = "group-1",
        firstName: String? = "John",
        lastName: String? = "Doe",
        email: String? = "john@example.com"
    ) -> BetaTester {
        BetaTester(id: id, groupId: groupId, firstName: firstName, lastName: lastName, email: email)
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
        locale: String = "en-US",
        whatsNew: String? = nil,
        description: String? = nil,
        keywords: String? = nil,
        marketingUrl: String? = nil,
        supportUrl: String? = nil,
        promotionalText: String? = nil
    ) -> AppStoreVersionLocalization {
        AppStoreVersionLocalization(
            id: id,
            versionId: versionId,
            locale: locale,
            whatsNew: whatsNew,
            description: description,
            keywords: keywords,
            marketingUrl: marketingUrl,
            supportUrl: supportUrl,
            promotionalText: promotionalText
        )
    }

    static func makeScreenshotSet(
        id: String = "1",
        localizationId: String = "loc-1",
        displayType: ScreenshotDisplayType = .iphone67,
        screenshotsCount: Int = 0,
        repo: (any ScreenshotRepository)? = nil
    ) -> AppScreenshotSet {
        AppScreenshotSet(
            id: id,
            localizationId: localizationId,
            screenshotDisplayType: displayType,
            screenshotsCount: screenshotsCount,
            repo: repo
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

    static func makeAppInfo(
        id: String = "info-1",
        appId: String = "app-1"
    ) -> AppInfo {
        AppInfo(id: id, appId: appId)
    }

    static func makeAppInfoLocalization(
        id: String = "loc-1",
        appInfoId: String = "info-1",
        locale: String = "en-US",
        name: String? = "My App",
        subtitle: String? = nil,
        privacyPolicyUrl: String? = nil
    ) -> AppInfoLocalization {
        AppInfoLocalization(
            id: id,
            appInfoId: appInfoId,
            locale: locale,
            name: name,
            subtitle: subtitle,
            privacyPolicyUrl: privacyPolicyUrl
        )
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

    // MARK: - Build Upload

    static func makeBuildUpload(
        id: String = "upload-1",
        appId: String = "app-1",
        version: String = "1.0.0",
        buildNumber: String = "1",
        platform: BuildUploadPlatform = .iOS,
        state: BuildUploadState = .complete
    ) -> BuildUpload {
        BuildUpload(
            id: id,
            appId: appId,
            version: version,
            buildNumber: buildNumber,
            platform: platform,
            state: state
        )
    }

    static func makeBetaBuildLocalization(
        id: String = "bbl-1",
        buildId: String = "build-1",
        locale: String = "en-US",
        whatsNew: String? = "Bug fixes and improvements"
    ) -> BetaBuildLocalization {
        BetaBuildLocalization(id: id, buildId: buildId, locale: locale, whatsNew: whatsNew)
    }

    // MARK: - Code Signing

    static func makeBundleID(
        id: String = "bid-1",
        name: String = "My App",
        identifier: String = "com.example.app",
        platform: BundleIDPlatform = .iOS,
        seedID: String? = nil
    ) -> BundleID {
        BundleID(id: id, name: name, identifier: identifier, platform: platform, seedID: seedID)
    }

    static func makeCertificate(
        id: String = "cert-1",
        name: String = "iOS Distribution",
        certificateType: CertificateType = .distribution,
        displayName: String? = nil,
        serialNumber: String? = nil,
        platform: BundleIDPlatform? = nil,
        expirationDate: Date? = nil,
        certificateContent: String? = nil
    ) -> Certificate {
        Certificate(
            id: id,
            name: name,
            certificateType: certificateType,
            displayName: displayName,
            serialNumber: serialNumber,
            platform: platform,
            expirationDate: expirationDate,
            certificateContent: certificateContent
        )
    }

    static func makeDevice(
        id: String = "dev-1",
        name: String = "My iPhone",
        udid: String = "00000000-0000-0000-0000-000000000000",
        deviceClass: DeviceClass = .iPhone,
        platform: BundleIDPlatform = .iOS,
        status: DeviceStatus = .enabled,
        model: String? = nil,
        addedDate: Date? = nil
    ) -> Device {
        Device(
            id: id,
            name: name,
            udid: udid,
            deviceClass: deviceClass,
            platform: platform,
            status: status,
            model: model,
            addedDate: addedDate
        )
    }

    static func makeProfile(
        id: String = "prof-1",
        name: String = "My Profile",
        profileType: ProfileType = .iosAppStore,
        profileState: ProfileState = .active,
        bundleIdId: String = "bid-1",
        expirationDate: Date? = nil,
        uuid: String? = nil,
        profileContent: String? = nil
    ) -> Profile {
        Profile(
            id: id,
            name: name,
            profileType: profileType,
            profileState: profileState,
            bundleIdId: bundleIdId,
            expirationDate: expirationDate,
            uuid: uuid,
            profileContent: profileContent
        )
    }
}
