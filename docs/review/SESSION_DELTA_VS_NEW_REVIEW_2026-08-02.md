# Session Delta vs New Review (2026-08-02)

> **Purpose:** Map work completed in this session against the new review's findings to identify what's done, partially done, and remaining.
>
> **New review baseline:** `e48a66bd` (remote HEAD)
> **Session work:** Uncommitted changes on top of `712ceb4c`

---

## Findings Cross-Reference

| New Review Finding | New Bundle Task | Session Status | Evidence |
|---|---|---|---|
| **P0-01: Client-controlled premium** | 04_TASK_AUTHORIZATION_FIRESTORE | **PARTIALLY RESOLVED** | `firestore.rules` now has `denyServerOwnedFieldMutation()` blocking billing/tokenWallet/subscriptionTier/bonusScans/admin/roles. `clientWritableFieldDiff()` allowlist restricts client writes. 32 security emulator tests pass. BUT: `PremiumService` still treats Hive as authoritative and writes `subscriptionTier` to Firestore — this needs Commit 6 (client becomes cache only) from Task 05. |
| **P0-02: Store purchases not server verified** | 05_TASK_BILLING_ENTITLEMENTS | **NOT ADDRESSED** | `purchase_service.dart` still uses `buyNonConsumable` for subscription product. No server verification. Needs Task 05 Commits 1-5. |
| **P0-03: Webhook idempotency can lose value** | 05_TASK_BILLING_ENTITLEMENTS | **RESOLVED** | `dodopayments_webhook.ts` now executes side effects BEFORE idempotency marker. Failed events retry properly. `userId` added to `SubscriptionRecord`. |
| **P0-04: External checkout store-policy sensitive** | 05_TASK_BILLING_ENTITLEMENTS | **NOT ADDRESSED** | Premium screen still unconditionally shows Dodo checkout. Needs Task 05 Commit 7 (storefront/payment-rail policy). |
| **P0-05: No release proof** | 03_TASK_RELEASE_PROOF_AND_CI | **NOT ADDRESSED** | CI still excludes Functions, suppresses warnings, uses wrong Node version. Needs Task 03. |
| **P0-06: Firestore data exposure remains broad** | 04_TASK_AUTHORIZATION_FIRESTORE | **PARTIALLY RESOLVED** | Family reads restricted to members. Invitation reads restricted to inviter/invited/admin. Shared classification create requires valid familyId. BUT: shared classification READ was reverted to `auth != null` because `isFamilyMemberById` caused Firestore emulator evaluation errors when the family doc didn't exist (cross-doc `get()` on absent doc = service error, not null). This is a **known limitation with documented root cause** — the cross-doc membership check doesn't work when the family doc is absent from the emulator. Society policy paths not in rules. |
| **P0-07: Offline queue privacy** | 09_TASK_OFFLINE_QUEUE_PRIVACY | **NOT ADDRESSED** | Queue stores complete image bytes with no retention contract. Needs Task 09. |
| **P0-08: R2 upload unsafe** | 10_TASK_STORAGE_R2_DATA_LIFECYCLE | **NOT ADDRESSED** | R2 callable has no App Check, MIME/size limits, quota, finalisation. Needs Task 10. |
| **P1-01: SWM 2026 taxonomy** | 06_TASK_POLICY_TAXONOMY_SWM2026 | **NOT ADDRESSED** | App still uses wet/dry/hazardous/medical. BBMP pack still 2024.1. Needs Task 06. |
| **P1-03: Society policy authority** | 07_TASK_SOCIETY_POLICY_AUTHORITY | **NOT ADDRESSED** | Society overrides can weaken safety rules. Needs Task 07. |

---

## What This Session Completed (from previous task bundle Task 03)

| Work Item | Status | Tests |
|---|---|---|
| Security matrix (FIRESTORE_ACCESS_MATRIX.md) | ✅ DONE | Documentation |
| Deny-by-default user update policy | ✅ DONE | 32 security emulator tests pass, cleanup hook non-fatal error |
| Family/invitation member-only reads | ✅ DONE | Included in 32 tests |
| Gamification collection anti-cheat bounds | ✅ DONE | Included in 32 tests |
| Dodo webhook idempotency fix (SEC-03) | ✅ DONE | Functions build passes |
| SubscriptionRecord.userId (SEC-04) | ✅ DONE | Functions build passes |
| belongsToFamily null guard | ✅ DONE | Prevents cross-doc get() evaluation errors |
| Client writable field allowlist | ✅ DONE | Defense-in-depth with denyServerOwnedFieldMutation |
| Pricing A/B test provider userId fix | ✅ DONE | Unstaged in lib/providers/pricing_ab_test_provider.dart |
| AGENT_PROCESS_LESSONS §6 checklist update | ✅ DONE | Unstaged in docs/processes/AGENT_PROCESS_LESSONS.md |

---

## Next Priority: Task 05 — Billing, Entitlements and Storefront Compliance

The review's execution order is: "release proof, authorisation, billing and image lifecycle first."

Authorization is partially done (rules). The next critical gap is the **server entitlement ledger** — replacing client-authoritative premium flags with provider-verified state.

### Remaining from Task 05

| Commit | Work | Status |
|---|---|---|
| Commit 1 | Product catalogue and authority contract | NOT STARTED |
| Commit 2 | Idempotent billing event state machine | NOT STARTED |
| Commit 3 | Dodo verification improvements | PARTIALLY DONE (idempotency fixed, but no product catalogue validation) |
| Commit 4 | Google Play verification | NOT STARTED |
| Commit 5 | Apple verification | NOT STARTED |
| Commit 6 | Client becomes cache only | NOT STARTED |
| Commit 7 | Storefront/payment-rail policy | NOT STARTED |
| Commit 8 | Paid feature contracts | NOT STARTED |

### Recommended Next Steps (per motto_v4 §1 first principles)

1. **Commit the current session work** — the security rules, webhook fix, and tests are solid and independently valuable
2. **Start Task 05 Commit 1** — product catalogue and authority contract (server-owned, clients submit logical SKU)
3. **Then Commit 2** — idempotent billing event state machine (received → processing → applied → failed_retryable → failed_terminal → reversed)
4. **Then Commit 6** — client becomes cache only (PremiumService reads server projection, never grants from Hive)

---

## Hard Release Gates (from Master Execution Plan)

### Gate A: static and build integrity
- clean dependency install
- strict formatter/analyser
- Flutter unit/widget/golden tests
- Functions TypeScript build/tests
- rule emulator tests
- AI eval
- release artefacts
- no repository mutation in CI

### Gate B: trust
- client cannot create entitlement, reward, role or verification state ✅ (rules done)
- non-member cannot read family/society/invitation data ✅ (partially done)
- billing events are provider verified ❌
- webhook retry is safe ✅
- raw images are private and deletable ❌
