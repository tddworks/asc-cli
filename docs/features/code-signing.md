# Code Signing

Manage the four App Store Connect code signing resources: bundle identifiers, signing certificates, test devices, and provisioning profiles.

---

## CLI Usage

### `asc bundle-ids`

#### list

```
asc bundle-ids list [--platform <ios|macos|universal>] [--identifier <string>]
```

| Flag | Required | Description |
|------|----------|-------------|
| `--platform` | No | Filter by platform (`ios`, `macos`, `universal`) |
| `--identifier` | No | Filter by bundle identifier string (e.g. `com.example.app`) |

**Example:**
```bash
asc bundle-ids list --platform ios --pretty
```

**JSON output:**
```json
{
  "data": [
    {
      "affordances": {
        "delete": "asc bundle-ids delete --bundle-id-id B1",
        "listProfiles": "asc profiles list --bundle-id-id B1"
      },
      "id": "B1",
      "identifier": "com.example.app",
      "name": "My App",
      "platform": "IOS"
    }
  ]
}
```

#### create

```
asc bundle-ids create --name <name> --identifier <identifier> --platform <ios|macos|universal>
```

| Flag | Required | Description |
|------|----------|-------------|
| `--name` | Yes | Display name |
| `--identifier` | Yes | Bundle identifier string |
| `--platform` | Yes | `ios`, `macos`, or `universal` |

#### delete

```
asc bundle-ids delete --bundle-id-id <id>
```

| Flag | Required | Description |
|------|----------|-------------|
| `--bundle-id-id` | Yes | Bundle ID resource ID |

---

### `asc certificates`

#### list

```
asc certificates list [--type <type>] [--limit <n>] [--expired-only] [--before <iso8601>]
```

| Flag | Required | Description |
|------|----------|-------------|
| `--type` | No | Filter by type (e.g. `IOS_DISTRIBUTION`, `MAC_APP_STORE`) |
| `--limit` | No | Maximum number of certificates the server returns |
| `--expired-only` | No | Client-side filter; drops certificates whose `expirationDate` is in the future |
| `--before` | No | Client-side filter; keeps certificates whose `expirationDate` is strictly before this ISO8601 date (e.g. `2026-11-01T00:00:00Z`) |

#### create

```
asc certificates create --type <type> --csr-content <pem>
```

| Flag | Required | Description |
|------|----------|-------------|
| `--type` | Yes | Certificate type (e.g. `IOS_DISTRIBUTION`) |
| `--csr-content` | Yes | PEM-encoded Certificate Signing Request |

#### revoke

```
asc certificates revoke --certificate-id <id>
```

---

### `asc devices`

#### list

```
asc devices list [--platform <ios|macos>]
```

#### register

```
asc devices register --name <name> --udid <udid> --platform <ios|macos>
```

| Flag | Required | Description |
|------|----------|-------------|
| `--name` | Yes | Device name |
| `--udid` | Yes | Device UDID |
| `--platform` | Yes | `ios` or `macos` |

---

### `asc profiles`

#### list

```
asc profiles list [--bundle-id-id <id>] [--type <type>]
```

| Flag | Required | Description |
|------|----------|-------------|
| `--bundle-id-id` | No | Filter by bundle ID resource ID (server-side) |
| `--type` | No | Filter by profile type (e.g. `IOS_APP_STORE`) |

#### create

```
asc profiles create --name <name> --type <type> --bundle-id-id <id> \
  --certificate-ids <id1,id2> [--device-ids <id1,id2>]
```

| Flag | Required | Description |
|------|----------|-------------|
| `--name` | Yes | Profile name |
| `--type` | Yes | Profile type (e.g. `IOS_APP_STORE`) |
| `--bundle-id-id` | Yes | Bundle ID resource ID |
| `--certificate-ids` | Yes | Comma-separated certificate resource IDs (min 1) |
| `--device-ids` | No | Comma-separated device resource IDs (development profiles) |

