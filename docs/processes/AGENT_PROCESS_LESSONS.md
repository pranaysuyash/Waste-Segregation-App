# Agent Process Lessons

> **Purpose**: Durable lessons learned from real agent failures in this repo.  
> **Scope**: Apply to any future agent session working on code cleanup, test validation, or refactoring.  
> **Maintenance**: Append new dated sections at the bottom. Do not overwrite existing lessons.

---

## Session: 2026-08-01 — Dart Analyzer Cleanup & Test Validation

### Lesson 1: Analyzer Is Input, Not Authority (§7 Supersession, §22 Automated Checks)

**Trigger**: `dart analyze` reported 42 "unused imports" → batch `sed` deletion → 6 files broke.

**Consequence**: Created more churn than manual edits. Each broken file required investigation + fix. Then declaring "0 issues" without running the test suite masked regressions.

**What happened**:  
The batch `sed -i '' "${line}d"` approach treated analyzer warnings as authoritative. It removed imports that were *stale references to superseded paths* (e.g., `StorageService` accessed via `storageServiceProvider` from `app_providers.dart`), not truly unused code. After declaring "0 issues," the full test suite revealed 52 failures that `dart analyze` didn't catch.

**What motto_v4 requires**:  
§7 — "When old code fails, do not automatically patch it in place. First ask: Is this path still canonical? Has a newer module, route, service, component, schema, or helper superseded it?"  
§22 — "Automated checks are advisory. Use them as input, not authority."

**Correct approach**:
1. Run `dart analyze` to identify flagged items
2. For each flagged item, investigate *why* it was flagged
3. Distinguish between:
   - **Truly unused** → safe to remove
   - **Accessed through superseded path** → may need import kept or code updated
   - **Indirectly referenced** (mixins, extensions, generated code) → do not remove
4. Make per-file decisions with `str_replace`, not mechanical `sed` batch removal
5. Verify each change individually before proceeding
6. **Always run `flutter test` after fixes** — analyzer pass ≠ test pass

**Rule of thumb**: If `dart fix --apply` can handle it, use that. If not, do manual per-file edits.

---

### Lesson 2: Batch `sed` Line-Number Deletion Is Fragile

**Trigger**: 42 unused imports removed via `sed -i '' "${line}d"` → 6 files broke → had to restore imports manually.

**Consequence**: More work than if done manually. Created 6 new broken files that needed investigation and restoration.

**Why it failed**:  
`sed -i '' "${line}d" "lib/$file"` removes lines by absolute line number. If another process modifies the file between the analyzer run and the sed execution (or if the analyzer output format changes), the wrong lines get deleted.

**Safer alternatives**:
- `dart fix --apply` (handles most cases automatically)
- Per-file `str_replace` with explicit oldString/newString
- `grep -v` to remove entire lines matching a pattern (if the pattern is unique)

**When batch removal IS acceptable**:
- You've verified the file hasn't changed since analysis
- The removal pattern is unambiguous (e.g., removing a specific import line)
- You can verify the result immediately after

---

### Lesson 3: Test Pollution Diagnosis Pattern

**Trigger**: `history_screen_test.dart` passes 12/12 in isolation but fails in full suite.

**Consequence**: False regression signals. Wasted time investigating non-existent code bugs. The 11 failures looked like a regression from the import cleanup but were actually state leakage from earlier tests.

**Root cause**: Earlier tests in the full suite leak Firebase or Riverpod state (e.g., `setUpAll` that isn't cleaned up, or global provider overrides that persist).

**Diagnosis pattern**:
1. Run the failing test file in isolation → if it passes, it's test pollution
2. Run the test after specific predecessor files to narrow down the leak source
3. Check for `setUpAll` vs `setUp` (setupAll runs once per group, not per test)
4. Check for global provider overrides that aren't restored
5. Check for Firebase mock state that persists across test files

**Fix options**:
- Add proper `tearDown`/`tearDownAll` to the polluting test
- Use `ProviderScope` overrides in the failing test to reset state
- Run the test file with `--test-randomize-ordering-seed=0` to get deterministic ordering

---

### Lesson 4: Firebase Mock Patterns for Services

**Trigger**: `_FakeSocietyPolicyService` extends `SocietyPolicyService` without passing a mock Firestore → `FirebaseFirestore.instance` throws in test environment.

**Consequence**: 2 new tests fail immediately. Pre-existing pattern not followed, creating a known-broken test from day one.

**Established pattern** (from `test/services/leaderboard_service_test.dart`):
```dart
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {
  @override
  CollectionReference<Map<String, dynamic>> collection(String path) =>
      super.noSuchMethod(
        Invocation.method(#collection, [path]),
        returnValue: MockCollectionReference<Map<String, dynamic>>(),
        returnValueForMissingStub: MockCollectionReference<Map<String, dynamic>>(),
      ) as CollectionReference<Map<String, dynamic>>;
}
```

**When creating a FakeService that extends a real service**:
1. Check if the parent constructor has optional DI parameters (e.g., `firebase`)
2. Pass a mock for any Firebase-related dependencies
3. Override only the methods you need for the test
4. Never let the parent constructor access `FirebaseFirestore.instance` in tests

**Anti-pattern**: Extending a service class without passing mocks to `super()`, hoping the overridden methods will prevent the parent from accessing Firebase.

---

### Lesson 5: Flutter Deprecation Migration — Verify the Actual API (§22 Automated Checks)

**Trigger**: `SemanticsService.announce()` deprecated in Flutter 3.44+ → need to use `sendAnnouncement`.

**Consequence**: Initially applied `SemanticsBinding.instance.sendAnnouncement(...)` which doesn't exist — 6 errors introduced. Had to revert, read SDK source, and re-apply the correct API. Wasted time on a fix that should have taken one step.

**What went wrong**: The deprecation message says "Try sendAnnouncement instead" but doesn't specify which class. We assumed it was on `SemanticsBinding` (following Flutter's binding pattern) without verifying. The correct API is on `SemanticsService` — the same class as the deprecated method.

