import Foundation
import Testing
import Mockable
@testable import ASCCommand
@testable import Domain

@Suite
struct RESTRoutesTests {

    private static let formatter = OutputFormatter(format: .json, pretty: true)

    // MARK: - Apps

    @Test func `apps list returns JSON with _links`() async throws {
        let mockRepo = MockAppRepository()
        given(mockRepo).listApps(limit: .any).willReturn(
            PaginatedResponse(data: [App(id: "42", name: "MyApp", bundleId: "com.test")])
        )
        let output = try await AppsList.parse(["--pretty"]).execute(repo: mockRepo, affordanceMode: .rest)
        let normalized = output.replacingOccurrences(of: "\\/", with: "/")
        #expect(normalized.contains("\"_links\""))
        #expect(normalized.contains("/api/v1/apps/42/versions"))
        #expect(!normalized.contains("\"affordances\""))
    }

    @Test func `apps list returns data wrapper`() async throws {
        let mockRepo = MockAppRepository()
        given(mockRepo).listApps(limit: .any).willReturn(
            PaginatedResponse(data: [App(id: "1", name: "Test", bundleId: "com.test")])
        )
        let output = try await AppsList.parse(["--pretty"]).execute(repo: mockRepo, affordanceMode: .rest)
        #expect(output.contains("\"data\""))
    }

    // MARK: - Versions

    @Test func `versions list returns JSON with _links`() async throws {
        let mockRepo = MockVersionRepository()
        given(mockRepo).listVersions(appId: .any).willReturn([
            AppStoreVersion(id: "v-1", appId: "42", versionString: "1.0", platform: .iOS, state: .prepareForSubmission),
        ])
        let output = try await VersionsList.parse(["--app-id", "42", "--pretty"]).execute(repo: mockRepo, affordanceMode: .rest)
        let normalized = output.replacingOccurrences(of: "\\/", with: "/")
        #expect(normalized.contains("\"_links\""))
        #expect(normalized.contains("/api/v1/versions/v-1/localizations"))
    }

    @Test func `plugins updates list returns outdated entries with apply links`() async throws {
        let mockRepo = MockPluginRepository()
        given(mockRepo).listOutdated().willReturn([
            PluginUpdate(name: "Hello", installedVersion: "1.0.0", latestVersion: "1.2.0"),
        ])
        let output = try await PluginsUpdates.parse(["--pretty"]).execute(repo: mockRepo, affordanceMode: .rest)
        #expect(output.contains("\"_links\""))
        #expect(output.contains("\"name\" : \"Hello\""))
        #expect(output.contains("\"installedVersion\" : \"1.0.0\""))
        #expect(output.contains("\"latestVersion\" : \"1.2.0\""))
    }

    @Test func `plugins update returns the freshly installed plugin`() async throws {
        let mockRepo = MockPluginRepository()
        given(mockRepo).update(name: .value("Hello")).willReturn(
            Plugin(id: "Hello.plugin", name: "Hello", version: "1.2.0", isInstalled: true, slug: "Hello.plugin")
        )
        let output = try await PluginsUpdate.parse(["--name", "Hello", "--pretty"]).execute(repo: mockRepo, affordanceMode: .rest)
        #expect(output.contains("\"_links\""))
        #expect(output.contains("\"version\" : \"1.2.0\""))
        #expect(output.contains("\"isInstalled\" : true"))
    }

    @Test func `plugins install returns the installed plugin in data wrapper`() async throws {
        let mockRepo = MockPluginRepository()
        given(mockRepo).install(name: .any).willReturn(
            Plugin(id: "Hello.plugin", name: "Hello", version: "1.0", author: "me", isInstalled: true, slug: "Hello.plugin")
        )
        let output = try await PluginsInstall.parse(["--name", "Hello.plugin", "--pretty"])
            .execute(repo: mockRepo, affordanceMode: .rest)
        #expect(output.contains("\"data\""))
        #expect(output.contains("\"name\" : \"Hello\""))
        #expect(output.contains("\"isInstalled\" : true"))
    }

    @Test func `plugins market search returns filtered list under data wrapper`() async throws {
        let mockRepo = MockPluginRepository()
        given(mockRepo).searchAvailable(query: .value("hello")).willReturn([
            Plugin(id: "Hello.plugin", name: "Hello", version: "1.0", author: "me"),
        ])
        let output = try await MarketSearch.parse(["--query", "hello", "--pretty"])
            .execute(repo: mockRepo, affordanceMode: .rest)
        #expect(output.contains("\"data\""))
        #expect(output.contains("\"name\" : \"Hello\""))
    }

    @Test func `auth list returns accounts JSON wrapped in data`() async throws {
        let storage = MockAuthStorage()
        given(storage).loadAll().willReturn([
            ConnectAccount(name: "personal", keyID: "K1", issuerID: "I1", isActive: true),
            ConnectAccount(name: "work", keyID: "K2", issuerID: "I2", isActive: false),
        ])
        let output = try await AuthList.parse(["--pretty"]).execute(storage: storage, affordanceMode: .rest)
        #expect(output.contains("\"data\""))
        #expect(output.contains("\"name\" : \"personal\""))
        #expect(output.contains("\"name\" : \"work\""))
        #expect(output.contains("\"isActive\" : true"))
    }

