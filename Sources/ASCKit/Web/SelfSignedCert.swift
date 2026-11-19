import Foundation
import NIOSSL

/// Manages self-signed TLS certificates for HTTPS localhost.
///
/// Generates and stores certs at `~/.asc/server.key` + `~/.asc/server.crt`.
/// Optionally trusts the cert in macOS Keychain so browsers accept it.
///
/// Required for `asccli.app` (HTTPS) → `localhost` without mixed-content blocking.
enum SelfSignedCert {
    static let ascDir = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".asc")
    static let keyPath = ascDir.appendingPathComponent("server.key").path
    static let certPath = ascDir.appendingPathComponent("server.crt").path

    /// Returns TLSConfiguration if certs exist or can be generated, nil otherwise.
    static func tlsConfiguration() -> TLSConfiguration? {
        if !FileManager.default.fileExists(atPath: certPath) || !FileManager.default.fileExists(atPath: keyPath) {
            guard generate() else { return nil }
        }

        do {
            let cert = try NIOSSLCertificate(file: certPath, format: .pem)
            let key = try NIOSSLPrivateKey(file: keyPath, format: .pem)
            var config = TLSConfiguration.makeServerConfiguration(
                certificateChain: [.certificate(cert)],
                privateKey: .privateKey(key)
            )
            config.minimumTLSVersion = .tlsv12
            return config
        } catch {
            print("  TLS: failed to load certs: \(error)")
            return nil
        }
    }

    /// Generate self-signed cert via openssl CLI.
    private static func generate() -> Bool {
        do {
            try FileManager.default.createDirectory(at: ascDir, withIntermediateDirectories: true)
        } catch { return false }

        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/openssl")
        proc.arguments = [
            "req", "-x509", "-newkey", "rsa:2048",
            "-keyout", keyPath, "-out", certPath,
            "-days", "825", "-nodes",
            "-subj", "/CN=localhost",
            "-addext", "subjectAltName=DNS:localhost,IP:127.0.0.1",
        ]
        proc.standardOutput = Pipe()
        proc.standardError = Pipe()

        do {
            try proc.run()
            proc.waitUntilExit()
            guard proc.terminationStatus == 0 else { return false }
            print("  TLS: generated self-signed cert at ~/.asc/server.{key,crt}")
        } catch {
            return false
        }

        // Trust in macOS Keychain (best-effort)
        trustInKeychain()
        return true
    }

    /// Add cert to macOS login keychain so browsers accept it without warnings.
    private static func trustInKeychain() {
        let keychainPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Keychains/login.keychain-db").path

        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/security")
        proc.arguments = ["add-trusted-cert", "-p", "ssl", "-k", keychainPath, certPath]
        proc.standardOutput = Pipe()
        proc.standardError = Pipe()

        do {
            try proc.run()
            proc.waitUntilExit()
            if proc.terminationStatus == 0 {
                print("  TLS: cert trusted in macOS Keychain")
            } else {
                print("  TLS: could not auto-trust cert — visit https://localhost:8421 and accept manually")
            }
        } catch {
            print("  TLS: could not auto-trust cert")
        }
    }
}
