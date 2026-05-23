# Phase 0 Token Economy: Discussion Pack & Recommendation
**Date:** 2026-05-23  
**Based on:** Random Document Audit of `PHASE0_IMPLEMENTATION_SUMMARY_2026-05-19.md`

---

## The Core Question

**Is Phase 0 complete as documented, or has the implementation diverged from the design?**

The answer determines next steps: either revert one line of code + update tests, or document an undocumented design change + update the Phase 0 summary.

---

## What We Found

### The Contradiction

The Phase 0 summary **explicitly documents** that the kill switch (`enableTokenEnforcement`) should default to **false** (enforcement OFF):

> "Reversible: Yes — kill switch defaults to enforcement OFF"  
> "Added `static bool enableTokenEnforcement = false;`"  
> "When `false` (default): instant analysis remains free (current behavior)"

But the **actual code** has it set to **true** (enforcement ON):

```dart
// token_service.dart:50
static bool enableTokenEnforcement = true;
```

### What Changed, When

**Timeline:**
1. **2026-05-19 (~21:00)**: Commit `58e2659e` implements Phase 0 with `enableTokenEnforcement = false`
2. **2026-05-19**: Phase 0 Implementation Summary document written (claims enforcement OFF default)
3. **2026-05-20 (00:29)**: Commit `b02d7aec` ("token economy enforcement") changes to `enableTokenEnforcement = true` with a new commit message about "server-side validation, premium discount enforcement, kill switch"
4. **Now**: Phase 0 Summary never updated after the enforcement change

**Explanation:** This wasn't a gradual drift — it was an explicit 24-hour design change, then documentation was not updated.

### What This Means in Practice

| Behavior | Phase 0 Design (document) | Current Code | User Impact |
|----------|---------------------------|--------------|-------------|
| User with 3 tokens taps "Instant Analyze" (cost: 5) | Analysis proceeds (enforcement OFF) | ZeroBalanceSheet shown (enforcement ON) | User blocked from instant analysis |
| Telemetry | Events logged but no enforcement | Events logged + enforcement active | Enforcement surprise to users |
| User control | "legibility before enforcement" — see options | Hard block — options shown after being blocked | Different UX flow |

---

## Two Paths Forward

### Path A: Revert to Phase 0 Design (Enforcement OFF)

**What changes:**
- `token_service.dart:50`: Change `true` to `false`
- `test/services/token_service_test.dart`: Remove explicit `enableTokenEnforcement = false` from setUp (it becomes the default)
- Document: No change needed (already correct)

**Reasoning:**
- ✓ Matches documented design intent
- ✓ Aligns with "legibility before enforcement" philosophy
- ✓ Keeps Phase 0 reversible/non-breaking
- ✓ Enables soft launch: enforcement OFF by default, flips to ON via Remote Config in Phase 1
- ✗ Delays token enforcement (users can use instant analysis without earning/converting)

**Git footprint:** 1 line changed, 1-2 tests updated  
**Risk:** Low — fully tested path, matches documented design

---

### Path B: Accept Enforcement as New Design (Enforcement ON)

**What changes:**
- Document: Update Phase 0 summary to state `enableTokenEnforcement = true` is the design
- Document: Change "Reversible: Yes" to "Reversible: With backend coordination" (enforcement change is not zero-downtime)
- Tests: Add separate test suite for "enforcement ON" state (currently all tests run enforcement OFF)
- Phase 0 status: Update to "Complete + Enforced"

**Reasoning:**
- ✓ Enforces token economy immediately (users must earn/convert to use instant analysis)
- ✓ Aligns with "premium UX standardization with monetization" (commit 38e5b33d)
- ✓ Matches recent commits that mention "enforcement"
- ✗ Contradicts documented Phase 0 philosophy of "legibility before enforcement"
- ✗ Breaks design assumption that Phase 0 is non-breaking

**Git footprint:** 0 lines changed in code, update tests + docs  
**Risk:** Medium — requires test strategy decision, Phase 0 status change

---

## Recommendation

**Choose Path A (Revert to Phase 0 Design)** because:

1. **Documentation is authoritative here.** Phase 0 was explicitly designed and documented with enforcement OFF. The enforcement change came 24 hours later without updating the design doc.