    @Test func `auth login returns AuthStatus with the saved name`() async throws {
        let storage = MockAuthStorage()
        given(storage).save(.any, name: .any).willReturn(())
        given(storage).setActive(name: .any).willReturn(())
        let output = try await AuthLogin.parse([
            "--key-id", "KEY",
            "--issuer-id", "ISSUER",
            "--private-key=-----BEGIN PRIVATE KEY-----\nA\n-----END PRIVATE KEY-----",
            "--name", "personal",
            "--pretty",
        ]).execute(storage: storage, affordanceMode: .rest)
        #expect(output.contains("\"name\" : \"personal\""))
        #expect(output.contains("\"keyID\" : \"KEY\""))
        #expect(output.contains("\"source\" : \"file\""))
    }

    @Test func `age-rating update returns JSON with _links`() async throws {
        let mockRepo = MockAgeRatingDeclarationRepository()
        given(mockRepo).updateDeclaration(id: .any, update: .any).willReturn(
            AgeRatingDeclaration(id: "decl-1", appInfoId: "info-42", isAdvertising: false)
        )
        let output = try await AgeRatingUpdate
            .parse(["--declaration-id", "decl-1", "--advertising", "false", "--pretty"])
            .execute(repo: mockRepo, affordanceMode: .rest)
        let normalized = output.replacingOccurrences(of: "\\/", with: "/")
        #expect(normalized.contains("\"_links\""))
        #expect(normalized.contains("/api/v1/age-rating/decl-1"))
        #expect(!normalized.contains("\"affordances\""))
    }

    @Test func `apps update returns JSON with _links and contentRightsDeclaration`() async throws {
        let mockRepo = MockAppRepository()
        given(mockRepo).updateContentRights(appId: .any, declaration: .any).willReturn(
            App(id: "42", name: "Bakery", bundleId: "com.example", contentRightsDeclaration: .doesNotUseThirdPartyContent)
        )
        let output = try await AppsUpdate
            .parse(["--app-id", "42", "--content-rights-declaration", "DOES_NOT_USE_THIRD_PARTY_CONTENT", "--pretty"])
            .execute(repo: mockRepo, affordanceMode: .rest)
        let normalized = output.replacingOccurrences(of: "\\/", with: "/")
        #expect(normalized.contains("\"_links\""))
        #expect(normalized.contains("/api/v1/apps/42"))
        #expect(normalized.contains("\"contentRightsDeclaration\" : \"DOES_NOT_USE_THIRD_PARTY_CONTENT\""))
        #expect(!normalized.contains("\"affordances\""))
    }

    @Test func `versions update returns JSON with _links`() async throws {
        let mockRepo = MockVersionRepository()
        given(mockRepo).updateVersion(
            id: .any,
            versionString: .any,
            copyright: .any,
            releaseType: .any,
            earliestReleaseDate: .any
        ).willReturn(
            AppStoreVersion(id: "v-1", appId: "42", versionString: "1.5", platform: .iOS, state: .prepareForSubmission)
        )
        let output = try await VersionsUpdate
            .parse(["--version-id", "v-1", "--version", "1.5", "--pretty"])
            .execute(repo: mockRepo, affordanceMode: .rest)
        let normalized = output.replacingOccurrences(of: "\\/", with: "/")
        #expect(normalized.contains("\"_links\""))
        #expect(normalized.contains("/api/v1/versions/v-1"))
        #expect(!normalized.contains("\"affordances\""))
    }

    // MARK: - Version Localizations

    @Test func `version localizations list returns JSON with _links`() async throws {
        let mockRepo = MockVersionLocalizationRepository()
        given(mockRepo).listLocalizations(versionId: .any).willReturn([
            AppStoreVersionLocalization(id: "loc-1", versionId: "v-1", locale: "en-US", description: "A great app"),
        ])
        let output = try await VersionLocalizationsList.parse(["--version-id", "v-1", "--pretty"]).execute(repo: mockRepo, affordanceMode: .rest)
        let normalized = output.replacingOccurrences(of: "\\/", with: "/")
        #expect(normalized.contains("\"_links\""))
        #expect(normalized.contains("\"locale\" : \"en-US\""))
        #expect(normalized.contains("\"description\" : \"A great app\""))
        #expect(!normalized.contains("\"affordances\""))
    }

    // MARK: - API Root

    @Test func `api root returns _links to all top-level resources`() throws {
        let output = try Self.formatter.formatAgentItems([APIRoot()], headers: [], rowMapper: { _ in [] }, affordanceMode: .rest)
        let normalized = output.replacingOccurrences(of: "\\/", with: "/")
        #expect(normalized.contains("\"_links\""))
        #expect(normalized.contains("/api/v1/apps"))
        #expect(normalized.contains("/api/v1/certificates"))
        #expect(normalized.contains("/api/v1/simulators"))
        #expect(normalized.contains("/api/v1/plugins"))
        #expect(normalized.contains("/api/v1/territories"))
    }

    // MARK: - Simulators

    @Test func `simulators list returns JSON with _links`() async throws {
        let mockRepo = MockSimulatorRepository()
        given(mockRepo).listSimulators(filter: .any).willReturn([
            Simulator(id: "ABC-123", name: "iPhone 15", state: .booted, runtime: "iOS 17.0"),
        ])
        let output = try await SimulatorsList.parse(["--pretty"]).execute(repo: mockRepo, affordanceMode: .rest)
        let normalized = output.replacingOccurrences(of: "\\/", with: "/")
        #expect(normalized.contains("\"_links\""))
        #expect(normalized.contains("\"data\""))
    }

