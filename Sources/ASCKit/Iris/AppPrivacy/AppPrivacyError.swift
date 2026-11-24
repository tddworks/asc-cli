import Foundation

public enum AppPrivacyError: Error, Equatable, Sendable, CustomStringConvertible, LocalizedError {
    /// Publishing a label with nothing declared (law 5).
    case nothingDeclared(appId: String)
    /// `collectedData` is empty: that is "Data Not Collected", said another way.
    case noDataTypes
    case noPurposes(category: String)
    case unknownCategory(String)
    case unknownPurpose(String)
    case duplicateCategory(String)

    public var description: String {
        switch self {
        case .nothingDeclared(let appId):
            "App \(appId) has no privacy answers to publish. Declare them first: `asc iris app-privacy declare --app-id \(appId) --not-collected` or `--file <privacy.json>`."
        case .noDataTypes:
            "collectedData lists no data types. If the app collects nothing, declare --not-collected."
        case .noPurposes(let category):
            "\(category) needs at least one purpose."
        case .unknownCategory(let category):
            "\(category) isn't a data type App Privacy knows (e.g. EMAIL_ADDRESS, CRASH_DATA, DEVICE_ID)."
        case .unknownPurpose(let purpose):
            "\(purpose) isn't a purpose App Privacy knows: APP_FUNCTIONALITY, ANALYTICS, PRODUCT_PERSONALIZATION, DEVELOPERS_ADVERTISING, THIRD_PARTY_ADVERTISING or OTHER_PURPOSES."
        case .duplicateCategory(let category):
            "\(category) is declared twice; list each data type once with all its purposes."
        }
    }

    public var errorDescription: String? { description }
}
