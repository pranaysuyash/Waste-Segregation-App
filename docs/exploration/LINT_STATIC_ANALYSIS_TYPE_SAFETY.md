# Lint / Static Analysis / Type Safety Audit

**Date**: 2026-05-24
**Status**: Exploration — audit and recommendations
**Parent**: [EXPLORATION_TOPICS.md](../EXPLORATION_TOPICS.md)
**Decision this unblocks**: Whether to adopt stricter lint rules, static analysis tools, and type safety patterns across the codebase

---

## 1. Current State

### Current configuration
- `analysis_options.yaml` — exists at project root
- Uses `package:flutter_lints` (default/recommended)
- No custom lint rules
- No `very_good_analysis` or `dart_code_metrics`

### Current analysis results
- `flutter analyze` passes (no errors) — info-level warnings exist
- No CI-enforced coverage thresholds
- No dead code detection in CI
- No performance linting

### Gaps identified
1. **No strict lint ruleset** — default `flutter_lints` misses many catchable issues
2. **No type safety enforcement** — `dynamic` usage is not surfaced as errors
3. **No coverage requirements** — CI does not fail on coverage drops
4. **No dead code detection** — unused imports, parameters, and widgets go unnoticed
5. **No performance linting** — missing `const` constructors and unnecessary rebuilds are not flagged
6. **No DCM or custom_lint** — advanced architectural rules are unavailable
7. **No format enforcement** — `dart format` is not required to pass in CI

---

## 2. Recommended Tools

### 2.1 Lint Ruleset

| Tool | Recommendation | Rationale |
|---|---|---|
| `package:flutter_lints` | Keep as base | Official, stable, non-breaking |
| `package:very_good_analysis` | Add on top | Stricter, opinionated, production-proven (used by Very Good Ventures) |
| `package:custom_lint` | Optional | For project-specific rules (e.g., "no direct Firebase calls outside services/") |
| `package:dart_code_metrics` | Consider | Additional metrics: cyclomatic complexity, component coupling, maintainability index |

**Suggested stack**: `flutter_lints` + `very_good_analysis` (strict mode) + optional `custom_lint` for project-specific rules.

### 2.2 Static Analysis

| Tool | Purpose | Status |
|---|---|---|
| `dart analyze` / `flutter analyze` | Standard analysis | Already used |
| `dart format --set-exit-if-changed` | Format enforcement | Not in CI |
| DCM (Dart Code Metrics) | Complexity, coupling, anti-patterns | Not used |
| `custom_lint` | Project-specific rules | Not used |

---

## 3. Type Safety Patterns

### 3.1 Current Anti-Patterns (from code search)

| Pattern | Occurrences | Risk |
|---|---|---|
| `dynamic` type usage | Unknown (needs search) | Runtime type errors |
| `Map<String, dynamic>` | Widespread in JSON parsing | No compile-time safety |
| Late initialization without guarantee | Some | Runtime late errors |
| `!` null assertion operator | Some | Runtime null errors |

### 3.2 Recommended Patterns

**Strict Mode (in analysis_options.yaml)**:
```yaml
analyzer:
  errors:
    unused_import: error
    unused_local_variable: error
    dead_code: error
    inference_failure_on_untyped_parameter: error
    avoid_dynamic_calls: warning
    strict_raw_type: error  # Catch 'var' where type is obvious
```

**Sealed Classes for State Management**:
```dart
sealed class ClassificationState {}
class Loading extends ClassificationState {}
class Success extends ClassificationState { final WasteClassification result; }
class Error extends ClassificationState { final String message; }

// Exhaustive switch — Dart enforces all cases at compile time
switch (state) {
  case Loading(): // show spinner
  case Success(:final result): // show result
  case Error(:final message): // show error
}
```

**Type-safe JSON Parsing**:
```dart
// Instead of Map<String, dynamic> fromJson()
factory WasteClassification.fromJson(Map<String, dynamic> json) {
  return WasteClassification(
    id: json['id'] as String,
    category: json['category'] as String,
    confidence: (json['confidence'] as num).toDouble(),
    // vs raw access: json['id'] (could be null, wrong type)
  );
}
```

### 3.3 Migration Approach

