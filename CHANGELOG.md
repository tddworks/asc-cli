# Changelog

All notable changes to asc-swift will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- `asc iris app-privacy get`, `declare` and `publish` show, replace and publish an app's App Privacy label (Data Not Collected or the data it collects), so a submission is no longer refused over unpublished data usages; over CLI and REST. → [docs](docs/features/app-privacy/README.md) ([#46](https://github.com/tddworks/asc-cli/pull/46))

---

## [0.19.0] - 2026-11-19

### Added
- `asc iris app-compliance list` and `declare` answer an app's App Compliance page (China mainland Security Assessment, AI generated content), No or Yes with its evidence, over CLI and REST. → [docs](docs/features/app-compliance/README.md)

### Changed
- `asc versions submit` and `POST /api/v1/versions/:id/submit` refuse a version that can't be edited (e.g. Ready for Sale) before calling Apple, saying which states can go to review.
- **Breaking (library):** one `ASCKit` module (`import ASCKit`); 7 non-CRUD repositories take role names (`IrisAuthRepository` → `IrisSignIn`, …); `SubmissionRepository.submitVersion` → `AppStoreVersion.submitForReview(to:)`. → [design](docs/features/concept-folders/design.md)

### Fixed
- Command Center's Submit for Review no longer reports success when `versions submit` fails; it says the submission didn't go and points to the command log.

## Older releases

[0.18](docs/changelog/0.18.md) · [0.17](docs/changelog/0.17.md) · [0.16](docs/changelog/0.16.md) · [0.1](docs/changelog/0.1.md)

[Unreleased]: https://github.com/tddworks/asc-cli/compare/v0.19.0...HEAD
[0.19.0]: https://github.com/tddworks/asc-cli/compare/v0.18.9...v0.19.0
