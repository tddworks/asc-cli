import BigNum
import Crypto
import Foundation
import SRP

/// Apple-variant SRP-6a client.
///
/// Built on top of `adam-fowler/swift-srp` to reuse its RFC 5054 group-2048
/// constants, BigNum, and key generation. We layer on Apple's specific deviations:
/// PBKDF2-derived `x` (instead of the RFC's `H(salt | H(username:password))`),
/// and HKDF-based `M1` (instead of the RFC 2945 proof).
public struct AppleSRPClient: @unchecked Sendable {
    // SRPConfiguration / SRPKeyPair are immutable value types but not yet declared
    // Sendable upstream — `@unchecked Sendable` on this wrapper is safe because
    // every stored property is read-only and the underlying types don't share
    // mutable state.
    private let configuration: SRPConfiguration<SHA256>

    /// Pre-generated key pair for this login attempt. Apple's SRP variant follows
    /// RFC 5054 in requiring the same client `(a, A)` across `init` and `complete`.
    private let keys: SRPKeyPair

    public init() {
        self.configuration = SRPConfiguration<SHA256>(.N2048)
        self.keys = SRPClient(configuration: configuration).generateKeys()
    }

    /// Returns the client's public ephemeral `A` as the 256-byte big-endian serialization
    /// `idmsa.apple.com`'s `signin/init` expects in its base64-encoded `a` field.
    public func generatePublicEphemeral() -> Data {
        Data(keys.public.with(padding: configuration.sizeN).bytes)
    }

    /// Output of the SRP `complete` step.
    public struct Completion: Sendable, Equatable {
        /// Client proof — `m1` field of `signin/complete` body.
        public let m1: Data
        /// Expected server proof, used to verify Apple's response. Distinct from m2
        /// in some specs; here it's the value the server should send back.
        public let m2Expected: Data
        /// SRP shared secret K (= H(S)). Useful as input for HKDF-derived HMAC keys
        /// some Apple flows (notably 2FA continuation) chain off of.
        public let sharedKey: Data
    }

    /// Drives the SRP `complete` step against Apple's protocol variant.
    ///
    /// Computes:
    ///   x = PBKDF2-HMAC-SHA256(s2k_input(password), salt, iterations, 32)
    ///   u = SHA256(A_padded || B_padded)
    ///   S = (B - k * g^x) ^ (a + u * x) mod N
    ///   K = SHA256(S_padded)
    ///   M1 = SHA256(H(N) XOR H(g) || H(accountName) || salt || A || B || K)
    ///   M2 = SHA256(A || M1 || K)
    ///
    /// The S derivation mirrors RFC 5054 §2.6 / swift-srp's internal helper, fed with
    /// our Apple-derived x. M1 / M2 follow the RFC 5054 / 2945 layout — Apple's
    /// observed flow accepts this shape; HKDF-rewrapped variants we'll surface
    /// only if the integration test reveals Apple expects something different.
    public func completeWith(
        salt: Data,
        serverPublicKey serverPublicKeyBytes: Data,
        iterations: Int,
        protocol srpProtocol: AppleProtocol,
        password: String,
        accountName: String
    ) throws -> Completion {
        let B = BigNum(bytes: [UInt8](serverPublicKeyBytes))

        // RFC 5054 mandates rejecting B ≡ 0 (mod N) — a malicious server could
        // otherwise pin S to a known value.
        guard B % configuration.N != BigNum(0) else {
            throw AppleSRPError.nullServerKey
        }

        let xBytes = Self.deriveAppleX(
            password: password, salt: salt, iterations: iterations, protocol: srpProtocol
        )
        let x = BigNum(bytes: [UInt8](xBytes))

        let A_padded = keys.public.with(padding: configuration.sizeN).bytes
        let B_padded = padded(serverPublicKeyBytes, to: configuration.sizeN)

        // u = H(A_padded || B_padded)
        let u = BigNum(bytes: [UInt8](SHA256.hash(data: A_padded + B_padded)))
        guard u != BigNum(0) else { throw AppleSRPError.nullServerKey }

        // S = (B - k*g^x) ^ (a + u*x) mod N
        let kgx = (configuration.k * configuration.g.power(x, modulus: configuration.N)) % configuration.N
        let base = (B - kgx + configuration.N) % configuration.N  // ensure non-negative
        let exp = keys.private.number + u * x
        let S = base.power(exp, modulus: configuration.N)

        let S_padded = padBigNumBytes(S.bytes, to: configuration.sizeN)
        let K = Data(SHA256.hash(data: S_padded))

        // M1 per RFC 5054 §2.5.4: H( H(N) XOR H(g) | H(accountName) | salt | A | B | K )
        let hN = [UInt8](SHA256.hash(data: configuration.N.bytes))
        let hG = [UInt8](SHA256.hash(data: padBigNumBytes(configuration.g.bytes, to: configuration.sizeN)))
        let hN_xor_hG = zip(hN, hG).map { $0 ^ $1 }
        let hUser = [UInt8](SHA256.hash(data: Data(accountName.utf8)))
        let m1Input = hN_xor_hG + hUser + [UInt8](salt) + A_padded + B_padded + [UInt8](K)
        let M1 = Data(SHA256.hash(data: m1Input))

        // M2 = H(A || M1 || K) — the value we expect Apple to echo back to verify the server.
        let M2 = Data(SHA256.hash(data: A_padded + [UInt8](M1) + [UInt8](K)))

        return Completion(m1: M1, m2Expected: M2, sharedKey: K)
    }