    // MARK: - Builds

    @Test func `builds list returns JSON with _links`() async throws {
        let mockRepo = MockBuildRepository()
        given(mockRepo).listBuilds(appId: .any, platform: .any, version: .any, limit: .any).willReturn(
            PaginatedResponse(data: [Build(id: "b-1", version: "1.0", expired: false, processingState: .valid)])
        )
        let output = try await BuildsList.parse(["--app-id", "42", "--pretty"]).execute(repo: mockRepo, affordanceMode: .rest)
        let normalized = output.replacingOccurrences(of: "\\/", with: "/")
        #expect(normalized.contains("\"_links\""))
        #expect(normalized.contains("\"data\""))
    }

    // MARK: - TestFlight

    @Test func `testflight groups list returns JSON with _links`() async throws {
        let mockRepo = MockTestFlightRepository()
        given(mockRepo).listBetaGroups(appId: .any, limit: .any).willReturn(
            PaginatedResponse(data: [BetaGroup(id: "g-1", appId: "42", name: "External Testers", isInternalGroup: false)])
        )
        let output = try await BetaGroupsList.parse(["--app-id", "42", "--pretty"]).execute(repo: mockRepo, affordanceMode: .rest)
        let normalized = output.replacingOccurrences(of: "\\/", with: "/")
        #expect(normalized.contains("\"_links\""))
        #expect(normalized.contains("\"data\""))
    }

    // MARK: - App Shots

    @Test func `templates list returns data wrapper`() async throws {
        let mockRepo = MockTemplateRepository()
        given(mockRepo).listTemplates(size: .any).willReturn([])
        let output = try await AppShotsTemplatesList.parse(["--pretty"]).execute(repo: mockRepo, affordanceMode: .rest)
        #expect(output.contains("\"data\""))
    }

    @Test func `themes list returns data wrapper`() async throws {
        let mockRepo = MockThemeRepository()
        given(mockRepo).listThemes().willReturn([])
        let output = try await AppShotsThemesList.parse(["--pretty"]).execute(repo: mockRepo, affordanceMode: .rest)
        #expect(output.contains("\"data\""))
    }

    // MARK: - Review Submissions

    @Test func `review submissions list returns JSON with _links`() async throws {
        let mockRepo = MockSubmissionRepository()
        given(mockRepo).listSubmissions(appId: .any, states: .any, limit: .any).willReturn([
            ReviewSubmission(id: "sub-1", appId: "42", platform: .iOS, state: .waitingForReview),
        ])
        let output = try await ReviewSubmissionsList
            .parse(["--app-id", "42", "--pretty"])
            .execute(repo: mockRepo, affordanceMode: .rest)
        let normalized = output.replacingOccurrences(of: "\\/", with: "/")
        #expect(normalized.contains("\"_links\""))
        #expect(normalized.contains("/api/v1/apps/42/versions"))
        #expect(!normalized.contains("\"affordances\""))
    }

    // MARK: - Certificates REST filters

    @Test func `certificates list accepts limit via rest mode`() async throws {
        let mockRepo = MockCertificateRepository()
        given(mockRepo).listCertificates(certificateType: .any, limit: .value(200)).willReturn([
            Certificate(id: "cert-1", name: "Dist", certificateType: .iosDistribution),
        ])
        let output = try await CertificatesList
            .parse(["--limit", "200", "--pretty"])
            .execute(repo: mockRepo, affordanceMode: .rest)
        #expect(output.contains("\"_links\""))
        #expect(output.contains("cert-1"))
    }

    @Test func `api root includes app-shots resources`() throws {
        let output = try Self.formatter.formatAgentItems([APIRoot()], headers: [], rowMapper: { _ in [] }, affordanceMode: .rest)
        let normalized = output.replacingOccurrences(of: "\\/", with: "/")
        #expect(normalized.contains("appShotsTemplates"))
        #expect(normalized.contains("appShotsThemes"))
    }

    // MARK: - Promoted Purchases

    @Test func `promoted purchases list returns JSON with _links pointing at REST paths`() async throws {
        let mockRepo = MockPromotedPurchaseRepository()
        given(mockRepo).listPromotedPurchases(appId: .any, limit: .any).willReturn(
            PaginatedResponse(data: [
                PromotedPurchase(
                    id: "pp-1", appId: "app-42",
                    isVisibleForAllUsers: true, isEnabled: true,
                    state: .approved, inAppPurchaseId: "iap-1"
                )
            ], nextCursor: nil)
        )

        let output = try await PromotedPurchasesList.parse(["--app-id", "app-42", "--pretty"])
            .execute(repo: mockRepo, affordanceMode: .rest)
        let normalized = output.replacingOccurrences(of: "\\/", with: "/")

        #expect(normalized.contains("\"_links\""))
        #expect(normalized.contains("/api/v1/apps/app-42/promoted-purchases"))
        #expect(normalized.contains("/api/v1/promoted-purchases/pp-1"))
        #expect(!normalized.contains("\"affordances\""))
    }

    // MARK: - Subscription Group Localizations

