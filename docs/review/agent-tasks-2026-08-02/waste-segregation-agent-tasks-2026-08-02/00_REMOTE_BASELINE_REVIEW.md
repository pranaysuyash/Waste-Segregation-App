> **Review baseline:** `pranaysuyash/Waste-Segregation-App`, branch `main`, commit `d7a9c73f75779ddcbf9f22f4ce2fba9a0280b171`
>
> **Remote commit date:** 2026-05-25
>
> **Review date:** 2026-08-02
>
> **Hard limitation:** This review does not include local, uncommitted, or unpushed work. Run `02_TASK_LOCAL_CHANGE_RECONCILIATION.md` before implementing any other task. Existing local work is authoritative where it is newer and intentional.

# Remote Baseline Review

## Executive judgment

The repository demonstrates serious engineering effort and unusually broad feature coverage. It does not yet demonstrate a stable, commercially defensible product.

The central issue is not code volume. It is the absence of a single, enforced truth across:

- product positioning;
- AI classification paths;
- state management;
- subscription entitlement;
- storage;
- policy taxonomy;
- documentation;
- CI and release evidence.

The app can become marketable, but only after reducing scope and moving the revenue proposition from generic consumer education to measurable operational compliance.

## Scorecard

These are reviewer judgments, not externally benchmarked scores.

| Dimension | Score | Reason |
|---|---:|---|
| Feature capability | 7/10 | Broad functionality and substantial implementation depth |
| Architecture coherence | 3/10 | Multiple overlapping services, state systems and storage paths |
| Security and authorisation | 2/10 | Client-controlled entitlement surface and broad Firestore access |
| Payment integrity | 2/10 | No complete server-authoritative store lifecycle |
| AI evidence quality | 4/10 | Eval harness exists, but golden data is synthetic and taxonomy is stale |
| Release confidence | 2/10 | No status evidence on latest commit and CI omits backend build/tests |
| Consumer marketability | 3/10 | Useful feature, weak standalone willingness-to-pay |
| B2B/BWG marketability | 7/10 | Strong regulatory trigger and recurring operational job |
| Saleability today | 2/10 | Trust, compliance, proof and product focus are incomplete |
| Long-term defensibility | 5/10 | Local policy, corrections and evidence could form a data moat if governed well |

## What is genuinely strong

1. **The core use case is legible.** A user can photograph waste, get a category and disposal guidance.
2. **The repository contains real operational thinking.** Backend proxying, cost telemetry, rate limiting, caching, App Check gates, token reservation and an eval harness are better than a demo-only architecture.
3. **Local policy is treated as a versioned layer.** The policy-engine direction is strategically correct.
4. **There is an explicit feedback and training-data direction.** This can become defensible if consent, review and provenance are enforced.
5. **The app has multiple distribution surfaces.** Consumer, family, society and community concepts can support a B2B2C model.

## Critical gaps

### P0: security and money

#### 1. Billing entitlements are not protected by the Firestore trust boundary

`firestore.rules` allows an authenticated user to update their own user document if gamification and token-wallet checks pass. It does not whitelist immutable or server-owned fields. A client can therefore attempt to alter fields such as `billing`, `billing.entitlements`, or `subscriptionTier`.

This is especially serious because backend classification resolves premium status from `users/{uid}.billing.entitlements.pro_subscription`.

**Consequence:** premium discounts or access can be forged unless rules and server ownership are corrected.

#### 2. Mobile store purchases are granted from client events

`lib/services/purchase_service.dart` grants premium when the client purchase stream reports `purchased` or `restored`. There is no complete server verification, expiry reconciliation, refund handling, cancellation handling or authoritative subscription lifecycle.

The service calls `buyNonConsumable` for a product described as a subscription.

**Consequence:** entitlement can become stale or fraudulent and cannot be trusted across devices.

#### 3. Dodo webhook idempotency is ordered incorrectly

`functions/src/dodopayments_webhook.ts` writes the webhook event as processed before executing entitlement or token-credit side effects. If processing fails afterward, the provider retry is treated as a duplicate and skipped.

**Consequence:** paid users can permanently miss access or tokens.

#### 4. External mobile checkout is exposed without a policy-compliant integration

The premium screen presents both store billing and a Dodo web checkout, with copy saying “No app store required.” Google Play permits alternative billing in India only under its programme requirements, APIs, reporting and user-choice rules. Apple limits external purchase links by storefront and entitlement.

**Consequence:** store rejection, removal, fee/reporting non-compliance or a broken subscription experience.

#### 5. Storage upload controls are incomplete

`getR2UploadUrl` lacks a content-length limit, server-owned folder policy, strong MIME validation, App Check, quota/rate limiting, object lifecycle, signed read policy and a robust public-delivery design.

**Consequence:** abuse, cost exposure and accidental disclosure of user images.

### P0: release evidence

