public struct AppTerritoryAvailability: Sendable, Equatable, Identifiable, Codable {
    public let id: String
    public let territoryId: String
    public let isAvailable: Bool
    public let releaseDate: String?
    public let isPreOrderEnabled: Bool
    public let contentStatuses: [ContentStatus]

    public init(
        id: String,
        territoryId: String,
        isAvailable: Bool,
        releaseDate: String?,
        isPreOrderEnabled: Bool,
        contentStatuses: [ContentStatus]
    ) {
        self.id = id
        self.territoryId = territoryId
        self.isAvailable = isAvailable
        self.releaseDate = releaseDate
        self.isPreOrderEnabled = isPreOrderEnabled
        self.contentStatuses = contentStatuses
    }

    enum CodingKeys: String, CodingKey {
        case id, territoryId, isAvailable, releaseDate, isPreOrderEnabled, contentStatuses
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        territoryId = try c.decode(String.self, forKey: .territoryId)
        isAvailable = try c.decode(Bool.self, forKey: .isAvailable)
        releaseDate = try c.decodeIfPresent(String.self, forKey: .releaseDate)
        isPreOrderEnabled = try c.decode(Bool.self, forKey: .isPreOrderEnabled)
        contentStatuses = try c.decode([ContentStatus].self, forKey: .contentStatuses)
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(territoryId, forKey: .territoryId)
        try c.encode(isAvailable, forKey: .isAvailable)
        try c.encodeIfPresent(releaseDate, forKey: .releaseDate)
        try c.encode(isPreOrderEnabled, forKey: .isPreOrderEnabled)
        try c.encode(contentStatuses, forKey: .contentStatuses)
    }
}

public enum ContentStatus: String, Sendable, Codable, Equatable {
    case available = "AVAILABLE"
    case availableForPreorderOnDate = "AVAILABLE_FOR_PREORDER_ON_DATE"
    case availableForPreorder = "AVAILABLE_FOR_PREORDER"
    case availableForSaleUnreleasedApp = "AVAILABLE_FOR_SALE_UNRELEASED_APP"
    case preorderOnUnreleasedApp = "PREORDER_ON_UNRELEASED_APP"
    case processingToNotAvailable = "PROCESSING_TO_NOT_AVAILABLE"
    case processingToAvailable = "PROCESSING_TO_AVAILABLE"
    case processingToPreOrder = "PROCESSING_TO_PRE_ORDER"
    case missingRating = "MISSING_RATING"
    case missingGrn = "MISSING_GRN"
    case unverifiedGrn = "UNVERIFIED_GRN"
    case cannotSell = "CANNOT_SELL"
    case cannotSellRestrictedRating = "CANNOT_SELL_RESTRICTED_RATING"
    case cannotSellSeventeenPlusApps = "CANNOT_SELL_SEVENTEEN_PLUS_APPS"
    case cannotSellSexuallyExplicit = "CANNOT_SELL_SEXUALLY_EXPLICIT"
    case cannotSellNonIosGames = "CANNOT_SELL_NON_IOS_GAMES"
    case cannotSellCasino = "CANNOT_SELL_CASINO"
    case cannotSellCasinoWithoutGrac = "CANNOT_SELL_CASINO_WITHOUT_GRAC"
    case cannotSellCasinoWithoutAgeVerification = "CANNOT_SELL_CASINO_WITHOUT_AGE_VERIFICATION"
    case cannotSellGambling = "CANNOT_SELL_GAMBLING"
    case cannotSellGamblingContests = "CANNOT_SELL_GAMBLING_CONTESTS"
    case cannotSellContests = "CANNOT_SELL_CONTESTS"
    case cannotSellAdultOnly = "CANNOT_SELL_ADULT_ONLY"
    case cannotSellFrequentIntenseGambling = "CANNOT_SELL_FREQUENT_INTENSE_GAMBLING"
    case cannotSellFrequentIntenseViolence = "CANNOT_SELL_FREQUENT_INTENSE_VIOLENCE"
    case cannotSellFrequentIntenseSexualContentNudity = "CANNOT_SELL_FREQUENT_INTENSE_SEXUAL_CONTENT_NUDITY"
    case cannotSellFrequentIntenseAlcoholTobaccoDrugs = "CANNOT_SELL_FREQUENT_INTENSE_ALCOHOL_TOBACCO_DRUGS"
    case brazilRequiredTaxID = "BRAZIL_REQUIRED_TAX_ID"
    case icpNumberInvalid = "ICP_NUMBER_INVALID"
    case icpNumberMissing = "ICP_NUMBER_MISSING"
    case traderStatusNotProvided = "TRADER_STATUS_NOT_PROVIDED"
    case traderStatusVerificationFailed = "TRADER_STATUS_VERIFICATION_FAILED"
    case traderStatusVerificationStatusMissing = "TRADER_STATUS_VERIFICATION_STATUS_MISSING"
}
