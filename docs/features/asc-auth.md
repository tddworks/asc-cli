# Auth Feature

Multi-account credential management for the `asc` CLI. Saves App Store Connect API key credentials to `~/.asc/credentials.json`, with support for multiple named accounts and seamless switching between them.

---

## CLI Usage

### `asc auth login`

Save API key credentials for a named account.

| Flag | Required | Description |
|------|----------|-------------|
| `--key-id` | Yes | App Store Connect API Key ID |
| `--issuer-id` | Yes | App Store Connect Issuer ID |
| `--name` | No | Account name (defaults to `"default"`); no spaces allowed |
| `--private-key-path` | One of two | Path to the `.p8` private key file (supports `~`) |
| `--private-key` | One of two | Raw PEM content of the private key |
| `--output` | No | Output format: `json` (default), `table`, `markdown` |
| `--pretty` | No | Pretty-print JSON output |

**Examples:**

```bash
# Login with a name (recommended for multi-account)
asc auth login --key-id KEYID123 --issuer-id abc-def-456 --private-key-path ~/.asc/AuthKey_KEYID123.p8 --name personal

# Login using a .p8 key file (name defaults to "default"; no spaces in name)
asc auth login --key-id KEYID123 --issuer-id abc-def-456 --private-key-path ~/.asc/AuthKey_KEYID123.p8

# Login using raw PEM content
asc auth login --key-id KEYID123 --issuer-id abc-def-456 --private-key "$(cat ~/.asc/AuthKey_KEYID123.p8)" --name work
```

**Output (JSON):**

```json
{
  "data": [
    {
      "affordances": {
        "check": "asc auth check",
        "list": "asc auth list",
        "login": "asc auth login --key-id <id> --issuer-id <id> --private-key-path <path>",
        "logout": "asc auth logout"
      },
      "issuerID": "abc-def-456",
      "keyID": "KEYID123",
      "name": "personal",
      "source": "file"
    }
  ]
}
```

---

### `asc auth list`

List all saved App Store Connect accounts.

| Flag | Required | Description |
|------|----------|-------------|
| `--output` | No | Output format: `json`, `table`, `markdown` |
| `--pretty` | No | Pretty-print JSON output |

**Example:**

```bash
asc auth list --pretty
```

**Output (JSON):**

```json
{
  "data": [
    {
      "affordances": {
        "logout": "asc auth logout --name personal",
        "use": "asc auth use personal"
      },
      "isActive": false,
      "issuerID": "abc-def-456",
      "keyID": "KEYID123",
      "name": "personal"
    },
    {
      "affordances": {
        "logout": "asc auth logout --name work"
      },
      "isActive": true,
      "issuerID": "xyz-ghi-789",
      "keyID": "WORKKEY456",
      "name": "work"
    }
  ]
}
```

---

### `asc auth use`

Switch the active account. The active account is used by all `asc` commands.

```bash
asc auth use work
# → Switched to account "work"
```

---

### `asc auth logout`

Remove a saved account. Removes the active account if `--name` is not specified.

| Flag | Required | Description |
|------|----------|-------------|
| `--name` | No | Account name to remove (defaults to active account) |

```bash
asc auth logout                 # remove active account
asc auth logout --name personal # remove a specific account
# → Logged out successfully
```

---

### `asc auth check`

Verify credentials and show the active account source (`file` or `environment`).

| Flag | Required | Description |
|------|----------|-------------|
| `--output` | No | Output format: `json`, `table`, `markdown` |
| `--pretty` | No | Pretty-print JSON output |

**Example:**

```bash
asc auth check --pretty
```

**Output (JSON, file account):**

```json
{
  "data": [
    {
      "affordances": {
        "check": "asc auth check",
        "list": "asc auth list",
        "login": "asc auth login --key-id <id> --issuer-id <id> --private-key-path <path>",
        "logout": "asc auth logout"
      },
      "issuerID": "abc-def-456",
      "keyID": "KEYID123",
      "name": "work",
      "source": "file"
    }
  ]
}
```

**Output (JSON, environment variables — no `name` field):**

```json
{
  "data": [
    {
      "affordances": { ... },
      "issuerID": "abc-def-456",
      "keyID": "KEYID123",
      "source": "environment"
    }
  ]
}
```

---

## REST Endpoints

The same operations are reachable over HTTP via `asc web-server` so a local web app (e.g. an Electron/SPA setup wizard) can drive auth without spawning the CLI.

