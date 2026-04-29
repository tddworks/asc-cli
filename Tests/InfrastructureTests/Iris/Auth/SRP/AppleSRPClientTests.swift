import Foundation
import Testing
@testable import Infrastructure

@Suite
struct AppleSRPClientTests {

    @Test func `apple srp client generates client public key A sized to N2048`() {
        // RFC 5054 group 2048 → 2048 bits → 256-byte big-endian serialization.
        // First test only exercises key generation; password / salt come later.
        let client = AppleSRPClient()
        let A = client.generatePublicEphemeral()
        #expect(A.count == 256)
    }

    @Test func `apple srp client generates A as non-zero value`() {
        // Catches a broken key generator silently producing zero bytes.
        let client = AppleSRPClient()
        let A = client.generatePublicEphemeral()
        #expect(A.contains { $0 != 0 })
    }

    @Test func `two clients produce different public keys A`() {
        // Each login attempt must use fresh ephemeral keys per RFC 5054. If A
        // were deterministic, a server replay would compromise the protocol.
        let A1 = AppleSRPClient().generatePublicEphemeral()
        let A2 = AppleSRPClient().generatePublicEphemeral()
        #expect(A1 != A2)
    }

    // MARK: - Apple x derivation (PBKDF2-HMAC-SHA256 over SHA256(password))

    @Test func `apple x derivation returns 32 bytes`() {
        // Apple's SRP variant uses PBKDF2 to derive a 32-byte password key,
        // distinct from the RFC 5054 default of H(salt | H(username:password)).
        let salt = Data(repeating: 0xAB, count: 16)
        let x = AppleSRPClient.deriveAppleX(
            password: "test", salt: salt, iterations: 1000, protocol: .s2k
        )
        #expect(x.count == 32)
    }

    @Test func `apple x derivation is deterministic for same inputs`() {
        let salt = Data(repeating: 0xAB, count: 16)
        let x1 = AppleSRPClient.deriveAppleX(password: "p", salt: salt, iterations: 1000, protocol: .s2k)
        let x2 = AppleSRPClient.deriveAppleX(password: "p", salt: salt, iterations: 1000, protocol: .s2k)
        #expect(x1 == x2)
    }

    @Test func `apple x derivation differs between s2k and s2kFo protocols`() {
        // Apple's `signin/init` response can specify either "s2k" (input is SHA256
        // of password bytes) or "s2k_fo" (input is the lowercase hex string of
        // SHA256(password)). Different inputs to PBKDF2 must produce different x.
        let salt = Data(repeating: 0xAB, count: 16)
        let xS2k = AppleSRPClient.deriveAppleX(password: "p", salt: salt, iterations: 1000, protocol: .s2k)
        let xS2kFo = AppleSRPClient.deriveAppleX(password: "p", salt: salt, iterations: 1000, protocol: .s2kFo)
        #expect(xS2k != xS2kFo)
    }

    @Test func `apple x derivation differs between passwords`() {
        let salt = Data(repeating: 0xAB, count: 16)
        let x1 = AppleSRPClient.deriveAppleX(password: "p1", salt: salt, iterations: 1000, protocol: .s2k)
        let x2 = AppleSRPClient.deriveAppleX(password: "p2", salt: salt, iterations: 1000, protocol: .s2k)
        #expect(x1 != x2)
    }

    // MARK: - PBKDF2-HMAC-SHA256 cross-check

    /// RFC 7914 §11 PBKDF2-HMAC-SHA256 test vector — independent oracle that catches a
    /// bug in our implementation before it costs us a real login attempt against Apple.
    /// password = "passwd", salt = "salt", iterations = 1, dkLen = 64.
    // MARK: - completeWith (S + M1 derivation)
    //
    // These tests verify shape and internal consistency. Apple-correctness can only
    // be verified by a real login attempt — the integration is in slice 6.

    @Test func `completeWith returns 32-byte M1 when given plausible inputs`() throws {
        let client = AppleSRPClient()
        let result = try client.completeWith(
            salt: Data(repeating: 0xAB, count: 16),
            serverPublicKey: Data(repeating: 0x42, count: 256),
            iterations: 1000,
            protocol: .s2k,
            password: "test",
            accountName: "user@example.com"
        )
        #expect(result.m1.count == 32)
    }

    @Test func `completeWith is deterministic for same client and inputs`() throws {
        // Same AppleSRPClient instance has fixed `a`, so identical inputs must
        // produce identical M1. This catches accidental nondeterminism in the
        // S → M1 chain (e.g. random padding, wrong byte order).
        let client = AppleSRPClient()
        let salt = Data(repeating: 0xAB, count: 16)
        let B = Data(repeating: 0x42, count: 256)
        let r1 = try client.completeWith(salt: salt, serverPublicKey: B, iterations: 1000, protocol: .s2k, password: "p", accountName: "u@x.com")
        let r2 = try client.completeWith(salt: salt, serverPublicKey: B, iterations: 1000, protocol: .s2k, password: "p", accountName: "u@x.com")
        #expect(r1.m1 == r2.m1)
        #expect(r1.m2Expected == r2.m2Expected)
    }

    @Test func `completeWith produces different M1 for different passwords`() throws {
        let client = AppleSRPClient()
        let salt = Data(repeating: 0xAB, count: 16)
        let B = Data(repeating: 0x42, count: 256)
        let r1 = try client.completeWith(salt: salt, serverPublicKey: B, iterations: 1000, protocol: .s2k, password: "p1", accountName: "u@x.com")
        let r2 = try client.completeWith(salt: salt, serverPublicKey: B, iterations: 1000, protocol: .s2k, password: "p2", accountName: "u@x.com")
        #expect(r1.m1 != r2.m1)
    }

    @Test func `completeWith throws when server public key is null`() throws {
        // RFC 5054 mandates rejection of B ≡ 0 (mod N) — a malicious server could
        // otherwise force the shared secret to a known value.
        let client = AppleSRPClient()
        #expect(throws: AppleSRPClient.AppleSRPError.self) {
            _ = try client.completeWith(
                salt: Data(repeating: 0xAB, count: 16),
                serverPublicKey: Data(count: 256),  // all zeros
                iterations: 1000, protocol: .s2k, password: "p", accountName: "u@x.com"
            )
        }
    }

    @Test func `pbkdf2 hmac sha256 matches RFC 7914 vector for passwd salt 1 iter 64 byte`() {
        let password = Data("passwd".utf8)
        let salt = Data("salt".utf8)
        let expectedHex =
            "55ac046e56e3089fec1691c22544b605" +
            "f94185216dde0465e68b9d57c20dacbc" +
            "49ca9cccf179b645991664b39d77ef31" +
            "7c71b845b1e30bd509112041d3a19783"
        let derived = AppleSRPClient._testOnly_pbkdf2HmacSha256(
            password: password, salt: salt, iterations: 1, length: 64
        )
        #expect(derived.map { String(format: "%02x", $0) }.joined() == expectedHex)
    }
}
