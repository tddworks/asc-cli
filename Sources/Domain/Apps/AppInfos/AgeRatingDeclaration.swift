public enum ContentIntensity: String, Sendable, Equatable, Codable, CaseIterable {
    case none = "NONE"
    case infrequentOrMild = "INFREQUENT_OR_MILD"
    case frequentOrIntense = "FREQUENT_OR_INTENSE"
    case infrequent = "INFREQUENT"
    case frequent = "FREQUENT"
}

public enum KidsAgeBand: String, Sendable, Equatable, Codable, CaseIterable {
    case fiveAndUnder = "FIVE_AND_UNDER"
    case sixToEight = "SIX_TO_EIGHT"
    case nineToEleven = "NINE_TO_ELEVEN"
}

public enum AgeRatingOverride: String, Sendable, Equatable, Codable, CaseIterable {
    case none = "NONE"
    case ninePlus = "NINE_PLUS"
    case thirteenPlus = "THIRTEEN_PLUS"
    case sixteenPlus = "SIXTEEN_PLUS"
    case eighteenPlus = "EIGHTEEN_PLUS"
    case unrated = "UNRATED"
}

public enum KoreaAgeRatingOverride: String, Sendable, Equatable, Codable, CaseIterable {
    case none = "NONE"
    case fifteenPlus = "FIFTEEN_PLUS"
    case nineteenPlus = "NINETEEN_PLUS"
}

public struct AgeRatingDeclaration: Sendable, Equatable, Identifiable {
    public let id: String
    /// Parent app info identifier — injected by Infrastructure since the API doesn't return it.
    public let appInfoId: String

    // Boolean content flags
    public let isAdvertising: Bool?
    public let isGambling: Bool?
    public let isHealthOrWellnessTopics: Bool?
    public let isLootBox: Bool?
    public let isMessagingAndChat: Bool?
    public let isParentalControls: Bool?
    public let isAgeAssurance: Bool?
    public let isUnrestrictedWebAccess: Bool?
    public let isUserGeneratedContent: Bool?

    // Content intensity ratings
    public let alcoholTobaccoOrDrugUseOrReferences: ContentIntensity?
    public let contests: ContentIntensity?
    public let gamblingSimulated: ContentIntensity?
    public let gunsOrOtherWeapons: ContentIntensity?
    public let medicalOrTreatmentInformation: ContentIntensity?
    public let profanityOrCrudeHumor: ContentIntensity?
    public let sexualContentGraphicAndNudity: ContentIntensity?
    public let sexualContentOrNudity: ContentIntensity?
    public let horrorOrFearThemes: ContentIntensity?
    public let matureOrSuggestiveThemes: ContentIntensity?
    public let violenceCartoonOrFantasy: ContentIntensity?
    public let violenceRealisticProlongedGraphicOrSadistic: ContentIntensity?
    public let violenceRealistic: ContentIntensity?

    // Override ratings
    public let kidsAgeBand: KidsAgeBand?
    public let ageRatingOverride: AgeRatingOverride?
    public let koreaAgeRatingOverride: KoreaAgeRatingOverride?

    public init(
        id: String,
        appInfoId: String,
        isAdvertising: Bool? = nil,
        isGambling: Bool? = nil,
        isHealthOrWellnessTopics: Bool? = nil,
        isLootBox: Bool? = nil,
        isMessagingAndChat: Bool? = nil,
        isParentalControls: Bool? = nil,
        isAgeAssurance: Bool? = nil,
        isUnrestrictedWebAccess: Bool? = nil,
        isUserGeneratedContent: Bool? = nil,
        alcoholTobaccoOrDrugUseOrReferences: ContentIntensity? = nil,
        contests: ContentIntensity? = nil,
        gamblingSimulated: ContentIntensity? = nil,
        gunsOrOtherWeapons: ContentIntensity? = nil,
        medicalOrTreatmentInformation: ContentIntensity? = nil,
        profanityOrCrudeHumor: ContentIntensity? = nil,
        sexualContentGraphicAndNudity: ContentIntensity? = nil,
        sexualContentOrNudity: ContentIntensity? = nil,
        horrorOrFearThemes: ContentIntensity? = nil,
        matureOrSuggestiveThemes: ContentIntensity? = nil,
        violenceCartoonOrFantasy: ContentIntensity? = nil,
        violenceRealisticProlongedGraphicOrSadistic: ContentIntensity? = nil,
        violenceRealistic: ContentIntensity? = nil,
        kidsAgeBand: KidsAgeBand? = nil,
        ageRatingOverride: AgeRatingOverride? = nil,
        koreaAgeRatingOverride: KoreaAgeRatingOverride? = nil
    ) {
        self.id = id
        self.appInfoId = appInfoId
        self.isAdvertising = isAdvertising
        self.isGambling = isGambling
        self.isHealthOrWellnessTopics = isHealthOrWellnessTopics
        self.isLootBox = isLootBox
        self.isMessagingAndChat = isMessagingAndChat
        self.isParentalControls = isParentalControls
        self.isAgeAssurance = isAgeAssurance
        self.isUnrestrictedWebAccess = isUnrestrictedWebAccess
        self.isUserGeneratedContent = isUserGeneratedContent
        self.alcoholTobaccoOrDrugUseOrReferences = alcoholTobaccoOrDrugUseOrReferences
        self.contests = contests
        self.gamblingSimulated = gamblingSimulated
        self.gunsOrOtherWeapons = gunsOrOtherWeapons
        self.medicalOrTreatmentInformation = medicalOrTreatmentInformation
        self.profanityOrCrudeHumor = profanityOrCrudeHumor
        self.sexualContentGraphicAndNudity = sexualContentGraphicAndNudity
        self.sexualContentOrNudity = sexualContentOrNudity
        self.horrorOrFearThemes = horrorOrFearThemes
        self.matureOrSuggestiveThemes = matureOrSuggestiveThemes
        self.violenceCartoonOrFantasy = violenceCartoonOrFantasy
        self.violenceRealisticProlongedGraphicOrSadistic = violenceRealisticProlongedGraphicOrSadistic
        self.violenceRealistic = violenceRealistic
        self.kidsAgeBand = kidsAgeBand
        self.ageRatingOverride = ageRatingOverride
        self.koreaAgeRatingOverride = koreaAgeRatingOverride
    }
}

