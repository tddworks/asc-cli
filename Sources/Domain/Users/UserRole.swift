/// A role that can be assigned to a team member or user invitation.
public enum UserRole: String, Sendable, Equatable, Codable, CaseIterable {
    case admin = "ADMIN"
    case finance = "FINANCE"
    case accountHolder = "ACCOUNT_HOLDER"
    case sales = "SALES"
    case marketing = "MARKETING"
    case appManager = "APP_MANAGER"
    case developer = "DEVELOPER"
    case accessToReports = "ACCESS_TO_REPORTS"
    case customerSupport = "CUSTOMER_SUPPORT"
    case createApps = "CREATE_APPS"
    case cloudManagedDeveloperID = "CLOUD_MANAGED_DEVELOPER_ID"
    case cloudManagedAppDistribution = "CLOUD_MANAGED_APP_DISTRIBUTION"
    case generateIndividualKeys = "GENERATE_INDIVIDUAL_KEYS"

    public var displayName: String {
        switch self {
        case .admin: return "Admin"
        case .finance: return "Finance"
        case .accountHolder: return "Account Holder"
        case .sales: return "Sales"
        case .marketing: return "Marketing"
        case .appManager: return "App Manager"
        case .developer: return "Developer"
        case .accessToReports: return "Access to Reports"
        case .customerSupport: return "Customer Support"
        case .createApps: return "Create Apps"
        case .cloudManagedDeveloperID: return "Cloud Managed Developer ID"
        case .cloudManagedAppDistribution: return "Cloud Managed App Distribution"
        case .generateIndividualKeys: return "Generate Individual Keys"
        }
    }

    /// Accepts the raw uppercase value (e.g. "ADMIN") or lowercase (e.g. "admin").
    public init?(cliArgument: String) {
        if let match = UserRole(rawValue: cliArgument.uppercased()) {
            self = match
        } else {
            return nil
        }
    }
}
