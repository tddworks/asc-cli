import ArgumentParser
import Domain

struct AgeRatingCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "age-rating",
        abstract: "Manage App Store age rating declarations",
        subcommands: [AgeRatingGet.self, AgeRatingUpdate.self]
    )
}

// MARK: - Get

struct AgeRatingGet: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "get",
        abstract: "Get the age rating declaration for an app info"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "App Info ID")
    var appInfoId: String

    func run() async throws {
        let repo = try ClientProvider.makeAgeRatingDeclarationRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any AgeRatingDeclarationRepository) async throws -> String {
        let declaration = try await repo.getDeclaration(appInfoId: appInfoId)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            [declaration],
            headers: ["ID", "App Info ID", "Kids Age Band", "Age Rating Override"],
            rowMapper: { [$0.id, $0.appInfoId, $0.kidsAgeBand?.rawValue ?? "-", $0.ageRatingOverride?.rawValue ?? "-"] }
        )
    }
}

// MARK: - Update

struct AgeRatingUpdate: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "update",
        abstract: "Update the age rating declaration"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Age Rating Declaration ID")
    var declarationId: String

    // Boolean content flags
    @Option(name: .long, help: "Contains advertising (true/false)")
    var advertising: Bool?

    @Option(name: .long, help: "Contains gambling (true/false)")
    var gambling: Bool?

    @Option(name: .long, help: "Contains health or wellness topics (true/false)")
    var healthOrWellnessTopics: Bool?

    @Option(name: .long, help: "Contains loot box mechanics (true/false)")
    var lootBox: Bool?

    @Option(name: .long, help: "Contains messaging or chat (true/false)")
    var messagingAndChat: Bool?

    @Option(name: .long, help: "Contains parental controls (true/false)")
    var parentalControls: Bool?

    @Option(name: .long, help: "Contains age assurance features (true/false)")
    var ageAssurance: Bool?

    @Option(name: .long, help: "Contains unrestricted web access (true/false)")
    var unrestrictedWebAccess: Bool?

    @Option(name: .long, help: "Contains user-generated content (true/false)")
    var userGeneratedContent: Bool?

    // Intensity flags (NONE/INFREQUENT_OR_MILD/FREQUENT_OR_INTENSE/INFREQUENT/FREQUENT)
    @Option(name: .long, help: "Alcohol, tobacco or drug use intensity")
    var alcoholTobaccoDrugs: ContentIntensity?

    @Option(name: .long, help: "Contests intensity")
    var contests: ContentIntensity?

    @Option(name: .long, help: "Simulated gambling intensity")
    var gamblingSimulated: ContentIntensity?

    @Option(name: .long, help: "Guns or other weapons intensity")
    var gunsWeapons: ContentIntensity?

    @Option(name: .long, help: "Medical or treatment information intensity")
    var medicalTreatment: ContentIntensity?

    @Option(name: .long, help: "Profanity or crude humor intensity")
    var profanity: ContentIntensity?

    @Option(name: .long, help: "Sexual content (graphic and nudity) intensity")
    var sexualContentGraphic: ContentIntensity?

    @Option(name: .long, help: "Sexual content or nudity intensity")
    var sexualContent: ContentIntensity?

    @Option(name: .long, help: "Horror or fear themes intensity")
    var horrorFear: ContentIntensity?

    @Option(name: .long, help: "Mature or suggestive themes intensity")
    var matureSuggestive: ContentIntensity?

    @Option(name: .long, help: "Cartoon or fantasy violence intensity")
    var violenceCartoon: ContentIntensity?

    @Option(name: .long, help: "Realistic prolonged, graphic or sadistic violence intensity")
    var violenceRealisticProlonged: ContentIntensity?

    @Option(name: .long, help: "Realistic violence intensity")
    var violenceRealistic: ContentIntensity?

    // Override ratings
    @Option(name: .long, help: "Kids age band (FIVE_AND_UNDER/SIX_TO_EIGHT/NINE_TO_ELEVEN)")
    var kidsAgeBand: KidsAgeBand?

    @Option(name: .long, help: "Age rating override (NONE/NINE_PLUS/THIRTEEN_PLUS/SIXTEEN_PLUS/EIGHTEEN_PLUS/UNRATED)")
    var ageRatingOverride: AgeRatingOverride?

    @Option(name: .long, help: "Korea age rating override (NONE/FIFTEEN_PLUS/NINETEEN_PLUS)")
    var koreaAgeRatingOverride: KoreaAgeRatingOverride?

    func run() async throws {
        let repo = try ClientProvider.makeAgeRatingDeclarationRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any AgeRatingDeclarationRepository) async throws -> String {
        var update = AgeRatingDeclarationUpdate()
        update.isAdvertising = advertising
        update.isGambling = gambling
        update.isHealthOrWellnessTopics = healthOrWellnessTopics
        update.isLootBox = lootBox
        update.isMessagingAndChat = messagingAndChat
        update.isParentalControls = parentalControls
        update.isAgeAssurance = ageAssurance
        update.isUnrestrictedWebAccess = unrestrictedWebAccess
        update.isUserGeneratedContent = userGeneratedContent
        update.alcoholTobaccoOrDrugUseOrReferences = alcoholTobaccoDrugs
        update.contests = contests
        update.gamblingSimulated = gamblingSimulated
        update.gunsOrOtherWeapons = gunsWeapons
        update.medicalOrTreatmentInformation = medicalTreatment
        update.profanityOrCrudeHumor = profanity
        update.sexualContentGraphicAndNudity = sexualContentGraphic
        update.sexualContentOrNudity = sexualContent
        update.horrorOrFearThemes = horrorFear
        update.matureOrSuggestiveThemes = matureSuggestive
        update.violenceCartoonOrFantasy = violenceCartoon
        update.violenceRealisticProlongedGraphicOrSadistic = violenceRealisticProlonged
        update.violenceRealistic = violenceRealistic
        update.kidsAgeBand = kidsAgeBand
        update.ageRatingOverride = ageRatingOverride
        update.koreaAgeRatingOverride = koreaAgeRatingOverride

        let declaration = try await repo.updateDeclaration(id: declarationId, update: update)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            [declaration],
            headers: ["ID", "App Info ID", "Kids Age Band", "Age Rating Override"],
            rowMapper: { [$0.id, $0.appInfoId, $0.kidsAgeBand?.rawValue ?? "-", $0.ageRatingOverride?.rawValue ?? "-"] }
        )
    }
}

// MARK: - ExpressibleByArgument conformances

extension ContentIntensity: ExpressibleByArgument {}
extension KidsAgeBand: ExpressibleByArgument {}
extension AgeRatingOverride: ExpressibleByArgument {}
extension KoreaAgeRatingOverride: ExpressibleByArgument {}