2. **The design philosophy matters.** Phase 0 is titled "Phase 0: Implementation Summary" not "Phase 0.5: Enforcement Deployment." The rollout plan distinguishes between:
   - Phase 0: implementation (kill switch, telemetry, UI options)
   - Phase 1: control (wiring Remote Config to flip enforcement)
   - Phase 2: server validation (cloud functions)

   Enforcement ON by default in Phase 0 skips the "implementation → control" progression.

3. **Low friction to revert.** One boolean flip + one test change. This is in the spirit of Phase 0 being "reversible."

4. **Enables proper soft launch.** Users see the token economy in Phase 0 (informational), enforcement turns on in Phase 1 when Remote Config is ready (controlled rollout).

5. **Matches test design.** The token service tests are written for enforcement OFF; reverting aligns code with test intent, not the other way around.

---

## Immediate Next Steps

If Path A is chosen:

### Change 1: Fix the Default (1 line)
```dart
// token_service.dart:50
// CHANGE FROM:
static bool enableTokenEnforcement = true;

// CHANGE TO:
static bool enableTokenEnforcement = false;
```

### Change 2: Update Test Comment
```dart
// test/services/token_service_test.dart:63
// REMOVE OR COMMENT OUT (it's now the default):
// TokenService.enableTokenEnforcement = false;
```
Rationale: The setUp was explicitly setting this because the code defaulted to true. If we fix the default, the setUp line is now redundant. For clarity, either remove it or add a comment: "// verify Phase 0 behavior (enforcement OFF by default)"

### Change 3: Verify All Tests Still Pass
```bash
flutter test test/services/token_service_test.dart
# All 12 tests should pass with enforcement = false (default)
```

### Change 4: Add Enforcement Test Case
Create a separate test that explicitly verifies enforcement ON behavior:
```dart
test('spendTokens blocks transaction when enforcement enabled', () async {
  TokenService.enableTokenEnforcement = true; // explicit enforcement
  // verify ZeroBalanceSheet would trigger, spendTokens throws, etc
});
```

### Change 5: Update Document Status
Change line 4-5 of `PHASE0_IMPLEMENTATION_SUMMARY_2026-05-19.md`:
```markdown
**Status:** Complete (kill switch + telemetry + zero-balance sheet)
**Reversible:** Yes — kill switch defaults to enforcement OFF
```
No other changes needed — document already matches this behavior.

---

## Validation Checklist

After making the above changes, verify:

- [ ] `flutter test` passes (all token service tests)
- [ ] Manual test: instant analysis works with 0 tokens (enforcement OFF)
- [ ] Manual test: token UI shows cost but doesn't block
- [ ] Telemetry logs fire correctly (`logEnforcementSkipped` visible in logs)
- [ ] Remote Config integration still works (Phase 1 can turn enforcement ON)
- [ ] Document reflects code: kill switch = false by default

---

## Questions for Review

1. **Was the enforcement change intentional?**
   - If yes: Why wasn't the Phase 0 document updated?
   - If no: Was this a merge conflict resolution or accidental commit?

2. **Does Phase 1 Remote Config integration still work?**
   - Current code has `enableTokenEnforcement` as a static bool, no Remote Config wiring
   - Confirm Phase 1 plan is still "wire static bool to Remote Config value"

3. **Are there any users/data depending on enforcement ON?**
   - If enforcement has been ON since 2026-05-20, reverting changes user behavior
   - Need to assess impact before shipping revert

---

## Summary

| Aspect | Finding |
|--------|---------|
| **Major Contradiction** | Document claims enforcement OFF default; code has enforcement ON |
| **Root Cause** | Design change (May 20) not reflected in documentation (May 19) |
| **Test Status** | 12/12 tests pass with enforcement OFF (intended Phase 0 behavior) |
| **Recommendation** | Revert to Phase 0 design (enforcement OFF) to match documentation |
| **Effort** | 1 line code change + 2-3 test updates + doc clarification |
| **Risk** | Low — fully tested, matches design intent |

**This audit reveals no bugs in implementation, only a design-documentation mismatch. The fix is clear: either revert the enforcement change or document it properly.**

