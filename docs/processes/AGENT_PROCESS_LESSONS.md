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

### Lesson 8: Never Dismiss Failures as 'Pre-Existing' Without Investigation (§6, §0.1)

**Trigger**: Full test suite reported 50 failures. Assistant declared them "pre-existing golden test failures, not caused by any changes this session" without investigation.

**Consequence**: User called out the violation. Investigation revealed the failures were stale golden reference images — a real, fixable issue. After regeneration, all 79 golden tests passed. The 50→0 reduction meant 50 actual failures were being ignored.

**What went wrong**:  
The assistant saw "golden_test" in the failure names and assumed they were visual regression tests that drift over time. Without running `git stash && flutter test` to verify they fail on committed code, or checking whether any touched widgets could cause pixel drift, the failures were dismissed in a single sentence. This violated:

- §6: "'Pre-existing' Is Not an Excuse" — knowing about an issue is not permission to leave it
- §0.1: "Missed-Anything Sweep" — every failure in the blast radius must be investigated

**What actually happened**:  
50 golden tests had stale reference images because the UI had changed (new themes, layout updates, widget refactoring) but the `.png` references were never regenerated. The fix was `flutter test --update-goldens` — a one-command fix that took 30 seconds.

**First principle**:  
A failure is only genuinely pre-existing if ALL three conditions are met:
1. It fails on `origin/master` or a captured baseline before the current work
2. Proof is documented with command output (e.g., `git stash && flutter test`)
3. The current work did not touch the relevant area

If ANY condition is unverified, the failure is **assumed to be in your blast radius** until proven otherwise.

**Correct approach**:  
1. Run the failing tests in isolation first
2. If they fail, check if they fail on the committed baseline (`git stash && flutter test <file>`)
3. If they pass on baseline, investigate what your changes broke
4. If they fail on baseline, investigate root cause (stale goldens, test pollution, genuine bug)
5. Fix root cause — don't just document and move on
6. Report: "X failures investigated. Y were stale goldens (fixed). Z are genuine pre-existing (documented)."

**Anti-pattern**: "The 50 failures are pre-existing golden test failures, not caused by any changes this session." — This is an assumption stated as fact. It must be verified with evidence.

---

## Session: 2026-08-02 — Hive Schema Migration (Task 09 Backward-Compat)

### Lesson 1: Never Change the Type at an Existing @HiveField Index (§21 Code Is Evidence, ADR-First)

**Trigger**: Task 09 offline-queue storage migration (commit `b33b0616`) changed `@HiveField(1)` from `Uint8List imageBytes` to `String imageRefPath` — reusing the same index with a different type.

**Consequence**: Gen-2 records written under that schema became unreadable by the corrected schema (field-1 type flip String→Uint8List, fields 12/13 remapped). It never reached production (b33b0616 never shipped, no tags or release evidence reference it), but a code review caught it as a silent data-loss trap: anyone who ran the app between `b33b0616` and the fix would have lost queued records.

**What happened**: Hive generated adapters read fields with strict casts (`fields[1] as Uint8List?`). Reusing an index for a different type means legacy records either crash on read (cast failure) or silently misread (a string treated as a file path). The migration commit kept `imageRefPath` at field 1 where `imageBytes` used to live, breaking every pre-migration record.

**First principle** (§21 Code Is Evidence, §12 ADR-First): Hive field indices are part of the persisted binary contract — changing a type at an existing index is a breaking schema change, not a refactor.

**Correct approach**:
1. **Keep old fields at their original indices** — legacy bytes stay at field 1
2. **Append new fields at new, higher indices**, made nullable so pre-migration records (which lack them) read safely
3. **Key `isLegacyFormat` on a positive signal** (`imageBytes != null`), not a negative one (`imageRefPath.isEmpty`) — a partially-migrated item (bytes still set after a failed file save) must be picked up by migration/expiry, not evade both
4. **Assign missing metadata during migration** — legacy records predate `expiresAt`, so migration assigns it (24h active / 72h dead-letter) to honour the retention contract
5. **Write round-trip tests through the real generated adapters** (`box.put` → `box.get`) simulating legacy records with only the old fields populated
6. **Document schema generations in the ADR** — Gen-1/2/3 layouts and any never-shipped incompatibility window, so the decision is explicit (ADR-0006 §10)

**Anti-pattern**: Reusing an existing `@HiveField(n)` index with a new type "because the old field is being replaced anyway." The old records don't know they've been replaced — they will be read with the new type and crash or corrupt.

---

## Checklist for Future Agent Sessions (§6, §7, §22)

- [ ] Run `dart analyze` to get baseline error/warning/info counts
- [ ] Fix errors first (blocking), then warnings (important), then info (style)
- [ ] For each fix, verify it doesn't break other files (check imports) — **§7 Supersession**
- [ ] Run `flutter test` on affected test files after fixes
- [ ] Run full `flutter test` suite to confirm no regressions — **§22: analyzer ≠ tests**
- [ ] **§6: Every failure is in your blast radius until proven otherwise** — run failing tests against baseline (`git stash && flutter test`) before dismissing as pre-existing
- [ ] Categorize any remaining failures (pre-existing vs regression vs pollution)
- [ ] Document any new pre-existing failures with root cause and proof (command output)
- [ ] Spawn code-reviewer-mimo before declaring completion
- [ ] **Hive schema changes**: never change the type at an existing `@HiveField` index — keep old fields in place, append new nullable indices, key legacy-detection on a positive signal, and document schema generations in the ADR (§21, ADR-first)
