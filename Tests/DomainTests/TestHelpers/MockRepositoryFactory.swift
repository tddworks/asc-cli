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
        buildNumber: String? = "1",
        platform: BuildUploadPlatform? = nil
    ) -> Build {
        Build(
            id: id,
            version: version,
            expired: expired,
            processingState: processingState,
            buildNumber: buildNumber,
            platform: platform
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
        imageHeight: Int? = 1290,
        sourceUrl: String? = nil
    ) -> AppScreenshot {
        AppScreenshot(
            id: id,
            setId: setId,
            fileName: fileName,
            fileSize: fileSize,
            assetState: assetState,
            imageWidth: imageWidth,
            imageHeight: imageHeight,
            sourceUrl: sourceUrl
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

    // MARK: - App Availability

    static func makeAppTerritoryAvailability(
        id: String = "ta-1",
        territoryId: String = "USA",
        isAvailable: Bool = true,
        releaseDate: String? = nil,
        isPreOrderEnabled: Bool = false,
        contentStatuses: [ContentStatus] = [.available]
    ) -> AppTerritoryAvailability {
        AppTerritoryAvailability(
            id: id,
            territoryId: territoryId,
            isAvailable: isAvailable,
            releaseDate: releaseDate,
            isPreOrderEnabled: isPreOrderEnabled,
            contentStatuses: contentStatuses
        )
    }

    static func makeAppAvailability(
        id: String = "avail-1",
        appId: String = "app-1",
        isAvailableInNewTerritories: Bool = true,
        territories: [AppTerritoryAvailability] = [AppTerritoryAvailability(id: "ta-1", territoryId: "USA", isAvailable: true, releaseDate: nil, isPreOrderEnabled: false, contentStatuses: [.available])]
    ) -> AppAvailability {
        AppAvailability(
            id: id,
            appId: appId,
            isAvailableInNewTerritories: isAvailableInNewTerritories,
            territories: territories
        )
    }

    // MARK: - Territories

    static func makeTerritory(
        id: String = "USA",
        currency: String? = "USD"
    ) -> Territory {
        Territory(id: id, currency: currency)
    }

    // MARK: - IAP Availability

    static func makeInAppPurchaseAvailability(
        id: String = "avail-1",
        iapId: String = "iap-1",
        isAvailableInNewTerritories: Bool = true,
        territories: [Territory] = [Territory(id: "USA", currency: "USD")]
    ) -> InAppPurchaseAvailability {
        InAppPurchaseAvailability(
            id: id,
            iapId: iapId,
            isAvailableInNewTerritories: isAvailableInNewTerritories,
            territories: territories
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

    // MARK: - Subscription Availability

    static func makeSubscriptionAvailability(
        id: String = "avail-1",
        subscriptionId: String = "sub-1",
        isAvailableInNewTerritories: Bool = true,
        territories: [Territory] = [Territory(id: "USA", currency: "USD")]
    ) -> SubscriptionAvailability {
        SubscriptionAvailability(
            id: id,
            subscriptionId: subscriptionId,
            isAvailableInNewTerritories: isAvailableInNewTerritories,
            territories: territories
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

    // MARK: - Screenshots

    static func makeAppShotsConfig(
        geminiApiKey: String = "test-key-123"
    ) -> AppShotsConfig {
        AppShotsConfig(geminiApiKey: geminiApiKey)
    }

    // MARK: - Plugins

    static func makePlugin(
        id: String = "asc-pro",
        name: String = "ASC Pro",
        version: String = "1.0",
        description: String = "Simulator streaming, interaction & tunnel sharing",
        author: String? = "tddworks",
        repositoryURL: String? = "https://github.com/tddworks/asc-registry",
        categories: [String] = ["simulators", "streaming"],
        downloadURL: String? = "https://github.com/tddworks/asc-registry/releases/latest/download/ASCPro.plugin.zip",
        isInstalled: Bool = true,
        slug: String? = "ASCPro",
        uiScripts: [String] = ["ui/sim-stream.js"]
    ) -> Plugin {
        Plugin(
            id: id,
            name: name,
            version: version,
            description: description,
            author: author,
            repositoryURL: repositoryURL,
            categories: categories,
            downloadURL: downloadURL,
            isInstalled: isInstalled,
            slug: slug,
            uiScripts: uiScripts
        )
    }

    // MARK: - Skills

    static func makeSkill(
        id: String = "asc-cli",
        name: String = "asc-cli",
        description: String = "App Store Connect CLI skill",
        isInstalled: Bool = false
    ) -> Skill {
        Skill(id: id, name: name, description: description, isInstalled: isInstalled)
    }

    static func makeSkillConfig(
        skillsCheckedAt: Date? = nil
    ) -> SkillConfig {
        SkillConfig(skillsCheckedAt: skillsCheckedAt)
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

    // MARK: - App Clips

    static func makeAppClip(
        id: String = "clip-1",
        appId: String = "app-1",
        bundleId: String? = "com.example.clip"
    ) -> AppClip {
        AppClip(id: id, appId: appId, bundleId: bundleId)
    }

    static func makeAppClipDefaultExperience(
        id: String = "exp-1",
        appClipId: String = "clip-1",
        action: AppClipAction? = .open
    ) -> AppClipDefaultExperience {
        AppClipDefaultExperience(id: id, appClipId: appClipId, action: action)
    }

    static func makeAppClipDefaultExperienceLocalization(
        id: String = "loc-1",
        experienceId: String = "exp-1",
        locale: String = "en-US",
        subtitle: String? = "Quick access"
    ) -> AppClipDefaultExperienceLocalization {
        AppClipDefaultExperienceLocalization(id: id, experienceId: experienceId, locale: locale, subtitle: subtitle)
    }

    // MARK: - Customer Reviews

    static func makeCustomerReview(
        id: String = "rev-1",
        appId: String = "app-1",
        rating: Int = 5,
        title: String? = "Great app!",
        body: String? = "Love using this app",
        reviewerNickname: String? = "user123",
        createdDate: Date? = nil,
        territory: String? = "USA"
    ) -> CustomerReview {
        CustomerReview(
            id: id,
            appId: appId,
            rating: rating,
            title: title,
            body: body,
            reviewerNickname: reviewerNickname,
            createdDate: createdDate,
            territory: territory
        )
    }

    static func makeCustomerReviewResponse(
        id: String = "resp-1",
        reviewId: String = "rev-1",
        responseBody: String = "Thank you for your feedback!",
        lastModifiedDate: Date? = nil,
        state: ReviewResponseState = .published
    ) -> CustomerReviewResponse {
        CustomerReviewResponse(
            id: id,
            reviewId: reviewId,
            responseBody: responseBody,
            lastModifiedDate: lastModifiedDate,
            state: state
        )
    }

    // MARK: - Analytics Reports

    static func makeAnalyticsReportRequest(
        id: String = "req-1",
        appId: String = "app-1",
        accessType: AnalyticsAccessType = .oneTimeSnapshot,
        isStoppedDueToInactivity: Bool? = nil
    ) -> AnalyticsReportRequest {
        AnalyticsReportRequest(id: id, appId: appId, accessType: accessType, isStoppedDueToInactivity: isStoppedDueToInactivity)
    }

    static func makeAnalyticsReport(
        id: String = "rpt-1",
        requestId: String = "req-1",
        name: String? = "App Store Downloads",
        category: AnalyticsCategory? = .appUsage
    ) -> AnalyticsReport {
        AnalyticsReport(id: id, requestId: requestId, name: name, category: category)
    }

    static func makeAnalyticsReportInstance(
        id: String = "inst-1",
        reportId: String = "rpt-1",
        granularity: AnalyticsGranularity? = .daily,
        processingDate: String? = "2024-01-15"
    ) -> AnalyticsReportInstance {
        AnalyticsReportInstance(id: id, reportId: reportId, granularity: granularity, processingDate: processingDate)
    }

    // MARK: - Performance

    static func makePerfPowerMetric(
        id: String = "m-1",
        parentId: String = "app-1",
        parentType: PerfMetricParentType = .app,
        platform: String? = "IOS",
        category: PerformanceMetricCategory = .launch,
        metricIdentifier: String = "launchTime",
        unit: String? = "s",
        latestValue: Double? = 1.5,
        latestVersion: String? = "2.0",
        goalValue: Double? = 1.0
    ) -> PerformanceMetric {
        PerformanceMetric(
            id: id,
            parentId: parentId,
            parentType: parentType,
            platform: platform,
            category: category,
            metricIdentifier: metricIdentifier,
            unit: unit,
            latestValue: latestValue,
            latestVersion: latestVersion,
            goalValue: goalValue
        )
    }

    static func makeDiagnosticSignatureInfo(
        id: String = "sig-1",
        buildId: String = "build-1",
        diagnosticType: DiagnosticType = .hangs,
        signature: String = "main thread hang",
        weight: Double = 45.2,
        insightDirection: String? = nil
    ) -> DiagnosticSignatureInfo {
        DiagnosticSignatureInfo(
            id: id,
            buildId: buildId,
            diagnosticType: diagnosticType,
            signature: signature,
            weight: weight,
            insightDirection: insightDirection
        )
    }

    static func makeDiagnosticLogEntry(
        id: String = "log-1",
        signatureId: String = "sig-1",
        bundleId: String? = "com.example.app",
        appVersion: String? = "2.0",
        buildVersion: String? = "100",
        osVersion: String? = "iOS 17.0",
        deviceType: String? = "iPhone15,2",
        event: String? = "hang",
        callStackSummary: String? = "main > UIKit > layoutSubviews"
    ) -> DiagnosticLogEntry {
        DiagnosticLogEntry(
            id: id,
            signatureId: signatureId,
            bundleId: bundleId,
            appVersion: appVersion,
            buildVersion: buildVersion,
            osVersion: osVersion,
            deviceType: deviceType,
            event: event,
            callStackSummary: callStackSummary
        )
    }

    // MARK: - Subscription Offer Codes

    static func makeSubscriptionOfferCode(
        id: String = "oc-1",
        subscriptionId: String = "sub-1",
        name: String = "SUMMER2026",
        customerEligibilities: [SubscriptionCustomerEligibility] = [.new],
        offerEligibility: SubscriptionOfferEligibility = .stackable,
        duration: SubscriptionOfferDuration = .oneMonth,
        offerMode: SubscriptionOfferMode = .freeTrial,
        numberOfPeriods: Int = 1,
        totalNumberOfCodes: Int? = nil,
        isActive: Bool = true
    ) -> SubscriptionOfferCode {
        SubscriptionOfferCode(
            id: id,
            subscriptionId: subscriptionId,
            name: name,
            customerEligibilities: customerEligibilities,
            offerEligibility: offerEligibility,
            duration: duration,
            offerMode: offerMode,
            numberOfPeriods: numberOfPeriods,
            totalNumberOfCodes: totalNumberOfCodes,
            isActive: isActive
        )
    }

    static func makeSubscriptionOfferCodeCustomCode(
        id: String = "cc-1",
        offerCodeId: String = "oc-1",
        customCode: String = "SUMMER2026",
        numberOfCodes: Int = 1000,
        createdDate: String? = nil,
        expirationDate: String? = nil,
        isActive: Bool = true
    ) -> SubscriptionOfferCodeCustomCode {
        SubscriptionOfferCodeCustomCode(
            id: id,
            offerCodeId: offerCodeId,
            customCode: customCode,
            numberOfCodes: numberOfCodes,
            createdDate: createdDate,
            expirationDate: expirationDate,
            isActive: isActive
        )
    }

    static func makeSubscriptionOfferCodeOneTimeUseCode(
        id: String = "otc-1",
        offerCodeId: String = "oc-1",
        numberOfCodes: Int = 5000,
        createdDate: String? = nil,
        expirationDate: String? = "2026-12-31",
        isActive: Bool = true
    ) -> SubscriptionOfferCodeOneTimeUseCode {
        SubscriptionOfferCodeOneTimeUseCode(
            id: id,
            offerCodeId: offerCodeId,
            numberOfCodes: numberOfCodes,
            createdDate: createdDate,
            expirationDate: expirationDate,
            isActive: isActive
        )
    }

    // MARK: - IAP Offer Codes

    static func makeIAPOfferCode(
        id: String = "oc-1",
        iapId: String = "iap-1",
        name: String = "FREEGEMS",
        customerEligibilities: [IAPCustomerEligibility] = [.nonSpender],
        isActive: Bool = true,
        totalNumberOfCodes: Int? = nil
    ) -> InAppPurchaseOfferCode {
        InAppPurchaseOfferCode(
            id: id,
            iapId: iapId,
            name: name,
            customerEligibilities: customerEligibilities,
            isActive: isActive,
            totalNumberOfCodes: totalNumberOfCodes
        )
    }

    static func makeIAPOfferCodeCustomCode(
        id: String = "cc-1",
        offerCodeId: String = "oc-1",
        customCode: String = "FREEGEMS100",
        numberOfCodes: Int = 500,
        createdDate: String? = nil,
        expirationDate: String? = nil,
        isActive: Bool = true
    ) -> InAppPurchaseOfferCodeCustomCode {
        InAppPurchaseOfferCodeCustomCode(
            id: id,
            offerCodeId: offerCodeId,
            customCode: customCode,
            numberOfCodes: numberOfCodes,
            createdDate: createdDate,
            expirationDate: expirationDate,
            isActive: isActive
        )
    }

    static func makeIAPOfferCodeOneTimeUseCode(
        id: String = "otc-1",
        offerCodeId: String = "oc-1",
        numberOfCodes: Int = 3000,
        createdDate: String? = nil,
        expirationDate: String? = "2026-06-30",
        isActive: Bool = true
    ) -> InAppPurchaseOfferCodeOneTimeUseCode {
        InAppPurchaseOfferCodeOneTimeUseCode(
            id: id,
            offerCodeId: offerCodeId,
            numberOfCodes: numberOfCodes,
            createdDate: createdDate,
            expirationDate: expirationDate,
            isActive: isActive
        )
    }

    // MARK: - Beta App Review

    static func makeBetaAppReviewSubmission(
        id: String = "sub-1",
        buildId: String = "build-1",
        state: BetaReviewState = .waitingForReview,
        submittedDate: Date? = nil
    ) -> BetaAppReviewSubmission {
        BetaAppReviewSubmission(id: id, buildId: buildId, state: state, submittedDate: submittedDate)
    }

    static func makeBetaAppReviewDetail(
        id: String = "brd-1",
        appId: String = "app-1",
        contactFirstName: String? = "John",
        contactLastName: String? = "Doe",
        contactPhone: String? = "+1-555-0100",
        contactEmail: String? = "john@example.com",
        demoAccountName: String? = nil,
        demoAccountPassword: String? = nil,
        demoAccountRequired: Bool = false,
        notes: String? = nil
    ) -> BetaAppReviewDetail {
        BetaAppReviewDetail(
            id: id,
            appId: appId,
            contactFirstName: contactFirstName,
            contactLastName: contactLastName,
            contactPhone: contactPhone,
            contactEmail: contactEmail,
            demoAccountName: demoAccountName,
            demoAccountPassword: demoAccountPassword,
            demoAccountRequired: demoAccountRequired,
            notes: notes
        )
    }

    // MARK: - XcodeBuild Archive/Export

    static func makeArchiveRequest(
        scheme: String = "MyApp",
        workspace: String? = nil,
        project: String? = nil,
        platform: BuildUploadPlatform = .iOS,
        configuration: String = "Release",
        archivePath: String = "/tmp/MyApp.xcarchive"
    ) -> ArchiveRequest {
        ArchiveRequest(
            scheme: scheme,
            workspace: workspace,
            project: project,
            platform: platform,
            configuration: configuration,
            archivePath: archivePath
        )
    }

    static func makeArchiveResult(
        archivePath: String = "/tmp/MyApp.xcarchive",
        scheme: String = "MyApp",
        platform: BuildUploadPlatform = .iOS
    ) -> ArchiveResult {
        ArchiveResult(archivePath: archivePath, scheme: scheme, platform: platform)
    }

    static func makeExportResult(
        ipaPath: String = "/tmp/export/MyApp.ipa",
        exportPath: String = "/tmp/export"
    ) -> ExportResult {
        ExportResult(ipaPath: ipaPath, exportPath: exportPath)
    }

    // MARK: - Iris

    static func makeAppBundle(
        id: String = "bundle-1",
        name: String = "Test App",
        bundleId: String = "com.test.app",
        sku: String = "TESTSKU",
        primaryLocale: String = "en-US",
        platforms: [String] = ["IOS"]
    ) -> AppBundle {
        AppBundle(
            id: id,
            name: name,
            bundleId: bundleId,
            sku: sku,
            primaryLocale: primaryLocale,
            platforms: platforms
        )
    }

    static func makeAnalyticsReportSegment(
        id: String = "seg-1",
        instanceId: String = "inst-1",
        checksum: String? = "abc123",
        sizeInBytes: Int? = 1024,
        url: String? = "https://example.com/data.tsv"
    ) -> AnalyticsReportSegment {
        AnalyticsReportSegment(id: id, instanceId: instanceId, checksum: checksum, sizeInBytes: sizeInBytes, url: url)
    }

    // MARK: - Simulators

    static func makeSimulator(
        id: String = "sim-1",
        name: String = "iPhone 16 Pro",
        state: SimulatorState = .shutdown,
        runtime: String = "com.apple.CoreSimulator.SimRuntime.iOS-18-2"
    ) -> Simulator {
        Simulator(id: id, name: name, state: state, runtime: runtime)
    }

    // MARK: - Screenshot Templates

    // MARK: - Gallery

    static func makeAppShot(
        screenshot: String = "screen-0.png",
        type: ScreenType = .feature,
        headline: String? = nil,
        badges: [String] = [],
        trustMarks: [String]? = nil
    ) -> AppShot {
        let shot = AppShot(screenshot: screenshot, type: type)
        shot.headline = headline
        shot.badges = badges
        shot.trustMarks = trustMarks
        return shot
    }

    static func makeGallery(
        appName: String = "Test App",
        screenshots: [String] = ["screen-0.png", "screen-1.png"]
    ) -> Gallery {
        Gallery(appName: appName, screenshots: screenshots)
    }

    static func makeGalleryTemplate(
        id: String = "walkthrough",
        name: String = "Feature Walkthrough",
        screens: [ScreenType: ScreenLayout] = [:]
    ) -> GalleryTemplate {
        GalleryTemplate(id: id, name: name, screens: screens)
    }

    static func makeGalleryPalette(
        id: String = "green-mint",
        name: String = "Green Mint",
        background: String = "linear-gradient(135deg, #c4f7a0, #a0f7e0)"
    ) -> GalleryPalette {
        GalleryPalette(id: id, name: name, background: background)
    }

    static func makeScreenLayout(
        headline: TextSlot = TextSlot(y: 0.02, size: 0.10),
        devices: [DeviceSlot] = [DeviceSlot(y: 0.15, width: 0.85)],
        decorations: [Decoration] = []
    ) -> ScreenLayout {
        ScreenLayout(headline: headline, devices: devices, decorations: decorations)
    }

    static func makeAppShotTemplate(
        id: String = "top-hero",
        name: String = "Top Hero",
        category: TemplateCategory = .bold,
        supportedSizes: [ScreenSize] = [.portrait],
        description: String = "Indigo gradient with bold headline",
        background: String = "linear-gradient(150deg,#4338CA,#6D28D9)",
        hasDevice: Bool = true
    ) -> AppShotTemplate {
        let devices = hasDevice ? [DeviceSlot(x: 0.5, y: 0.18, width: 0.85)] : []
        return AppShotTemplate(
            id: id,
            name: name,
            category: category,
            supportedSizes: supportedSizes,
            description: description,
            screenLayout: ScreenLayout(
                headline: TextSlot(y: 0.04, size: 0.10, weight: 700, align: "center", preview: name),
                devices: devices
            ),
            palette: GalleryPalette(id: id, name: name, background: background)
        )
    }
}