- `docs/launch/LAUNCH_BLOCKERS.md` states Firestore rules were not deployed at the time of the recorded check.
- The latest remote commit has no combined CI status exposed by GitHub.
- `.github/workflows/ci.yml` does not build or test `functions/`.
- Flutter analysis explicitly ignores warnings and infos.
- The golden job can mutate `pubspec.yaml` during CI.
- The Storybook job runs the test command without using the provided server-starting CI script.
- There is no release build, signed artifact, smoke install or staging deployment gate.

### P1: AI and regulatory correctness

India's Solid Waste Management Rules, 2026 took effect on 1 April 2026 and require four-stream source segregation: wet, dry, sanitary and special-care waste.

The current code and eval data largely use the older taxonomy:

- Wet Waste
- Dry Waste
- Hazardous Waste
- Medical Waste

`AiService.localGuidelinesVersion` and generated references still identify BBMP 2024. The golden set is synthetic, unreviewed seed data and appears to test the older categorisation.

**Consequence:** the app can be technically consistent with itself while being inconsistent with current regulation and buyer workflows.

### P1: paid-product truthfulness

The premium catalogue advertises:

- Advanced Segmentation
- Offline Classification
- Advanced Analytics
- Data Export

The on-device service explicitly returns a placeholder result and does not run inference. Advanced segmentation remains incomplete. A paid plan must not market capabilities that are placeholders or partially routed.

### P1: architecture duplication

Examples:

- Provider and Riverpod coexist.
- `AiService` and `EnhancedAiApiService` each orchestrate provider routing, fallback and backend access.
- Client-side and backend AI paths remain in parallel.
- Firebase Storage and R2 concepts overlap.
- Store IAP and Dodo entitlements use different paths.
- Local Hive premium flags and Firestore billing fields both claim authority.
- `ResultPipeline` coordinates persistence, gamification, sync, community posting, ads, analytics and training capture in one non-transactional workflow.

This increases the probability of partial state, divergent behaviour and agent-created duplication.

### P1: documentation and issue hygiene

- Agent instructions point to `docs/APP_KNOWLEDGE_BASE.md`, while the file is under `docs/reference/APP_KNOWLEDGE_BASE.md`.
- Agent instructions also point to a current-issues file that does not exist at the stated path.
- Root and docs READMEs make conflicting “production-ready” and version claims.
- The open issue list contains old generated TODOs, including work that is partly or fully implemented.
- There is no reliable mapping from issue state to current code state.

### P1: brand collision

“ReLoop” is already used by multiple recycling products and companies, including mobile apps and a separate computer-vision waste product. Even before a formal trademark search, discoverability and confusion risk are high.

Do not invest further in the current brand until a structured naming and trademark screen is complete.

## Product and commercial review

### The weak proposition

> Take a photo and learn which bin to use.

This is useful, but it is episodic, easy to substitute with search or a general multimodal assistant, and difficult to monetise directly.

### The stronger proposition

> Help a building prove and improve correct four-stream segregation every day.

This has:

- a regulation-driven buyer;
- repeated use;
- measurable outcomes;
- operational records;
- a budget holder;
- expansion paths into training, audits, vendor performance and reporting.

### Recommended initial customer

Bengaluru Bulk Waste Generators:

- apartment complexes;
- schools and colleges;
- hotels and restaurants;
- offices and campuses;
- malls and event venues;
- authorised waste processors that need a resident/staff engagement layer.

### Recommended positioning

Do not compete head-on as a pickup marketplace or full waste processor.

Position the product as the **last-metre segregation assurance and evidence layer**:

- classify uncertain items;
- teach four-stream segregation;
- verify daily practice;
- capture corrections and contamination;
- train residents and staff;
- generate audit-ready evidence;
- expose trends by block, floor, department or vendor;
- integrate with processors and compliance portals.

### Revenue model priority

1. Per-site B2B SaaS or managed pilot.
2. White-label licence for authorised processors, facility-management companies or apartment-management platforms.
3. Sponsored household engagement funded by the society, processor, CSR programme or brand.
4. Consumer premium only after repeated consumer willingness-to-pay is demonstrated.

### Defensibility

The generic image classifier is not the moat.

The possible moat is:

- current municipal rule packs;
- buyer-specific workflows;
- reviewed corrections;
- contamination and uncertainty data;
- multilingual training;
- site-level evidence;
- audit exports;
- integrations with processors and compliance systems.

## Explicit kill list

Freeze until the core is trusted and sold:

- blockchain;
- additional social mechanics;
- new city expansion beyond one validated playbook;
- more premium tiers;
- broad marketplace;
- unverified carbon claims;
- hardware;
- new AI provider integrations;
- advanced on-device models without a benchmark and rollout gate;
- token-economy expansion;
- generic community feed growth.

## Decision

Continue the project, but stop treating the current repository as a nearly finished consumer launch.

Treat it as a capable prototype that must be converted into:

1. a secure and reproducible core;
2. a current four-stream classification and policy engine;
3. a narrow BWG compliance MVP;
4. a founder-led design-partner sale.