extension AgeRatingDeclaration: Codable {
    enum CodingKeys: String, CodingKey {
        case id, appInfoId
        case isAdvertising, isGambling, isHealthOrWellnessTopics, isLootBox
        case isMessagingAndChat, isParentalControls, isAgeAssurance
        case isUnrestrictedWebAccess, isUserGeneratedContent
        case alcoholTobaccoOrDrugUseOrReferences, contests, gamblingSimulated
        case gunsOrOtherWeapons, medicalOrTreatmentInformation, profanityOrCrudeHumor
        case sexualContentGraphicAndNudity, sexualContentOrNudity, horrorOrFearThemes
        case matureOrSuggestiveThemes, violenceCartoonOrFantasy
        case violenceRealisticProlongedGraphicOrSadistic, violenceRealistic
        case kidsAgeBand, ageRatingOverride, koreaAgeRatingOverride
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        appInfoId = try c.decode(String.self, forKey: .appInfoId)
        isAdvertising = try c.decodeIfPresent(Bool.self, forKey: .isAdvertising)
        isGambling = try c.decodeIfPresent(Bool.self, forKey: .isGambling)
        isHealthOrWellnessTopics = try c.decodeIfPresent(Bool.self, forKey: .isHealthOrWellnessTopics)
        isLootBox = try c.decodeIfPresent(Bool.self, forKey: .isLootBox)
        isMessagingAndChat = try c.decodeIfPresent(Bool.self, forKey: .isMessagingAndChat)
        isParentalControls = try c.decodeIfPresent(Bool.self, forKey: .isParentalControls)
        isAgeAssurance = try c.decodeIfPresent(Bool.self, forKey: .isAgeAssurance)
        isUnrestrictedWebAccess = try c.decodeIfPresent(Bool.self, forKey: .isUnrestrictedWebAccess)
        isUserGeneratedContent = try c.decodeIfPresent(Bool.self, forKey: .isUserGeneratedContent)
        alcoholTobaccoOrDrugUseOrReferences = try c.decodeIfPresent(ContentIntensity.self, forKey: .alcoholTobaccoOrDrugUseOrReferences)
        contests = try c.decodeIfPresent(ContentIntensity.self, forKey: .contests)
        gamblingSimulated = try c.decodeIfPresent(ContentIntensity.self, forKey: .gamblingSimulated)
        gunsOrOtherWeapons = try c.decodeIfPresent(ContentIntensity.self, forKey: .gunsOrOtherWeapons)
        medicalOrTreatmentInformation = try c.decodeIfPresent(ContentIntensity.self, forKey: .medicalOrTreatmentInformation)
        profanityOrCrudeHumor = try c.decodeIfPresent(ContentIntensity.self, forKey: .profanityOrCrudeHumor)
        sexualContentGraphicAndNudity = try c.decodeIfPresent(ContentIntensity.self, forKey: .sexualContentGraphicAndNudity)
        sexualContentOrNudity = try c.decodeIfPresent(ContentIntensity.self, forKey: .sexualContentOrNudity)
        horrorOrFearThemes = try c.decodeIfPresent(ContentIntensity.self, forKey: .horrorOrFearThemes)
        matureOrSuggestiveThemes = try c.decodeIfPresent(ContentIntensity.self, forKey: .matureOrSuggestiveThemes)
        violenceCartoonOrFantasy = try c.decodeIfPresent(ContentIntensity.self, forKey: .violenceCartoonOrFantasy)
        violenceRealisticProlongedGraphicOrSadistic = try c.decodeIfPresent(ContentIntensity.self, forKey: .violenceRealisticProlongedGraphicOrSadistic)
        violenceRealistic = try c.decodeIfPresent(ContentIntensity.self, forKey: .violenceRealistic)
        kidsAgeBand = try c.decodeIfPresent(KidsAgeBand.self, forKey: .kidsAgeBand)
        ageRatingOverride = try c.decodeIfPresent(AgeRatingOverride.self, forKey: .ageRatingOverride)
        koreaAgeRatingOverride = try c.decodeIfPresent(KoreaAgeRatingOverride.self, forKey: .koreaAgeRatingOverride)
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(appInfoId, forKey: .appInfoId)
        try c.encodeIfPresent(isAdvertising, forKey: .isAdvertising)
        try c.encodeIfPresent(isGambling, forKey: .isGambling)
        try c.encodeIfPresent(isHealthOrWellnessTopics, forKey: .isHealthOrWellnessTopics)
        try c.encodeIfPresent(isLootBox, forKey: .isLootBox)
        try c.encodeIfPresent(isMessagingAndChat, forKey: .isMessagingAndChat)
        try c.encodeIfPresent(isParentalControls, forKey: .isParentalControls)
        try c.encodeIfPresent(isAgeAssurance, forKey: .isAgeAssurance)
        try c.encodeIfPresent(isUnrestrictedWebAccess, forKey: .isUnrestrictedWebAccess)
        try c.encodeIfPresent(isUserGeneratedContent, forKey: .isUserGeneratedContent)
        try c.encodeIfPresent(alcoholTobaccoOrDrugUseOrReferences, forKey: .alcoholTobaccoOrDrugUseOrReferences)
        try c.encodeIfPresent(contests, forKey: .contests)
        try c.encodeIfPresent(gamblingSimulated, forKey: .gamblingSimulated)
        try c.encodeIfPresent(gunsOrOtherWeapons, forKey: .gunsOrOtherWeapons)
        try c.encodeIfPresent(medicalOrTreatmentInformation, forKey: .medicalOrTreatmentInformation)
        try c.encodeIfPresent(profanityOrCrudeHumor, forKey: .profanityOrCrudeHumor)
        try c.encodeIfPresent(sexualContentGraphicAndNudity, forKey: .sexualContentGraphicAndNudity)
        try c.encodeIfPresent(sexualContentOrNudity, forKey: .sexualContentOrNudity)
        try c.encodeIfPresent(horrorOrFearThemes, forKey: .horrorOrFearThemes)
        try c.encodeIfPresent(matureOrSuggestiveThemes, forKey: .matureOrSuggestiveThemes)
        try c.encodeIfPresent(violenceCartoonOrFantasy, forKey: .violenceCartoonOrFantasy)
        try c.encodeIfPresent(violenceRealisticProlongedGraphicOrSadistic, forKey: .violenceRealisticProlongedGraphicOrSadistic)
        try c.encodeIfPresent(violenceRealistic, forKey: .violenceRealistic)
        try c.encodeIfPresent(kidsAgeBand, forKey: .kidsAgeBand)
        try c.encodeIfPresent(ageRatingOverride, forKey: .ageRatingOverride)
        try c.encodeIfPresent(koreaAgeRatingOverride, forKey: .koreaAgeRatingOverride)
    }
}

