/// Cookie-based session for the iris private API.
///
/// Unlike JWT-based `AuthCredentials`, iris authentication uses browser
/// cookies (myacinfo, itctx, dqsid, etc.) extracted from the user's
/// browser or provided via environment variable.
public struct IrisSession: Sendable, Equatable {
    public let cookies: String

    public init(cookies: String) {
        self.cookies = cookies
    }
}