| CLI | REST | Body |
|-----|------|------|
| `asc auth login` | `POST /api/v1/auth/accounts` | `{ "keyId": "...", "issuerId": "...", "privateKeyPEM": "...", "name"?: "...", "vendorNumber"?: "..." }` |
| `asc auth list` | `GET /api/v1/auth/accounts` | — |
| `asc auth check` | `GET /api/v1/auth/accounts/active` | — |
| `asc auth use NAME` | `PATCH /api/v1/auth/accounts/active` | `{ "name": "personal" }` |
| `asc auth update --vendor-number N` | `PATCH /api/v1/auth/accounts/:name` | `{ "vendorNumber": "12345678" }` |
| `asc auth logout` | `DELETE /api/v1/auth/accounts/active` | — |
| `asc auth logout --name X` | `DELETE /api/v1/auth/accounts/:name` | — |

**Example — login from a web client:**

```bash
curl -X POST http://localhost:5173/api/v1/auth/accounts \
  -H 'content-type: application/json' \
  -d '{
    "keyId": "KEYID123",
    "issuerId": "abc-def-456",
    "privateKeyPEM": "-----BEGIN PRIVATE KEY-----\nMIGTA...\n-----END PRIVATE KEY-----",
    "name": "personal"
  }'
```

Response: `200 OK` with the same `{ "data": [{ ...AuthStatus }] }` shape returned by `asc auth login`.

**Security:** these routes write the API key PEM to `~/.asc/credentials.json`. Bind `asc web-server` to loopback only (`127.0.0.1`) when the controller is enabled — never expose it on a routable interface.

---

## Credential Resolution Priority

`CompositeAuthProvider` tries credentials in this order:

1. **Active account in `~/.asc/credentials.json`** — managed by `asc auth login` / `asc auth use`
2. **Environment variables** — `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_PRIVATE_KEY_PATH` / `ASC_PRIVATE_KEY_B64` / `ASC_PRIVATE_KEY`

All `asc` commands transparently benefit from this priority without any changes.

---

## Credentials File Format

`~/.asc/credentials.json` stores multiple accounts and tracks which is active:

```json
{
  "accounts" : {
    "personal" : {
      "issuerID" : "abc-def-456",
      "keyID" : "KEYID123",
      "privateKeyPEM" : "-----BEGIN PRIVATE KEY-----\n..."
    },
    "work" : {
      "issuerID" : "xyz-ghi-789",
      "keyID" : "WORKKEY456",
      "privateKeyPEM" : "-----BEGIN PRIVATE KEY-----\n..."
    }
  },
  "active" : "work"
}
```

**Migration:** Old single-credential format (pre-multi-account) is automatically migrated to a `"default"` named account on first use.

---

## Typical Workflow

```bash
# Add personal and work accounts
asc auth login \
  --key-id KEYID123 \
  --issuer-id abc-def-456 \
  --private-key-path ~/.asc/AuthKey_personal.p8 \
  --name personal

asc auth login \
  --key-id WORKKEY456 \
  --issuer-id xyz-ghi-789 \
  --private-key-path ~/.asc/AuthKey_work.p8 \
  --name work

# List all accounts
asc auth list --pretty

# Switch to work account
asc auth use work

# Verify active account
asc auth check --pretty

# Use any command — no env vars needed, uses active account
asc apps list --pretty

# Remove a specific account
asc auth logout --name personal

# Remove the active account
asc auth logout
```

---

## Architecture

```
ASCCommand
└── Commands/Auth/
    ├── AuthCommand.swift      [auth parent + AuthCheck subcommand]
    ├── AuthLogin.swift        [asc auth login — saves to FileAuthStorage, sets active]
    ├── AuthLogout.swift       [asc auth logout [--name] — deletes from FileAuthStorage]
    ├── AuthList.swift         [asc auth list — enumerates all ConnectAccounts]
    └── AuthUse.swift          [asc auth use <name> — switches active account]
         ↓
Infrastructure/Auth/
├── FileAuthStorage.swift      [reads/writes ~/.asc/credentials.json (multi-account format)]
├── FileAuthProvider.swift     [AuthProvider backed by FileAuthStorage active account]
└── CompositeAuthProvider.swift [file-first, then EnvironmentAuthProvider]
         ↓
Domain/Auth/
├── AuthStorage.swift          [@Mockable protocol: save/load/loadAll/delete/setActive]
├── ConnectAccount.swift       [struct: name, keyID, issuerID, isActive + AffordanceProviding]
├── AuthStatus.swift           [struct: name?, keyID, issuerID, source + AffordanceProviding]
├── CredentialSource.swift     [enum: .file / .environment]
├── AuthCredentials.swift      [Sendable + Equatable + Codable]
├── AuthProvider.swift         [@Mockable protocol: resolve()]
└── AuthError.swift            [enum: missingKeyID/IssuerID/PrivateKey/accountNotFound]
```

