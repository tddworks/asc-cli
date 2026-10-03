# Changelog

All notable changes to asc-swift will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

---

## [0.1.86] - 2026-10-03

### Changed
- Bug fixes and improvements.

---

## [0.1.85] - 2026-09-23

### Changed
- Docs reorganised: a short README, one folder per feature under `docs/features/`, and a full command reference generated from the binary (`docs/commands.md`). Releases before 0.18 moved to `docs/changelog/`. → [docs](docs/README.md) ([#29](https://github.com/tddworks/asc-cli/pull/29))
- Refused review submissions now list Apple's specific reasons (missing screenshots, content rights, App Privacy, pricing) instead of only "please check associated errors". ([#27](https://github.com/tddworks/asc-cli/pull/27))
- Dependencies updated to their latest releases, including appstoreconnect-swift-sdk 4.4.3 (was 4.2.0) and Hummingbird 2.27.0; `Package.swift` minimums raised to match. ([#27](https://github.com/tddworks/asc-cli/pull/27))

### Added
- `asc versions submit --with-products` submits every `READY_TO_SUBMIT` in-app purchase and subscription together with the app version, as first-time products require, with just your API key. `--dry-run` previews. → [docs](docs/features/submit-with-products/README.md) ([#27](https://github.com/tddworks/asc-cli/pull/27))
- `asc review-submissions create`, `items add`, `items remove` and `submit` build a review submission step by step. → [docs](docs/features/review-submissions/README.md) ([#27](https://github.com/tddworks/asc-cli/pull/27))
- `asc iap versions list`, `asc subscriptions versions list` and `asc subscription-groups versions list` show each product's review versions and state. REST: `GET /api/v1/{iap,subscriptions,subscription-groups}/:id/versions`. ([#27](https://github.com/tddworks/asc-cli/pull/27))
- `asc apps price-points list` and `asc apps prices set` set the app's price or make it free, fixing the "not eligible for submission until pricing has been set" refusal. → [docs](docs/features/app-pricing/README.md) ([#28](https://github.com/tddworks/asc-cli/pull/28))
- `asc app-availability create` sets the territories an app is sold in. REST: `POST /api/v1/apps/:appId/availability`. → [docs](docs/features/iap-subscription-availability/README.md) ([#28](https://github.com/tddworks/asc-cli/pull/28))
- `asc perf-metrics list --metric-type STORAGE` reads Apple's new storage metrics. ([#27](https://github.com/tddworks/asc-cli/pull/27))

### Fixed
- `asc app-availability get` on an app that was never set up returns `{"data":[]}` with a hint to run `create`, instead of a raw 404. ([#28](https://github.com/tddworks/asc-cli/pull/28))
- `asc review-submissions items list` shows what each item points at (app version, product versions and the rest) instead of an empty link. ([#27](https://github.com/tddworks/asc-cli/pull/27))

## Older releases

[0.18](docs/changelog/0.18.md) · [0.17](docs/changelog/0.17.md) · [0.16](docs/changelog/0.16.md) · [0.1](docs/changelog/0.1.md)

[Unreleased]: https://github.com/tddworks/asc-cli/compare/v0.1.86...HEAD
[0.1.86]: https://github.com/tddworks/asc-cli/compare/v0.1.85...v0.1.86
[0.1.85]: https://github.com/tddworks/asc-cli/compare/v0.18.4...v0.1.85
