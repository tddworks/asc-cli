public struct VersionReadiness: Sendable, Equatable, Identifiable {
    public let id: String            // = versionId
    public let appId: String
    public let versionString: String
    public let state: AppStoreVersionState
    /// True when all MUST FIX checks pass — safe to call `asc versions submit`.
    public let isReadyToSubmit: Bool

    // MUST FIX
    public let stateCheck: ReadinessCheck
    public let buildCheck: BuildReadinessCheck
    public let pricingCheck: ReadinessCheck
    public let localizationCheck: LocalizationReadinessCheck
    public let ageRatingCheck: ReadinessCheck
    // SHOULD FIX
    public let reviewContactCheck: ReadinessCheck

    public init(
        id: String,
        appId: String,
        versionString: String,
        state: AppStoreVersionState,
        isReadyToSubmit: Bool,
        stateCheck: ReadinessCheck,
        buildCheck: BuildReadinessCheck,
        pricingCheck: ReadinessCheck,
        localizationCheck: LocalizationReadinessCheck,
        ageRatingCheck: ReadinessCheck,
        reviewContactCheck: ReadinessCheck
    ) {
        self.id = id
        self.appId = appId
        self.versionString = versionString
        self.state = state
        self.isReadyToSubmit = isReadyToSubmit
        self.stateCheck = stateCheck
        self.buildCheck = buildCheck
        self.pricingCheck = pricingCheck
        self.localizationCheck = localizationCheck
        self.ageRatingCheck = ageRatingCheck
        self.reviewContactCheck = reviewContactCheck
    }
}

// MARK: - Codable

extension VersionReadiness: Codable {
    enum CodingKeys: String, CodingKey {
        case id, appId, versionString, state, isReadyToSubmit
        case stateCheck, buildCheck, pricingCheck, localizationCheck, ageRatingCheck, reviewContactCheck
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        appId = try c.decode(String.self, forKey: .appId)
        versionString = try c.decode(String.self, forKey: .versionString)
        state = try c.decode(AppStoreVersionState.self, forKey: .state)
        isReadyToSubmit = try c.decode(Bool.self, forKey: .isReadyToSubmit)
        stateCheck = try c.decode(ReadinessCheck.self, forKey: .stateCheck)
        buildCheck = try c.decode(BuildReadinessCheck.self, forKey: .buildCheck)
        pricingCheck = try c.decode(ReadinessCheck.self, forKey: .pricingCheck)
        localizationCheck = try c.decode(LocalizationReadinessCheck.self, forKey: .localizationCheck)
        ageRatingCheck = try c.decode(ReadinessCheck.self, forKey: .ageRatingCheck)
        reviewContactCheck = try c.decode(ReadinessCheck.self, forKey: .reviewContactCheck)
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(appId, forKey: .appId)
        try c.encode(versionString, forKey: .versionString)
        try c.encode(state, forKey: .state)
        try c.encode(isReadyToSubmit, forKey: .isReadyToSubmit)
        try c.encode(stateCheck, forKey: .stateCheck)
        try c.encode(buildCheck, forKey: .buildCheck)
        try c.encode(pricingCheck, forKey: .pricingCheck)
        try c.encode(localizationCheck, forKey: .localizationCheck)
        try c.encode(ageRatingCheck, forKey: .ageRatingCheck)
        try c.encode(reviewContactCheck, forKey: .reviewContactCheck)
    }
}

// MARK: - AffordanceProviding

extension VersionReadiness: AffordanceProviding {
    public var affordances: [String: String] {
        var cmds: [String: String] = [
            "checkReadiness": "asc versions check-readiness --version-id \(id)",
            "listLocalizations": "asc version-localizations list --version-id \(id)",
        ]
        if isReadyToSubmit {
            cmds["submit"] = "asc versions submit --version-id \(id)"
        }
        return cmds
    }
}

// MARK: - Sub-types

public struct ReadinessCheck: Sendable, Equatable {
    public let pass: Bool
    /// Populated only when the check fails.
    public let message: String?

    public init(pass: Bool, message: String? = nil) {
        self.pass = pass
        self.message = message
    }

    public static func pass() -> ReadinessCheck { ReadinessCheck(pass: true) }
    public static func fail(_ message: String) -> ReadinessCheck { ReadinessCheck(pass: false, message: message) }
}

extension ReadinessCheck: Codable {
    enum CodingKeys: String, CodingKey { case pass, message }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        pass = try c.decode(Bool.self, forKey: .pass)
        message = try c.decodeIfPresent(String.self, forKey: .message)
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(pass, forKey: .pass)
        try c.encodeIfPresent(message, forKey: .message)
    }
}

