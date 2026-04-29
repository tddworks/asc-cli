import Foundation

/// Apple ID + password used to drive an iris SRP login.
///
/// Held only as long as the SRP handshake plus any pending 2FA verification needs them;
/// not persisted (the persisted artifact is `IrisAuthSession`, which contains cookies
/// only — never the password).
public struct IrisAuthCredentials: Sendable, Equatable, Codable {
    public let appleId: String
    public let password: String

    public init(appleId: String, password: String) {
        self.appleId = appleId
        self.password = password
    }
}
