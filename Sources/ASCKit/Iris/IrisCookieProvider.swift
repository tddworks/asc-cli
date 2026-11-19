import Mockable

/// Resolves an iris session from browser cookies or environment.
@Mockable
public protocol IrisCookieProvider: Sendable {
    func resolveSession() throws -> IrisSession
    func resolveStatus() throws -> IrisStatus
}