    @Test func `subscription group localizations REST exposes nested path under group`() async throws {
        let mockRepo = MockSubscriptionGroupLocalizationRepository()
        given(mockRepo).listLocalizations(groupId: .any).willReturn([
            SubscriptionGroupLocalization(id: "loc-1", groupId: "grp-7", locale: "en-US", name: "Premium")
        ])

        let output = try await SubscriptionGroupLocalizationsList.parse(["--group-id", "grp-7", "--pretty"])
            .execute(repo: mockRepo, affordanceMode: .rest)
        let normalized = output.replacingOccurrences(of: "\\/", with: "/")

        #expect(normalized.contains("\"_links\""))
        #expect(normalized.contains("/api/v1/subscription-groups/grp-7/subscription-group-localizations"))
        #expect(normalized.contains("/api/v1/subscription-group-localizations/loc-1"))
    }

    // MARK: - Subscription Pricing

    @Test func `subscription price-points REST exposes nested path under subscription`() async throws {
        let mockRepo = MockSubscriptionPriceRepository()
        given(mockRepo).listPricePoints(subscriptionId: .any, territory: .any, limit: .any, cursor: .any)
            .willReturn(PaginatedResponse(data: [
                SubscriptionPricePoint(id: "spp-1", subscriptionId: "sub-7", territory: "USA",
                                       customerPrice: "9.99", proceeds: "6.99")
            ], nextCursor: nil))

        let output = try await SubscriptionPricePointsList.parse(["--subscription-id", "sub-7", "--pretty"])
            .execute(repo: mockRepo, affordanceMode: .rest)
        let normalized = output.replacingOccurrences(of: "\\/", with: "/")

        #expect(normalized.contains("\"_links\""))
        #expect(normalized.contains("/api/v1/subscriptions/sub-7/price-points"))
    }

    // MARK: - Subscription Promotional Offers

    @Test func `subscription promotional offers REST exposes nested paths`() async throws {
        let mockRepo = MockSubscriptionPromotionalOfferRepository()
        given(mockRepo).listPromotionalOffers(subscriptionId: .any).willReturn([
            SubscriptionPromotionalOffer(
                id: "po-1", subscriptionId: "sub-7", name: "Winback",
                offerCode: "wb25", duration: .oneMonth, offerMode: .payAsYouGo, numberOfPeriods: 1
            )
        ])

        let output = try await SubscriptionPromotionalOffersList.parse(["--subscription-id", "sub-7", "--pretty"])
            .execute(repo: mockRepo, affordanceMode: .rest)
        let normalized = output.replacingOccurrences(of: "\\/", with: "/")

        #expect(normalized.contains("\"_links\""))
        #expect(normalized.contains("/api/v1/subscriptions/sub-7/subscription-promotional-offers"))
        #expect(normalized.contains("/api/v1/subscription-promotional-offers/po-1"))
        #expect(normalized.contains("/api/v1/subscription-promotional-offers/po-1/prices"))
    }

    // MARK: - Win-Back Offers

    @Test func `win-back offers REST exposes nested paths under subscription`() async throws {
        let mockRepo = MockWinBackOfferRepository()
        given(mockRepo).listWinBackOffers(subscriptionId: .any).willReturn([
            WinBackOffer(
                id: "wb-1", subscriptionId: "sub-7",
                referenceName: "Lapsed", offerId: "lapsed25",
                duration: .oneMonth, offerMode: .freeTrial, periodCount: 1,
                customerEligibilityPaidSubscriptionDurationInMonths: 3,
                customerEligibilityTimeSinceLastSubscribedMin: 1,
                customerEligibilityTimeSinceLastSubscribedMax: 6,
                startDate: "2026-04-01", priority: .high
            )
        ])

        let output = try await WinBackOffersList.parse(["--subscription-id", "sub-7", "--pretty"])
            .execute(repo: mockRepo, affordanceMode: .rest)
        let normalized = output.replacingOccurrences(of: "\\/", with: "/")

        #expect(normalized.contains("\"_links\""))
        #expect(normalized.contains("/api/v1/subscriptions/sub-7/win-back-offers"))
        #expect(normalized.contains("/api/v1/win-back-offers/wb-1"))
        #expect(normalized.contains("/api/v1/win-back-offers/wb-1/prices"))
    }

    // MARK: - Offer Code Prices

    @Test func `iap offer code prices REST exposes nested path under offer code`() async throws {
        let mockRepo = MockInAppPurchaseOfferCodeRepository()
        given(mockRepo).listPrices(offerCodeId: .any).willReturn([
            InAppPurchaseOfferCodePrice(id: "p-1", offerCodeId: "oc-7", territory: "USA", pricePointId: "pp-1")
        ])

        let output = try await IAPOfferCodesPricesList.parse(["--offer-code-id", "oc-7", "--pretty"])
            .execute(repo: mockRepo, affordanceMode: .rest)
        let normalized = output.replacingOccurrences(of: "\\/", with: "/")

        #expect(normalized.contains("\"_links\""))
        #expect(normalized.contains("/api/v1/iap-offer-codes/oc-7/prices"))
    }

