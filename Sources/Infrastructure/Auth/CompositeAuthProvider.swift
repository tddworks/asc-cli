import Domain

public struct CompositeAuthProvider: AuthProvider {
    private let fileProvider: any AuthProvider
    private let environmentProvider: any AuthProvider

    public init(
        fileProvider: any AuthProvider = FileAuthProvider(),
        environmentProvider: any AuthProvider = EnvironmentAuthProvider()
    ) {
        self.fileProvider = fileProvider
        self.environmentProvider = environmentProvider
    }

    public func resolve() throws -> AuthCredentials {
        if let credentials = try? fileProvider.resolve() {
            return credentials
        }
        return try environmentProvider.resolve()
    }
}