---

## Domain Models

### `ConnectAccount`

Represents a saved App Store Connect account entry (for listing).

```swift
public struct ConnectAccount: Sendable, Equatable, Identifiable, Codable {
    public let name: String       // account alias (e.g. "work", "personal")
    public let keyID: String
    public let issuerID: String
    public let isActive: Bool     // true = currently active account
}
```

**Affordances:**

| Key | Command | Condition |
|-----|---------|-----------|
| `logout` | `asc auth logout --name <name>` | always |
| `use` | `asc auth use <name>` | only when `!isActive` |

### `AuthStatus`

Active credential status (output of `auth check` and `auth login`).

```swift
public struct AuthStatus: Sendable, Equatable, Identifiable, Codable {
    public let name: String?          // nil for environment credentials
    public let keyID: String
    public let issuerID: String
    public let source: CredentialSource
    public var id: String { name ?? keyID }
}
```

`name` is omitted from JSON when nil (custom `encodeIfPresent` Codable).

**Affordances:** `check`, `list`, `login`, `logout`

### `AuthStorage` (protocol)

```swift
@Mockable
public protocol AuthStorage: Sendable {
    func save(_ credentials: AuthCredentials, name: String) throws
    func load(name: String?) throws -> AuthCredentials?   // nil = active
    func loadAll() throws -> [ConnectAccount]
    func delete(name: String?) throws                     // nil = active
    func setActive(name: String) throws
}
```

---

## File Map

**Sources:**

```
Sources/
├── Domain/Auth/
│   ├── AuthStorage.swift          [@Mockable — 5-method multi-account protocol]
│   ├── ConnectAccount.swift       [new — name/keyID/issuerID/isActive + affordances]
│   ├── AuthStatus.swift           [name? field, custom Codable, list affordance]
│   ├── CredentialSource.swift     [.file / .environment]
│   └── AuthError.swift            [+ accountNotFound(String)]
├── Infrastructure/Auth/
│   ├── FileAuthStorage.swift      [multi-account JSON, auto-migration from legacy]
│   ├── FileAuthProvider.swift     [calls load(name: nil) for active account]
│   └── CompositeAuthProvider.swift [file-first composite]
└── ASCCommand/Commands/Auth/
    ├── AuthCommand.swift           [registers check + login + logout + list + use]
    ├── AuthLogin.swift             [--name option, calls save + setActive]
    ├── AuthLogout.swift            [--name option, calls delete(name:)]
    ├── AuthList.swift              [new — lists all ConnectAccounts]
    └── AuthUse.swift               [new — calls setActive(name:)]
```

**Tests:**

```
Tests/
├── DomainTests/Auth/
│   ├── ConnectAccountTests.swift             [new — affordances, id, encoding]
│   └── AuthStatusTests.swift                 [updated — name field, list affordance]
├── InfrastructureTests/Auth/
│   ├── FileAuthStorageTests.swift            [updated — new API]
│   └── FileAuthStorageMultiAccountTests.swift [new — multi-account scenarios + migration]
└── ASCCommandTests/Commands/Auth/
    ├── AuthLoginTests.swift                  [updated — name param, setActive mock]
    ├── AuthLogoutTests.swift                 [updated — name param]
    ├── AuthCheckTests.swift                  [updated — storage param, account name]
    ├── AuthListTests.swift                   [new]
    └── AuthUseTests.swift                    [new]
```

---

## Testing

```swift
@Test func `set active switches which account is returned by load nil`() throws {
    let storage = FileAuthStorage(fileURL: makeTempFileURL())
    try storage.save(credentials1, name: "personal")
    try storage.save(credentials2, name: "work")
    try storage.setActive(name: "work")

    let active = try storage.load(name: nil)
    #expect(active == credentials2)
}
```

Run auth tests:

```bash
swift test --filter 'Auth'
# Test run with 48 tests in 11 suites passed
```