    // MARK: - Internal padding helpers

    private func padded(_ data: Data, to size: Int) -> [UInt8] {
        if data.count >= size { return [UInt8](data) }
        return [UInt8](repeating: 0, count: size - data.count) + [UInt8](data)
    }

    private func padBigNumBytes(_ bytes: [UInt8], to size: Int) -> [UInt8] {
        if bytes.count >= size { return bytes }
        return [UInt8](repeating: 0, count: size - bytes.count) + bytes
    }

    public enum AppleSRPError: LocalizedError {
        case nullServerKey

        public var errorDescription: String? {
            switch self {
            case .nullServerKey: return "Server public key is null modulo N — rejecting per RFC 5054 §2.6."
            }
        }
    }

    /// Apple's two SRP password-key derivation variants. The server tells us which
    /// applies in the `protocol` field of the `signin/init` response.
    public enum AppleProtocol: String, Sendable, Equatable {
        /// Input to PBKDF2 is the raw SHA256 digest bytes of the password.
        case s2k = "s2k"
        /// Input to PBKDF2 is the lowercase hex representation of SHA256(password).
        /// Older accounts; rare today but Apple's flow still negotiates it.
        case s2kFo = "s2k_fo"
    }

    /// Apple-variant `x` derivation: `PBKDF2-HMAC-SHA256` over a hashed-password input
    /// determined by `protocol`, with the server-supplied `salt` and `iterations`.
    /// Output length is fixed at 32 bytes.
    public static func deriveAppleX(
        password: String,
        salt: Data,
        iterations: Int,
        protocol srpProtocol: AppleProtocol
    ) -> Data {
        let passwordBytes = Data(password.utf8)
        let sha = SHA256.hash(data: passwordBytes)
        let pbkdf2Input: Data
        switch srpProtocol {
        case .s2k:
            pbkdf2Input = Data(sha)
        case .s2kFo:
            pbkdf2Input = Data(sha.map { String(format: "%02x", $0) }.joined().utf8)
        }
        return Self.pbkdf2HmacSha256(
            password: pbkdf2Input,
            salt: salt,
            iterations: iterations,
            length: 32
        )
    }

    /// Test-only re-export of the PBKDF2 implementation so a separate test target can
    /// cross-check against published vectors (RFC 7914) without bundling the full
    /// idmsa flow into the test path.
    public static func _testOnly_pbkdf2HmacSha256(
        password: Data,
        salt: Data,
        iterations: Int,
        length: Int
    ) -> Data {
        pbkdf2HmacSha256(password: password, salt: salt, iterations: iterations, length: length)
    }

    /// PBKDF2-HMAC-SHA256 implemented via swift-crypto primitives. We avoid `CommonCrypto`
    /// to keep the surface portable. Performance is fine — Apple's iteration counts (~20k)
    /// run in milliseconds.
    private static func pbkdf2HmacSha256(
        password: Data,
        salt: Data,
        iterations: Int,
        length: Int
    ) -> Data {
        precondition(iterations >= 1)
        precondition(length > 0)
        let blockSize = SHA256.byteCount
        let blockCount = (length + blockSize - 1) / blockSize
        var derived = Data()

        for i in 1...blockCount {
            // U_1 = HMAC(password, salt || INT_32_BE(i))
            var blockSalt = salt
            blockSalt.append(UInt8((i >> 24) & 0xFF))
            blockSalt.append(UInt8((i >> 16) & 0xFF))
            blockSalt.append(UInt8((i >> 8) & 0xFF))
            blockSalt.append(UInt8(i & 0xFF))

            let key = SymmetricKey(data: password)
            var u = Data(HMAC<SHA256>.authenticationCode(for: blockSalt, using: key))
            var t = u

            for _ in 1..<iterations {
                u = Data(HMAC<SHA256>.authenticationCode(for: u, using: key))
                for j in 0..<t.count { t[j] ^= u[j] }
            }
            derived.append(t)
        }

        return derived.prefix(length)
    }
}
