/// A kind of data an app may collect (Apple's `appDataUsageCategories` id, e.g. `EMAIL_ADDRESS`).
/// One Apple sends that asc doesn't know is kept as sent; asc never sends one (law 6).
public struct DataCategory: RawRepresentable, Hashable, Sendable, Codable {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }

    public var isRecognized: Bool { Self.known.contains(rawValue) }

    /// The categories on the App Privacy page, by grouping.
    static let known: Set<String> = [
        "NAME", "EMAIL_ADDRESS", "PHONE_NUMBER", "PHYSICAL_ADDRESS", "OTHER_CONTACT_INFO",
        "HEALTH", "FITNESS",
        "PAYMENT_INFORMATION", "CREDIT_AND_FRAUD", "OTHER_FINANCIAL_INFO",
        "PRECISE_LOCATION", "COARSE_LOCATION",
        "SENSITIVE_INFO",
        "CONTACTS",
        "EMAILS_OR_TEXT_MESSAGES", "PHOTOS_OR_VIDEOS", "AUDIO", "GAMEPLAY_CONTENT", "CUSTOMER_SUPPORT", "OTHER_USER_CONTENT",
        "BROWSING_HISTORY",
        "SEARCH_HISTORY",
        "USER_ID", "DEVICE_ID",
        "PURCHASE_HISTORY",
        "PRODUCT_INTERACTION", "ADVERTISING_DATA", "OTHER_USAGE_DATA",
        "CRASH_DATA", "PERFORMANCE_DATA", "OTHER_DIAGNOSTIC_DATA",
        "OTHER_DATA_TYPES",
    ]
}

/// Why collected data is used (Apple's `appDataUsagePurposes` id, e.g. `ANALYTICS`).
public struct DataPurpose: RawRepresentable, Hashable, Sendable, Codable {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }

    public var isRecognized: Bool { Self.known.contains(rawValue) }

    static let known: Set<String> = [
        "APP_FUNCTIONALITY", "ANALYTICS", "PRODUCT_PERSONALIZATION",
        "DEVELOPERS_ADVERTISING", "THIRD_PARTY_ADVERTISING", "OTHER_PURPOSES",
    ]
}

/// How a row's data is handled (Apple's `appDataUsageDataProtections` id).
public struct DataProtection: RawRepresentable, Hashable, Sendable, Codable {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }

    /// The whole label: the app collects nothing (law 2).
    public static let notCollected = DataProtection(rawValue: "DATA_NOT_COLLECTED")
    public static let linkedToYou = DataProtection(rawValue: "DATA_LINKED_TO_YOU")
    public static let notLinkedToYou = DataProtection(rawValue: "DATA_NOT_LINKED_TO_YOU")
    /// A tracking row has no purpose.
    public static let usedToTrackYou = DataProtection(rawValue: "DATA_USED_TO_TRACK_YOU")
}

/// One row as Apple stores it: a category, a purpose and a protection (law 1). asc changes
/// a label row by row, but shows and takes it as `CollectedData`.
public struct DataUsageEntry: Hashable, Sendable, Codable {
    public let category: DataCategory?
    public let purpose: DataPurpose?
    public let protection: DataProtection

    public init(category: DataCategory?, purpose: DataPurpose?, protection: DataProtection) {
        self.category = category
        self.purpose = purpose
        self.protection = protection
    }
}

/// A row Apple holds for an app (`appDataUsages`), with the id a change deletes it by.
public struct DataUsage: Sendable, Equatable, Identifiable, Codable {
    public let id: String
    /// Parent: injected by the adapter from the request.
    public let appId: String
    public let category: DataCategory?
    public let purpose: DataPurpose?
    public let protection: DataProtection

    public init(id: String, appId: String, category: DataCategory?, purpose: DataPurpose?, protection: DataProtection) {
        self.id = id
        self.appId = appId
        self.category = category
        self.purpose = purpose
        self.protection = protection
    }

    public var entry: DataUsageEntry { DataUsageEntry(category: category, purpose: purpose, protection: protection) }
}
