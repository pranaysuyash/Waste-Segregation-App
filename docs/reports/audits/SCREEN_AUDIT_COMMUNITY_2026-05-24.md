# Screen Audit Report: `CommunityScreen`

**Date:** 2026-05-24  
**Scope:** Component-level review of feed loading, sync behavior, stats reconciliation, and moderation flow  
**Screen audited:** `lib/screens/community_screen.dart`  
**Method:** Evidence-first static audit (no app code changes)

---

## 1) Screen role and criticality

`CommunityScreen` is the social trust surface for collective impact. It directly affects:
- credibility of community stats,
- user confidence in feed authenticity,
- moderation/abuse controls,
- perceived product maturity for social features.

---

## 2) Flow map (ingress/egress)

## 2.1 Ingress
- Entry via `CommunityScreen(showAppBar: true|false)`.
- Initializes 3-tab controller (`Feed`, `Stats`, `Members`).

## 2.2 Core flows
1. `initState` calls `_loadCommunityData()`.
2. `_loadCommunityData()`:
   - reads `StorageService` and `CommunityService` from Provider,
   - initializes community backend,
   - loads local classifications,
   - **syncs user data to community feed**,
   - reads feed + stats,
   - runs reconciliation.
3. Manual sync (`sync` icon) runs `_forceSyncCommunityData()` with delta snackbars.
4. Feed item action supports report via `ModerationService.reportPost(...)`.

## 2.3 Egress
- No deep navigation to other screens in current implementation (except bottom sheet close/report submission).

---

## 3) Component-level findings

## 3.1 Screen load has write-side effects

**Evidence:**
- `_loadCommunityData()` calls `communityService.syncWithUserData(...)` during initial load/refresh.

**Risk (P1):**
- Opening/refeshing a read-heavy screen triggers write/sync operations by default.
- This can increase Firestore operation volume and create non-idempotent behavior risk perception even with dedupe safeguards.
- Better separation: read path vs explicit sync path.

---

## 3.2 Reconciliation panel comparison mismatch

**Evidence:**
- `Expected Total` uses `_getExpectedActivityCount()` = local classification count only.
- Feed can contain classification + achievement + streak items.

**Risk (P1):**
- UI reconciliation message can falsely report drift because comparison uses different semantics (classification-only expected vs mixed-activity feed actual).
- This undermines confidence in the “data reconciliation” narrative.

---

## 3.3 Dependency model consistency

**Evidence:**
- `CommunityScreen` uses `provider` package (`Provider.of<...>`), not Riverpod.

**Risk (P2):**
- Mixed state-management/DI patterns across app core screens increase maintenance and testing friction.
- Same cross-screen architectural inconsistency pattern observed elsewhere.

---

## 3.4 Error exposure and UX consistency

**Evidence:**
- Sync failures show raw exception text in snackbar (`'❌ Sync failed: $e'`).

**Risk (P2):**
- Potentially technical/internal error details leak into user-facing UX.
- Error UX tone differs from controlled mapping used in AI classification flows.

---

## 3.5 Members tab placeholder in production flow

**Evidence:**
- Members tab is static “Coming soon” placeholder.

**Risk (P3):**
- Placeholder is acceptable short-term but weakens perceived completeness of social module.

---

## 3.6 Service-side stats strategy quality

**Evidence (`community_service.dart`):**
- Uses stored stats doc with freshness window and background refresh.
- Includes recompute/reconcile path and discrepancy model.

**Strengths:**
- Good defensive design for stats consistency and stale handling.

**Risk:**
- Reconcile checks may still appear inconsistent when UI-level expected-count comparator is not aligned with canonical stats definition.

---

## 4) Prioritized findings

## P1 findings

### CM-01: Community load path performs sync writes by default
- Read-only screen entry should not implicitly trigger expensive sync mutation unless explicitly required.

### CM-02: Reconciliation panel compares incompatible metrics
- “Expected Total” (classification-only) vs feed activity count (multi-type) creates false drift warnings.

## P2 findings

### CM-03: Provider pattern divergence in social module
- Contributes to app-wide DI inconsistency.

### CM-04: Raw exception text exposed in sync failure snackbar
- Needs controlled, user-safe error mapping.

## P3 findings

### CM-05: Members tab is non-functional placeholder
- Product completeness gap (not a correctness bug).

---

## 5) Dependency map (screen-local)

- `CommunityService`:
  - feed writes/reads,
  - stats retrieval,
  - reconciliation.
- `StorageService`:
  - current user profile,
  - local classifications.
- `ModerationService`:
  - report post flow.
- `CommunityFeedItem`, `CommunityStats` model.

---

## 6) Verified vs inferred

## Verified
- Initial load path invokes `syncWithUserData`.
- Reconciliation expected count is derived from local classification count only.
- Feed can contain non-classification activity types.
- Sync failure path interpolates raw exception text in snackbar.

## Inferred
- Firestore cost/performance impact depends on user history size and sync frequency, but risk class is structurally present.

---

## 7) No-code recommendations

1. Split community read and sync concerns:
   - default load = read-only fetch,
   - explicit user-triggered sync = write path.
2. Align reconciliation panel metrics to canonical stats model (same units on both sides).
3. Standardize social-module dependency style with broader app DI direction.
4. Replace raw exception interpolation with curated user-safe messages.
5. Mark Members tab as roadmap item with expected availability to set user expectation clearly.

---

## 8) Final assessment

`CommunityScreen` has solid social scaffolding and reconciliation intent, but currently mixes read and sync concerns and presents one metric-comparison mismatch that can create false trust alarms.

**Overall status:** Strong foundation with medium-high trust signaling risk; prioritize load/sync separation and reconciliation metric alignment.
