# App Icons (REST)

`GET /api/v1/apps?include=icon` returns each app enriched with its primary build's icon asset. The icon template URL lets clients render at any size.

## REST Endpoint

| Endpoint | Query | Description |
|----------|-------|-------------|
| `GET /api/v1/apps` | — | List apps (no icons) |
| `GET /api/v1/apps` | `?include=icon` | List apps, each enriched with `iconAsset` |

### Example

```bash
asc web-server &
curl -s http://127.0.0.1:8420/api/v1/apps?include=icon | jq '.data[0].iconAsset'
```

```json
{
  "templateUrl": "https://is1-ssl.mzstatic.com/image/thumb/.../source/{w}x{h}bb.{f}",
  "width": 1024,
  "height": 1024
}
```

### Rendering the icon

Substitute `{w}`, `{h}`, `{f}` client-side. Aspect ratio is fixed by Apple's CDN (`bb` = bounded box). Examples:

| Size / format | URL result |
|---------------|------------|
| 120×120 PNG | `.../source/120x120bb.png` |
| 240×240 JPG | `.../source/240x240bb.jpg` |
| 1024×1024 PNG (original) | `.../source/1024x1024bb.png` |

Swift:

```swift
// Domain.ImageAsset.url(maxSize:format:)
asset.url(maxSize: 120)          // URL? with 120x120bb.png
asset.url(maxSize: 240, format: "jpg")
```

### When `iconAsset` is absent

- The query param was not `?include=icon` — default response never includes `iconAsset`
- The app has no app-store version, or no version has an attached build — field is omitted from JSON

## Architecture

```
ASCCommand
  └─ AppsController.loadApps(repo:includeIcon:)
        parallel: repo.fetchAppIcon(appId:) for every app
  ↓
Domain
  └─ App (adds optional iconAsset: ImageAsset?, with(iconAsset:))
  └─ ImageAsset (templateUrl, width, height, url(maxSize:format:))
  └─ AppRepository.fetchAppIcon(appId:) -> ImageAsset?
  ↓
Infrastructure
  └─ SDKAppRepository.fetchAppIcon
        GET /v1/apps/{id}/appStoreVersions?include=build&fields[builds]=iconAssetToken
        → match version.relationships.build → build.attributes.iconAssetToken
        → Domain.ImageAsset(templateUrl, width, height)
```

## Domain Models

### `ImageAsset`

```swift
public struct ImageAsset: Sendable, Codable, Equatable {
    public let templateUrl: String   // e.g. "https://.../source/{w}x{h}bb.{f}"
    public let width: Int
    public let height: Int

    public func url(maxSize size: Int, format: String = "png") -> URL?
}
```

### `App` (relevant additions)

```swift
public struct App: ... {
    public let iconAsset: ImageAsset?          // nil-omitting via encodeIfPresent
    public func with(iconAsset: ImageAsset?) -> App
}
```

## File Map

```
Sources/
├── Domain/
│   ├── Shared/ImageAsset.swift           (new)
│   └── Apps/App.swift                    (adds iconAsset + encodeIfPresent)
│   └── Apps/AppRepository.swift          (adds fetchAppIcon(appId:))
├── Infrastructure/
│   └── Apps/OpenAPIAppRepository.swift   (implements fetchAppIcon)
└── ASCCommand/
    └── Commands/Web/Controllers/AppsController.swift  (?include=icon + loadApps)

Tests/
├── DomainTests/Shared/ImageAssetTests.swift       (new)
├── DomainTests/Apps/AppIconTests.swift            (new)
├── DomainTests/Apps/AppRepositoryTests.swift      (+ fetchAppIcon tests)
├── InfrastructureTests/Apps/SDKAppRepositoryTests.swift  (+ iconAssetToken tests)
└── ASCCommandTests/Commands/Web/AppsControllerTests.swift (new)
```

## API Reference

| REST | CLI equivalent | SDK | Repository |
|------|----------------|-----|------------|
| `GET /api/v1/apps?include=icon` | — (REST-only) | `GET /v1/apps` + `GET /v1/apps/{id}/appStoreVersions?include=build` | `AppRepository.listApps(limit:)` + `AppRepository.fetchAppIcon(appId:)` |

## Testing

```swift
@Test func `apps list with include icon attaches iconAsset per app`() async throws {
    let mockRepo = MockAppRepository()
    let asset = ImageAsset(templateUrl: "https://.../{w}x{h}bb.{f}", width: 512, height: 512)
    given(mockRepo).listApps(limit: .any).willReturn(PaginatedResponse(data: [
        App(id: "42", name: "MyApp", bundleId: "com.test"),
    ]))
    given(mockRepo).fetchAppIcon(appId: .any).willReturn(asset)

    let apps = try await AppsController.loadApps(repo: mockRepo, includeIcon: true)
    let output = try OutputFormatter(format: .json, pretty: true)
        .formatAgentItems(apps, affordanceMode: .rest)
    #expect(output.contains("\"iconAsset\""))
}
```

```bash
swift test --filter 'AppsControllerTests|ImageAssetTests|AppIconTests|SDKAppRepositoryTests'
```

## Extending

### Cache icons per process

Wrap `SDKAppRepository` with an in-memory cache keyed by `appId` so the N+1 fetch runs only once per process per app.

### Add CLI flag

Expose `asc apps list --include-icon` by threading the flag through `AppsList.execute(repo:includeIcon:affordanceMode:)` and reusing `AppsController.loadApps` (or extracting it to a domain service).
