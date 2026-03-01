/// Parameters for creating or updating an App Store review detail record.
/// All fields are optional — only supplied values are sent to the API.
public struct ReviewDetailUpdate: Sendable, Equatable {
    public let contactFirstName: String?
    public let contactLastName: String?
    public let contactPhone: String?
    public let contactEmail: String?
    public let demoAccountRequired: Bool?
    public let demoAccountName: String?
    public let demoAccountPassword: String?
    public let notes: String?

    public init(
        contactFirstName: String? = nil,
        contactLastName: String? = nil,
        contactPhone: String? = nil,
        contactEmail: String? = nil,
        demoAccountRequired: Bool? = nil,
        demoAccountName: String? = nil,
        demoAccountPassword: String? = nil,
        notes: String? = nil
    ) {
        self.contactFirstName = contactFirstName
        self.contactLastName = contactLastName
        self.contactPhone = contactPhone
        self.contactEmail = contactEmail
        self.demoAccountRequired = demoAccountRequired
        self.demoAccountName = demoAccountName
        self.demoAccountPassword = demoAccountPassword
        self.notes = notes
    }
}