    @Test func `subscription offer code prices REST exposes nested path under offer code`() async throws {
        let mockRepo = MockSubscriptionOfferCodeRepository()
        given(mockRepo).listPrices(offerCodeId: .any).willReturn([
            SubscriptionOfferCodePrice(id: "p-1", offerCodeId: "oc-7", territory: "USA", subscriptionPricePointId: "spp-1")
        ])

        let output = try await SubscriptionOfferCodesPricesList.parse(["--offer-code-id", "oc-7", "--pretty"])
            .execute(repo: mockRepo, affordanceMode: .rest)
        let normalized = output.replacingOccurrences(of: "\\/", with: "/")

        #expect(normalized.contains("\"_links\""))
        #expect(normalized.contains("/api/v1/subscription-offer-codes/oc-7/prices"))
    }

    // MARK: - One-Time Use Codes (IAP + Subscription)

    @Test func `IAP one-time codes list REST resolves to nested path under offer code`() async throws {
        let mockRepo = MockInAppPurchaseOfferCodeRepository()
        given(mockRepo).listOneTimeUseCodes(offerCodeId: .any).willReturn([
            InAppPurchaseOfferCodeOneTimeUseCode(
                id: "otc-1", offerCodeId: "oc-7", numberOfCodes: 100,
                expirationDate: "2026-12-31", isActive: true, environment: .sandbox
            )
        ])

        let output = try await IAPOfferCodeOneTimeCodesList.parse(["--offer-code-id", "oc-7", "--pretty"])
            .execute(repo: mockRepo, affordanceMode: .rest)
        let normalized = output.replacingOccurrences(of: "\\/", with: "/")

        #expect(normalized.contains("\"_links\""))
        #expect(normalized.contains("/api/v1/iap-offer-codes/oc-7/one-time-codes"))
        #expect(normalized.contains("\"environment\" : \"SANDBOX\""))
    }

    @Test func `IAP one-time codes update REST resolves to PATCH on the code id`() async throws {
        let mockRepo = MockInAppPurchaseOfferCodeRepository()
        given(mockRepo).updateOneTimeUseCode(oneTimeCodeId: .any, isActive: .any).willReturn(
            InAppPurchaseOfferCodeOneTimeUseCode(
                id: "otc-1", offerCodeId: "oc-7", numberOfCodes: 100,
                expirationDate: "2026-12-31", isActive: false, environment: .production
            )
        )

        let output = try await IAPOfferCodeOneTimeCodesUpdate
            .parse(["--one-time-code-id", "otc-1", "--active", "false", "--pretty"])
            .execute(repo: mockRepo, affordanceMode: .rest)
        let normalized = output.replacingOccurrences(of: "\\/", with: "/")

        #expect(normalized.contains("\"_links\""))
        // listOneTimeCodes affordance is preserved on the row → nested path under parent.
        #expect(normalized.contains("/api/v1/iap-offer-codes/oc-7/one-time-codes"))
    }

    @Test func `subscription one-time codes list REST resolves to nested path under offer code`() async throws {
        let mockRepo = MockSubscriptionOfferCodeRepository()
        given(mockRepo).listOneTimeUseCodes(offerCodeId: .any).willReturn([
            SubscriptionOfferCodeOneTimeUseCode(
                id: "otc-1", offerCodeId: "oc-7", numberOfCodes: 100,
                expirationDate: "2026-12-31", isActive: true, environment: .sandbox
            )
        ])

        let output = try await SubscriptionOfferCodeOneTimeCodesList.parse(["--offer-code-id", "oc-7", "--pretty"])
            .execute(repo: mockRepo, affordanceMode: .rest)
        let normalized = output.replacingOccurrences(of: "\\/", with: "/")

        #expect(normalized.contains("\"_links\""))
        #expect(normalized.contains("/api/v1/subscription-offer-codes/oc-7/one-time-codes"))
        #expect(normalized.contains("\"environment\" : \"SANDBOX\""))
    }

    @Test func `IAP offer codes create REST emits _links pointing back at parent IAP path`() async throws {
        let mockRepo = MockInAppPurchaseOfferCodeRepository()
        given(mockRepo).createOfferCode(
            iapId: .any, name: .any, customerEligibilities: .any, prices: .any
        ).willReturn(InAppPurchaseOfferCode(
            id: "oc-new", iapId: "iap-7", name: "Promo",
            customerEligibilities: [.nonSpender], isActive: true
        ))

        let output = try await IAPOfferCodesCreate.parse([
            "--iap-id", "iap-7",
            "--name", "Promo",
            "--eligibility", "NON_SPENDER",
            "--pretty",
        ]).execute(repo: mockRepo, affordanceMode: .rest)
        let normalized = output.replacingOccurrences(of: "\\/", with: "/")

        #expect(normalized.contains("\"_links\""))
        #expect(normalized.contains("/api/v1/iap-offer-codes/oc-new/one-time-codes"))
    }

    @Test func `subscription offer codes create REST emits _links`() async throws {
        let mockRepo = MockSubscriptionOfferCodeRepository()
        given(mockRepo).createOfferCode(
            subscriptionId: .any, name: .any, customerEligibilities: .any,
            offerEligibility: .any, duration: .any, offerMode: .any, numberOfPeriods: .any,
            isAutoRenewEnabled: .any, prices: .any
        ).willReturn(SubscriptionOfferCode(
            id: "oc-new", subscriptionId: "sub-7", name: "Loyalty",
            customerEligibilities: [.new], offerEligibility: .stackable,
            duration: .oneMonth, offerMode: .freeTrial, numberOfPeriods: 1, isActive: true
        ))

        let output = try await SubscriptionOfferCodesCreate.parse([
            "--subscription-id", "sub-7",
            "--name", "Loyalty",
            "--duration", "ONE_MONTH",
            "--mode", "FREE_TRIAL",
            "--periods", "1",
            "--eligibility", "NEW",
            "--offer-eligibility", "STACKABLE",
            "--pretty",
        ]).execute(repo: mockRepo, affordanceMode: .rest)
        let normalized = output.replacingOccurrences(of: "\\/", with: "/")

        #expect(normalized.contains("\"_links\""))
        #expect(normalized.contains("/api/v1/subscription-offer-codes/oc-new/one-time-codes"))
    }

