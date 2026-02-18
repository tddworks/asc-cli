
┌─────────────────────────────────────────────────────────────────────┐                                                                                                                                                                                                                                                    
│                   ARCHITECTURE: Screenshots Feature                  │                                                                                                                                                                                                                                                   
├─────────────────────────────────────────────────────────────────────┤                                                                                                                                                                                                                                                    
│                                                                      │
│  EXTERNAL              INFRASTRUCTURE              DOMAIN            │
│  ┌──────────────────┐  ┌────────────────────────┐ ┌──────────────┐  │
│  │ GET /v1/         │  │                        │ │AppScreenshot │  │
│  │ appStoreVersion  │─▶│ OpenAPIScreenshot      │─▶Set (struct) │  │
│  │ Localizations/   │  │ Repository             │ └──────────────┘  │
│  │ {id}/screenshot  │  │ (implements            │ ┌──────────────┐  │
│  │ Sets             │  │  ScreenshotRepository) │─▶AppScreenshot │  │
│  │                  │  │                        │ │ (struct)     │  │
│  │ GET /v1/         │  │                        │ └──────────────┘  │
│  │ appScreenshot    │─▶│                        │ ┌──────────────┐  │
│  │ Sets/{id}/       │  │                        │─▶ScreenshotDis│  │
│  │ appScreenshots   │  │                        │ │playType(enum)│  │
│  └──────────────────┘  └────────────────────────┘ └──────────────┘  │
│                                                    ┌──────────────┐  │
│                                                    │Screenshot    │  │
│                                                    │Repository    │  │
│                                                    │ (protocol)   │  │
│                                                    └──────────────┘  │
│                                                            │         │
│                                                            ▼         │
│  ┌─────────────────────────────────────────────────────────────────┐ │
│  │  ASCCommand Layer                                               │ │
│  │  asc screenshots                                                │ │
│  │    sets list --localization <id> [--output table|json|md]       │ │
│  │    list    --set <id>            [--output table|json|md]       │ │
│  └─────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────┘

Domain Models

AppScreenshotSet — a container of screenshots per display type for a localization:
id, screenshotDisplayType: ScreenshotDisplayType, screenshotsCount: Int

// User asks: "Is this a phone or tablet set?"
var deviceCategory: DeviceCategory { screenshotDisplayType.deviceCategory }

AppScreenshot — an individual screenshot within a set:
id, fileName, fileSize, assetState: AssetDeliveryState, imageWidth: Int?, imageHeight: Int?

// User asks: "Is this ready to view?"
var isProcessed: Bool { assetState == .processed }

ScreenshotDisplayType — enum mapping all ASC display types (APP_IPHONE_69, APP_IPAD_PRO_3GEN_129, etc.) with human-readable names.

AssetDeliveryState — awaitingUpload, uploadFailed, processing, processed.

Component Table

┌─────────────────────────────┬────────────────┬───────────────────────────────────────┬────────────────────────┬──────────────────────────────────────┐
│          Component          │     Layer      │                Purpose                │         Inputs         │               Outputs                │
├─────────────────────────────┼────────────────┼───────────────────────────────────────┼────────────────────────┼──────────────────────────────────────┤
│ AppScreenshotSet            │ Domain         │ Value type with display type behavior │ init                   │ computed properties                  │
├─────────────────────────────┼────────────────┼───────────────────────────────────────┼────────────────────────┼──────────────────────────────────────┤
│ AppScreenshot               │ Domain         │ Value type with asset state behavior  │ init                   │ isProcessed, etc.                    │
├─────────────────────────────┼────────────────┼───────────────────────────────────────┼────────────────────────┼──────────────────────────────────────┤
│ ScreenshotDisplayType       │ Domain         │ Enum with display name + category     │ raw SDK value          │ human-readable strings               │
├─────────────────────────────┼────────────────┼───────────────────────────────────────┼────────────────────────┼──────────────────────────────────────┤
│ ScreenshotRepository        │ Domain         │ DI boundary @Mockable                 │ localizationId / setId │ [AppScreenshotSet] / [AppScreenshot] │
├─────────────────────────────┼────────────────┼───────────────────────────────────────┼────────────────────────┼──────────────────────────────────────┤
│ OpenAPIScreenshotRepository │ Infrastructure │ SDK adapter                           │ APIProvider            │ domain models                        │
├─────────────────────────────┼────────────────┼───────────────────────────────────────┼────────────────────────┼──────────────────────────────────────┤
│ ScreenshotsCommand          │ ASCCommand     │ asc screenshots group                 │ —                      │ routes subcommands                   │
├─────────────────────────────┼────────────────┼───────────────────────────────────────┼────────────────────────┼──────────────────────────────────────┤
│ ScreenshotSetsCommand       │ ASCCommand     │ asc screenshots sets group            │ —                      │ routes subcommands                   │
├─────────────────────────────┼────────────────┼───────────────────────────────────────┼────────────────────────┼──────────────────────────────────────┤
│ ScreenshotSetsList          │ ASCCommand     │ asc screenshots sets list             │ --localization         │ table/JSON/markdown                  │
├─────────────────────────────┼────────────────┼───────────────────────────────────────┼────────────────────────┼──────────────────────────────────────┤
│ ScreenshotsList             │ ASCCommand     │ asc screenshots list                  │ --set                  │ table/JSON/markdown                  │
└─────────────────────────────┴────────────────┴───────────────────────────────────────┴────────────────────────┴──────────────────────────────────────┘