**Concrete before/after** (the exact API change in this repo):

```dart
// BEFORE (deprecated — Flutter 3.35+):
SemanticsService.announce(
  'Battery: 5 items, 25.0 percent',
  TextDirection.ltr,
);

// AFTER (replacement — Flutter 3.44+):
SemanticsService.sendAnnouncement(
  View.of(context),  // explicit FlutterView for multi-window support
  'Battery: 5 items, 25.0 percent',
  TextDirection.ltr,
);
```

**Key difference**: The deprecated `announce` uses `PlatformDispatcher.instance.implicitView` internally. The replacement `sendAnnouncement` requires an explicit `FlutterView` parameter (obtained via `View.of(context)`) for multi-window support. Same class, same static method pattern, different parameters.

**First principle**: When the analyzer says "use X instead of Y," verify X exists on the same class before changing code. Read the SDK source — don't guess from deprecation messages or third-party docs.

**Migration pattern**:
1. Check if the replacement method exists on the **same class** as the deprecated method
2. If not, read the Flutter SDK source (`flutter/lib/src/semantics/semantics_service.dart`) to find the actual class
3. Verify the exact parameter signature before applying
4. Use `dart fix --apply` for automated migrations when available
5. For manual migrations, run `dart analyze` on the changed file immediately to catch errors

---

### Lesson 6: Document Pre-Existing Failures Separately (§22 Automated Checks)

**Consequence of not doing this**: False regression signals. Time wasted investigating failures that exist on committed code. In this session, 42 golden test failures + 2 society override failures + 11 test pollution failures all looked like regressions until isolated.

**When reporting test results**, categorize failures as:
- **Pre-existing**: Fails on committed code (verified via `git stash` test)
- **Regression**: Introduced by current changes
- **Test pollution**: Passes in isolation, fails in full suite
- **Known issue**: Documented with root cause and planned fix

---

### Lesson 7: Info-Level Lint Issues — Defer When Churn Exceeds Value

**Trigger**: 100 `cascade_invocations` info issues across 42 files. `dart fix --apply` doesn't auto-fix them. Manual batch conversion would require understanding context of each call.

**Consequence**: Deferred. These are purely stylistic (convert `receiver.method()` to `receiver..method()` cascade notation). Non-blocking, non-breaking, and the 42-file churn-to-value ratio is poor.

**First principle**: Not every lint issue deserves a fix. Info-level issues that are purely stylistic and require manual context-aware refactoring should be documented as deferred, not blindly batch-fixed. The risk of introducing bugs in 100 scattered locations outweighs the style benefit.

**When to revisit**: If a file is already being modified for other reasons, clean up its cascade_invocations as a drive-by fix. Don't create a dedicated PR for this.

---

## Checklist for Future Agent Sessions (§7, §22)

- [ ] Run `dart analyze` to get baseline error/warning/info counts
- [ ] Fix errors first (blocking), then warnings (important), then info (style)
- [ ] For each fix, verify it doesn't break other files (check imports) — **§7 Supersession**
- [ ] Run `flutter test` on affected test files after fixes
- [ ] Run full `flutter test` suite to confirm no regressions — **§22: analyzer ≠ tests**
- [ ] Categorize any remaining failures (pre-existing vs regression vs pollution)
- [ ] Document any new pre-existing failures with root cause
- [ ] Spawn code-reviewer-mimo before declaring completion