#### delete

```
asc profiles delete --profile-id <id>
```

---

## Typical Workflow

End-to-end CI/CD code signing setup:

```bash
# 1. Register the bundle identifier
asc bundle-ids create \
  --name "My App" \
  --identifier "com.example.myapp" \
  --platform ios

# 2. Create a distribution certificate from a CSR
asc certificates create \
  --type IOS_DISTRIBUTION \
  --csr-content "$(cat MyApp.certSigningRequest)"

# 3. (Development only) Register test devices
asc devices register \
  --name "My iPhone" \
  --udid "00000000-0000-0000-0000-000000000001" \
  --platform ios

# 4. List resource IDs for the create profile step
asc bundle-ids list --identifier com.example.myapp
asc certificates list --type IOS_DISTRIBUTION

# 5. Create the provisioning profile
asc profiles create \
  --name "My App Store Profile" \
  --type IOS_APP_STORE \
  --bundle-id-id <bundle-id-id> \
  --certificate-ids <cert-id>

# 6. List profiles for verification
asc profiles list --bundle-id-id <bundle-id-id> --pretty
```

---

## Architecture

```
ASCCommand Layer
  asc bundle-ids    list | create | delete
  asc certificates  list | create | revoke
  asc devices       list | register
  asc profiles      list | create | delete
         │
Infrastructure Layer
  SDKBundleIDRepository     GET/POST/DELETE /v1/bundleIds
  SDKCertificateRepository  GET/POST/DELETE /v1/certificates
  SDKDeviceRepository       GET/POST        /v1/devices
  SDKProfileRepository      GET/POST/DELETE /v1/profiles
                            GET /v1/bundleIds/{id}/profiles (when bundleIdId filter provided)
         │
Domain Layer
  BundleID    BundleIDRepository
  Certificate CertificateRepository
  Device      DeviceRepository
  Profile     ProfileRepository
  BundleIDPlatform (shared enum: IOS | MAC_OS | UNIVERSAL | SERVICES)
```

**Dependency rule:** `ASCCommand → Infrastructure → Domain`

---

## Domain Models

### `BundleID`

| Field | Type | Notes |
|-------|------|-------|
| `id` | `String` | Resource ID |
| `name` | `String` | Display name |
| `identifier` | `String` | Bundle ID string, e.g. `com.example.app` |
| `platform` | `BundleIDPlatform` | IOS / MAC_OS / UNIVERSAL / SERVICES |
| `seedID` | `String?` | Omitted from JSON when nil |

**Affordances:** `listProfiles`, `delete`

### `Certificate`

| Field | Type | Notes |
|-------|------|-------|
| `id` | `String` | Resource ID |
| `name` | `String` | Certificate name |
| `certificateType` | `CertificateType` | e.g. `IOS_DISTRIBUTION` |
| `displayName` | `String?` | Omitted when nil |
| `serialNumber` | `String?` | Omitted when nil |
| `platform` | `BundleIDPlatform?` | Omitted when nil |
| `expirationDate` | `Date?` | Omitted when nil |
| `certificateContent` | `String?` | PEM content; omitted when nil |

**Computed:** `isExpired: Bool`

**Affordances:** `revoke`

### `Device`

| Field | Type | Notes |
|-------|------|-------|
| `id` | `String` | Resource ID |
| `name` | `String` | Device name |
| `udid` | `String` | Unique Device Identifier |
| `deviceClass` | `DeviceClass` | IPHONE / IPAD / MAC / APPLE_WATCH / etc. |
| `platform` | `BundleIDPlatform` | IOS or MAC_OS |
| `status` | `DeviceStatus` | ENABLED / DISABLED |
| `model` | `String?` | Omitted when nil |
| `addedDate` | `Date?` | Omitted when nil |

**Computed:** `isEnabled: Bool`

**Affordances:** `listDevices`

### `Profile`