Files to Create

┌──────────────────────────────────────────────────────────────────────────────┬─────────────────────────────────────────┐
│                                     File                                     │                 Action                  │
├──────────────────────────────────────────────────────────────────────────────┼─────────────────────────────────────────┤
│ Sources/Domain/Screenshots/AppScreenshotSet.swift                            │ Create                                  │
├──────────────────────────────────────────────────────────────────────────────┼─────────────────────────────────────────┤
│ Sources/Domain/Screenshots/AppScreenshot.swift                               │ Create                                  │
├──────────────────────────────────────────────────────────────────────────────┼─────────────────────────────────────────┤
│ Sources/Domain/Screenshots/ScreenshotDisplayType.swift                       │ Create                                  │
├──────────────────────────────────────────────────────────────────────────────┼─────────────────────────────────────────┤
│ Sources/Domain/Screenshots/AssetDeliveryState.swift                          │ Create                                  │
├──────────────────────────────────────────────────────────────────────────────┼─────────────────────────────────────────┤
│ Sources/Domain/Screenshots/ScreenshotRepository.swift                        │ Create (@Mockable)                      │
├──────────────────────────────────────────────────────────────────────────────┼─────────────────────────────────────────┤
│ Sources/Infrastructure/Screenshots/OpenAPIScreenshotRepository.swift         │ Create                                  │
├──────────────────────────────────────────────────────────────────────────────┼─────────────────────────────────────────┤
│ Sources/ASCCommand/Commands/Screenshots/ScreenshotsCommand.swift             │ Create                                  │
├──────────────────────────────────────────────────────────────────────────────┼─────────────────────────────────────────┤
│ Sources/ASCCommand/Commands/Screenshots/ScreenshotSetsCommand.swift          │ Create                                  │
├──────────────────────────────────────────────────────────────────────────────┼─────────────────────────────────────────┤
│ Sources/ASCCommand/Commands/Screenshots/ScreenshotSetsList.swift             │ Create                                  │
├──────────────────────────────────────────────────────────────────────────────┼─────────────────────────────────────────┤
│ Sources/ASCCommand/Commands/Screenshots/ScreenshotsList.swift                │ Create                                  │
├──────────────────────────────────────────────────────────────────────────────┼─────────────────────────────────────────┤
│ Sources/ASCCommand/ClientProvider.swift                                      │ Modify — add makeScreenshotRepository() │
├──────────────────────────────────────────────────────────────────────────────┼─────────────────────────────────────────┤
│ Sources/ASCCommand/ASC.swift                                                 │ Modify — add ScreenshotsCommand.self    │
├──────────────────────────────────────────────────────────────────────────────┼─────────────────────────────────────────┤
│ Tests/DomainTests/Screenshots/AppScreenshotSetTests.swift                    │ Create                                  │
├──────────────────────────────────────────────────────────────────────────────┼─────────────────────────────────────────┤
│ Tests/DomainTests/Screenshots/AppScreenshotTests.swift                       │ Create                                  │
├──────────────────────────────────────────────────────────────────────────────┼─────────────────────────────────────────┤
│ Tests/DomainTests/Screenshots/ScreenshotDisplayTypeTests.swift               │ Create                                  │
├──────────────────────────────────────────────────────────────────────────────┼─────────────────────────────────────────┤
│ Tests/InfrastructureTests/Screenshots/OpenAPIScreenshotRepositoryTests.swift │ Create                                  │
└──────────────────────────────────────────────────────────────────────────────┴─────────────────────────────────────────┘  