extension AgeRatingDeclaration: AffordanceProviding {
    public var affordances: [String: String] {
        [
            "update": "asc age-rating update --declaration-id \(id)",
            "getAgeRating": "asc age-rating get --app-info-id \(appInfoId)",
        ]
    }
}

/// Partial update for age rating declaration — only set fields that should change.
public struct AgeRatingDeclarationUpdate: Sendable {
    public var isAdvertising: Bool?
    public var isGambling: Bool?
    public var isHealthOrWellnessTopics: Bool?
    public var isLootBox: Bool?
    public var isMessagingAndChat: Bool?
    public var isParentalControls: Bool?
    public var isAgeAssurance: Bool?
    public var isUnrestrictedWebAccess: Bool?
    public var isUserGeneratedContent: Bool?
    public var alcoholTobaccoOrDrugUseOrReferences: ContentIntensity?
    public var contests: ContentIntensity?
    public var gamblingSimulated: ContentIntensity?
    public var gunsOrOtherWeapons: ContentIntensity?
    public var medicalOrTreatmentInformation: ContentIntensity?
    public var profanityOrCrudeHumor: ContentIntensity?
    public var sexualContentGraphicAndNudity: ContentIntensity?
    public var sexualContentOrNudity: ContentIntensity?
    public var horrorOrFearThemes: ContentIntensity?
    public var matureOrSuggestiveThemes: ContentIntensity?
    public var violenceCartoonOrFantasy: ContentIntensity?
    public var violenceRealisticProlongedGraphicOrSadistic: ContentIntensity?
    public var violenceRealistic: ContentIntensity?
    public var kidsAgeBand: KidsAgeBand?
    public var ageRatingOverride: AgeRatingOverride?
    public var koreaAgeRatingOverride: KoreaAgeRatingOverride?

    public init() {}
}