| Field | Type | Notes |
|-------|------|-------|
| `id` | `String` | Resource ID |
| `name` | `String` | Profile name |
| `profileType` | `ProfileType` | e.g. `IOS_APP_STORE` |
| `profileState` | `ProfileState` | ACTIVE / INVALID |
| `bundleIdId` | `String` | **Parent ID** — injected from request or relationship |
| `expirationDate` | `Date?` | Omitted when nil |
| `uuid` | `String?` | Omitted when nil |
| `profileContent` | `String?` | Base64 `.mobileprovision`; omitted when nil |

**Computed:** `isActive: Bool`

**Affordances:** `delete`, `listProfiles`

---

## File Map

### Sources

```
Sources/
├── Domain/CodeSigning/
│   ├── BundleIDs/
│   │   ├── BundleID.swift          (model + BundleIDPlatform enum)
│   │   └── BundleIDRepository.swift
│   ├── Certificates/
│   │   ├── Certificate.swift       (model + CertificateType enum)
│   │   └── CertificateRepository.swift
│   ├── Devices/
│   │   ├── Device.swift            (model + DeviceClass + DeviceStatus enums)
│   │   └── DeviceRepository.swift
│   └── Profiles/
│       ├── Profile.swift           (model + ProfileType + ProfileState enums)
│       └── ProfileRepository.swift
├── Infrastructure/CodeSigning/
│   ├── SDKBundleIDRepository.swift
│   ├── SDKCertificateRepository.swift
│   ├── SDKDeviceRepository.swift
│   └── SDKProfileRepository.swift
└── ASCCommand/Commands/
    ├── BundleIDs/
    │   ├── BundleIDsCommand.swift
    │   ├── BundleIDsList.swift
    │   ├── BundleIDsCreate.swift
    │   └── BundleIDsDelete.swift
    ├── Certificates/
    │   ├── CertificatesCommand.swift
    │   ├── CertificatesList.swift
    │   ├── CertificatesCreate.swift
    │   └── CertificatesRevoke.swift
    ├── Devices/
    │   ├── DevicesCommand.swift
    │   ├── DevicesList.swift
    │   └── DevicesRegister.swift
    └── Profiles/
        ├── ProfilesCommand.swift
        ├── ProfilesList.swift
        ├── ProfilesCreate.swift
        └── ProfilesDelete.swift
```

### Wiring files modified

| File | Change |
|------|--------|
| `Sources/Infrastructure/Client/APIClient.swift` | Added `func request(_ endpoint: Request<Void>) async throws` |
| `Sources/Infrastructure/Client/ClientFactory.swift` | Added 4 `make*Repository` methods |
| `Sources/ASCCommand/ClientProvider.swift` | Added 4 `make*Repository` static methods |
| `Sources/ASCCommand/ASC.swift` | Registered 4 new command groups |

### Tests

```
Tests/
├── DomainTests/CodeSigning/
│   ├── BundleIDTests.swift
│   ├── CertificateTests.swift
│   ├── DeviceTests.swift
│   └── ProfileTests.swift
├── InfrastructureTests/CodeSigning/
│   ├── SDKBundleIDRepositoryTests.swift
│   ├── SDKCertificateRepositoryTests.swift
│   ├── SDKDeviceRepositoryTests.swift
│   └── SDKProfileRepositoryTests.swift
└── ASCCommandTests/Commands/
    ├── BundleIDs/BundleIDsListTests.swift
    ├── Certificates/CertificatesListTests.swift
    ├── Devices/DevicesListTests.swift
    └── Profiles/ProfilesListTests.swift
```

---

## API Reference

