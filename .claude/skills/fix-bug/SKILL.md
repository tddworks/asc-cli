---
name: fix-bug
description: |
  Guide for fixing bugs in asc-swift (App Store Connect CLI) with Chicago School TDD: reproduce, find the layer that owns the rule, write a failing `should …` test, fix minimally. Use this skill when:
  (1) User reports a bug or unexpected `asc` / `asc web-server` output
  (2) A field is missing, wrong or `null` compared to App Store Connect
  (3) User asks "fix this bug" or "this doesn't work correctly"
  (4) An SDK bump added enum cases or fields the domain doesn't mirror yet
  For enhancements use improvement; for new commands use implement-feature.
---

# Fix a Bug in asc-swift

```
1. REPRODUCE & LOCATE  →  2. FAILING TEST (Red)  →  3. FIX & VERIFY (Green)
```

## Phase 1: Reproduce & Locate

1. **Reproduce** with the real command: `make run ARGS="<command> --pretty"`, or the REST route under `asc web-server`.
2. **Expected**: what the person or agent should see — the App Store Connect state, in our JSON schema.
3. **Actual**: what `asc` prints instead.
4. **The real response**: when the SDK answer matters, capture it and turn it into the test fixture with **placeholder data** (`1234567890`, `app-1`, `ver-1`) — never IDs, names, emails or text from a real account. Never log a key, JWT or cookie while investigating.

### Find the layer that owns the rule

Fix the bug where the rule lives, not at a call site that happens to show it:

| Symptom | Owner | Test lives in |
|---|---|---|
| Wrong `isLive` / `isEditable` / `isPending` | the state enum in `Sources/Domain/…` | `Tests/DomainTests/…` |
| Missing or wrong next command / `_links` | the model's `structuredAffordances` (CLI and REST both derive from it) | `Tests/DomainTests/…` |
| Field `null`, wrong value, missing parent ID | the `SDK*Repository` mapper in `Sources/Infrastructure/…` | `Tests/InfrastructureTests/…` |
| A value App Store Connect sends shows as `null` | a domain enum missing a case the SDK has (mapped via `init(rawValue:)` → `nil`) | Domain + Infrastructure |
| Wrong flag parsing, table, or JSON shape | the command in `Sources/ASCCommand/Commands/…` | `Tests/ASCCommandTests/…` |
| CLI right but REST wrong (or the reverse) | the controller in `Commands/Web/Controllers/` — CLI and REST should share one path; make them | `Tests/ASCCommandTests/…` |

If the right fix changes the JSON schema (renames or removes a field), that is a breaking change for agents: ask the user before fixing.

## Phase 2: Failing Test (Red)

Name the test after the **correct** behaviour, not the bug: `should <outcome> when <the situation that showed the bug>` → [Naming tests](../implement-feature/references/tdd-patterns.md#naming-tests). State-based only — stub the answer, assert the result, no `verify()`.

Example — after the SDK bump to 4.5.1, App Store Connect can send `koreaAgeRatingOverride: TWELVE_PLUS`, which our domain enum lacks:

```swift
@Test func `should show a Korea override of twelve plus when App Store Connect sends it`() async throws {
    // Given - the response that triggers the bug
    let stub = StubAPIClient()
    stub.willReturn(AgeRatingDeclarationResponse(
        data: AgeRatingDeclaration(
            type: .ageRatingDeclarations, id: "decl-1",
            attributes: .init(koreaAgeRatingOverride: .twelvePlus)
        ),
        links: .init(this: "")
    ))
    let repo = SDKAgeRatingDeclarationRepository(client: stub)

    // When - the real mapper reads it
    let declaration = try await repo.getDeclaration(appInfoId: "info-1")

    // Then - the EXPECTED value (fails before the fix: it is nil)
    #expect(declaration.koreaAgeRatingOverride == .twelvePlus)
}
```

Run it and **watch it fail for the right reason** (the assertion, or the missing symbol the test names). Report the red line to the user before touching `Sources/`:

```bash
swift test --filter 'SDKAgeRatingDeclarationRepositoryTests'
```

## Phase 3: Fix & Verify (Green)

1. **Minimal change** at the owner from Phase 1 — no unrelated refactors.
2. **Fix it once for both surfaces**: if the CLI and REST disagree, route both through the same code rather than patching each.
3. Run the suite again (green), then `swift test` (all green). A pre-existing flaky test that shows up is not part of this fix — mention it, don't fix it here.
4. Docs in the same change: `docs/features/<x>/README.md` Gotchas when the person could hit it again; `make docs` if a flag changed.

## Checklist

- [ ] Reproduced with the real command (or REST route)
- [ ] Owner of the rule identified (table above)
- [ ] `should …` test written for the correct behaviour, with placeholder fixture data
- [ ] Test FAILS before the fix — red reported to the user
- [ ] Minimal fix at the owner; CLI and REST share the path
- [ ] Test PASSES; full `swift test` green
- [ ] Feature README updated if the person could hit it again
- [ ] One line under `## [Unreleased]` → `### Fixed` in `CHANGELOG.md`: the effect in the person's words, with an absolute issue or PR link
