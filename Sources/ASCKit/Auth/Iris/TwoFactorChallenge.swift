import Foundation

/// The 2FA challenge Apple presents after a successful SRP `complete` returns 409.
///
/// `maskedDestination` is whatever Apple gives us — for trusted-device push that's
/// usually the literal string "Trusted devices"; for SMS it's the masked phone
/// number Apple has on file. We don't unmask or normalize.
public struct TwoFactorChallenge: Sendable, Equatable, Codable {
    public enum Method: String, Sendable, Equatable, Codable {
        case trustedDevice = "TRUSTED_DEVICE"
        case phone = "PHONE"
    }

    public let method: Method
    public let maskedDestination: String
    public let codeLength: Int

    public init(method: Method, maskedDestination: String, codeLength: Int) {
        self.method = method
        self.maskedDestination = maskedDestination
        self.codeLength = codeLength
    }
}