1. **Add strict analyzer rules** — start with `error` level for unused code
2. **Search and eliminate `dynamic`** — replace with proper types or `Object?` + pattern matching
3. **Eliminate unnecessary `!` assertions** — use null-aware operators (`??`, `?.`) or early returns
4. **Convert `Map<String, dynamic>` usages** — prefer typed DTOs and mappers

---

## 4. CI Pipeline Integration

### Recommended CI Check Order

```yaml
jobs:
  analyze:
    steps:
      - run: dart format --set-exit-if-changed .
      - run: flutter analyze
      - run: flutter test --coverage
      - run: # Generate coverage report; fail if < 80%
  # Run in parallel:
  dcm:
    steps:
      - run: dart run dart_code_metrics:metrics analyze lib
```

### Current CI status
- CI exists (`.github/workflows/ci.yml`)
- Runs `flutter analyze` and `flutter test`
- Does NOT enforce: formatting, coverage thresholds, DCM analysis, dead code detection

---

## 5. Dead Code Detection

### Built-in Analyzer Rules (already available, just need enabling)
```yaml
linter:
  rules:
    - unused_import
    - unused_local_variable
    - dead_code
    - avoid_unused_constructor_parameters
```

### DCM Advanced Detection
```yaml
dart_code_metrics:
  rules:
    - avoid-unused-parameters
    - avoid-unused-private-elements
    - no-empty-block
```

**Coverage gap**: Currently unused provider classes, dead widget files, and unused utility functions are not flagged. A one-time dead-code sweep plus enabling these rules would clean up significant technical debt.

---

## 6. Performance Linting

| Rule | What it catches |
|---|---|
| `prefer_const_constructors` | Missing const on constructors (prevents widget reuse) |
| `prefer_const_literals_to_create_immutables` | Unnecessary rebuilds of list/map literals |
| `avoid_redundant_argument_values` | Redundant default parameter values |
| `avoid_print` (warning) | Accidental debug prints in production |
| `use_key_in_widget_constructors` | Missing keys (affects reconciliation) |
| `avoid_unnecessary_containers` | Redundant widget tree nesting |

**Current state**: Most of these are not enforced at error level.

---

## 7. Implementation Roadmap

### Phase A: Configuration (1 session)
1. Add `very_good_analysis` package
2. Update `analysis_options.yaml` with strict rules
3. Run `flutter analyze` and fix new errors
4. Add `dart format` check to CI
5. Enable dead code lint rules

### Phase B: Type Safety (2-3 sessions)
6. Search and fix `dynamic` usage across codebase
7. Add sealed class patterns for state management where applicable
8. Audit `!` null assertion usage, replace with safe patterns
9. Audit `Map<String, dynamic>` usage, add typed mappers

### Phase C: Tooling (1 session)
10. Evaluate and optionally integrate DCM
11. Write `custom_lint` rules for project-specific patterns
12. Add coverage thresholds to CI
13. Document developer workflow in CONTRIBUTING.md

---

## 8. Expected Impact

| Change | Issues Caught | Effort |
|---|---|---|
| `very_good_analysis` + strict rules | 20-50 new warnings/errors per run | 1 session to fix initial batch |
| `dart format` enforcement | Format drift caught in CI | None (auto-fix with `--fix`) |
| Dead code lint rules | 5-15 unused imports/variables | 30 min to fix |
| Type safety audit | 20-50 `dynamic` uses, 10-30 `!` assertions | 2-3 sessions |
| Performance linting | 50-200 missing consts | 1 session (mechanical fixes) |
| Coverage enforcement | Prevents untested PRs | Add CI step (30 min) |

---

## 9. Risks and Mitigations

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| New lint rules cause CI failures | High | Medium | Enable incrementally; fix per category |
| `very_good_analysis` too strict | Medium | Low | Disable specific rules; document rationale |
| DCM license cost | Low (OSS) | Medium | Evaluate free tier first |
| Type safety audit high effort | High | Medium | Phase B over 2-3 sessions; prioritize critical paths |
| Developers push back on strict rules | Low | Low | CI is automated — no pushback needed; document in CONTRIBUTING.md |

---

## 10. Related

- [analysis_options.yaml](../../analysis_options.yaml) — current configuration
- [EXPLORATION_TOPICS.md](../EXPLORATION_TOPICS.md) — master exploration index
- `.github/workflows/ci.yml` — current CI configuration (needs format + coverage steps)
