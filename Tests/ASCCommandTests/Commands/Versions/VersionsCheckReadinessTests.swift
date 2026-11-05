import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct VersionsCheckReadinessTests {

    // MARK: - Helpers

    private func makeEditable(buildId: String? = "build-55") -> AppStoreVersion {
        AppStoreVersion(
            id: "v-123",
            appId: "app-456",
            versionString: "1.2.0",
            platform: .iOS,
            state: .prepareForSubmission,
            buildId: buildId
        )
    }

    private func makeBuild() -> Build {
        Build(id: "build-55", version: "1.2.0", expired: false, processingState: .valid, buildNumber: "55")
    }

    private func makeReviewDetail(phone: String? = "+1-555-0100", email: String? = "dev@example.com") -> AppStoreReviewDetail {
        AppStoreReviewDetail(
            id: "rd-1",
            versionId: "v-123",
            contactPhone: phone,
            contactEmail: email,
            demoAccountRequired: false
        )
    }

    private func makeApp(primaryLocale: String = "en-US") -> App {
        App(id: "app-456", name: "TestApp", bundleId: "com.test.app", primaryLocale: primaryLocale)
    }

    private func makeLocalization(id: String = "loc-1", locale: String = "en-US") -> AppStoreVersionLocalization {
        AppStoreVersionLocalization(
            id: id,
            versionId: "v-123",
            locale: locale,
            description: "App description",
            keywords: "app, tool"
        )
    }

    private func makeScreenshotSet() -> AppScreenshotSet {
        AppScreenshotSet(
            id: "set-1",
            localizationId: "loc-1",
            screenshotDisplayType: .iphone67,
            screenshotsCount: 3
        )
    }

    private func makeAppInfo(id: String = "info-1", state: String = "PREPARE_FOR_SUBMISSION") -> AppInfo {
        AppInfo(id: id, appId: "app-456", state: state)
    }

    private func makeDeclaration(id: String = "decl-1", isSocialMedia: Bool? = false) -> AgeRatingDeclaration {
        AgeRatingDeclaration(
            id: id, appInfoId: "info-1",
            isAdvertising: false, isGambling: false, isHealthOrWellnessTopics: false, isLootBox: false,
            isMessagingAndChat: false, isParentalControls: false, isAgeAssurance: false,
            isUnrestrictedWebAccess: false, isUserGeneratedContent: false, isSocialMedia: isSocialMedia,
            alcoholTobaccoOrDrugUseOrReferences: ContentIntensity.none, contests: ContentIntensity.none,
            gamblingSimulated: ContentIntensity.none, gunsOrOtherWeapons: ContentIntensity.none,
            medicalOrTreatmentInformation: ContentIntensity.none, profanityOrCrudeHumor: ContentIntensity.none,
            sexualContentGraphicAndNudity: ContentIntensity.none, sexualContentOrNudity: ContentIntensity.none,
            horrorOrFearThemes: ContentIntensity.none, matureOrSuggestiveThemes: ContentIntensity.none,
            violenceCartoonOrFantasy: ContentIntensity.none, violenceRealisticProlongedGraphicOrSadistic: ContentIntensity.none,
            violenceRealistic: ContentIntensity.none
        )
    }

    private func makeAnsweredAgeRating() -> (MockAppInfoRepository, MockAgeRatingDeclarationRepository) {
        let appInfoRepo = MockAppInfoRepository()
        let ageRatingRepo = MockAgeRatingDeclarationRepository()
        given(appInfoRepo).listAppInfos(appId: .value("app-456")).willReturn([makeAppInfo()])
        given(ageRatingRepo).getDeclaration(appInfoId: .value("info-1")).willReturn(makeDeclaration())
        return (appInfoRepo, ageRatingRepo)
    }

    /// Runs the check on an otherwise ready version, with the given age rating setup.
    private func checkReadyVersion(
        appInfoRepo: MockAppInfoRepository,
        ageRatingRepo: MockAgeRatingDeclarationRepository
    ) async throws -> String {
        let mockVersionRepo = MockVersionRepository()
        let mockAppRepo = MockAppRepository()
        let mockBuildRepo = MockBuildRepository()
        let mockReviewDetailRepo = MockReviewDetailRepository()
        let mockLocalizationRepo = MockVersionLocalizationRepository()
        let mockScreenshotRepo = MockScreenshotRepository()
        let mockPricingRepo = MockPricingRepository()
        given(mockAppRepo).getApp(id: .value("app-456")).willReturn(makeApp())
        given(mockVersionRepo).getVersion(id: .value("v-123")).willReturn(makeEditable())
        given(mockBuildRepo).getBuild(id: .value("build-55")).willReturn(makeBuild())
        given(mockPricingRepo).hasPricing(appId: .value("app-456")).willReturn(true)
        given(mockReviewDetailRepo).getReviewDetail(versionId: .value("v-123")).willReturn(makeReviewDetail())
        given(mockLocalizationRepo).listLocalizations(versionId: .value("v-123")).willReturn([makeLocalization()])
        given(mockScreenshotRepo).listScreenshotSets(localizationId: .value("loc-1")).willReturn([makeScreenshotSet()])

        return try await VersionsCheckReadiness.parse(["--version-id", "v-123", "--pretty"]).execute(
            versionRepo: mockVersionRepo,
            appRepo: mockAppRepo,
            buildRepo: mockBuildRepo,
            reviewDetailRepo: mockReviewDetailRepo,
            localizationRepo: mockLocalizationRepo,
            screenshotRepo: mockScreenshotRepo,
            pricingRepo: mockPricingRepo,
            appInfoRepo: appInfoRepo,
            ageRatingRepo: ageRatingRepo
        )
    }

    // MARK: - Tests

    @Test func `should not be ready and should name social media when it is unanswered`() async throws {
        let appInfoRepo = MockAppInfoRepository()
        let ageRatingRepo = MockAgeRatingDeclarationRepository()
        given(appInfoRepo).listAppInfos(appId: .value("app-456")).willReturn([makeAppInfo()])
        given(ageRatingRepo).getDeclaration(appInfoId: .value("info-1")).willReturn(makeDeclaration(isSocialMedia: nil))

        let output = try await checkReadyVersion(appInfoRepo: appInfoRepo, ageRatingRepo: ageRatingRepo)

        #expect(output.contains(#""isReadyToSubmit" : false"#))
        #expect(output.contains("""
              "ageRatingCheck" : {
                "message" : "Age rating questions not answered: socialMedia. Answer them with asc age-rating update --declaration-id decl-1",
                "pass" : false
              },
        """))
        #expect(!output.contains("asc versions submit"))
    }

    @Test func `should read the age rating of the app info being prepared, not the live one`() async throws {
        let appInfoRepo = MockAppInfoRepository()
        let ageRatingRepo = MockAgeRatingDeclarationRepository()
        given(appInfoRepo).listAppInfos(appId: .value("app-456")).willReturn([
            makeAppInfo(id: "info-live", state: "READY_FOR_DISTRIBUTION"),
            makeAppInfo(id: "info-1", state: "PREPARE_FOR_SUBMISSION"),
        ])
        given(ageRatingRepo).getDeclaration(appInfoId: .value("info-live")).willReturn(makeDeclaration(isSocialMedia: nil))
        given(ageRatingRepo).getDeclaration(appInfoId: .value("info-1")).willReturn(makeDeclaration(isSocialMedia: false))

        let output = try await checkReadyVersion(appInfoRepo: appInfoRepo, ageRatingRepo: ageRatingRepo)

        #expect(output.contains(#""isReadyToSubmit" : true"#))
    }

    @Test func `should read the age rating of a rejected app info rather than the live one`() async throws {
        let appInfoRepo = MockAppInfoRepository()
        let ageRatingRepo = MockAgeRatingDeclarationRepository()
        given(appInfoRepo).listAppInfos(appId: .value("app-456")).willReturn([
            makeAppInfo(id: "info-live", state: "READY_FOR_DISTRIBUTION"),
            makeAppInfo(id: "info-1", state: "REJECTED"),
        ])
        given(ageRatingRepo).getDeclaration(appInfoId: .value("info-live")).willReturn(makeDeclaration(isSocialMedia: false))
        given(ageRatingRepo).getDeclaration(appInfoId: .value("info-1")).willReturn(makeDeclaration(isSocialMedia: nil))

        let output = try await checkReadyVersion(appInfoRepo: appInfoRepo, ageRatingRepo: ageRatingRepo)

        #expect(output.contains(#""isReadyToSubmit" : false"#))
    }

    @Test func `should not be ready when the app has no app info to read an age rating from`() async throws {
        let appInfoRepo = MockAppInfoRepository()
        given(appInfoRepo).listAppInfos(appId: .value("app-456")).willReturn([])

        let output = try await checkReadyVersion(appInfoRepo: appInfoRepo, ageRatingRepo: MockAgeRatingDeclarationRepository())

        #expect(output.contains(#""isReadyToSubmit" : false"#))
        #expect(output.contains(#""message" : "No app info found to read the age rating from""#))
    }

    @Test func `version with valid build and pricing is ready to submit`() async throws {
        let mockVersionRepo = MockVersionRepository()
        let mockAppRepo = MockAppRepository()
        let mockBuildRepo = MockBuildRepository()
        let mockReviewDetailRepo = MockReviewDetailRepository()
        let mockLocalizationRepo = MockVersionLocalizationRepository()
        let mockScreenshotRepo = MockScreenshotRepository()
        let mockPricingRepo = MockPricingRepository()
        let (mockAppInfoRepo, mockAgeRatingRepo) = makeAnsweredAgeRating()
        given(mockAppRepo).getApp(id: .value("app-456")).willReturn(makeApp())

        given(mockVersionRepo).getVersion(id: .value("v-123")).willReturn(makeEditable())
        given(mockBuildRepo).getBuild(id: .value("build-55")).willReturn(makeBuild())
        given(mockPricingRepo).hasPricing(appId: .value("app-456")).willReturn(true)
        given(mockReviewDetailRepo).getReviewDetail(versionId: .value("v-123")).willReturn(makeReviewDetail())
        given(mockLocalizationRepo).listLocalizations(versionId: .value("v-123")).willReturn([makeLocalization()])
        given(mockScreenshotRepo).listScreenshotSets(localizationId: .value("loc-1")).willReturn([makeScreenshotSet()])

        let cmd = try VersionsCheckReadiness.parse(["--version-id", "v-123", "--pretty"])
        let output = try await cmd.execute(
            versionRepo: mockVersionRepo,
            appRepo: mockAppRepo,
            buildRepo: mockBuildRepo,
            reviewDetailRepo: mockReviewDetailRepo,
            localizationRepo: mockLocalizationRepo,
            screenshotRepo: mockScreenshotRepo,
            pricingRepo: mockPricingRepo,
            appInfoRepo: mockAppInfoRepo,
            ageRatingRepo: mockAgeRatingRepo
        )

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "checkReadiness" : "asc versions check-readiness --version-id v-123",
                "listLocalizations" : "asc version-localizations list --version-id v-123",
                "submit" : "asc versions submit --version-id v-123"
              },
              "ageRatingCheck" : {
                "pass" : true
              },
              "appId" : "app-456",
              "buildCheck" : {
                "buildVersion" : "1.2.0 (55)",
                "linked" : true,
                "notExpired" : true,
                "pass" : true,
                "valid" : true
              },
              "id" : "v-123",
              "isReadyToSubmit" : true,
              "localizationCheck" : {
                "localizations" : [
                  {
                    "hasDescription" : true,
                    "hasKeywords" : true,
                    "hasSupportUrl" : false,
                    "hasWhatsNew" : false,
                    "isPrimary" : true,
                    "locale" : "en-US",
                    "pass" : true,
                    "screenshotSetCount" : 1
                  }
                ],
                "pass" : true
              },
              "pricingCheck" : {
                "pass" : true
              },
              "reviewContactCheck" : {
                "pass" : true
              },
              "state" : "PREPARE_FOR_SUBMISSION",
              "stateCheck" : {
                "pass" : true
              },
              "versionString" : "1.2.0"
            }
          ]
        }
        """)
    }

    @Test func `version without linked build is not ready to submit`() async throws {
        let mockVersionRepo = MockVersionRepository()
        let mockAppRepo = MockAppRepository()
        let mockBuildRepo = MockBuildRepository()
        let mockReviewDetailRepo = MockReviewDetailRepository()
        let mockLocalizationRepo = MockVersionLocalizationRepository()
        let mockScreenshotRepo = MockScreenshotRepository()
        let mockPricingRepo = MockPricingRepository()
        let (mockAppInfoRepo, mockAgeRatingRepo) = makeAnsweredAgeRating()
        given(mockAppRepo).getApp(id: .value("app-456")).willReturn(makeApp())

        given(mockVersionRepo).getVersion(id: .value("v-123")).willReturn(makeEditable(buildId: nil))
        given(mockPricingRepo).hasPricing(appId: .value("app-456")).willReturn(true)
        given(mockReviewDetailRepo).getReviewDetail(versionId: .value("v-123")).willReturn(makeReviewDetail())
        given(mockLocalizationRepo).listLocalizations(versionId: .value("v-123")).willReturn([])

        let cmd = try VersionsCheckReadiness.parse(["--version-id", "v-123", "--pretty"])
        let output = try await cmd.execute(
            versionRepo: mockVersionRepo,
            appRepo: mockAppRepo,
            buildRepo: mockBuildRepo,
            reviewDetailRepo: mockReviewDetailRepo,
            localizationRepo: mockLocalizationRepo,
            screenshotRepo: mockScreenshotRepo,
            pricingRepo: mockPricingRepo,
            appInfoRepo: mockAppInfoRepo,
            ageRatingRepo: mockAgeRatingRepo
        )

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "checkReadiness" : "asc versions check-readiness --version-id v-123",
                "listLocalizations" : "asc version-localizations list --version-id v-123"
              },
              "ageRatingCheck" : {
                "pass" : true
              },
              "appId" : "app-456",
              "buildCheck" : {
                "linked" : false,
                "notExpired" : false,
                "pass" : false,
                "valid" : false
              },
              "id" : "v-123",
              "isReadyToSubmit" : false,
              "localizationCheck" : {
                "localizations" : [

                ],
                "pass" : false
              },
              "pricingCheck" : {
                "pass" : true
              },
              "reviewContactCheck" : {
                "pass" : true
              },
              "state" : "PREPARE_FOR_SUBMISSION",
              "stateCheck" : {
                "pass" : true
              },
              "versionString" : "1.2.0"
            }
          ]
        }
        """)
    }

    @Test func `live version is not editable so cannot submit`() async throws {
        let mockVersionRepo = MockVersionRepository()
        let mockAppRepo = MockAppRepository()
        let mockBuildRepo = MockBuildRepository()
        let mockReviewDetailRepo = MockReviewDetailRepository()
        let mockLocalizationRepo = MockVersionLocalizationRepository()
        let mockScreenshotRepo = MockScreenshotRepository()
        let mockPricingRepo = MockPricingRepository()
        let (mockAppInfoRepo, mockAgeRatingRepo) = makeAnsweredAgeRating()
        given(mockAppRepo).getApp(id: .value("app-456")).willReturn(makeApp())

        let liveVersion = AppStoreVersion(
            id: "v-123",
            appId: "app-456",
            versionString: "1.0.0",
            platform: .iOS,
            state: .readyForSale,
            buildId: "build-55"
        )
        given(mockVersionRepo).getVersion(id: .value("v-123")).willReturn(liveVersion)
        given(mockBuildRepo).getBuild(id: .value("build-55")).willReturn(makeBuild())
        given(mockPricingRepo).hasPricing(appId: .value("app-456")).willReturn(true)
        given(mockReviewDetailRepo).getReviewDetail(versionId: .value("v-123")).willReturn(makeReviewDetail())
        given(mockLocalizationRepo).listLocalizations(versionId: .value("v-123")).willReturn([])

        let cmd = try VersionsCheckReadiness.parse(["--version-id", "v-123", "--pretty"])
        let output = try await cmd.execute(
            versionRepo: mockVersionRepo,
            appRepo: mockAppRepo,
            buildRepo: mockBuildRepo,
            reviewDetailRepo: mockReviewDetailRepo,
            localizationRepo: mockLocalizationRepo,
            screenshotRepo: mockScreenshotRepo,
            pricingRepo: mockPricingRepo,
            appInfoRepo: mockAppInfoRepo,
            ageRatingRepo: mockAgeRatingRepo
        )

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "checkReadiness" : "asc versions check-readiness --version-id v-123",
                "listLocalizations" : "asc version-localizations list --version-id v-123"
              },
              "ageRatingCheck" : {
                "pass" : true
              },
              "appId" : "app-456",
              "buildCheck" : {
                "buildVersion" : "1.2.0 (55)",
                "linked" : true,
                "notExpired" : true,
                "pass" : true,
                "valid" : true
              },
              "id" : "v-123",
              "isReadyToSubmit" : false,
              "localizationCheck" : {
                "localizations" : [

                ],
                "pass" : false
              },
              "pricingCheck" : {
                "pass" : true
              },
              "reviewContactCheck" : {
                "pass" : true
              },
              "state" : "READY_FOR_SALE",
              "stateCheck" : {
                "message" : "Version state 'READY_FOR_SALE' is not editable",
                "pass" : false
              },
              "versionString" : "1.0.0"
            }
          ]
        }
        """)
    }

    @Test func `secondary locale without screenshots does not block submission`() async throws {
        let mockVersionRepo = MockVersionRepository()
        let mockAppRepo = MockAppRepository()
        let mockBuildRepo = MockBuildRepository()
        let mockReviewDetailRepo = MockReviewDetailRepository()
        let mockLocalizationRepo = MockVersionLocalizationRepository()
        let mockScreenshotRepo = MockScreenshotRepository()
        let mockPricingRepo = MockPricingRepository()
        let (mockAppInfoRepo, mockAgeRatingRepo) = makeAnsweredAgeRating()
        given(mockAppRepo).getApp(id: .value("app-456")).willReturn(makeApp())

        given(mockVersionRepo).getVersion(id: .value("v-123")).willReturn(makeEditable())
        given(mockBuildRepo).getBuild(id: .value("build-55")).willReturn(makeBuild())
        given(mockPricingRepo).hasPricing(appId: .value("app-456")).willReturn(true)
        given(mockReviewDetailRepo).getReviewDetail(versionId: .value("v-123")).willReturn(makeReviewDetail())
        given(mockLocalizationRepo).listLocalizations(versionId: .value("v-123")).willReturn([
            makeLocalization(id: "loc-1", locale: "en-US"),
            makeLocalization(id: "loc-2", locale: "zh-Hans"),
        ])
        // Primary locale has screenshots; secondary does not
        given(mockScreenshotRepo).listScreenshotSets(localizationId: .value("loc-1")).willReturn([makeScreenshotSet()])
        given(mockScreenshotRepo).listScreenshotSets(localizationId: .value("loc-2")).willReturn([])

        let cmd = try VersionsCheckReadiness.parse(["--version-id", "v-123", "--pretty"])
        let output = try await cmd.execute(
            versionRepo: mockVersionRepo,
            appRepo: mockAppRepo,
            buildRepo: mockBuildRepo,
            reviewDetailRepo: mockReviewDetailRepo,
            localizationRepo: mockLocalizationRepo,
            screenshotRepo: mockScreenshotRepo,
            pricingRepo: mockPricingRepo,
            appInfoRepo: mockAppInfoRepo,
            ageRatingRepo: mockAgeRatingRepo
        )

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "checkReadiness" : "asc versions check-readiness --version-id v-123",
                "listLocalizations" : "asc version-localizations list --version-id v-123",
                "submit" : "asc versions submit --version-id v-123"
              },
              "ageRatingCheck" : {
                "pass" : true
              },
              "appId" : "app-456",
              "buildCheck" : {
                "buildVersion" : "1.2.0 (55)",
                "linked" : true,
                "notExpired" : true,
                "pass" : true,
                "valid" : true
              },
              "id" : "v-123",
              "isReadyToSubmit" : true,
              "localizationCheck" : {
                "localizations" : [
                  {
                    "hasDescription" : true,
                    "hasKeywords" : true,
                    "hasSupportUrl" : false,
                    "hasWhatsNew" : false,
                    "isPrimary" : true,
                    "locale" : "en-US",
                    "pass" : true,
                    "screenshotSetCount" : 1
                  },
                  {
                    "hasDescription" : true,
                    "hasKeywords" : true,
                    "hasSupportUrl" : false,
                    "hasWhatsNew" : false,
                    "isPrimary" : false,
                    "locale" : "zh-Hans",
                    "pass" : false,
                    "screenshotSetCount" : 0
                  }
                ],
                "pass" : true
              },
              "pricingCheck" : {
                "pass" : true
              },
              "reviewContactCheck" : {
                "pass" : true
              },
              "state" : "PREPARE_FOR_SUBMISSION",
              "stateCheck" : {
                "pass" : true
              },
              "versionString" : "1.2.0"
            }
          ]
        }
        """)
    }

    @Test func `missing review contact does not block submission`() async throws {
        let mockVersionRepo = MockVersionRepository()
        let mockAppRepo = MockAppRepository()
        let mockBuildRepo = MockBuildRepository()
        let mockReviewDetailRepo = MockReviewDetailRepository()
        let mockLocalizationRepo = MockVersionLocalizationRepository()
        let mockScreenshotRepo = MockScreenshotRepository()
        let mockPricingRepo = MockPricingRepository()
        let (mockAppInfoRepo, mockAgeRatingRepo) = makeAnsweredAgeRating()
        given(mockAppRepo).getApp(id: .value("app-456")).willReturn(makeApp())

        given(mockVersionRepo).getVersion(id: .value("v-123")).willReturn(makeEditable())
        given(mockBuildRepo).getBuild(id: .value("build-55")).willReturn(makeBuild())
        given(mockPricingRepo).hasPricing(appId: .value("app-456")).willReturn(true)
        given(mockReviewDetailRepo).getReviewDetail(versionId: .value("v-123")).willReturn(
            makeReviewDetail(phone: nil, email: nil)
        )
        given(mockLocalizationRepo).listLocalizations(versionId: .value("v-123")).willReturn([makeLocalization()])
        given(mockScreenshotRepo).listScreenshotSets(localizationId: .value("loc-1")).willReturn([makeScreenshotSet()])

        let cmd = try VersionsCheckReadiness.parse(["--version-id", "v-123", "--pretty"])
        let output = try await cmd.execute(
            versionRepo: mockVersionRepo,
            appRepo: mockAppRepo,
            buildRepo: mockBuildRepo,
            reviewDetailRepo: mockReviewDetailRepo,
            localizationRepo: mockLocalizationRepo,
            screenshotRepo: mockScreenshotRepo,
            pricingRepo: mockPricingRepo,
            appInfoRepo: mockAppInfoRepo,
            ageRatingRepo: mockAgeRatingRepo
        )

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "checkReadiness" : "asc versions check-readiness --version-id v-123",
                "listLocalizations" : "asc version-localizations list --version-id v-123",
                "submit" : "asc versions submit --version-id v-123"
              },
              "ageRatingCheck" : {
                "pass" : true
              },
              "appId" : "app-456",
              "buildCheck" : {
                "buildVersion" : "1.2.0 (55)",
                "linked" : true,
                "notExpired" : true,
                "pass" : true,
                "valid" : true
              },
              "id" : "v-123",
              "isReadyToSubmit" : true,
              "localizationCheck" : {
                "localizations" : [
                  {
                    "hasDescription" : true,
                    "hasKeywords" : true,
                    "hasSupportUrl" : false,
                    "hasWhatsNew" : false,
                    "isPrimary" : true,
                    "locale" : "en-US",
                    "pass" : true,
                    "screenshotSetCount" : 1
                  }
                ],
                "pass" : true
              },
              "pricingCheck" : {
                "pass" : true
              },
              "reviewContactCheck" : {
                "message" : "No contact email or phone set in App Store review information",
                "pass" : false
              },
              "state" : "PREPARE_FOR_SUBMISSION",
              "stateCheck" : {
                "pass" : true
              },
              "versionString" : "1.2.0"
            }
          ]
        }
        """)
    }
}
