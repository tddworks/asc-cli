import Domain

public struct FileAuthProvider: AuthProvider {
    private let storage: any AuthStorage

    public init(storage: any AuthStorage = FileAuthStorage()) {
        self.storage = storage
    }

    public func resolve() throws -> AuthCredentials {
        guard let credentials = try storage.load(name: nil) else {
            throw AuthError.missingKeyID
        }
        try credentials.validate()
        return credentials
    }
}
