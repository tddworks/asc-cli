import ArgumentParser
import Domain

struct VersionsCheckReadiness: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "check-readiness",
        abstract: "Pre-flight check for App Store submission readiness"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "App Store Version ID")
    var versionId: String

    func run() async throws {
        let versionRepo = try ClientProvider.makeVersionRepository()
        let appRepo = try ClientProvider.makeAppRepository()
        let buildRepo = try ClientProvider.makeBuildRepository()
        let reviewDetailRepo = try ClientProvider.makeReviewDetailRepository()
        let localizationRepo = try ClientProvider.makeVersionLocalizationRepository()
        let screenshotRepo = try ClientProvider.makeScreenshotRepository()
        let pricingRepo = try ClientProvider.makePricingRepository()
        let appInfoRepo = try ClientProvider.makeAppInfoRepository()
        let ageRatingRepo = try ClientProvider.makeAgeRatingDeclarationRepository()
        print(try await execute(
            versionRepo: versionRepo,
            appRepo: appRepo,
            buildRepo: buildRepo,
            reviewDetailRepo: reviewDetailRepo,
            localizationRepo: localizationRepo,
            screenshotRepo: screenshotRepo,
            pricingRepo: pricingRepo,
            appInfoRepo: appInfoRepo,
            ageRatingRepo: ageRatingRepo
        ))
    }

    func execute(
        versionRepo: any VersionRepository,
        appRepo: any AppRepository,
        buildRepo: any BuildRepository,
        reviewDetailRepo: any ReviewDetailRepository,
        localizationRepo: any VersionLocalizationRepository,
        screenshotRepo: any ScreenshotRepository,
        pricingRepo: any PricingRepository,
        appInfoRepo: any AppInfoRepository,
        ageRatingRepo: any AgeRatingDeclarationRepository
    ) async throws -> String {
        // 1. Fetch version (includes appId + buildId)
        let version = try await versionRepo.getVersion(id: versionId)

        // 2. State check (MUST FIX)
        let stateCheck: ReadinessCheck = version.isEditable
            ? .pass()
            : .fail("Version state '\(version.state.rawValue)' is not editable")

        // 3. Build check (MUST FIX)
        let buildCheck: BuildReadinessCheck
        if let buildId = version.buildId {
            let build = try await buildRepo.getBuild(id: buildId)
            let buildVersion: String
            if let num = build.buildNumber {
                buildVersion = "\(build.version) (\(num))"
            } else {
                buildVersion = build.version
            }
            buildCheck = BuildReadinessCheck(
                linked: true,
                valid: build.processingState == .valid,
                notExpired: !build.expired,
                buildVersion: buildVersion
            )
        } else {
            buildCheck = BuildReadinessCheck(linked: false, valid: false, notExpired: false)
        }

        // 4. Pricing check (MUST FIX)
        let hasPricing = try await pricingRepo.hasPricing(appId: version.appId)
        let pricingCheck: ReadinessCheck = hasPricing
            ? .pass()
            : .fail("No price schedule configured for this app")

        // 5. Review contact check (SHOULD FIX)
        let reviewDetail = try await reviewDetailRepo.getReviewDetail(versionId: versionId)
        let reviewContactCheck: ReadinessCheck = reviewDetail.hasContact
            ? .pass()
            : .fail("No contact email or phone set in App Store review information")

        // 6. Localization readiness — use app primaryLocale for accurate isPrimary
        let app = try await appRepo.getApp(id: version.appId)
        let primaryLocale = app.primaryLocale
        let localizations = try await localizationRepo.listLocalizations(versionId: versionId)
        var localizationReadiness: [LocalizationReadiness] = []
        for loc in localizations {
            let sets = try await screenshotRepo.listScreenshotSets(localizationId: loc.id)
            let screenshotSetCount = sets.filter { $0.screenshotsCount > 0 }.count
            let isPrimary = primaryLocale != nil
                ? loc.locale == primaryLocale
                : localizations.first?.id == loc.id
            localizationReadiness.append(LocalizationReadiness(
                locale: loc.locale,
                isPrimary: isPrimary,
                hasDescription: loc.description != nil,
                hasKeywords: loc.keywords != nil,
                hasSupportUrl: loc.supportUrl != nil,
                hasWhatsNew: loc.whatsNew != nil,
                screenshotSetCount: screenshotSetCount
            ))
        }

        // 7. Age rating check (MUST FIX) — the app info going to review, not the live one
        let appInfos = try await appInfoRepo.listAppInfos(appId: version.appId)
        let ageRatingCheck: ReadinessCheck
        if let appInfo = appInfos.first(where: \.isEditable) ?? appInfos.first(where: { !$0.isLive }) ?? appInfos.first {
            ageRatingCheck = try await ageRatingRepo.getDeclaration(appInfoId: appInfo.id).readinessCheck
        } else {
            ageRatingCheck = .fail("No app info found to read the age rating from")
        }

        // 8. Aggregate MUST FIX result — primary locale must pass
        let localizationCheck = LocalizationReadinessCheck(localizations: localizationReadiness)
        let isReadyToSubmit = stateCheck.pass && buildCheck.pass && pricingCheck.pass
            && localizationCheck.pass && ageRatingCheck.pass

        let readiness = VersionReadiness(
            id: version.id,
            appId: version.appId,
            versionString: version.versionString,
            state: version.state,
            isReadyToSubmit: isReadyToSubmit,
            stateCheck: stateCheck,
            buildCheck: buildCheck,
            pricingCheck: pricingCheck,
            localizationCheck: localizationCheck,
            ageRatingCheck: ageRatingCheck,
            reviewContactCheck: reviewContactCheck
        )

        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            [readiness],
            headers: ["ID", "Version", "State", "Ready"],
            rowMapper: { [$0.id, $0.versionString, $0.state.displayName, $0.isReadyToSubmit ? "yes" : "no"] }
        )
    }
}
