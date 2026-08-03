# Round-3 Audit Scorecard (refreshed 2026-08-02)

> **Purpose:** Refresh the done-vs-pending status of every round-3 review finding now that
> Tasks 01 (release proof), 02 (image lifecycle), 06 (society policy authority), 08 (paid
> feature contracts) and 09 (offline queue privacy) are committed, and the **Task 03 round-3
> corrective work** (Firestore trust boundary) is complete on disk.
>
> **Method:** Every status below was verified against the **current on-disk code** (not commit
> messages). Evidence is a concrete file path + rule/line. Statuses are:
> `✅ DONE` · `🟡 PARTIAL` · `❌ PENDING` · `⛔ BLOCKED`.
> Where a fix is complete on disk but **not yet committed**, the status is `✅ DONE` with a
> ⚠️ **UNCOMMITTED** marker — commit is the remaining action.
>
> **Supersedes:** the earlier status tables in `SESSION_DELTA_VS_NEW_REVIEW_2026-08-02.md`
> and the previous revision of this scorecard where they conflict with this verified audit.

---

## Scorecard

| # | Round-3 finding | Status | Verified evidence | Notes / next step |
|---|---|---|---|---|
| 1 | Firestore user-create unrestricted; update checks full resulting doc, not changed-field diff | ✅ **DONE** | `firestore.rules:506-525` — `clientCanCreate`: `hasOnly(clientWritableKeys + [email,familyId,role] + serverOwnedKeys)` **and** `!hasServerOwnedValue(data)` **and** familyId/role/email null-or-absent guards. `firestore.rules:486-496` — `denyServerOwnedFieldMutation` and `clientWritableFieldDiff` both use `newData.diff(oldData).affectedKeys()` (diff-based, round-3). Shared `serverOwnedKeys()`/`clientWritableKeys()` helpers at `:464-479`; every nested access presence-guarded (`:531-543`) against rules-engine missing-key evaluation errors. `lib/services/cloud_storage_service.dart` — `_applyUserProfilePrivacyGuard` now strips `tokenWallet`/`tokenTransactions` before any write. Anti-drift invariant test added in `test/services/firestore_schema_drift_test.dart` (emittable server-owned keys ⊆ guard-stripped keys). Emulator gate: **150 firestore + 5 storage = 155 passing** (on-disk working tree, incl. Task 06 disposal tests) | Committed as Task 03 round-3 corrective (2026-08-03) — rules deploy-ready. Atomic set also includes the C-07 client refactor (`firebase_family_service.dart`, `firestore_schema_registry.dart`) so the subcollection move is self-consistent at HEAD |
| 2 | New security tests not run | ✅ **DONE** | `firestore-rules-test/package.json:7` — `test` script now runs `rules-test.spec.js classification-feedback-rules-test.spec.js family-rules-test.spec.js security-authz-test.spec.js`; `test:security` script added (`:8`). CI exercises it directly: `.github/workflows/ci.yml:46` `firebase_rules` job → `:63` `npm --prefix firestore-rules-test run test:all:emulator` → `test:all` → `npm test` includes the security spec. Spec grew +229 lines (SEC-01B create-restriction incl. negative familyId/role/email, SEC-01C diff-based update with server fields present) | Committed 2026-08-03 — `security-authz-test.spec.js` (+428 lines, production-shaped fixtures w/ server billing fields) + `firestore-rules-test/package.json` `test`/`test:security` wiring landed together |
| 3 | Family / shared-data authority unsafe | 🔶 **PARTIAL** (C-07 landed + committed) | Shared classifications now live under `families/{familyId}/shared_classifications/{classificationId}` (subcollection, C-07) with **read/create/update/delete all gated by `isFamilyMemberById`** — non-members get permission denied (emulator-tested: SEC-T3-09/09b/10/11 + family-rules read/update negatives). **Migration note (pre-launch, no data backfill needed):** any legacy top-level `shared_classifications` docs are orphaned by the path move — no production data exists to migrate, and a backfill script should be written before any future launch if old docs are found. Family `update` still allowed for **any** `belongsToFamily` member (`:148-151`) and `validateFamilyUpdate` only pins `createdBy`/`createdAt`/`id` → membership + settings remain member-mutable. Invitation update (`validateInvitationUpdate`) still does **not** protect `roleToAssign`. `validateClassificationFeedbackUpdate` allowlist still includes `adminReviewerId`/`adminNotes`/`adminReviewTimestamp`/`reviewStatus` — owner-writable reviewer/admin fields | Next corrective: family update → owner/admin role only; protect `roleToAssign`; remove reviewer/admin fields from client update allowlist |
| 4 | Webhook idempotency incorrect | ✅ **DONE** ⚠️ uncommitted | `functions/src/dodopayments_webhook.ts` — C-09/C-10 fix: **all side effects now run inside one atomic `db.runTransaction`** that reads `billing_events/{event.data.id}` first (gate keyed on the provider's unique **transaction ID**, not the webhookId header). Gate absent → side effects applied + gate doc created in the same commit; gate present → acknowledged `duplicate` with **no side effects** (a crash mid-transaction applies nothing, so redelivery re-processes safely). `creditTokenPurchase`/`grantPremiumAccess`/`revokePremiumAccess`/`recordSubscription` refactored to `tx`-scoped ops. **`subscription.active` now handled** (`payment.succeeded`/`subscription.active` → premium grant + record). Also fixed: `verify()` return was **double-`JSON.parse`d** (401 on every valid webhook) and the handler now verifies over `req.rawBody` (`{ rawBody: true }`) for signature fidelity. Emulator tests: `functions/test/dodopayments_webhook.emulator.test.js` — duplicate delivery credits **exactly once**, same event.id under rotated webhookId still duplicate, subscription.active grants + records, cancelled revokes, bad signature → 401/no side effects. `firestore.rules` + schema registry add `billing_events` (server-only, deny client) | ⚠️ **UNCOMMITTED** — `dodopayments_webhook.ts`, `dodopayments_webhook.emulator.test.js`, `firestore.rules`, `firestore_schema_registry.dart`, `functions/package.json` (DODO_WEBHOOK_SECRET env) modified in working tree. Commit as part of the billing corrective |
| 5 | App-store purchasing still client-authoritative | ❌ **PENDING** | `lib/services/purchase_service.dart:106,240,277,288` — still `buyNonConsumable` for a subscription SKU; no `purchaseToken`/`receipt`/`verifyPurchase` anywhere (`grep` empty); local `purchased`/`restored` stream events grant premium | Needs a server verify callable + renewal/expiry/refund reconciliation before store purchases can ship |
| 6 | External checkout eligibility incomplete | 🟡 **PARTIAL** | Server **improved**: `functions/src/create_checkout_session.ts:21-22,63-64` accepts `platform?` and validates via `isProductEligibleForPlatform`. Client **still doesn't send platform**: `lib/services/web_checkout_service.dart` has no `platform` field (grep empty) → server defaults to `'web'` for all mobile checkouts | Client must pass `platform` (+ install channel) so eligibility is correct per platform |
| 7 | Queue migration fails before migration starts | ✅ **DONE** | `lib/services/offline_queue_service.dart` — `@HiveField(1)` remains `Uint8List? imageBytes` (type preserved); `imageRefPath` at a **new** index; `isLegacyFormat => imageBytes != null` (`:137,:229`) + `_migrateLegacyItems()` (`:1073`). Old records deserialize safely. Regression-tested via `runLegacyMigrationForTesting` (`:265`) | Committed `e371ffad`. Schema rule upheld (never change type at an existing index) |
| 8 | Queue privacy implementation ≠ ADR | ❌ **PENDING** | Repo-wide crypto scan: `grep -rln 'AES|AesGcm|encrypt|decrypt' lib/ --include='*.dart'` → **no matches** (excluding generated); no `encrypted_image_store.dart`. Files still go to sandboxed temp dir as plaintext; ADR-0006 requires AES-256-GCM + per-item IV + read-verification + file deletion on completion + purge wiring | Scope caveat from previous scorecard **resolved** — the repo-wide scan confirms no encryption implementation exists anywhere in `lib/`. Either implement encryption or downgrade the ADR claim — code must match ADR-0006 |
| 9 | Release evidence / CI | ✅ **DONE** ⚠️ Task 06 uncommitted | `.github/workflows/ci.yml:81-104` — `functions:` job builds (`npm run build`) + tests (`npm test`); combined status job `needs: [analyze, firebase_rules, functions, test, golden, storybook, eval]` (`:190`); analyzer debt gate + `git diff --exit-code pubspec.yaml pubspec.lock` | Committed `fc6b7a49` (Task 01). **Task 06 round-3 corrective (uncommitted in working tree):** `comprehensive_testing.yml` static_analysis now runs `bash tools/check_analyzer_baseline.sh` (errors+warnings **blocking** — removed the `--no-fatal-warnings --no-fatal-infos` escape hatch); **Node 22 pinned** across all 7 `setup-node` usages (ci.yml storybook, firestore_rules_test.yml, sync-todos, markdown-lint, visual_regression_tests); legacy `firestore_rules_test.yml` **deleted** (duplicated `ci.yml` `firebase_rules` — which runs the identical `test:all:emulator` unconditionally on every PR/push to main and is in the automerge `needs`; its embedded jest tests were stale and its coverage check referenced functions no longer in `firestore.rules`, so it failed spuriously). Coverage parity preserved: 3 `disposal_instructions` tests added to `firestore-rules-test/rules-test.spec.js` (read succeeds auth, write fails auth, write fails unauth) — canonical suite now **150 firestore + 5 storage = 155 passing**. Webhook emulator test wired into `functions` `test:emulator` with `DODO_WEBHOOK_SECRET` set. **Ops follow-up:** if 'Firestore Rules Testing'/'Test Firestore Security Rules' was ever registered as a required status check in GitHub branch protection, remove the stale required check after this lands (cannot be done from this environment) |
| — | SWM 2026 four-stream taxonomy | ❌ **PENDING** | Not touched by Tasks 01/02/06/08/09. App still models wet/dry/hazardous/medical; BBMP pack still `BBMP-2024.1` per prior review | Separate workstream (taxonomy task in the review bundle) — out of scope for this refresh |
| — | Society policy authority | ✅ **DONE** | `firestore.rules:334` — `society_policies` read/create/update/delete rules; `societyVerifyFieldChanged()` blocks non-admin writes to `isVerified`/`verifiedById`/`verifiedAt`. `lib/services/society_policy_service.dart:116` — `verifySocietyPolicy` `@Deprecated`, rules reject non-admin writes. Haversine corrected at `:148` — `c = 2 * atan2(sqrt(a), sqrt(1 - a))` (proper 2-arg atan2) | Committed (Task 06) |
| — | Task 02 image-lifecycle retention/purge | ✅ **DONE** | `lib/services/enhanced_image_service.dart:411` — `localImageRetention = Duration(days: 90)`; `:424` `purgeExpiredLocalImages({Duration olderThan})`; wired at startup `lib/main.dart:293`. **Retention test now exists**: `test/services/storage_service_test.dart` exercises `purgeExpiredLocalImages`/`localImageRetention` | Committed `34b1fa6a`. Previous "no dedicated test" caveat **resolved** |
| — | Paid feature contracts (`sellable`) | ✅ **DONE** | `lib/models/premium_feature.dart` — `advanced_segmentation` and `offline_mode` marked `sellable: false`; `lib/services/premium_service.dart:318-345` filters to sellable-only; `premium_service_test.dart` aligned (38/38 pass) | Committed (Task 08) |

---

## Task commit mapping (verification anchor)

| Commit | Work |
|---|---|
| `fc6b7a49` | Task 01 — release-proof CI gates, Functions gate, release evidence |
| `34b1fa6a` | Task 02 — image-lifecycle retention and purge (+ retention test in `storage_service_test.dart`) |
| `e371ffad` | Task 09 backward-compat — legacy `imageBytes` schema fix |
| `490d3e10` / `de8783db` | Tasks 06/08/09 + test fixes, goldens, docs |
| `b33b0616` | Task 09 — offline queue storage migration + privacy contract |
| *(this commit, 2026-08-03)* | **Task 03 round-3 corrective** — `firestore.rules` (clientCanCreate + diff-based updates + shared_classifications subcollection + billing_events deny-all), `firestore-rules-test/package.json` + `security-authz-test.spec.js` (SEC-01B/01C wired into gate), `lib/services/cloud_storage_service.dart` (strip server-owned keys), `lib/services/firebase_family_service.dart` + `firestore_schema_registry.dart` (C-07 subcollection refactor), `test/services/firestore_schema_drift_test.dart` (anti-drift invariant) — 155 rules emulator tests passing |
| ⚠️ *(uncommitted)* | **Task 06 round-3 corrective (finding #9)** — warnings-blocking analyzer in `comprehensive_testing.yml`, Node 22 pinned across all workflows, legacy `firestore_rules_test.yml` deleted, 3 `disposal_instructions` tests added to `rules-test.spec.js` (155 rules emulator tests passing). **Ops follow-up:** remove any stale 'Firestore Rules Testing' required check from GitHub branch protection |

---

## Bottom line

**Tasks verified done:** 01 release-proof CI, 02 image-lifecycle retention/purge (now with a
dedicated test), 06 society policy authority, 08 sellable feature contracts, the
storage-migration/back-compat half of 09, and **Task 03 round-3 corrective (findings #1 and
#2 + the C-07 subcollection half of #3) — committed 2026-08-03 — 155 rules emulator tests
passing.**
**Task 06 round-3 corrective (finding #9, CI/release)** is also complete on disk — warnings
now blocking, Node 22 uniform, legacy duplicate rules workflow deleted, disposal_instructions
coverage preserved (155 rules emulator tests passing) — also not yet committed.

**Still pending (all P0 trust/release-critical):** shared/family authority residual (#3,
family update/invitation role/feedback admin fields), client→server store verification (#5),
checkout platform propagation (#6), and the encryption gap between ADR-0006 and the queue
implementation (#8). Webhook exactly-once (#4) is **complete on disk** — atomic
`billing_events` gate, `subscription.active` handled, signature-fidelity + double-parse fixes,
with a 5-test emulator suite proving no double-credit. SWM 2026 four-stream taxonomy remains
a separate open workstream.

**Sequencing recommendation:** Task 03 corrective now committed; the **C-09/C-10 webhook
corrective** (finding #4) remains uncommitted in the working tree and should be committed
next, then continue — **release proof ✅, authorisation (#1/#2 ✅, #3 residual), billing
(#4 ✅ on disk → commit; #5/#6), image lifecycle (#8)**.
Pricing/product/GTM work must not outrun these.

> **Pre-existing emulator failures (NOT caused by C-09/C-10):** `functions/test/`
> `spendUserTokens` claims-fallback + billing-authority (`8 !== 7`) and
> `buildTrainingDatasetManifest` (`0 !== 1`) fail even in isolation without the webhook test
> file. `npm run test:emulator` (and `ci`) is therefore red for pre-existing reasons. Track
> as a separate fix; do not attribute to the webhook corrective. The new
> `dodopayments_webhook.emulator.test.js` (6 tests) passes 6/6.