public struct BuildReadinessCheck: Sendable, Equatable {
    public let linked: Bool
    public let valid: Bool
    public let notExpired: Bool
    /// Human-readable label, e.g. "1.2.0 (55)". Nil when no build is linked.
    public let buildVersion: String?

    public var pass: Bool { linked && valid && notExpired }

    public init(linked: Bool, valid: Bool, notExpired: Bool, buildVersion: String? = nil) {
        self.linked = linked
        self.valid = valid
        self.notExpired = notExpired
        self.buildVersion = buildVersion
    }
}

extension BuildReadinessCheck: Codable {
    enum CodingKeys: String, CodingKey { case linked, valid, notExpired, buildVersion, pass }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        linked = try c.decode(Bool.self, forKey: .linked)
        valid = try c.decode(Bool.self, forKey: .valid)
        notExpired = try c.decode(Bool.self, forKey: .notExpired)
        buildVersion = try c.decodeIfPresent(String.self, forKey: .buildVersion)
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(linked, forKey: .linked)
        try c.encode(valid, forKey: .valid)
        try c.encode(notExpired, forKey: .notExpired)
        try c.encodeIfPresent(buildVersion, forKey: .buildVersion)
        try c.encode(pass, forKey: .pass)
    }
}

/// Wraps per-locale readiness details. Pass is true when the primary locale passes.
public struct LocalizationReadinessCheck: Sendable, Equatable {
    public let localizations: [LocalizationReadiness]

    /// True when the primary locale has a description and at least one screenshot set.
    public var pass: Bool {
        localizations.first(where: { $0.isPrimary })?.pass ?? false
    }

    public init(localizations: [LocalizationReadiness]) {
        self.localizations = localizations
    }
}

extension LocalizationReadinessCheck: Codable {
    enum CodingKeys: String, CodingKey { case localizations, pass }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        localizations = try c.decode([LocalizationReadiness].self, forKey: .localizations)
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(localizations, forKey: .localizations)
        try c.encode(pass, forKey: .pass)
    }
}

public struct LocalizationReadiness: Sendable, Equatable {
    public let locale: String
    /// True when this is the app's default/primary locale (first returned by the API).
    public let isPrimary: Bool
    public let hasDescription: Bool
    public let hasKeywords: Bool
    public let hasSupportUrl: Bool
    public let hasWhatsNew: Bool
    public let screenshotSetCount: Int

    public var pass: Bool { hasDescription && screenshotSetCount > 0 }

    public init(
        locale: String,
        isPrimary: Bool,
        hasDescription: Bool,
        hasKeywords: Bool,
        hasSupportUrl: Bool,
        hasWhatsNew: Bool,
        screenshotSetCount: Int
    ) {
        self.locale = locale
        self.isPrimary = isPrimary
        self.hasDescription = hasDescription
        self.hasKeywords = hasKeywords
        self.hasSupportUrl = hasSupportUrl
        self.hasWhatsNew = hasWhatsNew
        self.screenshotSetCount = screenshotSetCount
    }
}

extension LocalizationReadiness: Codable {
    enum CodingKeys: String, CodingKey {
        case locale, isPrimary, hasDescription, hasKeywords, hasSupportUrl, hasWhatsNew, screenshotSetCount, pass
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        locale = try c.decode(String.self, forKey: .locale)
        isPrimary = try c.decode(Bool.self, forKey: .isPrimary)
        hasDescription = try c.decode(Bool.self, forKey: .hasDescription)
        hasKeywords = try c.decode(Bool.self, forKey: .hasKeywords)
        hasSupportUrl = try c.decode(Bool.self, forKey: .hasSupportUrl)
        hasWhatsNew = try c.decode(Bool.self, forKey: .hasWhatsNew)
        screenshotSetCount = try c.decode(Int.self, forKey: .screenshotSetCount)
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(locale, forKey: .locale)
        try c.encode(isPrimary, forKey: .isPrimary)
        try c.encode(hasDescription, forKey: .hasDescription)
        try c.encode(hasKeywords, forKey: .hasKeywords)
        try c.encode(hasSupportUrl, forKey: .hasSupportUrl)
        try c.encode(hasWhatsNew, forKey: .hasWhatsNew)
        try c.encode(screenshotSetCount, forKey: .screenshotSetCount)
        try c.encode(pass, forKey: .pass)
    }
}