    @Test func `subscription one-time codes create REST forwards environment to repo and emits _links`() async throws {
        let mockRepo = MockSubscriptionOfferCodeRepository()
        given(mockRepo).createOneTimeUseCode(
            offerCodeId: .any, numberOfCodes: .any, expirationDate: .any, environment: .any
        ).willReturn(
            SubscriptionOfferCodeOneTimeUseCode(
                id: "otc-new", offerCodeId: "oc-7", numberOfCodes: 50,
                expirationDate: "2026-12-31", isActive: true, environment: .sandbox
            )
        )

        let output = try await SubscriptionOfferCodeOneTimeCodesCreate.parse([
            "--offer-code-id", "oc-7",
            "--number-of-codes", "50",
            "--expiration-date", "2026-12-31",
            "--environment", "sandbox",
            "--pretty",
        ]).execute(repo: mockRepo, affordanceMode: .rest)
        let normalized = output.replacingOccurrences(of: "\\/", with: "/")

        verify(mockRepo).createOneTimeUseCode(
            offerCodeId: .any, numberOfCodes: .any, expirationDate: .any,
            environment: .value(.sandbox)
        ).called(1)
        #expect(normalized.contains("\"_links\""))
        #expect(normalized.contains("\"environment\" : \"SANDBOX\""))
    }

    // MARK: - IAP Review Assets

    @Test func `IAP review screenshot REST returns nested path under iap`() async throws {
        let mockRepo = MockInAppPurchaseReviewRepository()
        given(mockRepo).getReviewScreenshot(iapId: .any).willReturn(
            InAppPurchaseReviewScreenshot(id: "rs-1", iapId: "iap-7", fileName: "review.png",
                                          fileSize: 1234, assetState: .complete)
        )

        let output = try await IAPReviewScreenshotGet.parse(["--iap-id", "iap-7", "--pretty"])
            .execute(repo: mockRepo, affordanceMode: .rest)
        let normalized = output.replacingOccurrences(of: "\\/", with: "/")

        #expect(normalized.contains("\"_links\""))
        // Singleton `get` resolves through the nested parent path.
        #expect(normalized.contains("/api/v1/iap/iap-7/review-screenshot"))
        // Delete uses the screenshot's own id (no parent in params), so the flat path applies.
        #expect(normalized.contains("/api/v1/iap-review-screenshot/rs-1"))
    }

    @Test func `IAP images REST returns nested path under iap`() async throws {
        let mockRepo = MockInAppPurchaseReviewRepository()
        given(mockRepo).listImages(iapId: .any).willReturn([
            InAppPurchasePromotionalImage(id: "img-1", iapId: "iap-7", fileName: "promo.png",
                                          fileSize: 9999, state: .approved)
        ])

        let output = try await IAPImagesList.parse(["--iap-id", "iap-7", "--pretty"])
            .execute(repo: mockRepo, affordanceMode: .rest)
        let normalized = output.replacingOccurrences(of: "\\/", with: "/")

        #expect(normalized.contains("\"_links\""))
        #expect(normalized.contains("/api/v1/iap/iap-7/images"))
    }

    // MARK: - Subscription Review Asset

    @Test func `subscription review screenshot REST returns nested path under subscription`() async throws {
        let mockRepo = MockSubscriptionReviewRepository()
        given(mockRepo).getReviewScreenshot(subscriptionId: .any).willReturn(
            SubscriptionReviewScreenshot(id: "rs-1", subscriptionId: "sub-7", fileName: "review.png",
                                         fileSize: 1234, assetState: .complete)
        )

        let output = try await SubscriptionReviewScreenshotGet.parse(["--subscription-id", "sub-7", "--pretty"])
            .execute(repo: mockRepo, affordanceMode: .rest)
        let normalized = output.replacingOccurrences(of: "\\/", with: "/")

        #expect(normalized.contains("\"_links\""))
        // Singleton `get` resolves through the nested parent path.
        #expect(normalized.contains("/api/v1/subscriptions/sub-7/review-screenshot"))
        // Delete uses the screenshot's own id (no parent in params), so the flat path applies.
        #expect(normalized.contains("/api/v1/subscription-review-screenshot/rs-1"))
    }

    @Test func `promoted purchases REST suppresses update and delete links while in review`() async throws {
        let mockRepo = MockPromotedPurchaseRepository()
        given(mockRepo).listPromotedPurchases(appId: .any, limit: .any).willReturn(
            PaginatedResponse(data: [
                PromotedPurchase(
                    id: "pp-1", appId: "app-42",
                    isVisibleForAllUsers: true, isEnabled: true,
                    state: .inReview, inAppPurchaseId: "iap-1"
                )
            ], nextCursor: nil)
        )

        let output = try await PromotedPurchasesList.parse(["--app-id", "app-42", "--pretty"])
            .execute(repo: mockRepo, affordanceMode: .rest)
        let normalized = output.replacingOccurrences(of: "\\/", with: "/")

        // listSiblings link still appears
        #expect(normalized.contains("/api/v1/apps/app-42/promoted-purchases"))
        // Update + delete are suppressed by isLocked guard
        #expect(!normalized.contains("\"update\""))
        #expect(!normalized.contains("\"delete\""))
    }

