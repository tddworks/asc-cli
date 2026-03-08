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
        state: AppStoreVersionState = .readyForSale,
        buildId: String? = nil
    ) -> AppStoreVersion {
        AppStoreVersion(id: id, appId: appId, versionString: versionString, platform: platform, state: state, buildId: buildId)
    }

    static func makeReviewDetail(
        id: String = "rd-1",
        versionId: String = "version-1",
        contactFirstName: String? = "John",
        contactLastName: String? = "Doe",
        contactPhone: String? = "+1-555-0100",
        contactEmail: String? = "john@example.com",
        demoAccountRequired: Bool = false,
        demoAccountName: String? = nil,
        demoAccountPassword: String? = nil,
        notes: String? = nil
    ) -> AppStoreReviewDetail {
        AppStoreReviewDetail(
            id: id,
            versionId: versionId,
            contactFirstName: contactFirstName,
            contactLastName: contactLastName,
            contactPhone: contactPhone,
            contactEmail: contactEmail,
            demoAccountRequired: demoAccountRequired,
            demoAccountName: demoAccountName,
            demoAccountPassword: demoAccountPassword,
            notes: notes
        )
    }

    static func makeVersionReadiness(
        id: String = "v-1",
        appId: String = "app-1",
        versionString: String = "1.2.0",
        state: AppStoreVersionState = .prepareForSubmission,
        isReadyToSubmit: Bool = true,
        stateCheck: ReadinessCheck = .pass(),
        buildCheck: BuildReadinessCheck = BuildReadinessCheck(linked: true, valid: true, notExpired: true, buildVersion: "1.2.0 (55)"),
        pricingCheck: ReadinessCheck = .pass(),
        localizationCheck: LocalizationReadinessCheck = LocalizationReadinessCheck(localizations: []),
        reviewContactCheck: ReadinessCheck = .pass()
    ) -> VersionReadiness {
        VersionReadiness(
            id: id,
            appId: appId,
            versionString: versionString,
            state: state,
            isReadyToSubmit: isReadyToSubmit,
            stateCheck: stateCheck,
            buildCheck: buildCheck,
            pricingCheck: pricingCheck,
            localizationCheck: localizationCheck,
            reviewContactCheck: reviewContactCheck
        )
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
        appId: String = "app-1",
        primaryCategoryId: String? = nil,
        secondaryCategoryId: String? = nil
    ) -> AppInfo {
        AppInfo(id: id, appId: appId, primaryCategoryId: primaryCategoryId, secondaryCategoryId: secondaryCategoryId)
    }

    static func makeAppCategory(
        id: String = "6014",
        platforms: [String] = ["IOS"],
        parentId: String? = nil
    ) -> AppCategory {
        AppCategory(id: id, platforms: platforms, parentId: parentId)
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

    // MARK: - App Previews

    static func makePreviewSet(
        id: String = "set-1",
        localizationId: String = "loc-1",
        previewType: PreviewType = .iphone67,
        previewsCount: Int = 0
    ) -> AppPreviewSet {
        AppPreviewSet(
            id: id,
            localizationId: localizationId,
            previewType: previewType,
            previewsCount: previewsCount
        )
    }

    static func makePreview(
        id: String = "prev-1",
        setId: String = "set-1",
        fileName: String = "preview.mp4",
        fileSize: Int = 10_485_760,
        mimeType: String? = "video/mp4",
        assetDeliveryState: AppPreview.AssetDeliveryState? = .complete,
        videoDeliveryState: AppPreview.VideoDeliveryState? = .complete,
        videoURL: String? = nil,
        previewFrameTimeCode: String? = nil
    ) -> AppPreview {
        AppPreview(
            id: id,
            setId: setId,
            fileName: fileName,
            fileSize: fileSize,
            mimeType: mimeType,
            assetDeliveryState: assetDeliveryState,
            videoDeliveryState: videoDeliveryState,
            videoURL: videoURL,
            previewFrameTimeCode: previewFrameTimeCode
        )
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

    // MARK: - InAppPurchases

    static func makeInAppPurchase(
        id: String = "iap-1",
        appId: String = "app-1",
        referenceName: String = "Gold Coins",
        productId: String = "com.app.gold",
        type: InAppPurchaseType = .consumable,
        state: InAppPurchaseState = .missingMetadata
    ) -> InAppPurchase {
        InAppPurchase(
            id: id,
            appId: appId,
            referenceName: referenceName,
            productId: productId,
            type: type,
            state: state
        )
    }

    static func makeInAppPurchaseSubmission(
        id: String = "sub-1",
        iapId: String = "iap-1"
    ) -> InAppPurchaseSubmission {
        InAppPurchaseSubmission(id: id, iapId: iapId)
    }

    static func makeInAppPurchasePricePoint(
        id: String = "pp-1",
        iapId: String = "iap-1",
        territory: String? = "USA",
        customerPrice: String? = "0.99",
        proceeds: String? = "0.70"
    ) -> InAppPurchasePricePoint {
        InAppPurchasePricePoint(id: id, iapId: iapId, territory: territory, customerPrice: customerPrice, proceeds: proceeds)
    }

    static func makeInAppPurchasePriceSchedule(
        id: String = "sched-1",
        iapId: String = "iap-1"
    ) -> InAppPurchasePriceSchedule {
        InAppPurchasePriceSchedule(id: id, iapId: iapId)
    }

    static func makeInAppPurchaseLocalization(
        id: String = "iap-loc-1",
        iapId: String = "iap-1",
        locale: String = "en-US",
        name: String? = "Gold Coins",
        description: String? = nil,
        state: InAppPurchaseLocalizationState? = nil
    ) -> InAppPurchaseLocalization {
        InAppPurchaseLocalization(
            id: id,
            iapId: iapId,
            locale: locale,
            name: name,
            description: description,
            state: state
        )
    }

    // MARK: - Subscriptions

    static func makeSubscriptionGroup(
        id: String = "grp-1",
        appId: String = "app-1",
        referenceName: String = "Premium Plans"
    ) -> SubscriptionGroup {
        SubscriptionGroup(id: id, appId: appId, referenceName: referenceName)
    }

    static func makeSubscription(
        id: String = "sub-1",
        groupId: String = "grp-1",
        name: String = "Monthly Premium",
        productId: String = "com.app.monthly",
        subscriptionPeriod: SubscriptionPeriod = .oneMonth,
        isFamilySharable: Bool = false,
        state: SubscriptionState = .missingMetadata,
        groupLevel: Int? = nil
    ) -> Subscription {
        Subscription(
            id: id,
            groupId: groupId,
            name: name,
            productId: productId,
            subscriptionPeriod: subscriptionPeriod,
            isFamilySharable: isFamilySharable,
            state: state,
            groupLevel: groupLevel
        )
    }

    static func makeSubscriptionSubmission(
        id: String = "sub-submit-1",
        subscriptionId: String = "sub-1"
    ) -> SubscriptionSubmission {
        SubscriptionSubmission(id: id, subscriptionId: subscriptionId)
    }

    static func makeSubscriptionIntroductoryOffer(
        id: String = "offer-1",
        subscriptionId: String = "sub-1",
        duration: SubscriptionOfferDuration = .oneMonth,
        offerMode: SubscriptionOfferMode = .freeTrial,
        numberOfPeriods: Int = 1,
        startDate: String? = nil,
        endDate: String? = nil,
        territory: String? = nil
    ) -> SubscriptionIntroductoryOffer {
        SubscriptionIntroductoryOffer(
            id: id,
            subscriptionId: subscriptionId,
            duration: duration,
            offerMode: offerMode,
            numberOfPeriods: numberOfPeriods,
            startDate: startDate,
            endDate: endDate,
            territory: territory
        )
    }

    static func makeSubscriptionLocalization(
        id: String = "sub-loc-1",
        subscriptionId: String = "sub-1",
        locale: String = "en-US",
        name: String? = "Monthly Premium",
        description: String? = nil,
        state: SubscriptionLocalizationState? = nil
    ) -> SubscriptionLocalization {
        SubscriptionLocalization(
            id: id,
            subscriptionId: subscriptionId,
            locale: locale,
            name: name,
            description: description,
            state: state
        )
    }

    // MARK: - AgeRating

    static func makeAgeRatingDeclaration(
        id: String = "decl-1",
        appInfoId: String = "info-1",
        isAdvertising: Bool? = nil,
        isGambling: Bool? = nil,
        violenceRealistic: ContentIntensity? = nil,
        ageRatingOverride: AgeRatingOverride? = nil,
        kidsAgeBand: KidsAgeBand? = nil
    ) -> AgeRatingDeclaration {
        AgeRatingDeclaration(
            id: id,
            appInfoId: appInfoId,
            isAdvertising: isAdvertising,
            isGambling: isGambling,
            violenceRealistic: violenceRealistic,
            kidsAgeBand: kidsAgeBand,
            ageRatingOverride: ageRatingOverride
        )
    }

    // MARK: - ScreenshotPlans

    static func makeAppShotsConfig(
        geminiApiKey: String = "test-key-123"
    ) -> AppShotsConfig {
        AppShotsConfig(geminiApiKey: geminiApiKey)
    }

    static func makeScreenPlan(
        appId: String = "app-1",
        appName: String = "Test App",
        tagline: String = "Great app for everyone",
        tone: ScreenTone = .professional,
        colors: ScreenColors = ScreenColors(primary: "#000000", accent: "#FF0000", text: "#FFFFFF", subtext: "#CCCCCC"),
        screens: [ScreenConfig] = []
    ) -> ScreenPlan {
        ScreenPlan(
            appId: appId,
            appName: appName,
            tagline: tagline,
            tone: tone,
            colors: colors,
            screens: screens
        )
    }

    static func makeScreenConfig(
        index: Int = 0,
        screenshotFile: String = "screen1.png",
        heading: String = "Work Smarter",
        subheading: String = "Organize your tasks effortlessly",
        layoutMode: LayoutMode = .center,
        visualDirection: String = "Main dashboard with task list",
        imagePrompt: String = "Clean dark UI with colorful task cards"
    ) -> ScreenConfig {
        ScreenConfig(
            index: index,
            screenshotFile: screenshotFile,
            heading: heading,
            subheading: subheading,
            layoutMode: layoutMode,
            visualDirection: visualDirection,
            imagePrompt: imagePrompt
        )
    }

    // MARK: - Plugins

    static func makePlugin(
        id: String = "slack-notify",
        name: String = "slack-notify",
        version: String = "1.0.0",
        description: String = "Send Slack notifications for App Store events",
        author: String? = "Test Author",
        executablePath: String = "/tmp/slack-notify/run",
        subscribedEvents: [PluginEvent] = [.buildUploaded, .versionSubmitted],
        isEnabled: Bool = true
    ) -> Plugin {
        Plugin(
            id: id,
            name: name,
            version: version,
            description: description,
            author: author,
            executablePath: executablePath,
            subscribedEvents: subscribedEvents,
            isEnabled: isEnabled
        )
    }

    static func makePluginEventPayload(
        event: PluginEvent = .buildUploaded,
        appId: String? = "app-1",
        versionId: String? = nil,
        buildId: String? = "build-1",
        metadata: [String: String] = [:]
    ) -> PluginEventPayload {
        PluginEventPayload(
            event: event,
            appId: appId,
            versionId: versionId,
            buildId: buildId,
            timestamp: Date(timeIntervalSince1970: 0),
            metadata: metadata
        )
    }

    static func makePluginResult(
        success: Bool = true,
        message: String? = "Notification sent",
        error: String? = nil
    ) -> PluginResult {
        PluginResult(success: success, message: message, error: error)
    }

    // MARK: - XcodeCloud

    static func makeXcodeCloudProduct(
        id: String = "prod-1",
        appId: String = "app-1",
        name: String = "My App CI",
        productType: XcodeCloudProductType = .app,
        createdDate: Date? = nil
    ) -> XcodeCloudProduct {
        XcodeCloudProduct(id: id, appId: appId, name: name, productType: productType, createdDate: createdDate)
    }

    static func makeXcodeCloudWorkflow(
        id: String = "wf-1",
        productId: String = "prod-1",
        name: String = "CI Build",
        description: String? = nil,
        isEnabled: Bool = true,
        isLockedForEditing: Bool = false,
        containerFilePath: String? = nil
    ) -> XcodeCloudWorkflow {
        XcodeCloudWorkflow(
            id: id, productId: productId, name: name,
            description: description, isEnabled: isEnabled,
            isLockedForEditing: isLockedForEditing, containerFilePath: containerFilePath
        )
    }

    static func makeXcodeCloudBuildRun(
        id: String = "run-1",
        workflowId: String = "wf-1",
        number: Int? = 1,
        executionProgress: XcodeCloudBuildRunExecutionProgress = .pending,
        completionStatus: XcodeCloudBuildRunCompletionStatus? = nil,
        startReason: XcodeCloudBuildRunStartReason? = nil,
        createdDate: Date? = nil,
        startedDate: Date? = nil,
        finishedDate: Date? = nil
    ) -> XcodeCloudBuildRun {
        XcodeCloudBuildRun(
            id: id, workflowId: workflowId,
            number: number, executionProgress: executionProgress,
            completionStatus: completionStatus, startReason: startReason,
            createdDate: createdDate, startedDate: startedDate, finishedDate: finishedDate
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

    static func makeGameCenterDetail(
        id: String = "gc-1",
        appId: String = "app-1",
        isArcadeEnabled: Bool = false
    ) -> GameCenterDetail {
        GameCenterDetail(id: id, appId: appId, isArcadeEnabled: isArcadeEnabled)
    }

    static func makeGameCenterAchievement(
        id: String = "ach-1",
        gameCenterDetailId: String = "gc-1",
        referenceName: String = "Test Achievement",
        vendorIdentifier: String = "test_achievement",
        points: Int = 10,
        isShowBeforeEarned: Bool = false,
        isRepeatable: Bool = false,
        isArchived: Bool = false
    ) -> GameCenterAchievement {
        GameCenterAchievement(
            id: id,
            gameCenterDetailId: gameCenterDetailId,
            referenceName: referenceName,
            vendorIdentifier: vendorIdentifier,
            points: points,
            isShowBeforeEarned: isShowBeforeEarned,
            isRepeatable: isRepeatable,
            isArchived: isArchived
        )
    }

    static func makeGameCenterLeaderboard(
        id: String = "lb-1",
        gameCenterDetailId: String = "gc-1",
        referenceName: String = "Test Leaderboard",
        vendorIdentifier: String = "test_leaderboard",
        scoreSortType: ScoreSortType = .desc,
        submissionType: LeaderboardSubmissionType = .bestScore,
        isArchived: Bool = false
    ) -> GameCenterLeaderboard {
        GameCenterLeaderboard(
            id: id,
            gameCenterDetailId: gameCenterDetailId,
            referenceName: referenceName,
            vendorIdentifier: vendorIdentifier,
            scoreSortType: scoreSortType,
            submissionType: submissionType,
            isArchived: isArchived
        )
    }
}