| Operation | Endpoint | SDK call | Repository method |
|-----------|----------|----------|-------------------|
| List bundle IDs | `GET /v1/bundleIds` | `APIEndpoint.v1.bundleIDs.get(parameters:)` | `listBundleIDs(platform:identifier:)` |
| Create bundle ID | `POST /v1/bundleIds` | `APIEndpoint.v1.bundleIDs.post(_)` | `createBundleID(name:identifier:platform:)` |
| Delete bundle ID | `DELETE /v1/bundleIds/{id}` | `APIEndpoint.v1.bundleIDs.id(id).delete` | `deleteBundleID(id:)` |
| List certificates | `GET /v1/certificates` | `APIEndpoint.v1.certificates.get(parameters:)` | `listCertificates(certificateType:limit:)` |
| Create certificate | `POST /v1/certificates` | `APIEndpoint.v1.certificates.post(_)` | `createCertificate(certificateType:csrContent:)` |
| Revoke certificate | `DELETE /v1/certificates/{id}` | `APIEndpoint.v1.certificates.id(id).delete` | `revokeCertificate(id:)` |
| List devices | `GET /v1/devices` | `APIEndpoint.v1.devices.get(parameters:)` | `listDevices(platform:)` |
| Register device | `POST /v1/devices` | `APIEndpoint.v1.devices.post(_)` | `registerDevice(name:udid:platform:)` |
| List profiles (all) | `GET /v1/profiles` | `APIEndpoint.v1.profiles.get(parameters:)` | `listProfiles(bundleIdId:nil, profileType:)` |
| List profiles (filtered) | `GET /v1/bundleIds/{id}/profiles` | `APIEndpoint.v1.bundleIDs.id(id).profiles.get()` | `listProfiles(bundleIdId:id, profileType:)` |
| Create profile | `POST /v1/profiles` | `APIEndpoint.v1.profiles.post(_)` | `createProfile(name:profileType:bundleIdId:certificateIds:deviceIds:)` |
| Delete profile | `DELETE /v1/profiles/{id}` | `APIEndpoint.v1.profiles.id(id).delete` | `deleteProfile(id:)` |

**Note on `Request<Void>`:** Delete endpoints return `Request<Void>`. This required adding `func request(_ endpoint: Request<Void>) async throws` to `APIClient` (distinct from the generic `Decodable` variant).

---

## Testing

```bash
swift test --filter 'BundleIDsListTests'
swift test --filter 'CertificatesListTests'
swift test --filter 'DevicesListTests'
swift test --filter 'ProfilesListTests'
swift test  # all 267 tests
```

**Representative domain test:**
```swift
@Test func `profile carries bundleIdId as parent`() {
    let profile = MockRepositoryFactory.makeProfile(id: "prof-1", bundleIdId: "bid-99")
    #expect(profile.bundleIdId == "bid-99")
}
```

**Representative infrastructure test (parent ID injection):**
```swift
@Test func `listProfiles injects bundleIdId from request when filtering by bundle id`() async throws {
    let stub = StubAPIClient()
    stub.willReturn(ProfilesWithoutIncludesResponse(data: [
        AppStoreConnect_Swift_SDK.Profile(type: .profiles, id: "prof-1",
            attributes: .init(name: "My Profile", profileType: .iosAppStore, profileState: .active))
    ], links: .init(this: "")))

    let repo = SDKProfileRepository(client: stub)
    let result = try await repo.listProfiles(bundleIdId: "bid-99", profileType: nil)

    #expect(result[0].bundleIdId == "bid-99")
}
```

---

## Extending

**Add profile download** (exports `.mobileprovision` to disk):
```swift
// Domain
func downloadProfile(id: String) async throws -> Profile  // profileContent is base64

// Command
struct ProfilesDownload: AsyncParsableCommand {
    @Option var profileId: String
    @Option var outputPath: String
    // decode base64 profileContent → write to file
}
```

**Add bundle ID capabilities** (push, iCloud, Sign in with Apple, etc.):
```swift
// Domain
public struct BundleIDCapability: Sendable, Equatable, Identifiable, Codable { ... }
func listCapabilities(bundleIdId: String) async throws -> [BundleIDCapability]
func enableCapability(bundleIdId: String, type: CapabilityType) async throws -> BundleIDCapability
```