    // MARK: - IAP detail listings (Localizations, Availability, OfferCodes, PricePoints)

    @Test func `IAP localizations list REST exposes nested path under iap`() async throws {
        let mockRepo = MockInAppPurchaseLocalizationRepository()
        given(mockRepo).listLocalizations(iapId: .any).willReturn([
            InAppPurchaseLocalization(id: "loc-1", iapId: "iap-7", locale: "en-US", name: "Lifetime", description: "Lifetime pass", state: .approved)
        ])

        let output = try await IAPLocalizationsList.parse(["--iap-id", "iap-7", "--pretty"])
            .execute(repo: mockRepo, affordanceMode: .rest)
        let normalized = output.replacingOccurrences(of: "\\/", with: "/")

        #expect(normalized.contains("\"_links\""))
        #expect(normalized.contains("/api/v1/iap/iap-7/localizations"))
    }

    @Test func `IAP availability get REST exposes nested path under iap`() async throws {
        let mockRepo = MockInAppPurchaseAvailabilityRepository()
        given(mockRepo).getAvailability(iapId: .any).willReturn(
            InAppPurchaseAvailability(id: "avail-1", iapId: "iap-7",
                                      isAvailableInNewTerritories: true,
                                      territories: [Territory(id: "USA", currency: "USD")])
        )

        let output = try await IAPAvailabilityGet.parse(["--iap-id", "iap-7", "--pretty"])
            .execute(repo: mockRepo, affordanceMode: .rest)
        let normalized = output.replacingOccurrences(of: "\\/", with: "/")

        #expect(normalized.contains("\"_links\""))
        #expect(normalized.contains("/api/v1/iap/iap-7/availability"))
    }

    @Test func `IAP offer codes list REST exposes nested path under iap`() async throws {
        let mockRepo = MockInAppPurchaseOfferCodeRepository()
        given(mockRepo).listOfferCodes(iapId: .any).willReturn([
            InAppPurchaseOfferCode(id: "oc-1", iapId: "iap-7", name: "Promo", customerEligibilities: [.nonSpender], isActive: true)
        ])

        let output = try await IAPOfferCodesList.parse(["--iap-id", "iap-7", "--pretty"])
            .execute(repo: mockRepo, affordanceMode: .rest)
        let normalized = output.replacingOccurrences(of: "\\/", with: "/")

        #expect(normalized.contains("\"_links\""))
        #expect(normalized.contains("/api/v1/iap/iap-7/offer-codes"))
    }

    @Test func `IAP equalizations list REST exposes nested path under price point`() async throws {
        let mockRepo = MockInAppPurchasePriceRepository()
        given(mockRepo).listEqualizations(pricePointId: .any, limit: .any).willReturn([
            InAppPurchasePricePoint(id: "pp-USA", iapId: "", territory: "USA", customerPrice: "9.99", proceeds: "6.99"),
            InAppPurchasePricePoint(id: "pp-JPN", iapId: "", territory: "JPN", customerPrice: "1500", proceeds: "1050"),
        ])

        let output = try await IAPEqualizationsList.parse(["--price-point-id", "pp-USA", "--pretty"])
            .execute(repo: mockRepo, affordanceMode: .rest)
        let normalized = output.replacingOccurrences(of: "\\/", with: "/")

        #expect(normalized.contains("\"data\""))
        #expect(normalized.contains("\"territory\" : \"USA\""))
        #expect(normalized.contains("\"territory\" : \"JPN\""))
    }

    @Test func `IAP price-schedule get REST exposes nested path under iap`() async throws {
        let mockRepo = MockInAppPurchasePriceRepository()
        given(mockRepo).getPriceSchedule(iapId: .any).willReturn(
            InAppPurchasePriceSchedule(id: "iap-7", iapId: "iap-7")
        )

        let output = try await IAPPriceScheduleGet.parse(["--iap-id", "iap-7", "--pretty"])
            .execute(repo: mockRepo, affordanceMode: .rest)
        let normalized = output.replacingOccurrences(of: "\\/", with: "/")

        #expect(normalized.contains("\"_links\""))
        #expect(normalized.contains("/api/v1/iap/iap-7/price-points"))
    }

    @Test func `IAP price-schedule get REST returns empty data when no schedule`() async throws {
        let mockRepo = MockInAppPurchasePriceRepository()
        given(mockRepo).getPriceSchedule(iapId: .any).willReturn(nil)

        let output = try await IAPPriceScheduleGet.parse(["--iap-id", "iap-7", "--pretty"])
            .execute(repo: mockRepo, affordanceMode: .rest)
        // Mirrors `iap-review-screenshot get` shape: empty data array for "not configured yet".
        #expect(output.contains("\"data\" : ["))
        #expect(output.contains("]"))
    }

