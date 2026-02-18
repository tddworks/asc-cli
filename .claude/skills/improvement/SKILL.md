---
name: improvement
description: |
  Guide for making improvements to existing asc-swift (App Store Connect CLI) functionality using TDD. Use this skill when:
  (1) Enhancing existing features (not adding new ones)
  (2) Improving output formatting, performance, or code quality
  (3) User asks "improve X", "make Y better", or "enhance Z"
  (4) Small enhancements that don't require full architecture design
  For NEW features, use implement-feature skill instead.
---

# Improve asc-swift Feature

Make improvements to existing functionality using TDD and rich domain design.

## When to Use This vs Other Skills

| Scenario | Skill to Use |
|----------|--------------|
| Enhance existing behavior | **improvement** (this skill) |
| Add new feature | implement-feature |

## Workflow

```
┌─────────────────────────────────────────────────────────────┐
│  1. UNDERSTAND CURRENT STATE                                 │
├─────────────────────────────────────────────────────────────┤
│  • Read existing code                                        │
│  • Understand current behavior                               │
│  • Identify what to improve                                  │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  2. WRITE TEST FOR IMPROVED BEHAVIOR (Red)                   │
├─────────────────────────────────────────────────────────────┤
│  • Test describes the IMPROVED behavior                      │
│  • Test should FAIL initially                                │
│  • Keep existing tests passing                               │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  3. IMPLEMENT & VERIFY (Green)                               │
├─────────────────────────────────────────────────────────────┤
│  • Implement the improvement                                 │
│  • New test PASSES                                           │
│  • All existing tests still pass                             │
└─────────────────────────────────────────────────────────────┘
```

## Types of Improvements

### 1. Domain Model Improvements

Enhance value type behavior:

```
Examples:
- Add computed property for common queries (Build.isReady, App.shortIdentifier)
- Improve date formatting on Build.ageDescription
- Add convenience accessors on BetaGroup or BetaTester
- Better encapsulation of domain rules in ProcessingState
```

**Test approach**: State-based domain tests

```swift
@Test func `build provides human-readable processing state`() {
    let build = Build(id: "1", version: "2.0", processingState: .valid, uploadedDate: .now)
    #expect(build.processingState.displayName == "Valid")
}
```

### 2. Output Improvements

Enhance CLI output formatting:

```
Examples:
- Better table column widths or alignment
- Richer JSON output fields
- More useful error messages with suggestions
- Improved markdown formatting for apps/builds
```

**Test approach**: `OutputFormatterTests` with known domain model inputs

### 3. Infrastructure Improvements

Enhance OpenAPI adapters or error handling:

```
Examples:
- Better error messages from API failures
- Improved pagination handling
- More robust response field mapping
- Additional fields mapped from SDK types to domain types
```

**Test approach**: Adapter tests with mocked `APIProvider`

### 4. Command UX Improvements

Enhance CLI command ergonomics:

```
Examples:
- Better --help text
- Additional --filter or --sort options
- Smarter defaults for --limit
- Improved TUI navigation or display
```

**Test approach**: Argument parsing tests or manual TUI verification

## TDD Pattern (Chicago School)

```swift
@Suite
struct {Component}Tests {
    @Test func `{describes improved behavior}`() {
        // Given - standard setup
        let component = Component(...)

        // When - action
        let result = component.improvedMethod()

        // Then - verify improved state/return value
        #expect(result.hasImprovedProperty)
    }
}
```

Keep existing tests passing:

```bash
swift test  # Must remain all green
```

## Architecture Reference

| Layer | Location | Improvement Examples |
|-------|----------|---------------------|
| **Domain** | `Sources/Domain/` | New computed properties, convenience methods, better enums |
| **Infrastructure** | `Sources/Infrastructure/` | Better error mapping, additional field mapping |
| **ASCCommand** | `Sources/ASCCommand/` | Output formatting, command options, TUI enhancements |

## Guidelines

### Do
- Keep changes focused and minimal
- Maintain existing behavior
- Add tests for new behavior
- Follow existing code patterns

### Don't
- Over-engineer simple improvements
- Change unrelated code
- Break existing tests
- Add features (use implement-feature)
- Skip tests for "small" changes

## Checklist

- [ ] Current behavior understood
- [ ] Improvement scope defined (minimal)
- [ ] Test for improved behavior written
- [ ] Test FAILS before implementation
- [ ] Improvement implemented
- [ ] New test PASSES
- [ ] All existing tests still pass (`swift test`)