    @Test func `IAP price-points list REST exposes nested path under iap`() async throws {
        let mockRepo = MockInAppPurchasePriceRepository()
        given(mockRepo).listPricePoints(iapId: .any, territory: .any, limit: .any, cursor: .any)
            .willReturn(PaginatedResponse(data: [
                InAppPurchasePricePoint(id: "pp-1", iapId: "iap-7", territory: "USA", customerPrice: "9.99", proceeds: "6.99")
            ], nextCursor: nil))

        let output = try await IAPPricePointsList.parse(["--iap-id", "iap-7", "--pretty"])
            .execute(repo: mockRepo, affordanceMode: .rest)
        let normalized = output.replacingOccurrences(of: "\\/", with: "/")

        #expect(normalized.contains("\"_links\""))
        #expect(normalized.contains("/api/v1/iap/iap-7/price-points"))
    }

    // MARK: - Subscription detail listings (Localizations, Availability, OfferCodes, IntroOffers)

    @Test func `subscriptions list REST exposes nested path under subscription group`() async throws {
        let mockRepo = MockSubscriptionRepository()
        given(mockRepo).listSubscriptions(groupId: .any, limit: .any).willReturn(
            PaginatedResponse(data: [
                Subscription(
                    id: "sub-1", groupId: "grp-7", name: "Monthly Premium",
                    productId: "com.app.monthly", subscriptionPeriod: .oneMonth,
                    isFamilySharable: false, state: .missingMetadata
                )
            ], nextCursor: nil)
        )

        let output = try await SubscriptionsList.parse(["--group-id", "grp-7", "--pretty"])
            .execute(repo: mockRepo, affordanceMode: .rest)
        let normalized = output.replacingOccurrences(of: "\\/", with: "/")

        #expect(normalized.contains("\"_links\""))
        // Each subscription advertises navigation links to its detail endpoints.
        #expect(normalized.contains("/api/v1/subscriptions/sub-1/localizations"))
        #expect(normalized.contains("/api/v1/subscriptions/sub-1/availability"))
        #expect(normalized.contains("/api/v1/subscriptions/sub-1/price-schedule"))
    }

    @Test func `subscription localizations list REST exposes nested path under subscription`() async throws {
        let mockRepo = MockSubscriptionLocalizationRepository()
        given(mockRepo).listLocalizations(subscriptionId: .any).willReturn([
            SubscriptionLocalization(id: "loc-1", subscriptionId: "sub-7", locale: "en-US", name: "Premium", description: "Premium plan", state: .approved)
        ])

        let output = try await SubscriptionLocalizationsList.parse(["--subscription-id", "sub-7", "--pretty"])
            .execute(repo: mockRepo, affordanceMode: .rest)
        let normalized = output.replacingOccurrences(of: "\\/", with: "/")

        #expect(normalized.contains("\"_links\""))
        #expect(normalized.contains("/api/v1/subscriptions/sub-7/localizations"))
    }

    @Test func `subscription availability get REST exposes nested path under subscription`() async throws {
        let mockRepo = MockSubscriptionAvailabilityRepository()
        given(mockRepo).getAvailability(subscriptionId: .any).willReturn(
            SubscriptionAvailability(id: "avail-1", subscriptionId: "sub-7",
                                     isAvailableInNewTerritories: true,
                                     territories: [Territory(id: "USA", currency: "USD")])
        )

        let output = try await SubscriptionAvailabilityGet.parse(["--subscription-id", "sub-7", "--pretty"])
            .execute(repo: mockRepo, affordanceMode: .rest)
        let normalized = output.replacingOccurrences(of: "\\/", with: "/")

        #expect(normalized.contains("\"_links\""))
        #expect(normalized.contains("/api/v1/subscriptions/sub-7/availability"))
    }

    @Test func `subscription offer codes list REST exposes nested path under subscription`() async throws {
        let mockRepo = MockSubscriptionOfferCodeRepository()
        given(mockRepo).listOfferCodes(subscriptionId: .any).willReturn([
            SubscriptionOfferCode(id: "oc-1", subscriptionId: "sub-7", name: "Promo",
                                  customerEligibilities: [.new], offerEligibility: .introductory,
                                  duration: .oneMonth, offerMode: .freeTrial, numberOfPeriods: 1, isActive: true)
        ])

        let output = try await SubscriptionOfferCodesList.parse(["--subscription-id", "sub-7", "--pretty"])
            .execute(repo: mockRepo, affordanceMode: .rest)
        let normalized = output.replacingOccurrences(of: "\\/", with: "/")

        #expect(normalized.contains("\"_links\""))
        #expect(normalized.contains("/api/v1/subscriptions/sub-7/offer-codes"))
    }

    @Test func `subscription introductory offers list REST exposes nested path under subscription`() async throws {
        let mockRepo = MockSubscriptionIntroductoryOfferRepository()
        given(mockRepo).listIntroductoryOffers(subscriptionId: .any).willReturn([
            SubscriptionIntroductoryOffer(id: "io-1", subscriptionId: "sub-7", duration: .oneMonth, offerMode: .freeTrial, numberOfPeriods: 1)
        ])

        let output = try await SubscriptionOffersList.parse(["--subscription-id", "sub-7", "--pretty"])
            .execute(repo: mockRepo, affordanceMode: .rest)
        let normalized = output.replacingOccurrences(of: "\\/", with: "/")

        #expect(normalized.contains("\"_links\""))
        #expect(normalized.contains("/api/v1/subscriptions/sub-7/introductory-offers"))
    }
}
